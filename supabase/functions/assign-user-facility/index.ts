// assign-user-facility
// Assigns (or reassigns) a pending user to a facility and activates their account.
// Called by admin or super_admin from the admin dashboard.
//
// Request body: { userId: string, facility: "ohio" | "florida" }
// Auth: requires a valid admin JWT

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
    // ── Auth: verify the calling user is an admin ──────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Get the calling user from the JWT
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

    // Fetch caller's profile to confirm admin role
    const { data: callerProfile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("role, admin_facility")
      .eq("id", caller.id)
      .single();

    if (profileError || !callerProfile) {
      return new Response(JSON.stringify({ error: "Could not verify admin role" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const callerRole: string = callerProfile.role;
    if (!["admin", "super_admin"].includes(callerRole)) {
      return new Response(JSON.stringify({ error: "Forbidden: admin role required" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Parse request body ─────────────────────────────────────────────────
    const { userId, facility } = await req.json();

    if (!userId || !facility) {
      return new Response(JSON.stringify({ error: "userId and facility are required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!["ohio", "florida"].includes(facility)) {
      return new Response(JSON.stringify({ error: "facility must be 'ohio' or 'florida'" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Authorization: regular admin can only assign their own facility ─────
    if (callerRole === "admin" && callerProfile.admin_facility !== facility) {
      return new Response(
        JSON.stringify({ error: `You can only assign users to your facility (${callerProfile.admin_facility})` }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Update profile: set facility + activate ────────────────────────────
    const { data: updatedUser, error: updateError } = await supabaseAdmin
      .from("profiles")
      .update({ facility, status: "active" })
      .eq("id", userId)
      .select("id, full_name, email, status, facility")
      .single();

    if (updateError) {
      console.error("[assign-user-facility] Update error:", updateError);
      return new Response(JSON.stringify({ error: "Failed to assign facility" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Send push notification to the approved user ────────────────────────
    const facilityLabel = facility === "ohio" ? "Ohio 🌻" : "Florida 🌴";
    try {
      await supabaseAdmin.functions.invoke("send-push-notification", {
        body: {
          target: "user",
          userId,
          title: "You're Approved! 🎉",
          body: `Welcome to the Milton Nation ${facilityLabel} community!`,
          data: { type: "account_approved", facility },
        },
      });
    } catch (pushError) {
      // Non-fatal — approval succeeded even if push fails
      console.warn("[assign-user-facility] Push notification failed:", pushError);
    }

    // ── Audit log ──────────────────────────────────────────────────────────
    await supabaseAdmin.from("audit_logs").insert({
      user_id: caller.id,
      action: "assign_facility",
      resource_type: "profile",
      resource_id: userId,
      detail: `Assigned to ${facility}, status set to active`,
      timestamp: new Date().toISOString(),
    });

    return new Response(
      JSON.stringify({ success: true, user: updatedUser }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("[assign-user-facility] Unhandled error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
