-- ============================================================
-- Dashboard Stats: Table + Refresh Function + pg_cron Schedule
-- Run this entire block in the Supabase SQL Editor
-- ============================================================

-- 1. Create the table
CREATE TABLE IF NOT EXISTS dashboard_stats (
  id                      INT PRIMARY KEY DEFAULT 1,

  -- Talent Profiles
  tp_total                INT DEFAULT 0,
  tp_with_slug            INT DEFAULT 0,
  tp_music                INT DEFAULT 0,
  tp_film                 INT DEFAULT 0,
  tp_sport                INT DEFAULT 0,
  tp_enriched_spotify     INT DEFAULT 0,
  tp_enriched_musicbrainz INT DEFAULT 0,
  tp_enriched_audiodb     INT DEFAULT 0,
  tp_enriched_tmdb        INT DEFAULT 0,
  tp_enriched_rovi        INT DEFAULT 0,
  tp_enriched_musicfetch  INT DEFAULT 0,
  tp_with_image           INT DEFAULT 0,
  tp_with_bio             INT DEFAULT 0,
  tp_updated_24h          INT DEFAULT 0,

  -- Social Profiles
  sp_total                INT DEFAULT 0,
  sp_spotify              INT DEFAULT 0,
  sp_instagram            INT DEFAULT 0,
  sp_facebook             INT DEFAULT 0,
  sp_twitter              INT DEFAULT 0,
  sp_youtube              INT DEFAULT 0,
  sp_tiktok               INT DEFAULT 0,
  sp_soundcloud           INT DEFAULT 0,
  sp_apple_music          INT DEFAULT 0,
  sp_musicbrainz          INT DEFAULT 0,
  sp_chartmetric          INT DEFAULT 0,
  sp_deezer               INT DEFAULT 0,
  sp_tmdb                 INT DEFAULT 0,
  sp_audiodb              INT DEFAULT 0,
  sp_orphaned             INT DEFAULT 0,
  sp_total_followers      BIGINT DEFAULT 0,

  -- Media Profiles
  mp_total                INT DEFAULT 0,
  mp_albums               INT DEFAULT 0,
  mp_singles              INT DEFAULT 0,
  mp_compilations         INT DEFAULT 0,
  mp_movies               INT DEFAULT 0,
  mp_tv                   INT DEFAULT 0,

  -- Other
  users_total             INT DEFAULT 0,
  events_total            INT DEFAULT 0,
  crm_companies_total     INT DEFAULT 0,
  crm_contacts_total      INT DEFAULT 0,
  venues_total            INT DEFAULT 0,
  workflows_total         INT DEFAULT 0,
  workflows_active        INT DEFAULT 0,

  -- Meta
  last_refreshed_at       TIMESTAMPTZ DEFAULT now()
);

-- Insert the single row
INSERT INTO dashboard_stats (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- 2. Create the refresh function
CREATE OR REPLACE FUNCTION refresh_dashboard_stats()
RETURNS void AS $$
BEGIN
  UPDATE dashboard_stats SET
    -- Talent Profiles
    tp_total                = (SELECT count(*) FROM talent_profiles),
    tp_with_slug            = (SELECT count(*) FROM talent_profiles WHERE slug IS NOT NULL),
    tp_music                = (SELECT count(*) FROM talent_profiles WHERE talent_type @> ARRAY['Music']),
    tp_film                 = (SELECT count(*) FROM talent_profiles WHERE talent_type @> ARRAY['Film']),
    tp_sport                = (SELECT count(*) FROM talent_profiles WHERE talent_type @> ARRAY['Sport']),
    tp_enriched_spotify     = (SELECT count(*) FROM talent_profiles WHERE soc_spotify IS NOT NULL OR sp_artist_id IS NOT NULL),
    tp_enriched_musicbrainz = (SELECT count(*) FROM talent_profiles WHERE mb_check IS NOT NULL),
    tp_enriched_audiodb     = (SELECT count(*) FROM talent_profiles WHERE adb_check IS NOT NULL),
    tp_enriched_tmdb        = (SELECT count(*) FROM talent_profiles WHERE tmdb_check IS NOT NULL),
    tp_enriched_rovi        = (SELECT count(*) FROM talent_profiles WHERE rovi_check IS NOT NULL),
    tp_enriched_musicfetch  = (SELECT count(*) FROM talent_profiles WHERE mf_check IS NOT NULL),
    tp_with_image           = (SELECT count(*) FROM talent_profiles WHERE profile_image IS NOT NULL),
    tp_with_bio             = (SELECT count(*) FROM talent_profiles WHERE description IS NOT NULL),
    tp_updated_24h          = (SELECT count(*) FROM talent_profiles WHERE updated_at > now() - interval '24 hours'),

    -- Social Profiles
    sp_total                = (SELECT count(*) FROM social_profiles),
    sp_spotify              = (SELECT count(*) FROM social_profiles WHERE social_type = 'Spotify'),
    sp_instagram            = (SELECT count(*) FROM social_profiles WHERE social_type = 'Instagram'),
    sp_facebook             = (SELECT count(*) FROM social_profiles WHERE social_type = 'Facebook'),
    sp_twitter              = (SELECT count(*) FROM social_profiles WHERE social_type = 'Twitter'),
    sp_youtube              = (SELECT count(*) FROM social_profiles WHERE social_type = 'YouTube'),
    sp_tiktok               = (SELECT count(*) FROM social_profiles WHERE social_type = 'TikTok'),
    sp_soundcloud           = (SELECT count(*) FROM social_profiles WHERE social_type = 'SoundCloud'),
    sp_apple_music          = (SELECT count(*) FROM social_profiles WHERE social_type = 'Apple Music'),
    sp_musicbrainz          = (SELECT count(*) FROM social_profiles WHERE social_type = 'MusicBrainz'),
    sp_chartmetric          = (SELECT count(*) FROM social_profiles WHERE social_type = 'Chartmetric'),
    sp_deezer               = (SELECT count(*) FROM social_profiles WHERE social_type = 'Deezer'),
    sp_tmdb                 = (SELECT count(*) FROM social_profiles WHERE social_type = 'TMDB'),
    sp_audiodb              = (SELECT count(*) FROM social_profiles WHERE social_type = 'AudioDB'),
    sp_orphaned             = (SELECT count(*) FROM social_profiles WHERE talent_id IS NULL),
    sp_total_followers      = (SELECT COALESCE(SUM(followers_count), 0) FROM social_profiles),

    -- Media Profiles
    mp_total                = (SELECT count(*) FROM media_profiles),
    mp_albums               = (SELECT count(*) FROM media_profiles WHERE spotify_type = 'album'),
    mp_singles              = (SELECT count(*) FROM media_profiles WHERE spotify_type = 'single'),
    mp_compilations         = (SELECT count(*) FROM media_profiles WHERE spotify_type = 'compilation'),
    mp_movies               = (SELECT count(*) FROM media_profiles WHERE tmdb_media_type = 'movie'),
    mp_tv                   = (SELECT count(*) FROM media_profiles WHERE tmdb_media_type = 'tv'),

    -- Other
    users_total             = (SELECT count(*) FROM users),
    events_total            = (SELECT count(*) FROM event_profiles),
    crm_companies_total     = (SELECT count(*) FROM crm_companies),
    crm_contacts_total      = (SELECT count(*) FROM crm_contacts),
    venues_total            = (SELECT count(*) FROM venue_profiles),
    workflows_total         = (SELECT count(*) FROM workflows),
    workflows_active        = (SELECT count(*) FROM workflows WHERE status = 'active'),

    -- Meta
    last_refreshed_at       = now()
  WHERE id = 1;
END;
$$ LANGUAGE plpgsql;

-- 3. Run it once to populate
SELECT refresh_dashboard_stats();

-- 4. Schedule with pg_cron (every 6 hours)
SELECT cron.schedule(
  'refresh-dashboard-stats',
  '0 */6 * * *',
  $$ SELECT refresh_dashboard_stats(); $$
);
