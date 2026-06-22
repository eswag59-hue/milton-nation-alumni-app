import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// Restrict CORS to our Supabase project
const ALLOWED_ORIGIN = Deno.env.get("ALLOWED_ORIGIN") ?? "https://hksxzuytcmqqwxmfjzdp.supabase.co";

const corsHeaders = {
  "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ── App Store reviewer demo account ───────────────────────────────────────────
// Only active when DEMO_BYPASS_ENABLED=true is set as an Edge Function secret.
// Set this in Supabase Dashboard → Edge Functions → Secrets for review builds only.
// NEVER enable in production — disable after Apple review is complete.
const DEMO_BYPASS_ENABLED = Deno.env.get("DEMO_BYPASS_ENABLED") === "true";
const DEMO_PHONE = "15550001234"; // Supabase stores without leading +
const DEMO_OTP   = "000000";
// ─────────────────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
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

    // Parse the code from the request body
    const { code } = await req.json();

    if (!code || typeof code !== "string" || code.length !== 6) {
      return new Response(JSON.stringify({ error: "Invalid code format" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Demo bypass: App Store reviewer + TestFlight admin/super-admin demo accounts ──
    // Gated by DEMO_BYPASS_ENABLED env var — must be explicitly enabled per-deployment.
    //
    // Two recognition paths:
    //  1. user_metadata.is_test_account == true  (preferred — works for any test account)
    //  2. profile.phone matches DEMO_PHONE       (legacy — kept for the original reviewer account)
    //
    // Either path is sufficient. Path 1 lets us add more test accounts (admin, super_admin,
    // alumni roles) without needing each to share a single demo phone number.
    if (DEMO_BYPASS_ENABLED && code === DEMO_OTP) {
      const isTestAccount =
        (user.user_metadata as Record<string, unknown> | null)?.is_test_account === true;

      // Path 2 fallback — profile.phone match
      const { data: demoProfile } = await supabaseAdmin
        .from("profiles")
        .select("phone")
        .eq("id", user.id)
        .single();
      const normalise = (p: string | null | undefined) =>
        (p ?? "").replace(/\D/g, "");
      const phoneMatch = normalise(demoProfile?.phone) === normalise(DEMO_PHONE);

      if (isTestAccount || phoneMatch) {
        console.log("[verify-sms-otp] Demo bypass used", { isTestAccount, phoneMatch });
        return new Response(
          JSON.stringify({ verified: true }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }
    // ────────────────────────────────────────────────────────────────────────

    // ── Real path: check the code with Twilio Verify ─────────────────────
    // Verify owns code storage, expiry, and attempt-counting. We look up the
    // user's phone and ask Verify whether <phone, code> is approved.
    const { data: profile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("phone")
      .eq("id", user.id)
      .single();

    if (profileError || !profile?.phone) {
      return new Response(
        JSON.stringify({ verified: false, error: "No phone number on file. Please request a new code." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let toPhone = profile.phone.replace(/[\s\-\(\)]/g, "");
    if (!toPhone.startsWith("+")) {
      toPhone = "+1" + toPhone; // Default to US
    }

    const twilioSid = Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";
    const twilioAuth = Deno.env.get("TWILIO_AUTH_TOKEN") ?? "";
    const verifyServiceSid = Deno.env.get("TWILIO_VERIFY_SERVICE_SID") ?? "";

    const checkUrl = `https://verify.twilio.com/v2/Services/${verifyServiceSid}/VerificationCheck`;
    const checkBody = new URLSearchParams({ To: toPhone, Code: code });

    const checkResponse = await fetch(checkUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: "Basic " + btoa(`${twilioSid}:${twilioAuth}`),
      },
      body: checkBody.toString(),
    });

    // Verify returns 404 when there is no pending verification — i.e. the code
    // expired, was already consumed, or too many wrong attempts voided it.
    if (checkResponse.status === 404) {
      return new Response(
        JSON.stringify({ verified: false, error: "No active verification code. Please request a new one." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!checkResponse.ok) {
      const checkError = await checkResponse.text();
      console.error("Twilio Verify check error:", checkError);
      return new Response(
        JSON.stringify({ verified: false, error: "Couldn't verify the code. Please try again." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const checkResult = await checkResponse.json();

    if (checkResult.status === "approved") {
      // Clear the rate-limit ledger rows for this user.
      await supabaseAdmin
        .from("sms_otp_challenges")
        .delete()
        .eq("user_id", user.id);

      return new Response(
        JSON.stringify({ verified: true }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ verified: false, error: "Invalid code. Please try again." }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("verify-sms-otp error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
