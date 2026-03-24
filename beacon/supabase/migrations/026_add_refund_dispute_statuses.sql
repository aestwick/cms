-- Add 'partially_refunded' and 'disputed' to donations status constraint.
-- Needed for charge.refunded and charge.dispute webhook handlers (P1-9, P1-10).

-- Drop the old constraint and recreate with new allowed values.
-- Existing rows are unaffected — they already use values in the new set.
alter table donations
    drop constraint if exists donations_status_check;

alter table donations
    add constraint donations_status_check
    check (status in (
        'pledged',
        'pending',
        'processing',
        'succeeded',
        'failed',
        'refunded',
        'partially_refunded',
        'disputed'
    ));
