-- Migration 060: Add `placement` column to feedback_responses
--
-- Makes it easy to filter and report on WHERE in the flow feedback was submitted:
--   during_donation  — comment captured while making the donation
--   post_donation    — success page emoji rating or email link after donating
--   post_fulfillment — email link after gift shipped/delivered
--   post_cancellation — email link after membership cancelled
--   standalone       — general/staff feedback not tied to a specific flow step
--
-- Backfills existing rows based on form_type and metadata.

-- 1. Add the column (nullable first so existing rows aren't blocked)
ALTER TABLE feedback_responses
ADD COLUMN placement TEXT;

-- 2. Backfill existing rows based on form_type and metadata
-- donation_comment = during_donation (comments captured at pledge time)
UPDATE feedback_responses
SET placement = 'during_donation'
WHERE form_type = 'donation_comment';

-- donation_experience = post_donation (success page or email link)
UPDATE feedback_responses
SET placement = 'post_donation'
WHERE form_type = 'donation_experience';

-- fulfillment_satisfaction = post_fulfillment
UPDATE feedback_responses
SET placement = 'post_fulfillment'
WHERE form_type = 'fulfillment_satisfaction';

-- cancellation = post_cancellation
UPDATE feedback_responses
SET placement = 'post_cancellation'
WHERE form_type = 'cancellation';

-- general + staff = standalone
UPDATE feedback_responses
SET placement = 'standalone'
WHERE form_type IN ('general', 'staff');

-- Catch any remaining rows that somehow didn't match
UPDATE feedback_responses
SET placement = 'standalone'
WHERE placement IS NULL;

-- 3. Now set NOT NULL + default so all future rows must have a placement
ALTER TABLE feedback_responses
ALTER COLUMN placement SET NOT NULL,
ALTER COLUMN placement SET DEFAULT 'standalone';

-- 4. Add CHECK constraint for valid values
ALTER TABLE feedback_responses
ADD CONSTRAINT feedback_responses_placement_check
CHECK (placement IN ('during_donation', 'post_donation', 'post_fulfillment', 'post_cancellation', 'standalone'));

-- 5. Index for filtering by placement in the dashboard
CREATE INDEX idx_feedback_responses_placement ON feedback_responses (placement);

-- Notify PostgREST to reload schema so the new column is visible to API queries
NOTIFY pgrst, 'reload schema';
