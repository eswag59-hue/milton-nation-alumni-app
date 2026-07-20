// Change the signed-in user's phone number, with ownership proof.
//
// The phone number IS the second login factor — the OTP is delivered to it.
// Allowing a change without verifying the NEW number would be an account
// takeover path: anyone with a few seconds on an unlocked phone could point
// the account at a number they control and hold it permanently.
//
// So this is a two-step flow, and the write only happens after step 2:
//   { action: "start",   newPhone }        -> Twilio Verify SMS to the NEW number
//   { action: "confirm", newPhone, code }  -> check code, then write profiles.phone
//
// Deliberately separate from send-sms-otp / verify-sms-otp: those verify the
// number ALREADY on file and are the live login path. Extending them to accept
// an arbitrary target number would mean a bug here could break sign-in for
// everyone, so they are left untouched.
//
// HIPAA NOTE: the Verify SMS body is "Your <FriendlyName> verification code
// is: XXXXXX" where FriendlyName is "Milton Nation" — a brand-anonymous label
// with no SUD-treatment meaning. Same reasoning as the login OTP.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

/** Normalise to E.164, defaulting to US. Returns null if implausible. */
function toE164(raw: string): string | null {
  let p = raw.replace(/[\s\-\(\)\.]/g, "");
  if (!p.startsWith("+")) {
    if (p.length === 11 && p.startsWith("1")) p = "+" + p;
    else if (p.length === 10) p = "+1" + p;
    else return null;
  }
  return /^\+[1-9]\d{7,14}$/.test(p) ? p : null;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const admin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "Missing authorization header" }, 401);

    const { data: { user }, error: authError } =
      await admin.auth.getUser(authHeader.replace("Bearer ", ""));
    if (authError || !user) return json({ error: "Invalid token" }, 401);

    // Only an active member may change their own number.
    const { data: profile } = await admin
      .from("profiles").select("status, phone").eq("id", user.id).single();
    if (!profile || profile.status !== "active") {
      return json({ error: "Account is not active" }, 403);
    }

    const { action, newPhone, code } = await req.json();

    const e164 = typeof newPhone === "string" ? toE164(newPhone) : null;
    if (!e164) return json({ error: "Enter a valid mobile number." }, 400);

    if (profile.phone && toE164(profile.phone) === e164) {
      return json({ error: "That is already your phone number." }, 400);
    }

    // A number may only be attached to one account — otherwise two accounts
    // would receive the same login OTP.
    const { data: existing } = await admin
      .from("profiles").select("id").eq("phone", e164).neq("id", user.id).limit(1);
    if (existing && existing.length > 0) {
      return json({ error: "That number is already in use on another account." }, 409);
    }

    const twilioSid = Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";
    const twilioAuth = Deno.env.get("TWILIO_AUTH_TOKEN") ?? "";
    const verifyServiceSid = Deno.env.get("TWILIO_VERIFY_SERVICE_SID") ?? "";
    const basic = "Basic " + btoa(`${twilioSid}:${twilioAuth}`);

    // ── Step 1: send a code to the NEW number ───────────────────────────
    if (action === "start") {
      const res = await fetch(
        `https://verify.twilio.com/v2/Services/${verifyServiceSid}/Verifications`,
        {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded", Authorization: basic },
          body: new URLSearchParams({ To: e164, Channel: "sms" }).toString(),
        },
      );
      if (!res.ok) {
        console.error("Verify start failed:", await res.text());
        return json({ error: "Could not send a code to that number." }, 502);
      }
      const masked = e164.slice(0, -4).replace(/./g, "*") + e164.slice(-4);
      return json({ sent: true, phone: masked });
    }

    // ── Step 2: check the code, then commit the change ──────────────────
    if (action === "confirm") {
      if (typeof code !== "string" || !/^\d{6}$/.test(code)) {
        return json({ error: "Enter the 6-digit code." }, 400);
      }

      const res = await fetch(
        `https://verify.twilio.com/v2/Services/${verifyServiceSid}/VerificationCheck`,
        {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded", Authorization: basic },
          body: new URLSearchParams({ To: e164, Code: code }).toString(),
        },
      );

      // 404 = no pending verification: expired, already used, or voided by
      // too many wrong attempts.
      if (res.status === 404) {
        return json({ error: "That code expired. Request a new one." }, 400);
      }
      if (!res.ok) {
        console.error("Verify check failed:", await res.text());
        return json({ error: "Could not verify that code." }, 502);
      }

      const result = await res.json();
      if (result.status !== "approved") {
        return json({ error: "That code is not correct." }, 400);
      }

      const { error: updateError } = await admin
        .from("profiles")
        .update({ phone: e164, updated_at: new Date().toISOString() })
        .eq("id", user.id);
      if (updateError) {
        console.error("Phone update failed:", updateError);
        return json({ error: "Could not save the new number." }, 500);
      }

      // Security-relevant change — record it. Never log the full number.
      await admin.from("audit_logs").insert({
        action: "phoneNumberChanged",
        user_id: user.id,
        detail: `Phone changed to ******${e164.slice(-4)}`,
      });

      return json({ changed: true, phone: e164 });
    }

    return json({ error: "Unknown action" }, 400);
  } catch (err) {
    console.error("change-phone error:", err);
    return json({ error: String(err) }, 500);
  }
});
