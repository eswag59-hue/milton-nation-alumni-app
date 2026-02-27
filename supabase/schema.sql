-- Milton Nation Alumni App — Supabase Database Schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)
--
-- Prerequisites: Supabase project created with Auth enabled
-- This creates all tables, enables RLS, and sets up security policies.

-- ============================================================
-- 1. TABLES
-- ============================================================

-- Profiles (extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    phone TEXT,
    full_name TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    profile_photo_url TEXT,
    sobriety_date DATE NOT NULL,
    discharge_date DATE NOT NULL,
    recovery_program TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'alumni'
        CHECK (role IN ('alumni', 'case_manager', 'therapist', 'counselor', 'admin', 'super_admin')),
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'active', 'deactivated', 'deleted')),
    mfa_method TEXT CHECK (mfa_method IN ('sms', 'email', 'totp')),
    total_points INT NOT NULL DEFAULT 0,
    approved_post_count INT NOT NULL DEFAULT 0,
    last_login TIMESTAMPTZ,
    last_points_awarded TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Posts
CREATE TABLE public.posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    user_name TEXT NOT NULL,
    user_photo_url TEXT,
    category TEXT NOT NULL DEFAULT 'general'
        CHECK (category IN ('wins', 'struggles', 'support', 'gratitude', 'general')),
    content TEXT NOT NULL,
    media_url TEXT,
    media_type TEXT CHECK (media_type IN ('image', 'video')),
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'approved', 'rejected', 'pending_review', 'flagged_for_crisis')),
    is_pinned BOOLEAN NOT NULL DEFAULT false,
    likes_count INT NOT NULL DEFAULT 0,
    comments_count INT NOT NULL DEFAULT 0,
    matched_keywords TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    approved_at TIMESTAMPTZ
);

-- Comments
CREATE TABLE public.comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    user_name TEXT NOT NULL,
    user_photo_url TEXT,
    content TEXT NOT NULL,
    matched_keywords TEXT[] DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'approved'
        CHECK (status IN ('pending', 'approved', 'rejected', 'pending_review', 'flagged_for_crisis')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Likes (unique per user per post)
CREATE TABLE public.likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(post_id, user_id)
);

-- Conversations
CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    staff_id UUID NOT NULL REFERENCES public.profiles(id),
    last_message TEXT,
    last_message_at TIMESTAMPTZ,
    unread_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Messages
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id),
    message_type TEXT NOT NULL DEFAULT 'text'
        CHECK (message_type IN ('text', 'image', 'voice', 'file')),
    content TEXT,
    media_url TEXT,
    file_name TEXT,
    status TEXT NOT NULL DEFAULT 'clean'
        CHECK (status IN ('clean', 'pending', 'flagged', 'flagged_for_crisis', 'approved', 'denied')),
    matched_keywords TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Meetings
CREATE TABLE public.meetings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    meeting_type TEXT NOT NULL DEFAULT 'virtual'
        CHECK (meeting_type IN ('in_person', 'virtual', 'hybrid')),
    date DATE NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    location_address TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    virtual_link TEXT,
    is_recurring BOOLEAN NOT NULL DEFAULT false,
    recurrence_pattern TEXT CHECK (recurrence_pattern IN ('weekly', 'biweekly', 'monthly')),
    recurrence_end_date DATE,
    parent_meeting_id UUID REFERENCES public.meetings(id),
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Meeting RSVPs
CREATE TABLE public.meeting_rsvps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meeting_id UUID NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(meeting_id, user_id)
);

-- Badges
CREATE TABLE public.badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    emoji TEXT NOT NULL,
    points_required INT NOT NULL,
    sort_order INT NOT NULL DEFAULT 0
);

-- User Badges (earned)
CREATE TABLE public.user_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    badge_id UUID NOT NULL REFERENCES public.badges(id),
    earned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, badge_id)
);

-- Sobriety Milestones
CREATE TABLE public.sobriety_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    milestone_type TEXT NOT NULL
        CHECK (milestone_type IN ('30_days', '60_days', '90_days', '6_months', '1_year', 'yearly')),
    milestone_date DATE NOT NULL,
    points_awarded INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Announcements
CREATE TABLE public.announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Daily Quotes
CREATE TABLE public.daily_quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    text TEXT NOT NULL,
    attribution TEXT NOT NULL,
    scheduled_date DATE
);

-- Staff Assignments
CREATE TABLE public.staff_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    staff_id UUID NOT NULL REFERENCES public.profiles(id),
    role_type TEXT NOT NULL
        CHECK (role_type IN ('case_manager', 'therapist', 'counselor')),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Audit Logs (HIPAA — immutable, 6-year retention)
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    action TEXT NOT NULL,
    user_id UUID,
    detail TEXT,
    ip_address INET,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- SMS OTP Challenges (used by send-sms-otp and verify-sms-otp Edge Functions)
-- Stores short-lived hashed OTP codes for phone-based MFA.
-- Rows auto-expire and are cleaned up by the edge functions after use.
CREATE TABLE public.sms_otp_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    phone TEXT NOT NULL,
    otp_hash TEXT NOT NULL,             -- SHA-256 hash of the 6-digit code (never stored plaintext)
    expires_at TIMESTAMPTZ NOT NULL,    -- 5 minutes from creation
    verified BOOLEAN NOT NULL DEFAULT false,
    attempts INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 5,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 2. INDEXES
-- ============================================================

CREATE INDEX idx_posts_user_id ON public.posts(user_id);
CREATE INDEX idx_posts_status ON public.posts(status);
CREATE INDEX idx_posts_category ON public.posts(category);
CREATE INDEX idx_posts_created_at ON public.posts(created_at DESC);

CREATE INDEX idx_comments_post_id ON public.comments(post_id);
CREATE INDEX idx_comments_user_id ON public.comments(user_id);

CREATE INDEX idx_likes_post_id ON public.likes(post_id);
CREATE INDEX idx_likes_user_id ON public.likes(user_id);

CREATE INDEX idx_conversations_user_id ON public.conversations(user_id);
CREATE INDEX idx_conversations_staff_id ON public.conversations(staff_id);

CREATE INDEX idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at);

CREATE INDEX idx_meetings_date ON public.meetings(date);
CREATE INDEX idx_meetings_created_by ON public.meetings(created_by);

CREATE INDEX idx_meeting_rsvps_meeting_id ON public.meeting_rsvps(meeting_id);
CREATE INDEX idx_meeting_rsvps_user_id ON public.meeting_rsvps(user_id);

CREATE INDEX idx_user_badges_user_id ON public.user_badges(user_id);
CREATE INDEX idx_sobriety_milestones_user_id ON public.sobriety_milestones(user_id);

CREATE INDEX idx_staff_assignments_user_id ON public.staff_assignments(user_id);
CREATE INDEX idx_staff_assignments_staff_id ON public.staff_assignments(staff_id);

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX idx_audit_logs_timestamp ON public.audit_logs(timestamp DESC);

CREATE INDEX idx_sms_otp_challenges_user_id ON public.sms_otp_challenges(user_id);
CREATE INDEX idx_sms_otp_challenges_expires_at ON public.sms_otp_challenges(expires_at);

-- ============================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_rsvps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sobriety_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_otp_challenges ENABLE ROW LEVEL SECURITY;

-- Helper function: check if current user is admin or super_admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'super_admin')
        AND status = 'active'
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper function: check if current user is super_admin
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND role = 'super_admin'
        AND status = 'active'
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================
-- 3a. PROFILES policies
-- ============================================================

-- Users can read their own profile
CREATE POLICY "Users read own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

-- Users can read profiles of staff assigned to them
CREATE POLICY "Users read assigned staff profiles"
    ON public.profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.staff_assignments
            WHERE staff_assignments.staff_id = profiles.id
            AND staff_assignments.user_id = auth.uid()
        )
    );

-- Admins can read all profiles
CREATE POLICY "Admins read all profiles"
    ON public.profiles FOR SELECT
    USING (public.is_admin());

-- Users can update their own profile
CREATE POLICY "Users update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Admins can update any profile (for role changes, status updates)
CREATE POLICY "Admins update any profile"
    ON public.profiles FOR UPDATE
    USING (public.is_admin());

-- Allow insert during registration (user creates their own profile)
CREATE POLICY "Users insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ============================================================
-- 3b. POSTS policies
-- ============================================================

-- All authenticated users can read approved posts
CREATE POLICY "Read approved posts"
    ON public.posts FOR SELECT
    USING (status = 'approved' AND auth.uid() IS NOT NULL);

-- Authors can read their own posts (any status)
CREATE POLICY "Authors read own posts"
    ON public.posts FOR SELECT
    USING (user_id = auth.uid());

-- Admins can read all posts
CREATE POLICY "Admins read all posts"
    ON public.posts FOR SELECT
    USING (public.is_admin());

-- Authenticated users can create posts
CREATE POLICY "Authenticated users create posts"
    ON public.posts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Admins can update posts (moderation)
CREATE POLICY "Admins moderate posts"
    ON public.posts FOR UPDATE
    USING (public.is_admin());

-- ============================================================
-- 3c. COMMENTS policies
-- ============================================================

-- Read comments on posts the user can see (approved posts)
CREATE POLICY "Read comments on visible posts"
    ON public.comments FOR SELECT
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = comments.post_id
            AND (posts.status = 'approved' OR posts.user_id = auth.uid())
        )
    );

-- Admins can read all comments
CREATE POLICY "Admins read all comments"
    ON public.comments FOR SELECT
    USING (public.is_admin());

-- Authenticated users can create comments
CREATE POLICY "Authenticated users create comments"
    ON public.comments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 3d. LIKES policies
-- ============================================================

-- Users can manage their own likes
CREATE POLICY "Users manage own likes"
    ON public.likes FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Read likes on visible posts
CREATE POLICY "Read likes"
    ON public.likes FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- ============================================================
-- 3e. CONVERSATIONS policies
-- ============================================================

-- Only participants can read conversations
CREATE POLICY "Participants read conversations"
    ON public.conversations FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() = staff_id);

-- Admins can read all conversations (for monitoring)
CREATE POLICY "Admins read all conversations"
    ON public.conversations FOR SELECT
    USING (public.is_admin());

-- Participants can update conversations (unread count, etc.)
CREATE POLICY "Participants update conversations"
    ON public.conversations FOR UPDATE
    USING (auth.uid() = user_id OR auth.uid() = staff_id);

-- ============================================================
-- 3f. MESSAGES policies
-- ============================================================

-- Only conversation participants can read messages
CREATE POLICY "Participants read messages"
    ON public.messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE conversations.id = messages.conversation_id
            AND (conversations.user_id = auth.uid() OR conversations.staff_id = auth.uid())
        )
    );

-- Admins can read all messages (for monitoring)
CREATE POLICY "Admins read all messages"
    ON public.messages FOR SELECT
    USING (public.is_admin());

-- Conversation participants can send messages
CREATE POLICY "Participants send messages"
    ON public.messages FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id
        AND EXISTS (
            SELECT 1 FROM public.conversations
            WHERE conversations.id = messages.conversation_id
            AND (conversations.user_id = auth.uid() OR conversations.staff_id = auth.uid())
        )
    );

-- ============================================================
-- 3g. MEETINGS policies
-- ============================================================

-- All authenticated users can read meetings
CREATE POLICY "Authenticated users read meetings"
    ON public.meetings FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Admins can create/update/delete meetings
CREATE POLICY "Admins manage meetings"
    ON public.meetings FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ============================================================
-- 3h. MEETING RSVPs policies
-- ============================================================

-- Users can manage their own RSVPs
CREATE POLICY "Users manage own RSVPs"
    ON public.meeting_rsvps FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- All authenticated users can read RSVPs
CREATE POLICY "Read RSVPs"
    ON public.meeting_rsvps FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- ============================================================
-- 3i. BADGES policies (read-only for non-admins)
-- ============================================================

CREATE POLICY "Read badges"
    ON public.badges FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admins manage badges"
    ON public.badges FOR ALL
    USING (public.is_super_admin())
    WITH CHECK (public.is_super_admin());

-- ============================================================
-- 3j. USER BADGES policies
-- ============================================================

CREATE POLICY "Read user badges"
    ON public.user_badges FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Insert handled by RPC function (service role)
CREATE POLICY "System insert user badges"
    ON public.user_badges FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 3k. SOBRIETY MILESTONES policies
-- ============================================================

CREATE POLICY "Users read own milestones"
    ON public.sobriety_milestones FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Admins read all milestones"
    ON public.sobriety_milestones FOR SELECT
    USING (public.is_admin());

-- ============================================================
-- 3l. ANNOUNCEMENTS policies
-- ============================================================

CREATE POLICY "Read announcements"
    ON public.announcements FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admins manage announcements"
    ON public.announcements FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ============================================================
-- 3m. DAILY QUOTES policies
-- ============================================================

CREATE POLICY "Read daily quotes"
    ON public.daily_quotes FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admins manage quotes"
    ON public.daily_quotes FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ============================================================
-- 3n. STAFF ASSIGNMENTS policies
-- ============================================================

CREATE POLICY "Users read own assignments"
    ON public.staff_assignments FOR SELECT
    USING (user_id = auth.uid() OR staff_id = auth.uid());

CREATE POLICY "Admins manage assignments"
    ON public.staff_assignments FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ============================================================
-- 3o. AUDIT LOGS policies (HIPAA — read-only for admins, no deletes)
-- ============================================================

CREATE POLICY "Admins read audit logs"
    ON public.audit_logs FOR SELECT
    USING (public.is_admin());

-- Insert is allowed for any authenticated user (logging their own actions)
CREATE POLICY "Authenticated users insert audit logs"
    ON public.audit_logs FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND (user_id = auth.uid() OR user_id IS NULL)
    );

-- NO update or delete policies — audit logs are immutable

-- ============================================================
-- 3p. SMS OTP CHALLENGES policies (service role only via Edge Functions)
-- ============================================================

-- Edge Functions use SUPABASE_SERVICE_ROLE_KEY and bypass RLS.
-- Regular users have zero access to this table.
-- (No SELECT/INSERT/UPDATE/DELETE policies needed for anon/authenticated roles)

-- ============================================================
-- 4. RPC FUNCTIONS
-- ============================================================

-- Atomic point award: increments user points and returns new total
CREATE OR REPLACE FUNCTION public.award_points(
    p_user_id UUID,
    p_points INT,
    p_action TEXT
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_total INT;
BEGIN
    UPDATE public.profiles
    SET total_points = total_points + p_points,
        last_points_awarded = now(),
        updated_at = now()
    WHERE id = p_user_id
    RETURNING total_points INTO new_total;

    -- Check and award new badges
    INSERT INTO public.user_badges (user_id, badge_id)
    SELECT p_user_id, b.id
    FROM public.badges b
    WHERE b.points_required <= new_total
    AND NOT EXISTS (
        SELECT 1 FROM public.user_badges ub
        WHERE ub.user_id = p_user_id AND ub.badge_id = b.id
    );

    RETURN new_total;
END;
$$;

-- Toggle like: returns true if liked, false if unliked
CREATE OR REPLACE FUNCTION public.toggle_like(p_post_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    already_liked BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.likes
        WHERE post_id = p_post_id AND user_id = auth.uid()
    ) INTO already_liked;

    IF already_liked THEN
        DELETE FROM public.likes
        WHERE post_id = p_post_id AND user_id = auth.uid();

        UPDATE public.posts
        SET likes_count = GREATEST(likes_count - 1, 0)
        WHERE id = p_post_id;

        RETURN false;
    ELSE
        INSERT INTO public.likes (post_id, user_id)
        VALUES (p_post_id, auth.uid());

        UPDATE public.posts
        SET likes_count = likes_count + 1
        WHERE id = p_post_id;

        RETURN true;
    END IF;
END;
$$;

-- Increment comment count
CREATE OR REPLACE FUNCTION public.increment_comment_count(p_post_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.posts
    SET comments_count = comments_count + 1
    WHERE id = p_post_id;
END;
$$;

-- ============================================================
-- 5. TRIGGERS
-- ============================================================

-- Auto-create profile when a new auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, username, sobriety_date, discharge_date, recovery_program)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || LEFT(NEW.id::TEXT, 8)),
        COALESCE((NEW.raw_user_meta_data->>'sobriety_date')::DATE, CURRENT_DATE),
        COALESCE((NEW.raw_user_meta_data->>'discharge_date')::DATE, CURRENT_DATE),
        COALESCE(NEW.raw_user_meta_data->>'recovery_program', 'Milton Recovery')
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-update updated_at on profiles
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================================
-- 6. STORAGE BUCKETS (run separately in Dashboard → Storage)
-- ============================================================
-- ALL buckets are PRIVATE (public = false). Access is via signed URLs.
-- After running schema.sql, also run storage_policies.sql.
--
-- Create these buckets in Supabase Dashboard → Storage → New bucket
-- (ensure "Public bucket" is UNCHECKED for all three):
--   1. post-media        — community post images/videos
--   2. profile-photos    — user profile photos
--   3. chat-media        — private chat attachments
--
-- Or run via SQL (all private):
-- INSERT INTO storage.buckets (id, name, public) VALUES ('post-media', 'post-media', false);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('profile-photos', 'profile-photos', false);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('chat-media', 'chat-media', false);

-- =============================================================
-- Realtime Publications
-- Tables that need postgres_changes subscriptions
-- =============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
