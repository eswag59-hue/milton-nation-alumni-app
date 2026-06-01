import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// Restrict CORS to our Supabase project
const ALLOWED_ORIGIN = Deno.env.get("ALLOWED_ORIGIN") ?? "https://hksxzuytcmqqwxmfjzdp.supabase.co";

const corsHeaders = {
  "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Rate limit: max OTP requests per user per window
const RATE_LIMIT_MAX = 5;
const RATE_LIMIT_WINDOW_MINUTES = 60;

// ── App Store reviewer demo account ───────────────────────────────────────────
// Only active when DEMO_BYPASS_ENABLED=true is set as an Edge Function secret.
// Set this in Supabase Dashboard → Edge Functions → Secrets for review builds only.
// NEVER enable in production — disable after Apple review is complete.
// Matches the demo bypass in verify-sms-otp.
const DEMO_BYPASS_ENABLED = Deno.env.get("DEMO_BYPASS_ENABLED") === "true";
const DEMO_PHONE = "15550001234"; // Supabase stores without leading +
// ─────────────────────────────────────────────────────────────────────────────

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

    // Verify the user's JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Rate limiting ──────────────────────────────────────────────────────
    // Count how many OTP challenges this user has requested in the last hour.
    const windowStart = new Date(Date.now() - RATE_LIMIT_WINDOW_MINUTES * 60 * 1000).toISOString();
    const { count: recentCount, error: countError } = await supabaseAdmin
      .from("sms_otp_challenges")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id)
      .gte("created_at", windowStart);

    if (countError) {
      // Fail closed — block the request if we can't verify the rate limit
      console.error("Rate limit check error:", countError);
      return new Response(
        JSON.stringify({ error: "Unable to process request. Please try again." }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if ((recentCount ?? 0) >= RATE_LIMIT_MAX) {
      return new Response(
        JSON.stringify({
          error: `Too many verification code requests. Please wait before trying again.`,
        }),
        {
          status: 429,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
            "Retry-After": String(RATE_LIMIT_WINDOW_MINUTES * 60),
          },
        }
      );
    }
    // ─────────────────────────────────────────────────────────────────────

    // Look up the user's phone number from profiles
    const { data: profile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("phone")
      .eq("id", user.id)
      .single();

    if (profileError || !profile?.phone) {
      return new Response(JSON.stringify({ error: "No phone number on file" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Demo bypass: App Store reviewer account ──────────────────────────────
    // If the user's phone matches the demo phone AND DEMO_BYPASS_ENABLED is on,
    // skip Twilio entirely. The reviewer enters OTP "000000" which is bypassed
    // server-side in verify-sms-otp. No real SMS is sent.
    const normalisePhone = (p: string | null | undefined) =>
      (p ?? "").replace(/\D/g, "");

    // Two recognition paths (mirror verify-sms-otp):
    //  1. user_metadata.is_test_account == true  (new — any test account)
    //  2. profile.phone matches DEMO_PHONE       (legacy reviewer account)
    const isTestAccount =
      (user.user_metadata as Record<string, unknown> | null)?.is_test_account === true;
    const phoneMatch = normalisePhone(profile.phone) === normalisePhone(DEMO_PHONE);

    if (DEMO_BYPASS_ENABLED && (isTestAccount || phoneMatch)) {
      console.log("[send-sms-otp] Demo bypass — skipping Twilio", { isTestAccount, phoneMatch });
      let toPhoneDemo = profile.phone.replace(/[\s\-\(\)]/g, "");
      if (!toPhoneDemo.startsWith("+")) toPhoneDemo = "+" + normalisePhone(toPhoneDemo);
      const maskedPhoneDemo =
        toPhoneDemo.slice(0, -4).replace(/./g, "*") + toPhoneDemo.slice(-4);
      return new Response(
        JSON.stringify({ success: true, phone: maskedPhoneDemo, demo: true }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    // ────────────────────────────────────────────────────────────────────────

    // Generate 6-digit OTP
    const otp = String(Math.floor(100000 + Math.random() * 900000));

    // Hash the OTP with SHA-256
    const encoder = new TextEncoder();
    const data = encoder.encode(otp);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const otpHash = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

    // Delete any previous unexpired challenges for this user
    await supabaseAdmin
      .from("sms_otp_challenges")
      .delete()
      .eq("user_id", user.id)
      .eq("verified", false);

    // Store the challenge (expires in 5 minutes)
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();
    const { error: insertError } = await supabaseAdmin
      .from("sms_otp_challenges")
      .insert({
        user_id: user.id,
        phone: profile.phone,
        otp_hash: otpHash,
        expires_at: expiresAt,
      });

    if (insertError) {
      return new Response(JSON.stringify({ error: "Failed to create challenge" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Send SMS via Twilio
    const twilioSid = Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";
    const twilioAuth = Deno.env.get("TWILIO_AUTH_TOKEN") ?? "";
    const twilioPhone = Deno.env.get("TWILIO_PHONE_NUMBER") ?? "";

    // Format phone to E.164 if needed
    let toPhone = profile.phone.replace(/[\s\-\(\)]/g, "");
    if (!toPhone.startsWith("+")) {
      toPhone = "+1" + toPhone; // Default to US
    }

    const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${twilioSid}/Messages.json`;
    const twilioBody = new URLSearchParams({
      To: toPhone,
      From: twilioPhone,
      // SMS body must match the samples submitted to TCR for the A2P 10DLC
      // campaign. Includes STOP / HELP language as required by US carrier rules.
      // Changing this without also updating the TCR campaign samples risks
      // triggering a carrier-level filter.
      //
      // HIPAA NOTE (2026-05-31): brand reference deliberately omitted. A
      // phone number alone is not PHI, but a phone number + identifier of a
      // specific Substance Use Disorder treatment program IS PHI under the
      // HIPAA 18-identifiers rule. Keeping the OTP brand-anonymous means
      // Twilio is not processing PHI on our behalf and no BAA is required
      // for this OTP flow. In-app post-OTP screens remain fully branded.
      Body: `Your verification code is ${otp}. It expires in 5 minutes. Do not share this code. Reply STOP to opt out, HELP for help.`,
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
      const twilioError = await twilioResponse.text();
      console.error("Twilio error:", twilioError);
      return new Response(JSON.stringify({ error: "Failed to send SMS" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Mask the phone for the response
    const maskedPhone = toPhone.slice(0, -4).replace(/./g, "*") + toPhone.slice(-4);

    return new Response(
      JSON.stringify({ success: true, phone: maskedPhone }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("send-sms-otp error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
