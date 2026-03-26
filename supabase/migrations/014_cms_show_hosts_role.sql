-- Add role column to cms_show_hosts
-- Allows distinguishing hosts from producers and other roles
ALTER TABLE cms_show_hosts
  ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'host';

-- Add a check constraint for valid roles
ALTER TABLE cms_show_hosts
  ADD CONSTRAINT cms_show_hosts_role_check
  CHECK (role IN ('host', 'producer', 'co-host', 'contributor'));
