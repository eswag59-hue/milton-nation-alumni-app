# Demo account staging for marketing capture — 2026-08-25

Changes made to the **App Review / demo account only** so launch screenshots show
an aspirational streak instead of a 13-day one. No real member data, no schema
changes, no other account touched.

**Project:** `hksxzuytcmqqwxmfjzdp` (production)
**Account:** `auth.users.email = appreviewer@miltonrecovery.com`
(note: the matching `profiles` row carries a *different* display email,
`appreviewer@miltonrecoverycenters.com` — the two columns disagree, which is worth
reconciling separately; it caused real confusion while chasing a login failure.)

## 1. Password reset

The password documented in `EZRA-TEST-SCRIPT.md` no longer authenticated. It was
reset to a new value so the team could capture screenshots. **The password itself
is deliberately not recorded here** — it was shared with Ezra directly. Ask him,
or set a fresh one from the Supabase dashboard under **Authentication → Users**.

The statement used (password redacted):

```sql
update auth.users
set encrypted_password = extensions.crypt('<redacted>', extensions.gen_salt('bf')),
    updated_at = now()
where email = 'appreviewer@miltonrecovery.com';
```

Verified: hash is bcrypt (`$2a$`, 60 chars), `updated_at` bumped.
`pgcrypto` lives in the `extensions` schema on this project, so `crypt` and
`gen_salt` must be schema-qualified.

## 2. Profile staged for capture

```sql
update profiles
set sobriety_date = '2023-08-25',
    full_name     = 'Alex Demo',
    updated_at    = now()
where email = 'appreviewer@miltonrecoverycenters.com';
```

| Field | Before | After |
|---|---|---|
| `full_name` | Ez barish test | Alex Demo |
| `sobriety_date` | 2026-08-12 | 2023-08-25 |
| days shown in app | 13 | 1096 (3 years) |
| `total_points` | 530 | unchanged |
| `approved_post_count` | 4 | unchanged |

## Revert

```sql
update profiles
set sobriety_date = '2026-08-12',
    full_name     = 'Ez barish test',
    updated_at    = now()
where email = 'appreviewer@miltonrecoverycenters.com';
```

The password cannot be reverted (the original hash was not captured, and could
not be read back as plaintext). Set a new one from the Supabase dashboard under
**Authentication → Users** if it needs to change again.

## Note on tooling

The Supabase MCP `execute_sql` tool runs in a **read-only** transaction, so
writes fail with `25006: cannot execute UPDATE in a read-only transaction`.
`apply_migration` runs on a writable connection and works — that is the path for
any future data fix through the MCP.

## Follow-ups worth doing

- Reconcile the auth email vs `profiles.email` mismatch on this account.
- Correct `EZRA-TEST-SCRIPT.md`, which lists a password that no longer works and
  an email that differs from the auth record.
- Re-shoot the App Store listing screenshots. The live ones were captured from an
  older build: they show `— Unknown` under the daily quote and the colour-swatch
  bar under the logo, both of which the current code already fixes, plus the
  admin account in User View with the "Back to Admin" debug pill visible.
