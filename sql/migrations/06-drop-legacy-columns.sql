-- 06: Drop Legacy Talent Columns
-- WARNING: Run only after Phase 1 migration is verified.
ALTER TABLE talent_profiles
  DROP COLUMN IF EXISTS sp_about,
  DROP COLUMN IF EXISTS sp_verified,
  DROP COLUMN IF EXISTS sp_type,
  DROP COLUMN IF EXISTS sp_gallery_urls,
  DROP COLUMN IF EXISTS sp_avatar_image_urls,
  DROP COLUMN IF EXISTS sp_image,
  DROP COLUMN IF EXISTS sp_followers,
  DROP COLUMN IF EXISTS sp_listeners,
  DROP COLUMN IF EXISTS sp_popularity,
  DROP COLUMN IF EXISTS sp_rank,
  DROP COLUMN IF EXISTS sp_artist_id,
  DROP COLUMN IF EXISTS sp_genres;
