-- 02: Targeted Social Profile Deduplication (Chunked)
-- Deletes redundant social profiles while respecting connection pooler timeouts.

CREATE INDEX IF NOT EXISTS idx_sp_talent_social ON social_profiles(talent_id, social_type);

DO $$
DECLARE
  deleted_count INTEGER := 1;
  total_deleted INTEGER := 0;
BEGIN
  -- Loop until no more duplicates are found
  WHILE deleted_count > 0 LOOP
    WITH duplicates AS (
      SELECT id
      FROM (
        SELECT id, ROW_NUMBER() OVER (
          PARTITION BY talent_id, social_type
          ORDER BY followers_count DESC NULLS LAST, updated_at DESC NULLS LAST
        ) as rn
        FROM social_profiles
      ) ranked
      WHERE rn > 1
      LIMIT 10000 -- Delete in smaller chunks so the transaction doesn't take 5 mins
    )
    DELETE FROM social_profiles
    WHERE id IN (SELECT id FROM duplicates);

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    total_deleted := total_deleted + deleted_count;
    
    -- Optional: log progress (visible in pg_stat_activity or console)
    RAISE NOTICE 'Deleted % duplicates so far...', total_deleted;
  END LOOP;
END $$;

