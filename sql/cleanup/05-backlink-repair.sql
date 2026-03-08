-- 05: Repair Global social backlinks
-- Repairs all platform foreign keys on talent_profiles from social_profiles rows.
UPDATE talent_profiles tp
SET
  soc_instagram    = COALESCE(tp.soc_instagram,    (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Instagram' LIMIT 1)),
  soc_tiktok       = COALESCE(tp.soc_tiktok,       (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'TikTok' LIMIT 1)),
  soc_youtube      = COALESCE(tp.soc_youtube,      (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'YouTube' LIMIT 1)),
  soc_twitter      = COALESCE(tp.soc_twitter,      (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Twitter' LIMIT 1)),
  soc_facebook     = COALESCE(tp.soc_facebook,     (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Facebook' LIMIT 1)),
  soc_soundcloud   = COALESCE(tp.soc_soundcloud,   (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'SoundCloud' LIMIT 1)),
  soc_apple_music  = COALESCE(tp.soc_apple_music,  (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Apple Music' LIMIT 1)),
  soc_spotify      = COALESCE(tp.soc_spotify,      (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Spotify' LIMIT 1));
