# Compulsory Assignment 1 review guide

Submitted commit:

Setup and reset instructions: [Setup & Reset](./docs/setup-and-reset.md)

## Where to find the work
### Lecture 1: model, workload map and queries:
- [access-patterns](./docs/access-patterns.md)
- [ERD](./docs/diagrams/ERD_2.jpg)
- [001_relational_baseline](./database/postgres/init/001_relational_baseline.sql)
- [002_seed](./database/postgres/init/002_seed.sql)
- [003_route_queries](./database/postgres/queries/003_route_queries.sql)

### Lecture 2: constraints and tests:
- [integrity-map](./docs/integrity-map.md)
- [011_ticketing_integrity](./database/postgres/migrations/011_ticketing_integrity.sql)
- [test_suite](./database/postgres/tests/test_suite.sql)

### Lecture 3: reporting experiment and comparison:
- [reporting-cases](./database/postgres/experiments/lab_03/reporting_cases.sql)
- [lab3-reporting](./database/postgres/experiments/lab_03/lab3-reporting.md)
- [base_revenue](./database/postgres/queries/base_revenue.sql)
- [020_reporting_function](./database/postgres/migrations/020_reporting_function.sql)
- [021_daily_revenue_trigger](./database/postgres/migrations/021_daily_revenue_trigger.sql)
- [022_daily_captured_revenue](./database/postgres/migrations/022_daily_captured_revenue.sql)

### Lecture 4: migration stages and verification:
- [evidence](./database/postgres/experiments/lab_04/evidence.md)

#### Baseline (evidence 1)
- [baseline](./database/postgres/experiments/lab_04/baseline.sql)
- [baseline_snapshot](./database/postgres/experiments/lab_04/baseline_snapshot_table.sql)

#### Overlap (evidence 2-6)
- [030_expand_product_identity](./database/postgres/migrations/030_expand_product_identity.sql)
- [product_code_trigger](./database/postgres/experiments/lab_04/product_code_trigger.sql)
- [old_writer](./database/postgres/experiments/lab_04/old_writer_step4.sql)
- [old_reader](./database/postgres/experiments/lab_04/old_reader.sql)
- [new_writer](./database/postgres/experiments/lab_04/new_writer.sql)
- [new_reader](./database/postgres/experiments/lab_04/new_reader.sql)

#### Backfill (evidence 7)
- [031_backfill_ticket_product](./database/postgres/migrations/031_backfill_ticket_product.sql)

#### Late ticket + checks (evidence 8)
- [old_writer_step8](./database/postgres/experiments/lab_04/old_writer_step8.sql)
- [verify](./database/postgres/experiments/lab_04/verify.sql)

#### Contract (evidence 9-10)
- [032_make_product_id_required_reference](./database/postgres/migrations/032_make_product_id_required_reference.sql)
- [old_writer_step9](./database/postgres/experiments/lab_04/old_writer_step9.sql) (rejected)
- [033_drop_product_code](./database/postgres/migrations/033_drop_product_code.sql)
- [drop_product_code_trigger](./database/postgres/experiments/lab_04/drop_product_code_trigger.sql)
- [new_writer_step10](./database/postgres/experiments/lab_04/new_writer_step10.sql)

#### Price and currency (evidence 11)
- [baseline_snapshot](./database/postgres/experiments/lab_04/baseline_snapshot_table.sql)
- [compare_price_and_valuta](./database/postgres/experiments/lab_04/compare_price_and_valuta.sql)

## Two decisions worth discussing
For each: What did we choose? What was the alternative?
Why does our choice fit MobilityTicketing? Which file or result supports it?

## One limitation or open question
What does our implementation not guarantee, or what are we still unsure about?
Point to the relevant evidence. State what we would check next.