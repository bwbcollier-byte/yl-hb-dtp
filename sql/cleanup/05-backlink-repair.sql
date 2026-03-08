-- 05: Repair Global social backlinks (Background Job)
-- Repairs all platform foreign keys on talent_profiles from social_profiles rows.

SELECT cron.schedule(
  'manual-backlink-repair', 
  '* * * * *', 
  $$
    UPDATE talent_profiles tp
    SET
      soc_spotify      = COALESCE(tp.soc_spotify,      (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Spotify' LIMIT 1)),
      soc_instagram    = COALESCE(tp.soc_instagram,    (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Instagram' LIMIT 1)),
      soc_tiktok       = COALESCE(tp.soc_tiktok,       (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'TikTok' LIMIT 1)),
      soc_imdb         = COALESCE(tp.soc_imdb,         (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'IMDb' LIMIT 1)),
      soc_facebook     = COALESCE(tp.soc_facebook,     (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Facebook' LIMIT 1)),
      soc_twitter      = COALESCE(tp.soc_twitter,      (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Twitter' LIMIT 1)),
      soc_youtube      = COALESCE(tp.soc_youtube,      (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'YouTube' LIMIT 1)),
      soc_tmdb         = COALESCE(tp.soc_tmdb,         (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'TMDb' LIMIT 1)),
      soc_soundcloud   = COALESCE(tp.soc_soundcloud,   (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'SoundCloud' LIMIT 1)),
      soc_apple_music  = COALESCE(tp.soc_apple_music,  (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Apple Music' LIMIT 1)),
      soc_website      = COALESCE(tp.soc_website,      (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Website' LIMIT 1)),
      soc_deezer       = COALESCE(tp.soc_deezer,       (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Deezer' LIMIT 1)),
      soc_tidal        = COALESCE(tp.soc_tidal,        (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Tidal' LIMIT 1)),
      soc_pandora      = COALESCE(tp.soc_pandora,      (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Pandora' LIMIT 1)),
      soc_discogs      = COALESCE(tp.soc_discogs,      (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Discogs' LIMIT 1)),
      soc_allmusic     = COALESCE(tp.soc_allmusic,     (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'AllMusic' LIMIT 1)),
      soc_bandsintown  = COALESCE(tp.soc_bandsintown,  (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Bandsintown' LIMIT 1)),
      soc_songkick     = COALESCE(tp.soc_songkick,     (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Songkick' LIMIT 1)),
      soc_musicbrainz  = COALESCE(tp.soc_musicbrainz,  (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'MusicBrainz' LIMIT 1)),
      soc_audiodb      = COALESCE(tp.soc_audiodb,      (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'AudioDB' LIMIT 1)),
      soc_chartmetric  = COALESCE(tp.soc_chartmetric,  (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Chartmetric' LIMIT 1)),
      soc_rostr        = COALESCE(tp.soc_rostr,        (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'Rostr' LIMIT 1)),
      soc_imdbpro      = COALESCE(tp.soc_imdbpro,      (SELECT id FROM social_profiles WHERE talent_id = tp.id AND social_type = 'IMDbPro' LIMIT 1));
      
    SELECT cron.unschedule('manual-backlink-repair');
  $$
);
