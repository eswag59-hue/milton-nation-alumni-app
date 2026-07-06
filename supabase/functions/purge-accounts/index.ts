// purge-accounts
// Hard-deletes personal data for accounts that requested deletion >30 days ago.
// Thin wrapper around the SQL function `public.purge_deactivated_accounts()` so
// the purge can be triggered manually (in addition to the daily pg_cron job).
//
// Auth: super_admin JWT required. (The daily pg_cron schedule runs the same SQL
// function server-side without going through this function.)
//
// Retention: personal data (profile PII + the user's posts/comments/messages/
// likes/device tokens) is deleted; redacted content_flags and immutable
// audit_logs are RETAINED per HIPAA/audit requirements. See the migration
// 20260706_account_purge.sql for the authoritative delete-vs-retain scope
// (which needs legal/clinical sign-off).

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
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Service-role client — bypasses RLS to run the purge RPC.
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Identify + authorize the caller. We accept either:
    //   (a) the service role key itself (for server-to-server / cron-style calls), or
    //   (b) a super_admin user JWT.
    const bearer = authHeader.replace("Bearer ", "").trim();
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const isServiceCall = serviceKey.length > 0 && bearer === serviceKey;

    if (!isServiceCall) {
      const supabaseUser = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_ANON_KEY") ?? "",
        { global: { headers: { Authorization: authHeader } } }
      );
      const { data: { user: caller }, error: authError } = await supabaseUser.auth.getUser();
      if (authError || !caller) {
        return new Response(JSON.stringify({ error: "Unauthorized" }), {
          status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const { data: callerProfile, error: profileError } = await supabaseAdmin
        .from("profiles")
        .select("role")
        .eq("id", caller.id)
        .single();
      if (profileError || callerProfile?.role !== "super_admin") {
        return new Response(
          JSON.stringify({ error: "Forbidden: only super_admin can run the account purge" }),
          { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // Run the purge. The SQL function is idempotent and only touches accounts
    // deactivated >30 days ago.
    const { data, error } = await supabaseAdmin.rpc("purge_deactivated_accounts");

    if (error) {
      console.error("purge-accounts: RPC error:", error);
      return new Response(JSON.stringify({ error: "Purge failed", detail: error.message }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // The function returns a single row: { purged_count }.
    const purgedCount = Array.isArray(data) ? (data[0]?.purged_count ?? 0) : (data?.purged_count ?? 0);

    console.log(`purge-accounts: purged ${purgedCount} account(s)`);

    return new Response(
      JSON.stringify({ purged: purgedCount }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("purge-accounts error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
