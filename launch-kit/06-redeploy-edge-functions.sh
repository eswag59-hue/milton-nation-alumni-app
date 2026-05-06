#!/usr/bin/env bash
# Redeploy edge functions whose local source is newer than the deployed version.
#
# Usage:
#   chmod +x launch-kit/06-redeploy-edge-functions.sh
#   ./launch-kit/06-redeploy-edge-functions.sh
#
# Prerequisites:
#   - Supabase CLI installed: `brew install supabase/tap/supabase`
#   - Logged in:                `supabase login`
#   - Linked to project:        `supabase link --project-ref hksxzuytcmqqwxmfjzdp`

set -euo pipefail

PROJECT_REF="hksxzuytcmqqwxmfjzdp"
FUNCTIONS=(
  "verify-sms-otp"           # local has been edited since last deploy
  "send-push-notification"   # local has been edited since last deploy
  "assign-user-facility"     # local has been edited since last deploy
)

cd "$(dirname "$0")/.."  # project root

echo "🚀 Deploying edge functions to project $PROJECT_REF"
echo ""

for fn in "${FUNCTIONS[@]}"; do
  echo "→ Deploying $fn"
  supabase functions deploy "$fn" --project-ref "$PROJECT_REF" --no-verify-jwt=false
  echo "✅ $fn deployed"
  echo ""
done

echo "🎉 All functions deployed. Verify in Supabase Dashboard → Edge Functions."
echo ""
echo "Smoke test (replace <USER_JWT> with a real authed token):"
echo "  curl https://$PROJECT_REF.supabase.co/functions/v1/verify-sms-otp \\"
echo "    -X POST \\"
echo "    -H \"Authorization: Bearer <USER_JWT>\" \\"
echo "    -H \"apikey: \$SUPABASE_ANON_KEY\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"code\":\"000000\"}'"
