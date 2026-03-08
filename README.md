# yl-hb-dtp (Data Talent Profiles)

Database cleanup workflows, normalization scripts, and automated data health management for the Hypebase Talent Profiles database.

## 🏗️ Repository Structure

- `sql/migrations/`: One-time schema changes and constraints.
- `sql/cleanup/`: Idempotent SQL scripts for deduplication and normalization.
- `sql/analytics/`: Monitoring and audit queries.
- `scripts/`: TypeScript/Node.js scripts for complex logic (e.g., fuzzy matching).
- `.github/workflows/`: Automated GitHub Actions for scheduled cleanup.

## 🚀 Getting Started

### 1. Phase 1 — Foundation (Cleanup)

Run these in the Supabase SQL Editor in order:

1. `sql/cleanup/01-slug-generation.sql`
2. `sql/cleanup/02-social-dedup.sql`
3. `sql/migrations/03-unique-constraint.sql`
4. `sql/cleanup/04-spotify-migration.sql`
5. `sql/cleanup/05-backlink-repair.sql`
6. `sql/migrations/06-drop-legacy-columns.sql`

## 🛠️ Roadmap

### Phase 2 — Normalization

- URL standardization
- Username extraction
- Global Social Rank calculation

### Phase 3 — Smart Deduplication

- Fuzzy name matching (Levenshtein)
- Cross-platform ID linking

### Phase 4 — Automation

- Nightly cleanup via GitHub Actions
- Slug generation webhooks

---

## 🏗️ Technical Stack

- **PostgreSQL** (Supabase)
- **TypeScript** / **Node.js**
- **GitHub Actions**
