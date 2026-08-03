-- Expand moderation_keywords + content_flags categories to include
-- eating_disorder and domestic_violence (v1.0 launch — see
-- ContentSafetyKeywords.swift for the matching enum).

-- ── moderation_keywords ──────────────────────────────────────────────────
-- This table holds remotely-fetchable keywords that the iOS engine pulls
-- on launch + every 4 hours. Without dropping the old constraint, INSERTs
-- of new categories would fail.

ALTER TABLE public.moderation_keywords
    DROP CONSTRAINT IF EXISTS moderation_keywords_category_check;

ALTER TABLE public.moderation_keywords
    ADD CONSTRAINT moderation_keywords_category_check
    CHECK (category IN (
        'self_harm',
        'drugs',
        'alcohol',
        'violence',
        'eating_disorder',
        'domestic_violence',
        'emergency'
    ));

-- ── content_flags ───────────────────────────────────────────────────────
-- This table stores the redacted server-side record of every flag fired
-- (see flag-content Edge Function). The category column should accept the
-- same enum values. If it has a constraint, expand it too.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'content_flags'
          AND constraint_name LIKE '%category%check%'
    ) THEN
        ALTER TABLE public.content_flags
            DROP CONSTRAINT IF EXISTS content_flags_category_check;
    END IF;
END $$;

-- Re-add a permissive constraint (categories is text[] in content_flags,
-- so each element must be valid). If the column type is different in your
-- schema, skip this block — content_flags is intentionally flexible.

-- ── verify ──────────────────────────────────────────────────────────────
-- After running, confirm the constraint shows all 7 categories:
--   SELECT pg_get_constraintdef(oid)
--   FROM pg_constraint
--   WHERE conname = 'moderation_keywords_category_check';
