import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// Restrict CORS to our Supabase project
const ALLOWED_ORIGIN = Deno.env.get("ALLOWED_ORIGIN") ?? "https://hksxzuytcmqqwxmfjzdp.supabase.co";

const corsHeaders = {
  "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Rate limit: max invite SMS per admin per rolling window
const INVITE_RATE_LIMIT = 50;
const INVITE_RATE_WINDOW_MINUTES = 60;

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get Supabase client with service_role for DB access
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Verify the caller's JWT (must be admin or super_admin)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabaseAdmin.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify caller is admin or super_admin
    const { data: callerProfile, error: callerError } = await supabaseAdmin
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (
      callerError ||
      !callerProfile ||
      (callerProfile.role !== "admin" && callerProfile.role !== "super_admin")
    ) {
      return new Response(
        JSON.stringify({ error: "Only admins can send invites" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ── Per-admin rate limiting ────────────────────────────────────────────
    // Count invite SMS sent by this admin in the last rolling hour.
    const windowStart = new Date(
      Date.now() - INVITE_RATE_WINDOW_MINUTES * 60 * 1000
    ).toISOString();

    const { count: recentInvites, error: rateError } = await supabaseAdmin
      .from("audit_logs")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id)
      .eq("action", "send_invite")
      .gte("timestamp", windowStart);

    // Fail-secure: if audit table is unreachable, deny rather than bypass rate limit.
    if (rateError) {
      return new Response(
        JSON.stringify({ error: "Rate limit check failed. Please try again." }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    if ((recentInvites ?? 0) >= INVITE_RATE_LIMIT) {
      return new Response(
        JSON.stringify({
          error: `Invite limit reached. Maximum ${INVITE_RATE_LIMIT} invites per hour.`,
        }),
        {
          status: 429,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
            "Retry-After": String(INVITE_RATE_WINDOW_MINUTES * 60),
          },
        }
      );
    }
    // ─────────────────────────────────────────────────────────────────────

    // Parse request body
    const body = await req.json();
    const { phone, name } = body;

    if (!phone || typeof phone !== "string" || phone.trim().length < 7) {
      return new Response(
        JSON.stringify({ error: "A valid phone number is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Format phone to E.164
    let toPhone = phone.replace(/[\s\-\(\)\.]/g, "");
    if (!toPhone.startsWith("+")) {
      toPhone = "+1" + toPhone; // Default to US
    }

    // Branded invite message. STOP/HELP language is required by US carriers
    // for ANY A2P 10DLC traffic. This message must go through a SEPARATE
    // (future) TCR campaign registered with a Marketing or Mixed use case —
    // DO NOT send through the 2FA-only OTP campaign or carriers will silently
    // drop it and the OTP campaign risks suspension.
    const appStoreUrl = Deno.env.get("APP_STORE_URL") ??
      "https://apps.apple.com/us/app/milton-nation";
    const greeting = name ? `Hi ${name.trim()}, ` : "";
    // HIPAA NOTE (2026-05-31): an SMS that explicitly identifies the recipient
    // as an alumni of a specific Substance Use Disorder treatment program
    // creates PHI under the HIPAA 18-identifiers rule (phone + treatment-
    // program association). Invite SMS is intentionally vendor-anonymous;
    // recipient learns the specific program name only after installing the
    // app and signing in (inside BAA-covered Supabase). Update the App Store
    // listing title in tandem so the install destination isn't itself a
    // disclosure.
    const message =
      `${greeting}you've been invited to a peer recovery community app. ` +
      `Stay connected, find meetings, and reach your care team — all in one place.\n\n` +
      `Download for iOS: ${appStoreUrl}\n\n` +
      `Reply STOP to opt out, HELP for help.`;

    // Send SMS via Twilio.
    // Routed through the MARKETING-use-case Messaging Service (separate from
    // the 2FA OTP Messaging Service) so this invite traffic doesn't risk the
    // 2FA campaign's standing with carriers. The Messaging Service handles
    // sender selection automatically; do NOT set `From` here.
    // Service SID: MG58c4c25a365e158067a5875b6488bad8 (created 2026-06-01).
    // Falls back to TWILIO_INVITE_MESSAGING_SERVICE_SID env override for
    // staging / disaster-recovery rotation.
    const twilioSid = Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";
    const twilioAuth = Deno.env.get("TWILIO_AUTH_TOKEN") ?? "";
    const inviteMessagingServiceSid =
      Deno.env.get("TWILIO_INVITE_MESSAGING_SERVICE_SID") ??
      "MG58c4c25a365e158067a5875b6488bad8";

    const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${twilioSid}/Messages.json`;
    const twilioBody = new URLSearchParams({
      To: toPhone,
      MessagingServiceSid: inviteMessagingServiceSid,
      Body: message,
    });

    const twilioResponse = await fetch(twilioUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: "Basic " + btoa(`${twilioSid}:${twilioAuth}`),
      },
      body: twilioBody.toString(),
    });

    if (!twilioResponse.ok) {
      const twilioErrorRaw = await twilioResponse.text();
      console.error("Twilio error:", twilioErrorRaw);

      // Parse Twilio's error message for a user-friendly response
      let twilioMsg = "Failed to send invite SMS.";
      try {
        const parsed = JSON.parse(twilioErrorRaw);
        if (parsed.message) twilioMsg = parsed.message;
      } catch { /* use default */ }

      // Common Twilio trial-mode hint
      const hint = twilioMsg.toLowerCase().includes("unverified")
        ? " Twilio trial accounts can only send to verified numbers — verify the recipient in your Twilio Console or upgrade your account."
        : "";

      return new Response(
        JSON.stringify({ error: twilioMsg + hint }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Log the invite in the audit_logs table
    await supabaseAdmin.from("audit_logs").insert({
      action: "send_invite",
      user_id: user.id,
      detail: `Invited ${toPhone}${name ? " (" + name.trim() + ")" : ""}`,
      timestamp: new Date().toISOString(),
    });

    // Mask the phone for the response
    const maskedPhone =
      toPhone.slice(0, -4).replace(/./g, "*") + toPhone.slice(-4);

    return new Response(
      JSON.stringify({ success: true, phone: maskedPhone }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("send-invite-sms error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
