-- 11: Major Social Platforms Migration (Background Job)
-- This script moves enriched Instagram, YouTube, and TikTok data 
-- from talent_profiles into the social_profiles table.

SELECT cron.schedule(
  'manual-major-socials-migration', 
  '* * * * *', 
  $$
    -- Increase timeout for this worker
    SET statement_timeout = '2h';

    -- 1. Migrate Instagram
    INSERT INTO social_profiles (
      talent_id, social_type, username, name, social_about, 
      social_image, followers_count, following_count, media_count, is_verified, status
    )
    SELECT 
      id, 'Instagram', ig_username, ig_full_name, ig_biography, 
      ig_profile_image, 
      CAST(NULLIF(ig_follower_count, '') AS numeric), 
      CAST(NULLIF(ig_followed_count, '') AS numeric), 
      CAST(NULLIF(ig_media_count, '') AS numeric), 
      ig_verified, 'active'
    FROM talent_profiles 
    WHERE (ig_username IS NOT NULL OR NULLIF(ig_follower_count, '') IS NOT NULL OR ig_profile_image IS NOT NULL)
    ON CONFLICT (talent_id, social_type) DO UPDATE SET
      username = EXCLUDED.username,
      name = EXCLUDED.name,
      social_about = COALESCE(social_profiles.social_about, EXCLUDED.social_about),
      social_image = COALESCE(social_profiles.social_image, EXCLUDED.social_image),
      followers_count = GREATEST(COALESCE(social_profiles.followers_count, 0), COALESCE(EXCLUDED.followers_count, 0)),
      following_count = EXCLUDED.following_count,
      media_count = EXCLUDED.media_count,
      is_verified = EXCLUDED.is_verified;

    -- 2. Migrate YouTube
    INSERT INTO social_profiles (
      talent_id, social_type, username, name, social_id, social_url, 
      social_about, social_image, followers_count, is_verified, status
    )
    SELECT 
      id, 'YouTube', yt_handle, yt_title, yt_id, yt_url, 
      yt_description, yt_avatar, 
      CAST(NULLIF(yt_subscriber_count, '') AS numeric), 
      yt_is_verified, 'active'
    FROM talent_profiles 
    WHERE (yt_id IS NOT NULL OR NULLIF(yt_subscriber_count, '') IS NOT NULL OR yt_handle IS NOT NULL)
    ON CONFLICT (talent_id, social_type) DO UPDATE SET
      username = EXCLUDED.username,
      name = EXCLUDED.name,
      social_id = EXCLUDED.social_id,
      social_url = EXCLUDED.social_url,
      social_about = COALESCE(social_profiles.social_about, EXCLUDED.social_about),
      social_image = COALESCE(social_profiles.social_image, EXCLUDED.social_image),
      followers_count = GREATEST(COALESCE(social_profiles.followers_count, 0), COALESCE(EXCLUDED.followers_count, 0)),
      is_verified = EXCLUDED.is_verified;

    -- 3. Migrate TikTok
    INSERT INTO social_profiles (
      talent_id, social_type, username, name, social_id, 
      social_about, social_image, followers_count, following_count, media_count, is_verified, status
    )
    SELECT 
      id, 'TikTok', tt_username, tt_nickname, tt_id, 
      tt_signature, tt_avatar_larger, 
      CAST(NULLIF(tt_follower_count, '') AS numeric), 
      CAST(NULLIF(tt_following_count, '') AS numeric), 
      CAST(NULLIF(tt_video_count, '') AS numeric), 
      tt_verified, 'active'
    FROM talent_profiles 
    WHERE (tt_id IS NOT NULL OR NULLIF(tt_follower_count, '') IS NOT NULL OR tt_username IS NOT NULL)
    ON CONFLICT (talent_id, social_type) DO UPDATE SET
      username = EXCLUDED.username,
      name = EXCLUDED.name,
      social_id = EXCLUDED.social_id,
      social_about = COALESCE(social_profiles.social_about, EXCLUDED.social_about),
      social_image = COALESCE(social_profiles.social_image, EXCLUDED.social_image),
      followers_count = GREATEST(COALESCE(social_profiles.followers_count, 0), COALESCE(EXCLUDED.followers_count, 0)),
      following_count = EXCLUDED.following_count,
      media_count = EXCLUDED.media_count,
      is_verified = EXCLUDED.is_verified;

    -- Unschedule this job after one execution
    SELECT cron.unschedule('manual-major-socials-migration');
  $$
);

