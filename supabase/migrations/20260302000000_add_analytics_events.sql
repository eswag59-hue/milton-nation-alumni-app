-- Analytics events table for tracking user engagement.
-- Separate from audit_logs (security/compliance) — this is product analytics.

CREATE TABLE IF NOT EXISTS analytics_events (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
    event_name  TEXT        NOT NULL,
    properties  JSONB       NOT NULL DEFAULT '{}',
    role        TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Authenticated users may insert their own events (or anonymous events with null user_id).
CREATE POLICY "Users insert own analytics events"
    ON analytics_events FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

-- Only admins can query the analytics data.
CREATE POLICY "Admins read all analytics events"
    ON analytics_events FOR SELECT TO authenticated
    USING (is_admin());

-- Indexes for common query patterns.
CREATE INDEX IF NOT EXISTS analytics_events_user_id_idx   ON analytics_events(user_id);
CREATE INDEX IF NOT EXISTS analytics_events_event_name_idx ON analytics_events(event_name);
CREATE INDEX IF NOT EXISTS analytics_events_created_at_idx ON analytics_events(created_at DESC);
