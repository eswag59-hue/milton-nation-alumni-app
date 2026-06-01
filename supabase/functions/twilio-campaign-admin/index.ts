// ONE-SHOT admin function: Twilio A2P 10DLC management.
//
// Auth: requires custom header `x-admin-secret` matching env ADMIN_SECRET.
// This is NOT for end-user calls — it's an Ezra-only operations tool,
// re-deployed for the duration of an admin operation and torn down after.
//
// Actions:
//   ?action=inspect              → GET current US A2P registration for the
//                                   primary 2FA Messaging Service
//   ?action=delete               → DELETE a US A2P registration. body: { sid, messagingServiceSid }
//   ?action=create               → POST a new US A2P registration to a
//                                   given messaging service. Use case
//                                   overrideable in body.
//   ?action=full                 → inspect → DELETE → CREATE on the
//                                   primary 2FA Messaging Service
//   ?action=list-numbers         → List Incoming Phone Numbers on the account
//   ?action=available-numbers    → Search Twilio inventory for available
//                                   US local numbers. body: { areaCode }
//   ?action=buy-number           → Purchase a phone number. body: { phoneNumber }
//   ?action=create-service       → Create a new Messaging Service.
//                                   body: { friendlyName, useCase }
//   ?action=attach-number        → Attach a phone number to a Messaging
//                                   Service. body: { serviceSid, phoneNumberSid }
//   ?action=full-marketing-setup → Provision a number, create a Messaging
//                                   Service, attach the number, register
//                                   the marketing/invite Campaign in one
//                                   transaction. body: { areaCode?, friendlyName?, ...campaign overrides }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const PRIMARY_MESSAGING_SERVICE_SID = "MG5841b1dd280260d8d5107a2467b1a3d2";
const TWILIO_MESSAGING_BASE = "https://messaging.twilio.com/v1";
const TWILIO_API_BASE = "https://api.twilio.com/2010-04-01";

function accountSid(): string {
  return Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";
}

function authHeader(): string {
  const sid = accountSid();
  const token = Deno.env.get("TWILIO_AUTH_TOKEN") ?? "";
  return "Basic " + btoa(`${sid}:${token}`);
}

function formEncode(body: Record<string, unknown>): string {
  const form = new URLSearchParams();
  for (const [k, v] of Object.entries(body)) {
    if (Array.isArray(v)) {
      for (const item of v) form.append(k, String(item));
    } else if (v !== undefined && v !== null) {
      form.append(k, String(v));
    }
  }
  return form.toString();
}

async function twilio(method: string, fullUrl: string, body?: Record<string, unknown>) {
  const headers: Record<string, string> = { Authorization: authHeader() };
  let bodyStr: string | undefined;
  if (body) {
    headers["Content-Type"] = "application/x-www-form-urlencoded";
    bodyStr = formEncode(body);
  }
  const resp = await fetch(fullUrl, { method, headers, body: bodyStr });
  const text = await resp.text();
  let json: unknown;
  try { json = JSON.parse(text); } catch { json = text; }
  return { status: resp.status, ok: resp.ok, body: json };
}

// ─── Campaign primitives ─────────────────────────────────────────────────────

async function inspectCampaign(messagingServiceSid: string) {
  return await twilio("GET", `${TWILIO_MESSAGING_BASE}/Services/${messagingServiceSid}/Compliance/Usa2p`);
}

async function deleteCampaign(messagingServiceSid: string, sid: string) {
  return await twilio("DELETE", `${TWILIO_MESSAGING_BASE}/Services/${messagingServiceSid}/Compliance/Usa2p/${sid}`);
}

async function createCampaign(messagingServiceSid: string, payload: Record<string, unknown>) {
  return await twilio("POST", `${TWILIO_MESSAGING_BASE}/Services/${messagingServiceSid}/Compliance/Usa2p`, payload);
}

// ─── Number / Service primitives ─────────────────────────────────────────────

async function listIncomingNumbers() {
  return await twilio("GET", `${TWILIO_API_BASE}/Accounts/${accountSid()}/IncomingPhoneNumbers.json`);
}

async function findAvailableNumber(areaCode?: string) {
  const params = new URLSearchParams();
  if (areaCode) params.set("AreaCode", areaCode);
  params.set("SmsEnabled", "true");
  params.set("PageSize", "5");
  const url = `${TWILIO_API_BASE}/Accounts/${accountSid()}/AvailablePhoneNumbers/US/Local.json?${params}`;
  return await twilio("GET", url);
}

async function buyNumber(phoneNumber: string) {
  return await twilio("POST", `${TWILIO_API_BASE}/Accounts/${accountSid()}/IncomingPhoneNumbers.json`, { PhoneNumber: phoneNumber });
}

async function createMessagingService(friendlyName: string, useCase?: string) {
  const body: Record<string, unknown> = { FriendlyName: friendlyName };
  if (useCase) body.UseCase = useCase;
  return await twilio("POST", `${TWILIO_MESSAGING_BASE}/Services`, body);
}

async function attachNumberToService(serviceSid: string, phoneNumberSid: string) {
  return await twilio("POST", `${TWILIO_MESSAGING_BASE}/Services/${serviceSid}/PhoneNumbers`, { PhoneNumberSid: phoneNumberSid });
}

// ─── Marketing campaign default payload ──────────────────────────────────────

const DEFAULT_MARKETING_PAYLOAD: Record<string, unknown> = {
  BrandRegistrationSid: "BN4bb2811c5d19f19ae546b65b4c296cc6", // existing approved Brand
  UsAppToPersonUsecase: "MARKETING",
  Description:
    "One-time SMS invitations sent by Milton Recovery Centers admins to prospective alumni of the Milton Nation peer recovery community iOS app. Recipients have previously consented to receive this single invitation either via a written consent form signed during their discharge planning at Milton Recovery Centers, or via verbal consent given to their counselor and logged in the alumni-management system. Each invitation contains the iOS App Store download link and standard opt-out language.",
  MessageSamples: [
    "Hi Alex, you've been invited to a peer recovery community app. Stay connected, find meetings, and reach your care team — all in one place. Download for iOS: https://apps.apple.com/us/app/milton-nation. Reply STOP to opt out, HELP for help.",
    "Hi Jordan, you've been invited to a peer recovery community app. Stay connected, find meetings, and reach your care team — all in one place. Download for iOS: https://apps.apple.com/us/app/milton-nation. Reply STOP to opt out, HELP for help.",
  ],
  MessageFlow:
    "Recipients consent to receive a one-time invite SMS through Milton Recovery Centers' standard alumni engagement consent process. Consent is captured via either: (a) a written consent form executed during the patient's discharge planning at Milton Recovery Centers, retained in the patient's treatment record, explicitly authorizing one SMS containing the iOS App Store download link for the Milton Nation peer recovery community app; or (b) verbal consent given by the patient or alumni during a clinical interaction with their counselor, logged in Milton Recovery Centers' alumni-management system with the date, counselor name, and patient/alumni identifier. A Milton Recovery Centers admin manually triggers the invite SMS from the Milton Nation admin panel only after verifying that consent was recorded. The SMS body is: 'Hi {name}, you've been invited to a peer recovery community app. Stay connected, find meetings, and reach your care team — all in one place. Download for iOS: https://apps.apple.com/us/app/milton-nation. Reply STOP to opt out, HELP for help.' Recipients may opt out at any time by replying STOP, which is honored automatically by Twilio. Privacy policy: https://miltonrecovery.com/milton-nation-privacy. Terms of service: https://miltonrecovery.com/app-terms-of-use",
  HasEmbeddedLinks: true,
  HasEmbeddedPhone: false,
  HelpMessage: "Reply STOP to unsubscribe. Msg&Data Rates May Apply.",
  OptInKeywords: [],
  OptOutKeywords: ["OPTOUT", "CANCEL", "END", "QUIT", "UNSUBSCRIBE", "REVOKE", "STOP", "STOPALL"],
  HelpKeywords: ["HELP", "INFO"],
  OptInMessage:
    "Welcome to Milton Nation. You have been invited to download the Milton Nation iOS peer recovery community app. Reply STOP to opt out, HELP for help. Msg & data rates may apply.",
  OptOutMessage:
    "You have successfully been unsubscribed. You will not receive any more messages from this number. Reply START to resubscribe.",
  SubscriberOptIn: true,
  AgeGated: false,
  DirectLending: false,
};

// ─── Server ──────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
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

  function respond(payload: unknown, status = 200) {
    return new Response(JSON.stringify(payload, null, 2), {
      status,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    if (action === "inspect") {
      const sid = String(body.messagingServiceSid ?? PRIMARY_MESSAGING_SERVICE_SID);
      const r = await inspectCampaign(sid);
      return respond(r, r.ok ? 200 : r.status);
    }

    if (action === "list-numbers") {
      const r = await listIncomingNumbers();
      return respond(r, r.ok ? 200 : r.status);
    }

    if (action === "available-numbers") {
      const r = await findAvailableNumber(body.areaCode as string | undefined);
      return respond(r, r.ok ? 200 : r.status);
    }

    if (action === "buy-number") {
      const r = await buyNumber(String(body.phoneNumber ?? ""));
      return respond(r, r.ok ? 200 : r.status);
    }

    if (action === "create-service") {
      const r = await createMessagingService(
        String(body.friendlyName ?? "Milton Recovery Marketing & Alumni Invites"),
        body.useCase as string | undefined,
      );
      return respond(r, r.ok ? 200 : r.status);
    }

    if (action === "attach-number") {
      const r = await attachNumberToService(String(body.serviceSid ?? ""), String(body.phoneNumberSid ?? ""));
      return respond(r, r.ok ? 200 : r.status);
    }

    if (action === "delete") {
      const sid = String(body.sid ?? "");
      const messagingServiceSid = String(body.messagingServiceSid ?? PRIMARY_MESSAGING_SERVICE_SID);
      if (!sid) return respond({ error: "body.sid required" }, 400);
      const r = await deleteCampaign(messagingServiceSid, sid);
      return respond(r, r.ok ? 200 : r.status);
    }

    if (action === "create") {
      const messagingServiceSid = String(body.messagingServiceSid ?? PRIMARY_MESSAGING_SERVICE_SID);
      const payload = body.payload ? (body.payload as Record<string, unknown>) : DEFAULT_MARKETING_PAYLOAD;
      const r = await createCampaign(messagingServiceSid, payload);
      return respond(r, r.ok ? 200 : r.status);
    }

    if (action === "full-marketing-setup") {
      // 1. Find available number
      const areaCode = (body.areaCode as string | undefined) ?? "561"; // FL Palm Beach default
      const friendlyName = (body.friendlyName as string | undefined) ?? "Milton Recovery Marketing & Alumni Invites";
      const log: Record<string, unknown> = { steps: {} };

      const avail = await findAvailableNumber(areaCode);
      log.steps = { ...(log.steps as Record<string, unknown>), available: avail };
      if (!avail.ok) return respond({ failedAt: "available-numbers", ...log }, avail.status);
      const numbers = (avail.body as { available_phone_numbers?: Array<{ phone_number: string }> })?.available_phone_numbers ?? [];
      if (!numbers.length) return respond({ failedAt: "available-numbers", reason: "no numbers returned for area code", areaCode, ...log }, 422);
      const chosenPhoneNumber = numbers[0].phone_number;

      // 2. Buy it
      const buy = await buyNumber(chosenPhoneNumber);
      log.steps = { ...(log.steps as Record<string, unknown>), buy };
      if (!buy.ok) return respond({ failedAt: "buy-number", chosenPhoneNumber, ...log }, buy.status);
      const phoneNumberSid = (buy.body as { sid?: string })?.sid ?? "";

      // 3. Create Messaging Service
      const svc = await createMessagingService(friendlyName);
      log.steps = { ...(log.steps as Record<string, unknown>), createService: svc };
      if (!svc.ok) return respond({ failedAt: "create-service", chosenPhoneNumber, phoneNumberSid, ...log }, svc.status);
      const serviceSid = (svc.body as { sid?: string })?.sid ?? "";

      // 4. Attach number to service
      const att = await attachNumberToService(serviceSid, phoneNumberSid);
      log.steps = { ...(log.steps as Record<string, unknown>), attach: att };
      if (!att.ok) return respond({ failedAt: "attach-number", chosenPhoneNumber, phoneNumberSid, serviceSid, ...log }, att.status);

      // 5. Create the Marketing Campaign
      const camp = await createCampaign(serviceSid, DEFAULT_MARKETING_PAYLOAD);
      log.steps = { ...(log.steps as Record<string, unknown>), campaign: camp };
      if (!camp.ok) return respond({ failedAt: "create-campaign", chosenPhoneNumber, phoneNumberSid, serviceSid, ...log }, camp.status);
      const campaignSid = ((camp.body as Record<string, unknown>)?.sid as string | undefined) ?? "";

      return respond({
        success: true,
        summary: {
          phoneNumber: chosenPhoneNumber,
          phoneNumberSid,
          messagingServiceSid: serviceSid,
          campaignSid,
        },
        log,
      });
    }

    if (action === "full") {
      // Inspect → DELETE → CREATE on the primary 2FA Messaging Service.
      // (Retained from the original delete+recreate use case.)
      const inspect = await inspectCampaign(PRIMARY_MESSAGING_SERVICE_SID);
      if (!inspect.ok) return respond({ step: "inspect", ...inspect }, inspect.status);
      const existing = extractCampaign(inspect.body);
      if (!existing?.sid) return respond({ step: "inspect", error: "no campaign sid found", body: inspect.body }, 422);
      const del = await deleteCampaign(PRIMARY_MESSAGING_SERVICE_SID, existing.sid);
      if (!del.ok && del.status !== 404) return respond({ step: "delete", existing, ...del }, del.status);
      const payload = body.payload ? (body.payload as Record<string, unknown>) : DEFAULT_MARKETING_PAYLOAD;
      const create = await createCampaign(PRIMARY_MESSAGING_SERVICE_SID, payload);
      return respond({ step: "full", inspect: existing, delete: del, create }, create.ok ? 200 : create.status);
    }

    return respond({ error: "unknown action" }, 400);
  } catch (err) {
    return respond({ error: "internal", detail: String(err) }, 500);
  }
});

interface ExistingCampaign {
  sid: string;
  brandRegistrationSid: string;
  description: string;
}

function extractCampaign(body: unknown): ExistingCampaign | null {
  if (!body || typeof body !== "object") return null;
  const root = body as Record<string, unknown>;
  let cand: Record<string, unknown> | undefined;
  if (Array.isArray((root as { compliance?: unknown[] }).compliance) && (root as { compliance: unknown[] }).compliance.length) {
    cand = (root as { compliance: Record<string, unknown>[] }).compliance[0];
  } else {
    cand = root;
  }
  if (!cand || typeof cand !== "object") return null;
  return {
    sid: String(cand.sid ?? ""),
    brandRegistrationSid: String(cand.brand_registration_sid ?? cand.brandRegistrationSid ?? ""),
    description: String(cand.description ?? ""),
  };
}
