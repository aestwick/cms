-- Migration 050: Add 'donation_comment' form type to feedback_responses
--
-- When a donor leaves a comment on their donation (web form, phone pledge, etc.),
-- we auto-create a feedback_responses record so staff can see it in the feedback
-- dashboard alongside survey responses. The 'donation_comment' form type distinguishes
-- these auto-created entries from donor-initiated survey responses.

-- Update the CHECK constraint to include the new form type
ALTER TABLE feedback_responses
  DROP CONSTRAINT IF EXISTS feedback_form_type_check;

ALTER TABLE feedback_responses
  ADD CONSTRAINT feedback_form_type_check CHECK (
    form_type IN ('donation_experience', 'fulfillment_satisfaction', 'cancellation', 'general', 'staff', 'donation_comment')
  );

-- Tell PostgREST to reload the schema so it sees the new constraint
NOTIFY pgrst, 'reload schema';
