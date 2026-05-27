import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// Restrict CORS to our Supabase project
const ALLOWED_ORIGIN = Deno.env.get("ALLOWED_ORIGIN") ?? "https://hksxzuytcmqqwxmfjzdp.supabase.co";

const corsHeaders = {
  "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Rate limit for role-targeted notifications (prevents spam from newly registered users)
const ROLE_NOTIFY_RATE_LIMIT = 5;
const ROLE_NOTIFY_WINDOW_MINUTES = 60;

// Rate limit for user-targeted notifications (prevents any user from spamming another)
const USER_NOTIFY_RATE_LIMIT = 10;
const USER_NOTIFY_WINDOW_MINUTES = 60;

// ─── Direct APNs delivery ────────────────────────────────────────────────────
// We sign an ES256 JWT with our APNs auth key (.p8) and POST to
// https://api.push.apple.com/3/device/{token} per device. Apple requires HTTP/2;
// Deno Deploy negotiates HTTP/2 via ALPN automatically.

const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID") ?? "";
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID") ?? "";
const APNS_BUNDLE_ID = Deno.env.get("APNS_BUNDLE_ID") ?? "";
const APNS_PRIVATE_KEY_PEM = Deno.env.get("APNS_PRIVATE_KEY") ?? "";
// Production: api.push.apple.com. Sandbox: api.sandbox.push.apple.com (dev provisioning only).
const APNS_HOST = Deno.env.get("APNS_HOST") ?? "https://api.push.apple.com";

let cachedJwt: { token: string; refreshAfter: number } | null = null;

function base64UrlFromBytes(bytes: Uint8Array): string {
  let bin = "";
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function base64UrlFromString(str: string): string {
  return base64UrlFromBytes(new TextEncoder().encode(str));
}

async function importApnsPrivateKey(pem: string): Promise<CryptoKey> {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const der = Uint8Array.from(atob(cleaned), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    der.buffer,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
}

async function generateApnsJwt(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  // Apple requires JWT refresh at least every 60 min. Refresh at 50.
  if (cachedJwt && cachedJwt.refreshAfter > now) {
    return cachedJwt.token;
  }
  if (!APNS_KEY_ID || !APNS_TEAM_ID || !APNS_PRIVATE_KEY_PEM) {
    throw new Error("APNs env not configured: missing APNS_KEY_ID, APNS_TEAM_ID, or APNS_PRIVATE_KEY");
  }
  const header = base64UrlFromString(JSON.stringify({ alg: "ES256", kid: APNS_KEY_ID, typ: "JWT" }));
  const payload = base64UrlFromString(JSON.stringify({ iss: APNS_TEAM_ID, iat: now }));
  const signingInput = `${header}.${payload}`;
  const key = await importApnsPrivateKey(APNS_PRIVATE_KEY_PEM);
  const sigBuf = await crypto.subtle.sign(
    { name: "ECDSA", hash: { name: "SHA-256" } },
    key,
    new TextEncoder().encode(signingInput),
  );
  const sig = base64UrlFromBytes(new Uint8Array(sigBuf));
  const jwt = `${signingInput}.${sig}`;
  cachedJwt = { token: jwt, refreshAfter: now + 50 * 60 };
  return jwt;
}

interface ApnsResult {
  token: string;
  status: number;
  removed?: boolean;
  error?: string;
}

async function sendApns(
  deviceToken: string,
  apsPayload: Record<string, unknown>,
  jwt: string,
): Promise<Response> {
  return await fetch(`${APNS_HOST}/3/device/${deviceToken}`, {
    method: "POST",
    headers: {
      "authorization": `bearer ${jwt}`,
      "apns-topic": APNS_BUNDLE_ID,
      "apns-push-type": "alert",
      "content-type": "application/json",
    },
    body: JSON.stringify(apsPayload),
  });
}

// ─────────────────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Verify caller JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(
      authHeader.replace("Bearer ", "")
    );

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { target, userId, roles, title, body, data: notifData } = await req.json();

    if (!title || !body) {
      return new Response(JSON.stringify({ error: "title and body are required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let deviceTokens: string[] = [];

    if (target === "user" && userId) {
      // Sending to a specific user — caller must be admin or the user themselves
      const { data: callerProfile } = await supabaseAdmin
        .from("profiles")
        .select("role")
        .eq("id", user.id)
        .single();

      const isAdmin = callerProfile?.role === "admin" || callerProfile?.role === "super_admin";
      const isSelf = user.id === userId;

      if (!isAdmin && !isSelf) {
        return new Response(JSON.stringify({ error: "Forbidden" }), {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // ── Rate limit: non-admins may send at most USER_NOTIFY_RATE_LIMIT notifications
      // per target user per hour — prevents a user from spamming another user.
      if (!isAdmin) {
        const windowStart = new Date(
          Date.now() - USER_NOTIFY_WINDOW_MINUTES * 60 * 1000
        ).toISOString();

        const { count: recentCount } = await supabaseAdmin
          .from("push_notification_log")
          .select("id", { count: "exact", head: true })
          .eq("sent_by", user.id)
          .eq("target_user_id", userId)
          .gte("created_at", windowStart);

        if ((recentCount ?? 0) >= USER_NOTIFY_RATE_LIMIT) {
          return new Response(
            JSON.stringify({
              error: `Notification rate limit reached. Maximum ${USER_NOTIFY_RATE_LIMIT} notifications per user per hour.`,
            }),
            {
              status: 429,
              headers: {
                ...corsHeaders,
                "Content-Type": "application/json",
                "Retry-After": String(USER_NOTIFY_WINDOW_MINUTES * 60),
              },
            }
          );
        }
      }

      const { data: tokens } = await supabaseAdmin
        .from("device_tokens")
        .select("token")
        .eq("user_id", userId);

      deviceTokens = tokens?.map((t: { token: string }) => t.token) ?? [];

    } else if (target === "role" && roles && Array.isArray(roles)) {
      // Role-targeted notifications — ADMIN ONLY: only admins/super_admins may notify a role
      const { data: callerProfile, error: callerError } = await supabaseAdmin
        .from("profiles")
        .select("role")
        .eq("id", user.id)
        .single();

      if (callerError || !callerProfile) {
        return new Response(JSON.stringify({ error: "Could not verify caller role" }), {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const isAdmin = callerProfile.role === "admin" || callerProfile.role === "super_admin";
      if (!isAdmin) {
        return new Response(JSON.stringify({ error: "Forbidden: only admins can send role-targeted notifications" }), {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // ── Rate limit: max 5 role notifications per user per hour ────────────
      const windowStart = new Date(
        Date.now() - ROLE_NOTIFY_WINDOW_MINUTES * 60 * 1000
      ).toISOString();

      const { count: recentNotifs, error: rateError } = await supabaseAdmin
        .from("audit_logs")
        .select("id", { count: "exact", head: true })
        .eq("user_id", user.id)
        .eq("action", "send_push_notification")
        .gte("timestamp", windowStart);

      // Fail-closed: if the rate-limit query itself errors, refuse the request
      // rather than letting the notification through unchecked.
      if (rateError) {
        console.error("[send-push-notification] Rate-limit check failed:", rateError);
        return new Response(
          JSON.stringify({ error: "Rate limit check unavailable. Please try again shortly." }),
          {
            status: 429,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
              "Retry-After": "60",
            },
          }
        );
      }

      if ((recentNotifs ?? 0) >= ROLE_NOTIFY_RATE_LIMIT) {
        return new Response(
          JSON.stringify({
            error: `Notification rate limit reached. Maximum ${ROLE_NOTIFY_RATE_LIMIT} role notifications per hour.`,
          }),
          {
            status: 429,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
              "Retry-After": String(ROLE_NOTIFY_WINDOW_MINUTES * 60),
            },
          }
        );
      }
      // ─────────────────────────────────────────────────────────────────────

      const { data: profiles } = await supabaseAdmin
        .from("profiles")
        .select("id")
        .in("role", roles)
        .eq("status", "active");

      const userIds = profiles?.map((p: { id: string }) => p.id) ?? [];

      if (userIds.length > 0) {
        const { data: tokens } = await supabaseAdmin
          .from("device_tokens")
          .select("token")
          .in("user_id", userIds);

        deviceTokens = tokens?.map((t: { token: string }) => t.token) ?? [];
      }

      // Log this role-targeted notification for rate limiting
      await supabaseAdmin.from("audit_logs").insert({
        action: "send_push_notification",
        user_id: user.id,
        detail: `Role-targeted push to: ${roles.join(", ")} — ${title}`,
        timestamp: new Date().toISOString(),
      });

    } else {
      return new Response(JSON.stringify({ error: "Invalid target. Use 'user' with userId or 'role' with roles array." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (deviceTokens.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, message: "No registered device tokens found" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Direct APNs delivery ─────────────────────────────────────────────────
    const apsPayload: Record<string, unknown> = {
      aps: {
        alert: { title, body },
        sound: "default",
      },
      ...(notifData ?? {}),
    };

    let jwt: string;
    try {
      jwt = await generateApnsJwt();
    } catch (err) {
      console.error("[send-push-notification] APNs JWT signing failed:", err);
      return new Response(
        JSON.stringify({ error: "APNs credentials misconfigured", detail: String(err) }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const settled = await Promise.allSettled(
      deviceTokens.map(async (token): Promise<ApnsResult> => {
        const resp = await sendApns(token, apsPayload, jwt);
        if (resp.status === 200) {
          return { token, status: 200 };
        }
        // 410 = device token no longer valid; purge it.
        if (resp.status === 410) {
          await supabaseAdmin.from("device_tokens").delete().eq("token", token);
          return { token, status: 410, removed: true };
        }
        const errBody = await resp.text().catch(() => "");
        return { token, status: resp.status, error: errBody.slice(0, 500) };
      }),
    );

    const results: ApnsResult[] = settled.map((r) =>
      r.status === "fulfilled"
        ? r.value
        : { token: "?", status: 0, error: String(r.reason) }
    );
    const sent = results.filter((r) => r.status === 200).length;
    const failed = results.length - sent;

    console.log(`[send-push-notification] APNs sent=${sent} failed=${failed} of ${deviceTokens.length}`);

    return new Response(
      JSON.stringify({ sent, failed, total: deviceTokens.length, results }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("send-push-notification error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
