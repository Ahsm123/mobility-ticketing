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

### Reporting

1. **Valg**
   [captured_revenue_for_day(operator_id, date)](./database/postgres/migrations/020_reporting_function.sql)

- Funktion: alle kalder det samme, får samme data, og
  læser data direkte fra `payments`, hvilket betyder at alle callers
  bruger samme SQL, og der findes ingen kopi som kan blive stale.

2. **Alternativ**

- Materialized view: billigere reads, men stale indtil refresh. Det er dog ok,
  fordi reporting gerne må være eventual jf. access patterns, så MV vil måske være det
  næste, hvis read cost bliver et problem. Refresh i en trigger på `payments` er dog ikke
  optimalt, for så går read udover write cost, og hvis en refresh fejler, ruller
  det betalingen tilbage.
- Trigger table: data bliver ikke stale ved inserts, men det håndterer ikke at der skiftes
  payment status, så det kan være forkert uden at man opdager det.

3. **Hvorfor**

- `payments` er authority, og funktionen læser direkte fra den.
- Reporting er per operator, og det tager funktionen som parameter.
  MV skulle filtreres på igen eller vedligeholdes per operator.
- Read cost er ikke et problem endnu.

4. **Evidens**

- [lab3-reporting](./database/postgres/experiments/lab_03/lab3-reporting.md)

### Partial Unique index på payments

1. **Valg**

-
`UNIQUE INDEX payments_external_reference_unique ON payments (external_payment_reference) WHERE status IN ('Captured', 'Refunded')`

- [011_ticketing_integrity](./database/postgres/migrations/011_ticketing_integrity.sql)

2. **Alternativ**

- a. Almindelig UNIQUE på kolonnen.
- b. Ingen constraint, og check i appen.

3. **Hvorfor**

- Hvis en gateway sender betaling to gange, må det ikke kunne give dobbelt revenue.
  En betaling der fejler, skal kunne retries med samme reference, det kan a ikke hvis der er unique på `Failed`

  Alternativ b kan føre til race condition, hvis begge betalingerne forsøger at gøre det concurrent.

4. **Evidens**

- I [lab3-reporting](./database/postgres/experiments/lab_03/lab3-reporting.md) state 6, bliver en diplicate Captured
  afvist med 23505.
- [payment_retry](./database/postgres/experiments/lab_02/payment-retry.sql)

## One limitation or open question

### Ticket validation

- Som det er nu, kan en SINGLE billet godt valideres flere gange. Validations har ikke en constraint
  som forhindrer to accepted rows for samme ticket. Grunden til det ikke løst er, at antal valideringer, afhænger af
  produktet, hvor SINGLE skal valideres én gang, og en DAY billet flere gange. Det er også antaget,
  at i tog, skal en kontrollør kunne validerer on demand, så samme billet kan blive kontrolleret flere gange.
  Hvis vi har en constraint på table niveau, ved jeg ikke lige hvordan den skal kende til både type af produkt
  og transportmiddel.

**Evidens:**

- [integrity-map](./docs/integrity-map.md)
- [011_ticketing_integrity](./database/postgres/migrations/011_ticketing_integrity.sql)
  Der er ikke andre regler på Validations end FK og check på result.

**Next**

- Man kunne gøre så en SINGLE billet, når den valideres, skifter status fra Active til Validated,
  men kun hvis den er Active. Hvis den allerede er validated, sker der ingenting, og så ved vi at den er brugt.
- Hvis man antager at det er korrekt opførsel, at DAY billetten må valideres flere gange, skal man finde ud af,
  om reglen skal være i databasen, eller i den app der validerer billetter.