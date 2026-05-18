import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// Restrict CORS to our Supabase project — mobile apps don't send Origin headers
// so this only affects browser-based callers.
const ALLOWED_ORIGIN = Deno.env.get("ALLOWED_ORIGIN") ?? "https://hksxzuytcmqqwxmfjzdp.supabase.co";

const corsHeaders = {
  "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
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
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // ── Require a valid JWT ────────────────────────────────────────────────────
    // Prevents unauthenticated callers from sending branded emails from our domain.
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
    // ──────────────────────────────────────────────────────────────────────────

    // NOTE: We intentionally do NOT accept or use the user's name here.
    // This function is called via Resend, which does not hold a HIPAA BAA.
    // Transmitting any PHI (name, email content, etc.) to a non-BAA provider
    // is a HIPAA violation. The email destination (to) is required to route the
    // message but is not included in the email body or subject.
    const { to } = await req.json();

    if (!to) {
      return new Response(JSON.stringify({ error: "to is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Only allow sending to the authenticated user's own email address
    if (user.email && to !== user.email) {
      return new Response(
        JSON.stringify({ error: "Forbidden: can only send welcome email to own address" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

    if (!RESEND_API_KEY) {
      // Gracefully skip — email not yet configured
      console.warn("RESEND_API_KEY not set — skipping welcome email");
      return new Response(
        JSON.stringify({ sent: false, reason: "email_not_configured" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Generic greeting — no PHI in body or subject.
    // Resend does not hold a HIPAA BAA; never include name, DOB, diagnosis,
    // or any other PHI in emails sent through this function.
    const html = `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Welcome to Milton Nation</title></head>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#f5f5f5;margin:0;padding:0;">
  <div style="max-width:560px;margin:40px auto;background:white;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.1);">
    <div style="background:#1a3a5c;padding:32px;text-align:center;">
      <h1 style="color:white;margin:0;font-size:24px;font-weight:700;">Milton Nation</h1>
      <p style="color:rgba(255,255,255,0.8);margin:8px 0 0;font-size:14px;">Milton Recovery Centers Alumni Community</p>
    </div>
    <div style="padding:32px;">
      <h2 style="color:#1a3a5c;margin:0 0 16px;">Welcome to Milton Nation! 🎉</h2>
      <p style="color:#444;line-height:1.6;margin:0 0 16px;">
        Your application to join the <strong>Milton Nation</strong> alumni community has been received
        and is currently <strong>pending admin review</strong>.
      </p>
      <p style="color:#444;line-height:1.6;margin:0 0 24px;">
        You'll receive a push notification as soon as your account is approved and active.
      </p>
      <div style="background:#f0f4f8;border-radius:8px;padding:16px;margin:0 0 24px;">
        <p style="color:#1a3a5c;font-weight:600;margin:0 0 8px;font-size:14px;">What happens next?</p>
        <ul style="color:#555;margin:0;padding-left:20px;font-size:14px;line-height:1.8;">
          <li>An admin reviews your application (usually within 24 hours)</li>
          <li>You receive a push notification when approved</li>
          <li>Log in to access the full community, meetings, and care team chat</li>
        </ul>
      </div>
      <p style="color:#888;font-size:13px;margin:0;">
        Milton Recovery Centers &middot;
        <a href="https://miltonrecovery.com/app-support/" style="color:#1a3a5c;">Contact Support</a>
        &middot; <a href="https://miltonrecovery.com" style="color:#1a3a5c;">miltonrecovery.com</a>
      </p>
    </div>
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
        subject: "Welcome to Milton Nation!",
        html,
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      console.error("Resend error:", errText);
      return new Response(
        JSON.stringify({ sent: false, error: errText }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const result = await res.json();
    console.log("Welcome email sent to", to, "id:", result.id);

    return new Response(
      JSON.stringify({ sent: true, id: result.id }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("send-welcome-email error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
