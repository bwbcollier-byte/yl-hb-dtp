-- 03: Apply Social Profile Unique Constraint
-- Ensures no future duplicates are created for (talent_id, social_type).
ALTER TABLE social_profiles
ADD CONSTRAINT uq_social_profiles_talent_type
UNIQUE (talent_id, social_type);
