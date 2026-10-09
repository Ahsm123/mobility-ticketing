# Compulsory Assignment 1 review guide

Submitted commit: d9e6a785bde6ca16bb8e44c78a13e0822ba14046

Setup and reset instructions: [Setup & Reset](./setup-and-reset.md)

## Where to find the work

### Lecture 1: model, workload map and queries:

- [access-patterns](./model/access-patterns.md)
- [dossier](./model/dossier.md) (assumptions and functional dependency)
- [ERD](./model/diagrams/ERD_2.jpg)
- [001_relational_baseline](../postgres/init/001_relational_baseline.sql)
- [002_seed](../postgres/init/002_seed.sql)
- [003_route_queries](../postgres/queries/003_route_queries.sql)

### Lecture 2: constraints and tests:

- [integrity-map](./model/integrity-map.md)
- [011_ticketing_integrity](../postgres/migrations/011_ticketing_integrity.sql)
- [test_suite](../postgres/tests/test_suite.sql)

### Lecture 3: reporting experiment and comparison:

- [reporting-cases](../labs/lab03-reporting/reporting_cases.sql)
- [lab3-reporting](../labs/lab03-reporting/README.md)
- [base_revenue](../postgres/queries/base_revenue.sql)
- [020_reporting_function](../postgres/migrations/020_reporting_function.sql)
- [021_daily_revenue_trigger](../postgres/migrations/021_daily_revenue_trigger.sql)
- [022_daily_captured_revenue](../postgres/migrations/022_daily_captured_revenue.sql)

### Lecture 4: migration stages and verification:

- [evidence](../labs/lab04-product-migration/README.md)

#### Baseline (evidence 1)

- [baseline](../labs/lab04-product-migration/baseline.sql)
- [baseline_snapshot](../labs/lab04-product-migration/baseline_snapshot_table.sql)

#### Overlap (evidence 2-6)

- [030_expand_product_identity](../postgres/migrations/030_expand_product_identity.sql)
- [product_code_trigger](../labs/lab04-product-migration/product_code_trigger.sql)
- [old_writer](../labs/lab04-product-migration/old_writer_step4.sql)
- [old_reader](../labs/lab04-product-migration/old_reader.sql)
- [new_writer](../labs/lab04-product-migration/new_writer.sql)
- [new_reader](../labs/lab04-product-migration/new_reader.sql)

#### Backfill (evidence 7)

- [031_backfill_ticket_product](../postgres/migrations/031_backfill_ticket_product.sql)

#### Late ticket + checks (evidence 8)

- [old_writer_step8](../labs/lab04-product-migration/old_writer_step8.sql)
- [verify](../labs/lab04-product-migration/verify.sql)

#### Contract (evidence 9-10)

- [032_make_product_id_required_reference](../postgres/migrations/032_make_product_id_required_reference.sql)
- [old_writer_step9](../labs/lab04-product-migration/old_writer_step9.sql) (rejected)
- [033_drop_product_code](../postgres/migrations/033_drop_product_code.sql)
- [drop_product_code_trigger](../labs/lab04-product-migration/drop_product_code_trigger.sql)
- [new_writer_step10](../labs/lab04-product-migration/new_writer_step10.sql)

#### Price and currency (evidence 11)

- [baseline_snapshot](../labs/lab04-product-migration/baseline_snapshot_table.sql)
- [compare_price_and_valuta](../labs/lab04-product-migration/compare_price_and_valuta.sql)

## Two decisions worth discussing

### Reporting

1. **Valg**
   [captured_revenue_for_day(operator_id, date)](../postgres/migrations/020_reporting_function.sql)

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

- [lab3-reporting](../labs/lab03-reporting/README.md)

### Partial Unique index på payments

1. **Valg**

-
`UNIQUE INDEX payments_external_reference_unique ON payments (external_payment_reference) WHERE status IN ('Captured', 'Refunded')`

- [011_ticketing_integrity](../postgres/migrations/011_ticketing_integrity.sql)

2. **Alternativ**

- a. Almindelig UNIQUE på kolonnen.
- b. Ingen constraint, og check i appen.

3. **Hvorfor**

- Hvis en gateway sender betaling to gange, må det ikke kunne give dobbelt revenue.
  En betaling der fejler, skal kunne retries med samme reference, det kan a ikke hvis der er unique på `Failed`

  Alternativ b kan føre til race condition, hvis begge betalingerne forsøger at gøre det concurrent.

4. **Evidens**

- I [lab3-reporting](../labs/lab03-reporting/README.md) state 6, bliver en diplicate Captured
  afvist med 23505.
- [payment_retry](../labs/lab02-payment-retry/payment-retry.sql)

## One limitation or open question

### Ticket validation

- Som det er nu, kan en SINGLE billet godt valideres flere gange. Validations har ikke en constraint
  som forhindrer to accepted rows for samme ticket. Grunden til det ikke løst er, at antal valideringer, afhænger af
  produktet, hvor SINGLE skal valideres én gang, og en DAY billet flere gange. Det er også antaget,
  at i tog, skal en kontrollør kunne validerer on demand, så samme billet kan blive kontrolleret flere gange.
  Hvis vi har en constraint på table niveau, ved jeg ikke lige hvordan den skal kende til både type af produkt
  og transportmiddel.

**Evidens:**

- [integrity-map](./model/integrity-map.md)
- [011_ticketing_integrity](../postgres/migrations/011_ticketing_integrity.sql)
  Der er ikke andre regler på Validations end FK og check på result.

**Next**

- Man kunne gøre så en SINGLE billet, når den valideres, skifter status fra Active til Validated,
  men kun hvis den er Active. Hvis den allerede er validated, sker der ingenting, og så ved vi at den er brugt.
- Hvis man antager at det er korrekt opførsel, at DAY billetten må valideres flere gange, skal man finde ud af,
  om reglen skal være i databasen, eller i den app der validerer billetter.