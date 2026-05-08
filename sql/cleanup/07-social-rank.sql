-- 07: Social Rank Calculation
-- Ranks each hb_socials row within its platform type by follower count.

SELECT cron.schedule(
  'manual-social-rank',
  '* * * * *',
  $$
    UPDATE hb_socials hs
    SET rank = ranked.rn
    FROM (
      SELECT
        id,
        ROW_NUMBER() OVER (
          PARTITION BY LOWER(type)
          ORDER BY followers DESC NULLS LAST
        ) AS rn
      FROM hb_socials
      WHERE followers IS NOT NULL
    ) ranked
    WHERE hs.id = ranked.id;
    SELECT cron.unschedule('manual-social-rank');
  $$
);
