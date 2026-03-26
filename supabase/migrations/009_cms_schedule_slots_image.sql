-- Migration 009: Add image_path to schedule slots
-- Allows special programming slots to have custom artwork

ALTER TABLE cms_schedule_slots
  ADD COLUMN image_path text;
