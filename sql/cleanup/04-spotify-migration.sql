-- 04: Spotify Legacy Data Migration
-- Migrates data from sp_* columns on talent_profiles to social_profiles.
-- Requires unique constraint on (talent_id, social_type) to use ON CONFLICT.

-- Step 1: Insert Spotify social profiles
INSERT INTO social_profiles (
  talent_id, social_type, name, social_url, social_id,
  social_about, social_image, followers_count, listeners_count,
  spotify_popularity, spotify_genres, is_verified, social_rank, status
)
SELECT
  id                                                              AS talent_id,
  'Spotify'                                                       AS social_type,
  name,
  social_spotify                                                  AS social_url,
  COALESCE(
    sp_artist_id,
    SPLIT_PART(SPLIT_PART(social_spotify, '/artist/', 2), '?', 1)
  )                                                               AS social_id,
  sp_about                                                        AS social_about,
  sp_image                                                        AS social_image,
  sp_followers                                                    AS followers_count,
  sp_listeners                                                    AS listeners_count,
  sp_popularity                                                   AS spotify_popularity,
  sp_genres                                                       AS spotify_genres,
  sp_verified                                                     AS is_verified,
  sp_rank                                                         AS social_rank,
  'active'                                                        AS status
FROM talent_profiles
WHERE (sp_followers IS NOT NULL OR sp_listeners IS NOT NULL OR sp_artist_id IS NOT NULL)
ON CONFLICT (talent_id, social_type) DO UPDATE SET
  followers_count    = COALESCE(EXCLUDED.followers_count,    social_profiles.followers_count),
  listeners_count    = COALESCE(EXCLUDED.listeners_count,    social_profiles.listeners_count),
  social_about       = COALESCE(EXCLUDED.social_about,       social_profiles.social_about),
  social_image       = COALESCE(EXCLUDED.social_image,       social_profiles.social_image),
  spotify_popularity = COALESCE(EXCLUDED.spotify_popularity, social_profiles.spotify_popularity),
  spotify_genres     = COALESCE(EXCLUDED.spotify_genres,     social_profiles.spotify_genres),
  social_id          = COALESCE(EXCLUDED.social_id,          social_profiles.social_id),
  status             = 'active';

-- Step 2: Repair talent_profiles.soc_spotify FKs
UPDATE talent_profiles tp
SET soc_spotify = sp.id
FROM social_profiles sp
WHERE sp.talent_id = tp.id
  AND sp.social_type = 'Spotify'
  AND tp.soc_spotify IS NULL;
