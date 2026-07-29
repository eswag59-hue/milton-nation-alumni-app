// LLM crisis classifier — catches subtle / euphemistic self-harm or crisis
// language that a keyword list can't ("might be time to let it go").
//
// Runs alongside keyword matching, never instead of it. Returns a risk level
// the app folds into moderation. Fails SAFE-OPEN: if the API key is missing or
// the call errors, it returns {risk:"none", configured:false} so content flow
// is never blocked and the keyword layer still applies.
//
// PHI note: the classified text is user-authored content that may contain PHI.
// Anthropic's API is used under a signed BAA when processing such text — set
// ANTHROPIC_API_KEY only once that BAA is in place (see runbook).

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...corsHeaders, "Content-Type": "application/json" } });

const SYSTEM = `You are a safety classifier for a substance-use-disorder recovery community app.
Assess whether a user's message indicates they may be at risk of suicide, self-harm, or an acute mental-health/relapse crisis RIGHT NOW — including subtle, indirect, or euphemistic language (e.g. "might be time to let it go", "I'm just so tired of all of it", "everyone would be better off").
Do NOT over-flag ordinary sadness, venting, or recovery talk that is not crisis.
Respond with ONLY a compact JSON object: {"risk":"none|low|medium|high","reason":"<=12 words"}.
high = explicit or strongly-implied intent/plan of self-harm or suicide.
medium = concerning ideation, hopelessness, or possible relapse crisis without clear intent.
low = mild distress worth a gentle check-in.
none = no crisis signal.`;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    const { text } = await req.json().catch(() => ({ text: "" }));
    if (!text || typeof text !== "string" || text.trim().length === 0) {
      return json({ risk: "none", configured: !!apiKey });
    }
    // Safe-open until the key (and its BAA) are in place.
    if (!apiKey) return json({ risk: "none", configured: false });

    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 60,
        system: SYSTEM,
        messages: [{ role: "user", content: text.slice(0, 2000) }],
      }),
    });

    if (!res.ok) {
      console.error("[classify-crisis] Anthropic error:", res.status, await res.text());
      return json({ risk: "none", configured: true, error: "classifier_unavailable" });
    }

    const data = await res.json();
    const raw = (data?.content?.[0]?.text ?? "").trim();
    let risk = "none";
    let reason = "";
    try {
      const m = raw.match(/\{[\s\S]*\}/);
      const parsed = m ? JSON.parse(m[0]) : {};
      const r = String(parsed.risk ?? "none").toLowerCase();
      risk = ["none", "low", "medium", "high"].includes(r) ? r : "none";
      reason = String(parsed.reason ?? "").slice(0, 80);
    } catch (_) {
      risk = "none";
    }
    return json({ risk, reason, configured: true });
  } catch (err) {
    console.error("[classify-crisis] error:", err);
    return json({ risk: "none", configured: true, error: String(err) });
  }
});
