// Send an invitation email to a prospective member.
//
// Replaces the old SMS invite (send-invite-sms) — invites now go by EMAIL.
// Only admins / super-admins / clinical staff may call this, and unlike
// send-welcome-email (which is self-only) this intentionally sends to a
// third party, so the caller's role is checked server-side.
//
// HIPAA NOTE: Resend does not hold a BAA. The subject and body MUST NOT
// identify the recipient as a patient or alumni of a substance use disorder
// treatment program. "Milton Nation" is a brand name with no inherent
// treatment meaning and is safe; "recovery," "alumni," "treatment," and
// clinical phone numbers are deliberately omitted. The recipient learns the
// nature of the community only after installing and authenticating into
// Supabase, which is HIPAA-covered.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

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

    // Only staff may invite people.
    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("role, status")
      .eq("id", user.id)
      .single();

    const allowedRoles = ["admin", "super_admin", "case_manager", "therapist", "counselor"];
    if (!profile || profile.status !== "active" || !allowedRoles.includes(profile.role)) {
      return new Response(JSON.stringify({ error: "Forbidden: staff only" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { to, name } = await req.json();
    const emailRe = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!to || typeof to !== "string" || !emailRe.test(to)) {
      return new Response(JSON.stringify({ error: "A valid recipient email is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
    if (!RESEND_API_KEY) {
      console.warn("RESEND_API_KEY not set — skipping invite email");
      return new Response(JSON.stringify({ sent: false, reason: "email_not_configured" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const greeting = name && typeof name === "string" && name.trim().length > 0
      ? `Hi ${name.trim()},`
      : "Hi,";

    const html = `<!DOCTYPE html>
<html>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#f2f5f5;margin:0;padding:0;">
  <div style="max-width:520px;margin:0 auto;padding:32px 24px;">
    <div style="text-align:center;margin-bottom:28px;">
      <div style="font-size:30px;font-weight:700;letter-spacing:-0.5px;color:#101820;">milton</div>
      <div style="font-size:12px;letter-spacing:2px;color:#007396;margin-top:2px;">MILTON NATION</div>
    </div>
    <div style="background:#ffffff;border-radius:14px;padding:28px;">
      <p style="font-size:16px;color:#101820;margin:0 0 14px;">${greeting}</p>
      <p style="font-size:15px;line-height:1.55;color:#3c4650;margin:0 0 14px;">
        You've been invited to join <strong>Milton Nation</strong>, a private community app.
      </p>
      <p style="font-size:15px;line-height:1.55;color:#3c4650;margin:0 0 22px;">
        Download the app, then tap <strong>Register</strong> and use this email address to
        request access. Your request will be reviewed before your account is activated.
      </p>
      <div style="text-align:center;margin:26px 0;">
        <a href="https://miltonrecovery.com/app-support/"
           style="display:inline-block;background:#007396;color:#ffffff;text-decoration:none;
                  padding:13px 30px;border-radius:26px;font-weight:600;font-size:15px;">
          Get the App
        </a>
      </div>
      <p style="font-size:13px;line-height:1.5;color:#7b8794;margin:0;">
        If you weren't expecting this invitation, you can ignore this email.
      </p>
    </div>
    <p style="text-align:center;font-size:11px;color:#9aa5b1;margin-top:22px;">
      Sent by Milton Nation · Please do not reply to this address.
    </p>
  </div>
</body>
</html>`;

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Milton Nation <noreply@miltonrecovery.com>",
        to: [to],
        subject: "You're invited to Milton Nation",
        html,
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      console.error("Resend error:", errText);
      return new Response(JSON.stringify({ sent: false, error: errText }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const result = await res.json();
    console.log("Invite email sent, id:", result.id);

    return new Response(JSON.stringify({ sent: true, email: to }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("send-invite-email error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
