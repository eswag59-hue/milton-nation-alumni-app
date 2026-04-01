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

      if (!rateError && (recentNotifs ?? 0) >= ROLE_NOTIFY_RATE_LIMIT) {
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

    // Send via Supabase Push API (uses APNs key configured in Supabase Dashboard)
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const pushResponse = await fetch(`${supabaseUrl}/push/v1/send`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({
        recipients: deviceTokens.map((token) => ({
          device_token: token,
          provider: "apns",
        })),
        notification: { title, body },
        data: notifData ?? {},
      }),
    });

    const pushResult = pushResponse.ok
      ? await pushResponse.json().catch(() => ({}))
      : { error: await pushResponse.text() };

    console.log(`send-push-notification: sent to ${deviceTokens.length} device(s)`, pushResult);

    return new Response(
      JSON.stringify({ sent: deviceTokens.length, result: pushResult }),
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
