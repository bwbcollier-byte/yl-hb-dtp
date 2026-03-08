-- 10: HB Rank Calculation
-- Calculates a Hypebase Rank (0-100) for each talent based on their social footprint.
-- Formula: Normalized score based on total aggregate followers across all platforms.

SELECT cron.schedule(
  'manual-hb-rank-calculation',
  '* * * * *',
  $$
    WITH talent_metrics AS (
      SELECT 
        tp.id,
        COALESCE(SUM(sp.followers_count), 0) as total_followers,
        COUNT(sp.id) as platform_count
      FROM talent_profiles tp
      LEFT JOIN social_profiles sp ON sp.talent_id = tp.id
      GROUP BY tp.id
    ),
    global_max AS (
      SELECT MAX(total_followers) as max_followers FROM talent_metrics
    )
    UPDATE talent_profiles
    SET hb_rank = (
      CASE 
        WHEN m.total_followers = 0 THEN 0
        -- Use a log scale so it's not just the top 1% getting a score
        -- Score = (log(total) / log(max)) * 100
        ELSE ROUND(CAST((log(m.total_followers + 1) / log(g.max_followers + 1)) * 100 AS numeric), 2)
      END
    )
    FROM talent_metrics m, global_max g
    WHERE talent_profiles.id = m.id;

    SELECT cron.unschedule('manual-hb-rank-calculation');
  $$
);
