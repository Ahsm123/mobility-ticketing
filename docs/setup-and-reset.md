# Setup and reset

Requirements: Docker Desktop with Compose.

## Start the database

```bash
docker compose up -d
```

Available at `localhost:5432`, database `mobility`, user/password `mobility`.
pgweb runs at `localhost:8080`.

```bash
docker compose down
```

## Reset from scratch

`init/` scripts is run on empty db, so rebuild when you
need to replay them from scratch:

```bash
docker compose down -v
docker compose up -d
```

## Apply migrations

Migrations are not auto run. Apply them one at a time in order:

```bash
docker compose exec -T postgres psql -U mobility -d mobility < database/postgres/migrations/011_ticketing_integrity.sql
```

Order: `011`, `020`, `021`, `022`, `030`, `031`, `032`, `033`.

To replay Lab 4 with the old/new reader and writer scripts between the
migrations, follow the steps in
[evidence.md](../database/postgres/experiments/lab_04/evidence.md) instead.

## Run the tests

Run the integrity test suite after all migrations (011–033). The ticket
tests write `product_id`, which only exists after 030 and is required after 032.

```bash
docker compose exec -T postgres psql -U mobility -d mobility -v ON_ERROR_STOP=1 -f /tests/test_suite.sql
```

Every test prints `ok:`. Any other error means the test failed.

## Project layout

- `database/postgres/init/` - baseline schema and seed data. Runs once
  auto, when Postgres starts and volume is empty.
- `database/postgres/migrations/` - every schema change since the baseline in order.
- `database/postgres/queries/` - reference queries.
- `database/postgres/tests/` - the integrity test suite.
- `database/postgres/experiments/` - per lab scripts and evidence
  (`lab_02/`, `lab_03/`, `lab_04/`).
- `docs/` - `dossier.md` (assumptions, rules, decisions), `integrity-map.md`
  (invariants, issue register), `access-patterns.md` (workload table),
  `lab_descriptions/` (lab briefs), `diagrams/`.

