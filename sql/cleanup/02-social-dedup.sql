-- 02: Social Profile Deduplication
-- Removes duplicate hb_socials rows per (linked_talent, LOWER(type)).
-- Keeps the row with the highest followers, breaking ties by updated_at DESC.

CREATE INDEX IF NOT EXISTS idx_hb_socials_talent_type ON hb_socials(linked_talent, type);

SELECT cron.schedule(
  'manual-deduplication-run',
  '* * * * *',
  $$
    DELETE FROM hb_socials
    WHERE id IN (
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (
          PARTITION BY linked_talent, LOWER(type)
          ORDER BY followers DESC NULLS LAST, updated_at DESC NULLS LAST
        ) AS rn
        FROM hb_socials
        WHERE linked_talent IS NOT NULL
      ) ranked
      WHERE rn > 1
    );
    SELECT cron.unschedule('manual-deduplication-run');
  $$
);
