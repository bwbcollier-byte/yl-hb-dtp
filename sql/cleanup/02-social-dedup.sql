-- 02: Targeted Social Profile Deduplication (Background Job)
-- Triggers a pg_cron background job to bypass connection pooler timeouts.

CREATE INDEX IF NOT EXISTS idx_sp_talent_social ON social_profiles(talent_id, social_type);

-- Start a background worker instantly that has NO timeout limit
SELECT cron.schedule(
  'manual-deduplication-run', 
  '* * * * *', 
  $$
    DELETE FROM social_profiles
    WHERE id IN (
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (
          PARTITION BY talent_id, social_type
          ORDER BY followers_count DESC NULLS LAST, updated_at DESC NULLS LAST
        ) as rn
        FROM social_profiles
      ) ranked
      WHERE rn > 1
    );
    -- Delete the job immediately after it starts so it doesn't run again
    SELECT cron.unschedule('manual-deduplication-run');
  $$
);


