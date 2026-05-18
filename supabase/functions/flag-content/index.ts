import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// Restrict CORS to our Supabase project
const ALLOWED_ORIGIN = Deno.env.get("ALLOWED_ORIGIN") ?? "https://hksxzuytcmqqwxmfjzdp.supabase.co";

const corsHeaders = {
  "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ── Types ─────────────────────────────────────────────────────────────────────

interface FlagPayload {
  userId?: string;
  riskLevel: "low_risk" | "medium_risk" | "high_risk";
  categories: string[];      // e.g. ["self_harm", "drugs"]
  feature: string;           // e.g. "chat", "community_post"
  redactedSummary: string;   // e.g. "high_risk:self_harm:3_matches" — NO raw text
  isEmergency: boolean;
  timestamp: string;         // ISO 8601
}

// ── Main Handler ──────────────────────────────────────────────────────────────

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

    // ── Auth: require valid JWT ──────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Parse & validate payload ─────────────────────────────────────────────
    const payload: FlagPayload = await req.json();

    if (!payload.riskLevel || !payload.categories || !payload.feature || !payload.redactedSummary) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const VALID_RISK_LEVELS = ["low_risk", "medium_risk", "high_risk"];
    if (!VALID_RISK_LEVELS.includes(payload.riskLevel)) {
      return new Response(JSON.stringify({ error: "Invalid risk_level" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Verify payload userId matches JWT (or is null for anonymous) ─────────
    // Prevents a user from flagging content on behalf of a different user.
    if (payload.userId && payload.userId !== user.id) {
      return new Response(JSON.stringify({ error: "userId mismatch" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── 1. Store the flag (no raw text — only redactedSummary) ───────────────
    const { data: flag, error: insertError } = await supabaseAdmin
      .from("content_flags")
      .insert({
        user_id:          payload.userId ?? user.id,
        risk_level:       payload.riskLevel,
        categories:       payload.categories,
        feature:          payload.feature,
        redacted_summary: payload.redactedSummary,
        is_emergency:     payload.isEmergency ?? false,
        timestamp:        payload.timestamp ?? new Date().toISOString(),
        review_status:    "pending",
      })
      .select("id")
      .single();

    if (insertError || !flag) {
      console.error("flag-content: insert error:", insertError);
      return new Response(JSON.stringify({ error: "Failed to store flag" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const flagId = flag.id as string;

    // ── 2. Notify ALL admins AND super_admins (platform policy: all risk levels) ──
    const adminNotifyCount = await notifyAdmins(supabaseAdmin, {
      flagId,
      riskLevel: payload.riskLevel,
      categories: payload.categories,
      feature: payload.feature,
      isEmergency: payload.isEmergency,
      reportingUserId: user.id,
    });

    // ── 3. Audit log ─────────────────────────────────────────────────────────
    await supabaseAdmin.from("audit_logs").insert({
      action:    "content_flagged",
      user_id:   user.id,
      detail:    `flag_id:${flagId} ${payload.redactedSummary}`,
      timestamp: new Date().toISOString(),
    });

    console.log(`flag-content: stored flag ${flagId}, notified ${adminNotifyCount} admin(s)`);

    return new Response(
      JSON.stringify({ flagId, notified: adminNotifyCount }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("flag-content error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

// ── Admin Notification ────────────────────────────────────────────────────────

interface NotifyParams {
  flagId: string;
  riskLevel: string;
  categories: string[];
  feature: string;
  isEmergency: boolean;
  reportingUserId: string;
}

async function notifyAdmins(
  supabase: ReturnType<typeof createClient>,
  params: NotifyParams
): Promise<number> {

  try {
    // Fetch device tokens for ALL admins and super_admins
    const { data: adminProfiles } = await supabase
      .from("profiles")
      .select("id")
      .in("role", ["admin", "super_admin"])
      .eq("status", "active");

    if (!adminProfiles || adminProfiles.length === 0) {
      console.warn("flag-content: no active admins found to notify");
      return 0;
    }

    const adminIds = adminProfiles.map((p: { id: string }) => p.id);

    const { data: tokens } = await supabase
      .from("device_tokens")
      .select("token")
      .in("user_id", adminIds);

    const deviceTokens: string[] = tokens?.map((t: { token: string }) => t.token) ?? [];

    if (deviceTokens.length === 0) {
      console.warn("flag-content: admins found but no registered device tokens");
      return 0;
    }

    // Build notification content.
    // High-risk gets distinct, urgent copy that won't be skimmed past in a
    // crowded notification tray. Medium and low keep the descriptive format
    // since they're less time-sensitive and admins benefit from knowing the
    // categories at a glance.
    const riskEmoji   = params.riskLevel === "high_risk"   ? "🚨"
                      : params.riskLevel === "medium_risk" ? "⚠️"
                      : "ℹ️";
    const riskLabel   = params.riskLevel.replace("_", " ").replace(/\b\w/g, c => c.toUpperCase());
    const categoryStr = params.categories
      .map(c => c.replace("_", " ").replace(/\b\w/g, ch => ch.toUpperCase()))
      .join(", ");
    const featureStr  = params.feature.replace("_", " ").replace(/\b\w/g, c => c.toUpperCase());

    let title: string;
    let body:  string;
    if (params.riskLevel === "high_risk") {
      // Urgent — surface above other notifications, demand immediate review
      title = params.isEmergency
        ? "🚨 URGENT — Member Safety Alert"
        : "🚨 Member Safety Alert";
      body  = "Crisis content detected. Tap to review immediately.";
    } else {
      // Medium / low — descriptive so admins can prioritize across multiple
      const emergency = params.isEmergency ? " [EMERGENCY]" : "";
      title = `${riskEmoji} Content Flag: ${riskLabel}${emergency}`;
      body  = `${categoryStr} detected in ${featureStr}. Tap to review.`;
    }

    // Send via Supabase Push API
    const supabaseUrl       = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

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
        data: {
          type:       "content_flag",
          flagId:     params.flagId,
          riskLevel:  params.riskLevel,
          categories: params.categories.join(","),
          feature:    params.feature,
          isEmergency: String(params.isEmergency),
        },
      }),
    });

    if (!pushResponse.ok) {
      const errText = await pushResponse.text();
      console.error("flag-content: push notification failed:", errText);
      return 0;
    }

    return deviceTokens.length;

  } catch (err) {
    console.error("flag-content: notifyAdmins error:", err);
    return 0;
  }
}
