-- 11: Major Social Platforms Migration (Background Job)
-- This script moves enriched Instagram, YouTube, and TikTok data 
-- from talent_profiles into the social_profiles table.

SELECT cron.schedule(
  'manual-major-socials-migration', 
  '* * * * *', 
  $$
    -- 1. Migrate Instagram
    INSERT INTO social_profiles (
      talent_id, social_type, username, name, social_about, 
      social_image, followers_count, following_count, media_count, is_verified, status
    )
    SELECT 
      id, 'Instagram', ig_username, ig_full_name, ig_biography, 
      ig_profile_image, ig_follower_count, ig_followed_count, ig_media_count, ig_verified, 'active'
    FROM talent_profiles 
    WHERE (ig_username IS NOT NULL OR ig_follower_count > 0 OR ig_profile_image IS NOT NULL)
    ON CONFLICT (talent_id, social_type) DO UPDATE SET
      username = EXCLUDED.username,
      name = EXCLUDED.name,
      social_about = COALESCE(social_profiles.social_about, EXCLUDED.social_about),
      social_image = COALESCE(social_profiles.social_image, EXCLUDED.social_image),
      followers_count = GREATEST(social_profiles.followers_count, EXCLUDED.followers_count),
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
      yt_description, yt_avatar, yt_subscriber_count, yt_is_verified, 'active'
    FROM talent_profiles 
    WHERE (yt_id IS NOT NULL OR yt_subscriber_count > 0 OR yt_handle IS NOT NULL)
    ON CONFLICT (talent_id, social_type) DO UPDATE SET
      username = EXCLUDED.username,
      name = EXCLUDED.name,
      social_id = EXCLUDED.social_id,
      social_url = EXCLUDED.social_url,
      social_about = COALESCE(social_profiles.social_about, EXCLUDED.social_about),
      social_image = COALESCE(social_profiles.social_image, EXCLUDED.social_image),
      followers_count = GREATEST(social_profiles.followers_count, EXCLUDED.followers_count),
      is_verified = EXCLUDED.is_verified;

    -- 3. Migrate TikTok
    INSERT INTO social_profiles (
      talent_id, social_type, username, name, social_id, 
      social_about, social_image, followers_count, following_count, media_count, is_verified, status
    )
    SELECT 
      id, 'TikTok', tt_username, tt_nickname, tt_id, 
      tt_signature, tt_avatar_larger, tt_follower_count, tt_following_count, tt_video_count, tt_verified, 'active'
    FROM talent_profiles 
    WHERE (tt_id IS NOT NULL OR tt_follower_count > 0 OR tt_username IS NOT NULL)
    ON CONFLICT (talent_id, social_type) DO UPDATE SET
      username = EXCLUDED.username,
      name = EXCLUDED.name,
      social_id = EXCLUDED.social_id,
      social_about = COALESCE(social_profiles.social_about, EXCLUDED.social_about),
      social_image = COALESCE(social_profiles.social_image, EXCLUDED.social_image),
      followers_count = GREATEST(social_profiles.followers_count, EXCLUDED.followers_count),
      following_count = EXCLUDED.following_count,
      media_count = EXCLUDED.media_count,
      is_verified = EXCLUDED.is_verified;

    -- Unshedulae this job after one execution
    SELECT cron.unschedule('manual-major-socials-migration');
  $$
);
