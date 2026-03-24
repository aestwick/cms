-- Access requests table
-- When a new user signs up on admin.kpfk.org without an invite, they get
-- 'donor' role by default and can't access the admin portal. This table
-- lets them request staff access. Admins see pending requests in
-- Settings > Users > Requests and can approve (setting the role) or deny.

CREATE TABLE IF NOT EXISTS public.access_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    -- The user requesting access (references Supabase auth)
    user_id uuid NOT NULL REFERENCES auth.users(id),
    -- Snapshot of their email at request time (for admin convenience)
    email text NOT NULL,
    -- Their display name from profile (filled during profile completion)
    display_name text,
    -- Free-text: "phone volunteer", "development director", etc.
    -- Helps admin pick the right role without a back-and-forth
    station_role_description text,
    -- Which station they're requesting access to
    station_id uuid REFERENCES public.stations(id),
    -- pending → approved or denied
    status text NOT NULL DEFAULT 'pending',
    -- Who reviewed and when
    reviewed_by uuid REFERENCES auth.users(id),
    reviewed_at timestamptz,
    -- Optional note from the reviewer ("approved for spring drive")
    reviewer_note text,
    -- Role assigned on approval (null until approved)
    approved_role text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT access_requests_status_check CHECK (status IN ('pending', 'approved', 'denied'))
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_access_requests_user_id ON public.access_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_access_requests_station_id ON public.access_requests(station_id);
CREATE INDEX IF NOT EXISTS idx_access_requests_status ON public.access_requests(status);
-- Admin dashboard filters by station + status
CREATE INDEX IF NOT EXISTS idx_access_requests_station_status ON public.access_requests(station_id, status);

-- Only one pending request per user (prevent spam)
CREATE UNIQUE INDEX IF NOT EXISTS idx_access_requests_unique_pending
    ON public.access_requests(user_id) WHERE status = 'pending';

-- RLS: only the requesting user can see their own request,
-- staff can see all requests for their station
ALTER TABLE public.access_requests ENABLE ROW LEVEL SECURITY;

-- Users can read their own access requests
CREATE POLICY access_requests_select_own ON public.access_requests
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Users can insert their own access requests
CREATE POLICY access_requests_insert_own ON public.access_requests
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Staff with admin role can read all requests for their station
-- (API routes use service role so this is mainly defense-in-depth)
CREATE POLICY access_requests_select_staff ON public.access_requests
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('super_admin', 'admin')
            AND profiles.is_active = true
            AND (profiles.role = 'super_admin' OR profiles.station_id = access_requests.station_id)
        )
    );

-- Staff with admin role can update requests (approve/deny)
CREATE POLICY access_requests_update_staff ON public.access_requests
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('super_admin', 'admin')
            AND profiles.is_active = true
            AND (profiles.role = 'super_admin' OR profiles.station_id = access_requests.station_id)
        )
    );

COMMENT ON TABLE public.access_requests IS 'Staff access requests from users who signed up without an invite. Reviewed by admins in Settings > Users.';
COMMENT ON COLUMN public.access_requests.station_role_description IS 'Free-text description of their role at the station, e.g. "Phone volunteer for spring drive"';
COMMENT ON COLUMN public.access_requests.approved_role IS 'The role assigned when admin approves the request (volunteer, ops, admin)';

-- Tell PostgREST to reload schema so it sees the new table
NOTIFY pgrst, 'reload schema';
