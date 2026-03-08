-- 09: HB Rank and Performance Indexes
-- Adds the Hypebase Rank column and crucial performance indexes to talent_profiles.

-- 1. Add hb_rank column
ALTER TABLE talent_profiles ADD COLUMN IF NOT EXISTS hb_rank NUMERIC DEFAULT 0;

-- 2. Add performance indexes for sorting
CREATE INDEX IF NOT EXISTS idx_talent_created_at ON talent_profiles (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_talent_updated_at ON talent_profiles (updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_talent_hb_rank ON talent_profiles (hb_rank DESC);
