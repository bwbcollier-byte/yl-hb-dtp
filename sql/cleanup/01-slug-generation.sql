-- 01: Bulk Generate Talent Slugs
-- Replaces slow Node.js scripts.
UPDATE talent_profiles
SET slug = LOWER(
    REGEXP_REPLACE(
        REGEXP_REPLACE(TRIM(name), '[^a-zA-Z0-9\s]', '', 'g'),
        '\s+', '-', 'g'
    )
) || '-' || SUBSTRING(id::text, 1, 6)
WHERE slug IS NULL
  AND name IS NOT NULL;
