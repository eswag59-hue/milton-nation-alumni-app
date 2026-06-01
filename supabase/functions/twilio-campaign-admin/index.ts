// ONE-SHOT admin function: inspect / delete / recreate the A2P 10DLC Campaign
// attached to our Messaging Service.
//
// Auth: requires custom header `x-admin-secret` matching env ADMIN_SECRET.
// This is NOT for end-user calls — it's an Ezra-only operations tool.
//
// Actions (chosen via query string):
//   ?action=inspect  → GET the current US A2P registration JSON
//   ?action=delete   → DELETE the current registration (no body)
//   ?action=create   → POST a new registration with use case = VERIFICATION,
//                       reusing the fields from the prior inspect payload
//                       (BrandRegistrationSid, description, samples, etc.)
//   ?action=full     → inspect → delete → create in one shot, return all 3
//                       payloads. THIS IS THE COMMIT BUTTON.
//
// Body for ?action=create or ?action=full may include:
//   { brandSid, description, messageSamples[], messageFlow,
//     hasEmbeddedLinks, hasEmbeddedPhone, helpMessage,
//     optInKeywords[], optOutKeywords[], helpKeywords[],
//     optInMessage, optOutMessage, subscriberOptIn,
//     ageGated, directLending }
// If body omits any field, we reuse what came back from the inspect step.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const MESSAGING_SERVICE_SID = "MG5841b1dd280260d8d5107a2467b1a3d2";
const TWILIO_BASE = "https://messaging.twilio.com/v1";

function authHeader(): string {
  const sid = Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";
  const token = Deno.env.get("TWILIO_AUTH_TOKEN") ?? "";
  return "Basic " + btoa(`${sid}:${token}`);
}

async function twilio(method: string, path: string, body?: Record<string, unknown>) {
  const headers: Record<string, string> = {
    Authorization: authHeader(),
  };
  let bodyStr: string | undefined;
  if (body) {
    headers["Content-Type"] = "application/x-www-form-urlencoded";
    const form = new URLSearchParams();
    for (const [k, v] of Object.entries(body)) {
      if (Array.isArray(v)) {
        for (const item of v) form.append(k, String(item));
      } else if (v !== undefined && v !== null) {
        form.append(k, String(v));
      }
    }
    bodyStr = form.toString();
  }
  const resp = await fetch(`${TWILIO_BASE}${path}`, { method, headers, body: bodyStr });
  const text = await resp.text();
  let json: unknown;
  try { json = JSON.parse(text); } catch { json = text; }
  return { status: resp.status, ok: resp.ok, body: json };
}

async function inspectCampaign() {
  // GET list of US A2P registrations for the messaging service
  // (there's only ever one per service)
  return await twilio("GET", `/Services/${MESSAGING_SERVICE_SID}/Compliance/Usa2p`);
}

async function deleteCampaign(sid: string) {
  return await twilio("DELETE", `/Services/${MESSAGING_SERVICE_SID}/Compliance/Usa2p/${sid}`);
}

async function createCampaign(payload: Record<string, unknown>) {
  return await twilio("POST", `/Services/${MESSAGING_SERVICE_SID}/Compliance/Usa2p`, payload);
}

serve(async (req: Request) => {
  // Admin gate
  const adminSecret = Deno.env.get("ADMIN_SECRET") ?? "";
  const headerSecret = req.headers.get("x-admin-secret") ?? "";
  if (!adminSecret || headerSecret !== adminSecret) {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  const url = new URL(req.url);
  const action = url.searchParams.get("action") ?? "inspect";
  let body: Record<string, unknown> = {};
  if (req.method === "POST") {
    try { body = await req.json(); } catch { body = {}; }
  }

  try {
    if (action === "inspect") {
      const r = await inspectCampaign();
      return new Response(JSON.stringify(r, null, 2), {
        status: r.ok ? 200 : r.status,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (action === "delete") {
      const sid = String(body.sid ?? "");
      if (!sid) return new Response(JSON.stringify({ error: "body.sid required" }), { status: 400 });
      const r = await deleteCampaign(sid);
      return new Response(JSON.stringify(r, null, 2), {
        status: r.ok ? 200 : r.status,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (action === "create") {
      const r = await createCampaign(buildCreatePayload(body, null));
      return new Response(JSON.stringify(r, null, 2), {
        status: r.ok ? 200 : r.status,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (action === "full") {
      // Inspect → delete → create, all in one shot. THE LIVE BUTTON.
      const inspect = await inspectCampaign();
      if (!inspect.ok) {
        return new Response(JSON.stringify({ step: "inspect", ...inspect }, null, 2), {
          status: inspect.status,
          headers: { "Content-Type": "application/json" },
        });
      }
      const existing = extractCampaign(inspect.body);
      if (!existing?.sid) {
        return new Response(JSON.stringify({ step: "inspect", error: "no campaign sid found", body: inspect.body }, null, 2), {
          status: 422,
          headers: { "Content-Type": "application/json" },
        });
      }
      const del = await deleteCampaign(existing.sid);
      // Even if delete failed (e.g. already gone), continue if it's a 404
      if (!del.ok && del.status !== 404) {
        return new Response(JSON.stringify({ step: "delete", existing, ...del }, null, 2), {
          status: del.status,
          headers: { "Content-Type": "application/json" },
        });
      }
      const create = await createCampaign(buildCreatePayload(body, existing));
      return new Response(JSON.stringify({
        step: "full",
        inspect: existing,
        delete: { status: del.status, ok: del.ok, body: del.body },
        create: { status: create.status, ok: create.ok, body: create.body },
      }, null, 2), {
        status: create.ok ? 200 : create.status,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "unknown action" }), { status: 400 });
  } catch (err) {
    return new Response(JSON.stringify({ error: "internal", detail: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

interface ExistingCampaign {
  sid: string;
  brandRegistrationSid: string;
  description: string;
  messageSamples: string[];
  messageFlow: string;
  hasEmbeddedLinks: boolean;
  hasEmbeddedPhone: boolean;
  helpMessage?: string;
  optInKeywords?: string[];
  optOutKeywords?: string[];
  helpKeywords?: string[];
  optInMessage?: string;
  optOutMessage?: string;
  ageGated?: boolean;
  subscriberOptIn?: boolean;
  directLending?: boolean;
}

function extractCampaign(body: unknown): ExistingCampaign | null {
  // Twilio response shape (list endpoint returns { compliance: [...] } or
  // similar; the singular endpoint returns the campaign object directly).
  if (!body || typeof body !== "object") return null;
  const root = body as Record<string, unknown>;
  // List shape: { compliance: [...] } or { us_app_to_persons: [...] }
  let cand: Record<string, unknown> | undefined;
  if (Array.isArray((root as { compliance?: unknown[] }).compliance) && (root as { compliance: unknown[] }).compliance.length) {
    cand = (root as { compliance: Record<string, unknown>[] }).compliance[0];
  } else if (Array.isArray((root as { us_app_to_person?: unknown[] }).us_app_to_person) && (root as { us_app_to_person: unknown[] }).us_app_to_person.length) {
    cand = (root as { us_app_to_person: Record<string, unknown>[] }).us_app_to_person[0];
  } else {
    cand = root;
  }
  if (!cand || typeof cand !== "object") return null;
  return {
    sid: String(cand.sid ?? ""),
    brandRegistrationSid: String(cand.brand_registration_sid ?? cand.brandRegistrationSid ?? ""),
    description: String(cand.description ?? ""),
    messageSamples: Array.isArray(cand.message_samples) ? (cand.message_samples as string[]) : [],
    messageFlow: String(cand.message_flow ?? ""),
    hasEmbeddedLinks: Boolean(cand.has_embedded_links),
    hasEmbeddedPhone: Boolean(cand.has_embedded_phone),
    helpMessage: cand.help_message as string | undefined,
    optInKeywords: cand.opt_in_keywords as string[] | undefined,
    optOutKeywords: cand.opt_out_keywords as string[] | undefined,
    helpKeywords: cand.help_keywords as string[] | undefined,
    optInMessage: cand.opt_in_message as string | undefined,
    optOutMessage: cand.opt_out_message as string | undefined,
    ageGated: cand.age_gated as boolean | undefined,
    subscriberOptIn: cand.subscriber_opt_in as boolean | undefined,
    directLending: cand.direct_lending as boolean | undefined,
  };
}

function buildCreatePayload(
  override: Record<string, unknown>,
  existing: ExistingCampaign | null,
): Record<string, unknown> {
  const pick = <T,>(key: string, fallback?: T) => {
    if (override[key] !== undefined) return override[key];
    if (existing && (existing as Record<string, unknown>)[key] !== undefined) {
      return (existing as Record<string, unknown>)[key];
    }
    return fallback;
  };
  return {
    BrandRegistrationSid: pick("brandSid", existing?.brandRegistrationSid),
    UsAppToPersonUsecase: pick("useCase", "VERIFICATION"),
    Description: pick("description", existing?.description ?? "Two-factor authentication: 6-digit one-time passwords (OTP) sent to verified alumni of Milton Recovery Centers when they sign in to the Milton Nation iOS app. Codes expire after 5 minutes and are used as the second factor during login."),
    MessageSamples: pick("messageSamples", existing?.messageSamples?.length ? existing.messageSamples : ["Your Milton Nation verification code is 123456. Code expires in 5 minutes."]),
    MessageFlow: pick("messageFlow", existing?.messageFlow ?? "End users opt in by entering their phone number during account signup in the Milton Nation iOS app. By submitting their phone number, they consent to receive a one-time SMS verification code. The consent language is displayed inline below the phone field on the signup form: 'By providing your phone number, you consent to receive a one-time verification code via SMS. Message & data rates may apply.' Consent is recorded with timestamp, user ID, and IP address in our database."),
    HasEmbeddedLinks: pick("hasEmbeddedLinks", existing?.hasEmbeddedLinks ?? false),
    HasEmbeddedPhone: pick("hasEmbeddedPhone", existing?.hasEmbeddedPhone ?? false),
    HelpMessage: pick("helpMessage", existing?.helpMessage ?? "Reply STOP to opt out. For help, email support@miltonrecovery.com or call (844) 406-4325."),
    OptInKeywords: pick("optInKeywords", existing?.optInKeywords ?? []),
    OptOutKeywords: pick("optOutKeywords", existing?.optOutKeywords ?? ["STOP"]),
    HelpKeywords: pick("helpKeywords", existing?.helpKeywords ?? ["HELP"]),
    OptInMessage: pick("optInMessage", existing?.optInMessage ?? ""),
    OptOutMessage: pick("optOutMessage", existing?.optOutMessage ?? "You have been unsubscribed from Milton Nation SMS verification codes. You will no longer receive messages."),
    SubscriberOptIn: pick("subscriberOptIn", existing?.subscriberOptIn ?? true),
    AgeGated: pick("ageGated", existing?.ageGated ?? false),
    DirectLending: pick("directLending", existing?.directLending ?? false),
  };
}
