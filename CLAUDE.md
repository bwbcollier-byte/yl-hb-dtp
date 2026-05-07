# CLAUDE.md — `yl-hb-dtp` (Data Talent Profiles cleanup)

This file teaches Claude how this repo is laid out and what to be careful of
when editing it. Conventions shared across the `yl-hb-*` fleet live in
[`SCRAPER-CLAUDE-TEMPLATE.md`](../SCRAPER-CLAUDE-TEMPLATE.md) — read both.

## ⚠️ READ FIRST: SCHEMA MISMATCH WITH LIVE DB

**Every SQL file in this repo references `talent_profiles` and
`social_profiles`. Those tables do not exist on the live Supabase project
(`oerfmtjpwrefxuitsphl`).** Live uses `hb_talent` and `hb_socials` (and
sister tables `hb_companies`, `hb_contacts`, `hb_media`, etc.).

That means:

- The `nightly-cleanup.yml` workflow probably *appears* to succeed every
  night — it schedules `pg_cron` jobs and exits — while the cron jobs
  themselves error out on the missing tables and silently log nothing
  visible from the dashboard.
- No deduplication, backlink repair, social-rank, or hb-rank calculation
  has actually been running against the current schema.
- The `migrations/` files (`03-unique-constraint`, `06-drop-legacy-columns`,
  `08-dashboard-stats`, `09-hb-rank-indexes`) likewise target a schema
  that is no longer current.

Before editing anything substantive, decide one of three paths and tell
the user which one to take:

1. **Rewrite to target `hb_talent` / `hb_socials`.** Largest scope, but
   restores the cleanup pipeline. Need to map every legacy column
   (e.g. `talent_profiles.ig_username` → equivalent on `hb_talent` or
   `hb_socials`) before porting.
2. **Retire this repo.** If the cleanup logic has been re-implemented
   inside the enrichment workflows themselves (e.g. via `ON CONFLICT`
   upsert rules), this whole repo is dead weight.
3. **Confirm a separate, older Supabase project still exists** that this
   repo is silently maintaining. Possible but unlikely — none was
   discoverable in the org.

Until that decision is made, treat *every* SQL file here as suspect.
**Don't run them against `oerfmtjpwrefxuitsphl`.**

## What this repo was originally for

A SQL-only data-quality pipeline. Generates slugs, dedups social profile
duplicates by `(talent_id, social_type)`, repairs platform backlinks
on `talent_profiles`, calculates a per-platform `social_rank`, computes
a `hb_rank` (0-100 score from aggregate followers), and migrates legacy
columnar social fields (`ig_*`, `yt_*`, `tt_*`) into normalized rows.

Designed to be invoked nightly via `psql` from a GitHub Action, with
the heavy work delegated to `pg_cron` background jobs to bypass the
connection-pooler statement timeout.

## Stack

**SQL-only** variant: no Node, no TypeScript, no `package.json`.
Workflow uses `postgresql-client` + `psql` against `SUPABASE_DB_URL`.
Heavy jobs run inside `pg_cron` workers (`cron.schedule(...)` then
self-`cron.unschedule(...)` at the end of the body).

## Repo layout

```
sql/
  cleanup/
    01-slug-generation.sql           # bulk slug generation
    02-social-dedup.sql              # pg_cron dedup of (talent_id, social_type)
    04-spotify-migration.sql         # legacy Spotify field migration
    05-backlink-repair.sql           # pg_cron, repairs talent_profiles.soc_* FKs
    07-social-rank.sql               # pg_cron, per-platform rank by followers_count
    10-hb-rank-calc.sql              # pg_cron, calculates hb_rank (0-100)
    11-major-socials-migration.sql   # pg_cron, ig/yt/tt → social_profiles rows
  migrations/
    03-unique-constraint.sql         # uq_social_profiles_talent_type
    06-drop-legacy-columns.sql       # drops sp_*/ig_*/yt_*/tt_* columns
    08-dashboard-stats.sql           # dashboard_stats table + refresh fn + cron
    09-hb-rank-indexes.sql           # hb_rank column + perf indexes

.github/workflows/
  nightly-cleanup.yml                # 02:00 UTC — runs psql -f for each cleanup file

README.md
```

## Supabase auth

> Convention divergence: this repo uses `SUPABASE_DB_URL` (a full
> Postgres connection string), **not** `SUPABASE_SERVICE_KEY`. That's
> because it talks to the DB via `psql`, not the REST API.
>
> The lifecycle notification calls (`log_workflow_run`) still use the
> standard `SUPABASE_URL` + `SUPABASE_SERVICE_KEY` REST endpoint.

In Supabase, copy the connection string from
**Settings → Database → Connection String → URI**, mode **Session**
(port 5432). The transaction-pooler URL (port 6543) **will not work**
for this repo — `pg_cron` calls require a session-mode connection.
The workflow already includes a connection test that prints this hint
on failure ([`nightly-cleanup.yml:38-44`](.github/workflows/nightly-cleanup.yml)).

## Workflow lifecycle convention

Standard fleet pattern — `log_workflow_run` start + `if: always()`
result. The workflow id is **hardcoded** as `243099896`. Most other
fleet workflows use `vars.WORKFLOW_ID_*` instead; this is the
exception.

The workflow runs `cron: '0 2 * * *'` (02:00 UTC nightly) and accepts
manual `workflow_dispatch`. Total of ~6 SQL files invoked sequentially
via `psql`, plus a final dashboard refresh.

## Tables this repo intends to touch (from the SQL files)

> All of these are legacy / non-existent on live. Listed here for
> reference until the rewrite decision is made.

| Legacy table | Operation | Live equivalent (probably) |
|---|---|---|
| `talent_profiles` | UPDATE (slug, hb_rank, soc_*) | `public.hb_talent` |
| `social_profiles` | DELETE / UPDATE / INSERT (dedup, rank, migrate) | `public.hb_socials` |
| `dashboard_stats` | UPDATE (refresh fn) | does not exist on live |

## Running locally

This is SQL-only — no `npm install`. Just `psql` directly:

```bash
psql "$SUPABASE_DB_URL" -f sql/cleanup/02-social-dedup.sql
```

Or run against a local Postgres for testing:

```bash
psql postgres://localhost:5432/postgres -f sql/cleanup/01-slug-generation.sql
```

Required env vars:

```
SUPABASE_DB_URL          # full Postgres URI, session mode (port 5432)
SUPABASE_URL             # for log_workflow_run lifecycle calls
SUPABASE_SERVICE_KEY     # ditto
```

## Per-repo gotchas

- **Schema mismatch (see top of file).** Every SQL file is operating
  against tables that don't exist. Don't propose running any of them
  against production until the rewrite question is answered.
- **`pg_cron` self-unschedule pattern.** Each cleanup script schedules
  itself as a per-minute job, runs once, then calls
  `cron.unschedule('manual-<name>')` at the end of the body. If the
  body errors out (which it will, on missing tables), the unschedule
  never runs and the job sits in the cron table firing every minute.
  Audit `cron.job` on the live DB; you may have stranded jobs from
  past run attempts.
- **Connection pooler will silently break this repo.** `pg_cron` requires
  a direct/session-mode connection, not the PgBouncer transaction-mode
  endpoint. If you see `function cron.schedule does not exist` errors,
  that's the signature.
- **`statement_timeout = '2h'` is set inside several jobs**
  (e.g. [`11-major-socials-migration.sql:11`](sql/cleanup/11-major-socials-migration.sql)).
  Don't lower this — the migrations operate on millions of rows.
- **Workflow id `243099896` is hardcoded** instead of using
  `vars.WORKFLOW_ID_*`. Migrate to a GitHub variable when convenient,
  matching fleet convention.
- **README.md is aspirational, not current.** It still says "Phase 4 —
  Automation: Nightly cleanup via GitHub Actions" as a roadmap item,
  but `.github/workflows/nightly-cleanup.yml` already exists. Update
  the README when the schema rewrite happens.

## Conventions Claude should follow when editing this repo

All the fleet-wide rules from [`SCRAPER-CLAUDE-TEMPLATE.md`](../SCRAPER-CLAUDE-TEMPLATE.md)
apply, with these specifics:

- **Don't propose running any SQL file in this repo against
  `oerfmtjpwrefxuitsphl` until the schema mismatch is resolved.**
  This is the load-bearing rule for this repo.
- **All new cleanup SQL must be idempotent.** Re-running the workflow
  should never duplicate or delete unintended rows.
- **Heavy work goes through `pg_cron` background jobs**, not direct
  `psql` execution — the connection pooler kills long-running queries.
- **When adding a new cleanup, follow the numeric-prefix file
  naming** (`12-`, `13-`, etc.) and add it to the workflow's `psql -f`
  sequence.
- **Migrations (one-time schema changes) go in `sql/migrations/`** with
  a `migrations/NN-description.sql` name.
- **Cleanup scripts (idempotent, repeatable) go in `sql/cleanup/`.**

## Related repos

- All `yl-hb-*` enrichment repos (`yl-hb-am`, `yl-hb-bit`, `yl-hb-dz`,
  `yl-hb-imdb`, `yl-hb-imdbp`, `yl-hb-ml`, `yl-hb-rgm`, `yl-hb-sp`,
  `yl-hb-tadb`, `yl-hb-tmdb`) are this repo's *upstream* — they write
  data that this repo is supposed to clean and rank.
- `hb_app_build` — Next.js app reading the cleaned/ranked data.
