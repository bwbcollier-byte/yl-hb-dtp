# CLAUDE.md — `yl-hb-dtp` (Data Talent Profiles cleanup)

This file teaches Claude how this repo is laid out and what to be careful of
when editing it. Conventions shared across the `yl-hb-*` fleet live in
[`SCRAPER-CLAUDE-TEMPLATE.md`](../SCRAPER-CLAUDE-TEMPLATE.md) — read both.

## Status — rewritten May 2026, targeting live schema

All `sql/cleanup/` files have been rewritten to target `hb_talent` and
`hb_socials`. The pipeline is active and safe to run against
`oerfmtjpwrefxuitsphl`.

Three legacy migration scripts (01, 04, 11) have been retired — the inline
columns they migrated (`sp_*`, `ig_*`, `yt_*`, `tt_*`) never existed on
`hb_talent`; those enrichers always wrote directly to `hb_socials`.

The `sql/migrations/` files (`03`, `06`, `08`, `09`) still target the old
schema and should **not** be run against production — they are kept for
historical reference only.

## What this repo does

A SQL-only nightly data-quality pipeline. Runs at 02:00 UTC via GitHub
Actions, invoking each cleanup script via `psql`. Heavy work runs inside
`pg_cron` background jobs to bypass the connection-pooler statement timeout.

| Script | What it does | Status |
|---|---|---|
| `01-slug-generation.sql` | ~~Slug generation~~ | **Retired** — no slug column on hb_talent |
| `02-social-dedup.sql` | Dedup hb_socials by `(linked_talent, LOWER(type))`, keep highest-followers row | ✅ Active |
| `04-spotify-migration.sql` | ~~Legacy sp_* migration~~ | **Retired** — columns never existed |
| `05-backlink-repair.sql` | Fill null `soc_*` UUID FKs on hb_talent from hb_socials | ✅ Active |
| `07-social-rank.sql` | Rank hb_socials rows per platform type by follower count | ✅ Active |
| `10-hb-rank-calc.sql` | Compute 0-100 log-scale aggregate rank, written to `hb_talent.enrichment_meta->hb_rank` | ✅ Active |
| `11-major-socials-migration.sql` | ~~Legacy ig_*/yt_*/tt_* migration~~ | **Retired** — columns never existed |

## Stack

**SQL-only** — no Node, no TypeScript, no `package.json`.
Workflow uses `postgresql-client` + `psql` against `SUPABASE_DB_URL`.
Heavy jobs run inside `pg_cron` workers (`cron.schedule(...)` then
self-`cron.unschedule(...)` at the end of the body).

## Repo layout

```
sql/
  cleanup/
    01-slug-generation.sql           # RETIRED — comment only
    02-social-dedup.sql              # pg_cron dedup hb_socials by (linked_talent, LOWER(type))
    04-spotify-migration.sql         # RETIRED — comment only
    05-backlink-repair.sql           # pg_cron, repairs hb_talent.soc_* FKs
    07-social-rank.sql               # pg_cron, per-platform rank by followers
    10-hb-rank-calc.sql              # pg_cron, writes hb_rank to enrichment_meta
    11-major-socials-migration.sql   # RETIRED — comment only
  migrations/
    03-unique-constraint.sql         # ⚠️ legacy schema — do not run
    06-drop-legacy-columns.sql       # ⚠️ legacy schema — do not run
    08-dashboard-stats.sql           # ⚠️ legacy schema — do not run
    09-hb-rank-indexes.sql           # ⚠️ legacy schema — do not run

.github/workflows/
  nightly-cleanup.yml                # 02:00 UTC — runs psql -f for each active cleanup file
```

## Supabase auth

> Convention divergence: this repo uses `SUPABASE_DB_URL` (a full
> Postgres connection string), **not** `SUPABASE_SERVICE_KEY`. That's
> because it talks to the DB via `psql`, not the REST API.
>
> The lifecycle notification calls (`log_workflow_run`) still use the
> standard `SUPABASE_URL` + `SUPABASE_SERVICE_KEY` REST endpoint.

Copy the connection string from **Settings → Database → Connection String →
URI**, mode **Session** (port 5432). The transaction-pooler URL (port 6543)
**will not work** — `pg_cron` calls require a session-mode connection.

## Workflow lifecycle convention

Standard fleet pattern — `log_workflow_run` start + `if: always()` result.
Workflow ID is **hardcoded** as `243099896` (exception to the fleet's
`vars.WORKFLOW_ID_*` convention — migrate when convenient).

Runs `cron: '0 2 * * *'` (02:00 UTC nightly) plus `workflow_dispatch`.

## Tables touched

| Table | Operation |
|---|---|
| `hb_socials` | DELETE (dedup), UPDATE (rank) |
| `hb_talent` | UPDATE (soc_* FKs, enrichment_meta->hb_rank) |

## Running locally

```bash
psql "$SUPABASE_DB_URL" -f sql/cleanup/02-social-dedup.sql
psql "$SUPABASE_DB_URL" -f sql/cleanup/05-backlink-repair.sql
psql "$SUPABASE_DB_URL" -f sql/cleanup/07-social-rank.sql
psql "$SUPABASE_DB_URL" -f sql/cleanup/10-hb-rank-calc.sql
```

Required env vars:
```
SUPABASE_DB_URL          # full Postgres URI, session mode port 5432
SUPABASE_URL             # for log_workflow_run lifecycle calls
SUPABASE_SERVICE_KEY     # ditto
```

## Per-repo gotchas

- **`pg_cron` self-unschedule pattern.** Each script schedules itself as a
  per-minute job, runs once, then calls `cron.unschedule(...)` at the end.
  If the body errors, the unschedule never fires — audit `cron.job` on the
  live DB if you suspect stranded jobs.
- **Connection pooler will silently break this repo.** `pg_cron` requires
  direct/session-mode, not PgBouncer transaction-mode. If you see
  `function cron.schedule does not exist`, that's the signature.
- **hb_socials.type is mixed case** (`SPOTIFY` and `spotify` both exist).
  All cleanup scripts use `LOWER(type)` for comparisons — maintain this.
- **hb_rank lives in enrichment_meta JSONB**, not a dedicated column.
  Access it as `enrichment_meta->>'hb_rank'` or `(enrichment_meta->>'hb_rank')::numeric`.
- **migrations/ files are legacy** — do not run them against production.
  They target `talent_profiles`/`social_profiles` which don't exist on live.

## Conventions Claude should follow when editing this repo

- **All cleanup SQL must be idempotent.** Re-running should never duplicate
  or delete unintended rows.
- **Heavy work goes through `pg_cron` background jobs** — the connection
  pooler kills long-running direct queries.
- **New cleanup scripts** follow numeric-prefix naming (`12-`, `13-`, etc.)
  and must be added to the workflow's `psql -f` sequence.
- **Always use `LOWER(type)`** when matching on `hb_socials.type`.
- **Migrations go in `sql/migrations/`** — cleanup scripts in `sql/cleanup/`.

## Related repos

- All `yl-hb-*` enrichment repos are upstream — they write data this repo
  cleans and ranks.
- `hb_app_build` — Next.js app reading the cleaned/ranked data.
