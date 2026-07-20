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

    // Brand assets are hosted in the public brand-assets bucket so email
    // clients can load them (inline SVG / attachments are unreliable).
    // Dark-background wordmark: the teal/lime gradient logo is baked onto its
    // own #12181F field, so the header below uses that exact colour as a solid
    // fill. A CSS gradient here would show the image's edges as a rectangle,
    // and Outlook drops gradients entirely.
    const LOGO_URL = "https://hksxzuytcmqqwxmfjzdp.supabase.co/storage/v1/object/public/brand-assets/email/milton-logo-dark.png";
    const BADGE_URL = "https://hksxzuytcmqqwxmfjzdp.supabase.co/storage/v1/object/public/brand-assets/email/appstore-badge.png";
    // Swappable without a redeploy — set APP_STORE_URL once the listing is live.
    const APP_STORE_URL = Deno.env.get("APP_STORE_URL") ?? "https://apps.apple.com/us/app/milton-nation";

    const html = `<!DOCTYPE html>
<html>
<head><meta name="color-scheme" content="light"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#eef2f3;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#eef2f3;padding:28px 12px;">
    <tr><td align="center">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:540px;background:#ffffff;border-radius:18px;overflow:hidden;box-shadow:0 2px 14px rgba(16,24,32,0.08);">

        <!-- Brand header -->
        <tr>
          <td align="center" bgcolor="#12181F" style="background-color:#12181F;padding:38px 24px 32px;">
            <img src="${LOGO_URL}" width="200" alt="Milton Nation"
                 style="display:block;width:200px;max-width:66%;height:auto;margin:0 auto 16px;" />
            <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;
                        color:#D4EB8E;font-size:12px;letter-spacing:2.5px;font-weight:600;">
              YOU'RE INVITED
            </div>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:32px 30px 8px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
            <p style="font-size:19px;font-weight:700;color:#101820;margin:0 0 14px;">${greeting}</p>
            <p style="font-size:16px;line-height:1.6;color:#3c4650;margin:0 0 16px;">
              You've been invited to join <strong style="color:#007396;">Milton Nation</strong> &mdash;
              a private community app where you can connect, find meetings, and stay supported.
            </p>
            <p style="font-size:16px;line-height:1.6;color:#3c4650;margin:0 0 6px;">
              Getting in takes about a minute:
            </p>
            <table role="presentation" cellpadding="0" cellspacing="0" style="margin:14px 0 4px;">
              <tr><td style="padding:6px 0;font-size:15px;color:#3c4650;">
                <span style="display:inline-block;width:24px;height:24px;background:#E4F1F6;color:#007396;
                             border-radius:12px;text-align:center;line-height:24px;font-weight:700;font-size:13px;">1</span>
                &nbsp; Download the app below
              </td></tr>
              <tr><td style="padding:6px 0;font-size:15px;color:#3c4650;">
                <span style="display:inline-block;width:24px;height:24px;background:#E4F1F6;color:#007396;
                             border-radius:12px;text-align:center;line-height:24px;font-weight:700;font-size:13px;">2</span>
                &nbsp; Tap <strong>Register</strong> and use <strong>this email address</strong>
              </td></tr>
              <tr><td style="padding:6px 0;font-size:15px;color:#3c4650;">
                <span style="display:inline-block;width:24px;height:24px;background:#E4F1F6;color:#007396;
                             border-radius:12px;text-align:center;line-height:24px;font-weight:700;font-size:13px;">3</span>
                &nbsp; We'll review and activate your account
              </td></tr>
            </table>
          </td>
        </tr>

        <!-- App Store badge -->
        <tr>
          <td align="center" style="padding:22px 30px 30px;">
            <a href="${APP_STORE_URL}" style="text-decoration:none;">
              <img src="${BADGE_URL}" alt="Download on the App Store"
                   width="180" style="display:block;width:180px;height:auto;border:0;margin:0 auto;" />
            </a>
            <!-- Fallback: many clients block images by default, which would
                 otherwise leave no way to reach the listing. -->
            <p style="margin:14px 0 0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
              <a href="${APP_STORE_URL}" style="font-size:13px;color:#007396;text-decoration:underline;">
                Open in the App Store
              </a>
            </p>
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="background:#f7f9fa;padding:18px 30px;text-align:center;
                     font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
            <p style="font-size:12px;line-height:1.5;color:#7b8794;margin:0;">
              Not expecting this? You can safely ignore this email.<br/>
              Sent by Milton Nation &middot; please don't reply to this address.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
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
