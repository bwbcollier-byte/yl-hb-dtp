-- 07: Global Social Rank Calculation (Background Job)
-- Ranks all artists per platform based on followers_count.

SELECT cron.schedule(
  'manual-social-rank', 
  '* * * * *', 
  $$
    UPDATE social_profiles sp
    SET social_rank = ranked.rn
    FROM (
      SELECT
        id,
        ROW_NUMBER() OVER (
          PARTITION BY social_type
          ORDER BY followers_count DESC NULLS LAST
        ) AS rn
      FROM social_profiles
      WHERE followers_count IS NOT NULL
    ) ranked
    WHERE sp.id = ranked.id;
    
    SELECT cron.unschedule('manual-social-rank');
  $$
);

