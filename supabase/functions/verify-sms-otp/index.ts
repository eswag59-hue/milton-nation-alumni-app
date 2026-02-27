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

    // ── Demo bypass: App Store reviewer account ──────────────────────────────
    // Gated by DEMO_BYPASS_ENABLED env var — must be explicitly enabled per-deployment.
    if (DEMO_BYPASS_ENABLED && user.phone === DEMO_PHONE && code === DEMO_OTP) {
      console.log("[verify-sms-otp] Demo bypass used for reviewer account");
      return new Response(
        JSON.stringify({ verified: true }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    // ────────────────────────────────────────────────────────────────────────

    // Find the latest non-expired, non-verified challenge for this user
    const { data: challenge, error: challengeError } = await supabaseAdmin
      .from("sms_otp_challenges")
      .select("*")
      .eq("user_id", user.id)
      .eq("verified", false)
      .gt("expires_at", new Date().toISOString())
      .order("created_at", { ascending: false })
      .limit(1)
      .single();

    if (challengeError || !challenge) {
      return new Response(
        JSON.stringify({ verified: false, error: "No active verification code. Please request a new one." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check max attempts
    if (challenge.attempts >= challenge.max_attempts) {
      // Delete the exhausted challenge
      await supabaseAdmin
        .from("sms_otp_challenges")
        .delete()
        .eq("id", challenge.id);

      return new Response(
        JSON.stringify({ verified: false, error: "Too many attempts. Please request a new code." }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Hash the provided code
    const encoder = new TextEncoder();
    const data = encoder.encode(code);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const codeHash = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

    // Compare hashes
    if (codeHash !== challenge.otp_hash) {
      // Increment attempts
      await supabaseAdmin
        .from("sms_otp_challenges")
        .update({ attempts: challenge.attempts + 1 })
        .eq("id", challenge.id);

      const remaining = challenge.max_attempts - challenge.attempts - 1;
      return new Response(
        JSON.stringify({
          verified: false,
          error: `Invalid code. ${remaining} attempt${remaining !== 1 ? "s" : ""} remaining.`,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Code matches — mark as verified and clean up
    await supabaseAdmin
      .from("sms_otp_challenges")
      .update({ verified: true })
      .eq("id", challenge.id);

    // Clean up old challenges for this user
    await supabaseAdmin
      .from("sms_otp_challenges")
      .delete()
      .eq("user_id", user.id)
      .neq("id", challenge.id);

    return new Response(
      JSON.stringify({ verified: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("verify-sms-otp error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
