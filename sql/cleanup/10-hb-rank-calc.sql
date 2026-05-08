-- 10: HB Rank Calculation
-- Computes a 0-100 log-scale aggregate rank per talent from total social followers.
-- Written to hb_talent.enrichment_meta->>'hb_rank' (no dedicated column).

SELECT cron.schedule(
  'manual-hb-rank-calculation',
  '* * * * *',
  $$
    WITH talent_metrics AS (
      SELECT
        t.id,
        COALESCE(SUM(hs.followers), 0) AS total_followers,
        COUNT(hs.id) AS platform_count
      FROM hb_talent t
      LEFT JOIN hb_socials hs ON hs.linked_talent = t.id
      GROUP BY t.id
    ),
    global_max AS (
      SELECT MAX(total_followers) AS max_followers FROM talent_metrics
    )
    UPDATE hb_talent
    SET
      enrichment_meta = jsonb_set(
        COALESCE(enrichment_meta, '{}'),
        '{hb_rank}',
        to_jsonb(
          CASE
            WHEN m.total_followers = 0 THEN 0
            ELSE ROUND(CAST(
              (log(m.total_followers + 1) / log(g.max_followers + 1)) * 100
            AS numeric), 2)
          END
        )
      ),
      updated_at = now()
    FROM talent_metrics m, global_max g
    WHERE hb_talent.id = m.id;
    SELECT cron.unschedule('manual-hb-rank-calculation');
  $$
);
