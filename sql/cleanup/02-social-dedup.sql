-- 02: Targeted Social Profile Deduplication
-- Keeps the record with the most followers (or newest) and deletes redundant ones.
DELETE FROM social_profiles
WHERE id IN (
  SELECT id FROM (
    SELECT
      id,
      ROW_NUMBER() OVER (
        PARTITION BY talent_id, social_type
        ORDER BY followers_count DESC NULLS LAST, updated_at DESC NULLS LAST
      ) AS rn
    FROM social_profiles
  ) ranked
  WHERE rn > 1
);
