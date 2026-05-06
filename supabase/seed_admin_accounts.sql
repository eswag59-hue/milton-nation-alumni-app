-- ============================================================
-- seed_admin_accounts.sql — Phase 7 Post-Launch Setup
-- Run in Supabase SQL Editor AFTER schema.sql + all migrations
--
-- STEP 1: Create auth users in Supabase Dashboard first
--   Dashboard → Authentication → Users → "Invite User" (or "Add User")
--   For each admin, create the auth user with their email + a temporary password.
--   They will be prompted to reset it on first login.
--
-- STEP 2: Run this SQL to set their profiles with admin roles.
--
-- IMPORTANT: Replace the UUIDs below with the actual Supabase auth user IDs
--   shown in Dashboard → Authentication → Users after creating each account.
-- ============================================================


-- ============================================================
-- FLORIDA FACILITY — Admin & Staff Accounts
-- ============================================================

-- ============ SUPER ADMIN ============
-- Replace 'SUPER_ADMIN_AUTH_UUID' with the real UUID from Supabase Auth
UPDATE public.profiles
SET
    full_name     = 'Super Admin',        -- TODO: Replace with actual name
    role          = 'super_admin',
    status        = 'active',
    admin_facility = NULL,                -- NULL = manages ALL facilities
    recovery_program = 'Staff',
    sobriety_date = '2020-01-01',
    discharge_date = '2020-01-01'
WHERE id = 'SUPER_ADMIN_AUTH_UUID';

-- ============ FLORIDA ADMIN ============
-- Replace 'FLORIDA_ADMIN_AUTH_UUID' with the real UUID from Supabase Auth
UPDATE public.profiles
SET
    full_name      = 'Florida Admin',     -- TODO: Replace with actual name
    role           = 'admin',
    status         = 'active',
    admin_facility = 'florida',
    recovery_program = 'Staff',
    sobriety_date = '2020-01-01',
    discharge_date = '2020-01-01'
WHERE id = 'FLORIDA_ADMIN_AUTH_UUID';

-- ============ FLORIDA CASE MANAGER ============
-- Replace 'FL_CASE_MANAGER_UUID' with the real UUID from Supabase Auth
UPDATE public.profiles
SET
    full_name      = 'Florida Case Manager',  -- TODO: Replace with actual name
    role           = 'case_manager',
    status         = 'active',
    admin_facility = 'florida',
    recovery_program = 'Staff',
    sobriety_date = '2020-01-01',
    discharge_date = '2020-01-01'
WHERE id = 'FL_CASE_MANAGER_UUID';

-- ============ FLORIDA THERAPIST ============
-- Replace 'FL_THERAPIST_UUID' with the real UUID from Supabase Auth
UPDATE public.profiles
SET
    full_name      = 'Florida Therapist',  -- TODO: Replace with actual name
    role           = 'therapist',
    status         = 'active',
    admin_facility = 'florida',
    recovery_program = 'Staff',
    sobriety_date = '2020-01-01',
    discharge_date = '2020-01-01'
WHERE id = 'FL_THERAPIST_UUID';


-- ============================================================
-- Verify results
-- ============================================================
SELECT id, email, full_name, role, status, admin_facility, facility
FROM public.profiles
WHERE role IN ('admin', 'super_admin', 'case_manager', 'therapist', 'counselor')
ORDER BY role, full_name;
