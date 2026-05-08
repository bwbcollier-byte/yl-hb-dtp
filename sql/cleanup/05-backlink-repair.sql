-- 05: Repair hb_talent Social Backlinks
-- For each platform, fills in the soc_* UUID FK if it's NULL
-- but a matching hb_socials row exists for that talent.

SELECT cron.schedule(
  'manual-backlink-repair',
  '* * * * *',
  $$
    UPDATE hb_talent t
    SET
      soc_spotify     = COALESCE(t.soc_spotify,     (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'spotify'     LIMIT 1)),
      soc_instagram   = COALESCE(t.soc_instagram,   (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'instagram'   LIMIT 1)),
      soc_tiktok      = COALESCE(t.soc_tiktok,      (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'tiktok'      LIMIT 1)),
      soc_imdb        = COALESCE(t.soc_imdb,        (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'imdb'        LIMIT 1)),
      soc_facebook    = COALESCE(t.soc_facebook,    (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'facebook'    LIMIT 1)),
      soc_twitter     = COALESCE(t.soc_twitter,     (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'twitter'     LIMIT 1)),
      soc_youtube     = COALESCE(t.soc_youtube,     (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'youtube'     LIMIT 1)),
      soc_tmdb        = COALESCE(t.soc_tmdb,        (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'tmdb'        LIMIT 1)),
      soc_soundcloud  = COALESCE(t.soc_soundcloud,  (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'soundcloud'  LIMIT 1)),
      soc_allmusic    = COALESCE(t.soc_allmusic,    (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'allmusic'    LIMIT 1)),
      soc_songkick    = COALESCE(t.soc_songkick,    (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'songkick'    LIMIT 1)),
      soc_musicbrainz = COALESCE(t.soc_musicbrainz, (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'musicbrainz' LIMIT 1)),
      soc_chartmetric = COALESCE(t.soc_chartmetric, (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'chartmetric' LIMIT 1)),
      soc_deezer      = COALESCE(t.soc_deezer,      (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'deezer'      LIMIT 1)),
      soc_rostr       = COALESCE(t.soc_rostr,       (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'rostr'       LIMIT 1)),
      soc_viberate    = COALESCE(t.soc_viberate,    (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'viberate'    LIMIT 1)),
      soc_wikidata    = COALESCE(t.soc_wikidata,    (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'wikidata'    LIMIT 1)),
      soc_wikipedia   = COALESCE(t.soc_wikipedia,   (SELECT id FROM hb_socials WHERE linked_talent = t.id AND LOWER(type) = 'wikipedia'   LIMIT 1))
    WHERE t.id IN (
      SELECT DISTINCT linked_talent FROM hb_socials WHERE linked_talent IS NOT NULL
    );
    SELECT cron.unschedule('manual-backlink-repair');
  $$
);
