# MobilityTicketing

Coursework project: a PostgreSQL schema for ticket purchase, validation and
reporting, built up lecture by lecture. Each lab strengthens or evolves the
schema — see `docs/lab/` for the briefs and `docs/dossier.md` /
`docs/integrity-map.md` for assumptions, decisions and open issues.

## Start the database

Requirements: Docker Desktop with Compose.

```bash
docker compose up -d
```

Available at `localhost:5432`, database `mobility`, user/password `mobility`.

```bash
docker compose down
```

`init/` scripts only run against an empty data volume, so rebuild when you
need to replay them from scratch:

```bash
docker compose down -v
docker compose up -d
```

## Project layout

- `database/postgres/init/` — baseline schema and seed data. Runs once,
  automatically, when Postgres starts against an empty volume.
- `database/postgres/migrations/` — every schema change since the baseline,
  numbered in order. **Not** auto-run - apply one at a time, so you can
  inspect the effect of each step before moving to the next.
- `database/postgres/queries/`, `database/postgres/tests/` - reference
  queries and the integrity test suite.
- `database/postgres/experiments/` - per-lab scratch queries and captured
  evidence (`lab_03/`, `lab_04/`).
- `docs/` - `dossier.md` (assumptions), `integrity-map.md` (invariants,
  decision log, issue register), `access-patterns.md` (workload table),
  `lab/` (lab briefs and reporting evidence), `diagrams/`.

## Applying a migration

```bash
docker compose exec -T postgres psql -U mobility -d mobility < database/postgres/migrations/030_expand_product_identity.sql
```

Run them in numeric order, one command at a time, checking state (e.g. via
pgweb at `localhost:8080`) between each before applying the next.
