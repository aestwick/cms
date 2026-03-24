-- Allow super_admins to invite staff with non-@kpfk.org email addresses
-- When set to true on a profile, the middleware skips the email domain check
-- for admin portal access. Only super_admin can create invites that set this flag.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS allow_external_domain boolean NOT NULL DEFAULT false;

-- Comment explaining what this column does for future developers
COMMENT ON COLUMN profiles.allow_external_domain IS
  'When true, this user can access the admin portal even with a non-@kpfk.org email. Set automatically when a super_admin invites an off-domain email address.';

-- Notify PostgREST to reload schema (required after column changes)
NOTIFY pgrst, 'reload schema';
