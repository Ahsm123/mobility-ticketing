# Lab 4 evidence: product identity migration

## Noter

- `product_code_trigger.sql` køres efter 030. Ellers fejler new_writer på `product_code NOT NULL`.

## Setup

- Starter fra tom db: `docker compose down -v` og `docker compose up -d`
- Migreringer kørt før baseline: 011, 020, 021, 022
- Scripts i `experiments/` køres med:
  `docker compose exec -T postgres psql -U mobility -d mobility < database/postgres/experiments/lab_04/<fil>.sql`

## 1. Baseline

```
 current_database
------------------
 mobility
(1 row)

    id    | product_code | price | currency
----------+--------------+-------+----------
 TICKET-1 | SINGLE       | 36.00 | DKK
 TICKET-2 | SINGLE       | 36.00 | DKK
 TICKET-3 | DAY          | 80.00 | DKK
(3 rows)

 id | product_code
----+--------------
(0 rows)

DO
```

- `(0 rows)` betyder at alle tickets har et gyldigt produkt.
- `DO` tjekker at der er minimum 3 tickets med 2 produkter, og ingen uden produkt.

## 2. 030 expand

```
    id    | product_code | product_id
----------+--------------+------------
 TICKET-1 | SINGLE       |
 TICKET-2 | SINGLE       |
 TICKET-3 | DAY          |
(3 rows)
```

- Tilføjer `product_id`, har ikke rørt `product_code` endnu.
- `product_id` er null og skal backfilles.

## 3. product_code_trigger

Sætter `product_code` ved nye inserts når `product_id` er sat.
Uden trigger ville new_writer fejle, fordi den ikke indsætter `product_code`,
hvilket ville throw fordi den stadig er NOT NULL.

Den kan ikke køres før 030, fordi `product_id` ikke findes endnu.

## 4. old_writer_step4.sql (TICKET-6)

output fra: ``select id, product_code, product_id from tickets order by id;``

- id - product_code - product_id
- TICKET-1 - SINGLE - NULL
- TICKET-2 - SINGLE - NULL
- TICKET-3 - DAY - NULL
- TICKET-6 - SINGLE - NULL

`product_id` er stadig null, fordi betingelsen for at triggeren kører, er at `product_id`
bliver sat ind, og derved sætter `product_code` ud fra id.

## 5. old_reader

```
    id    | user_id |        trip_id        | ticket_code  |  status   | product_code |     valid_from_utc     |      valid_to_utc      | price | currency | product_id
----------+---------+-----------------------+--------------+-----------+--------------+------------------------+------------------------+-------+----------+------------
 TICKET-1 | USER-1  | TRIP-M2-20260429-0800 | CODE-M2-0001 | Active    | SINGLE       | 2026-04-29 07:45:00+00 | 2026-04-29 10:00:00+00 | 36.00 | DKK      |
 TICKET-2 | USER-2  | TRIP-5C-20260429-0900 | CODE-5C-0001 | Validated | SINGLE       | 2026-04-29 08:45:00+00 | 2026-04-29 11:00:00+00 | 36.00 | DKK      |
 TICKET-6 | USER-1  | TRIP-M2-20260429-0800 | CODE-M2-0003 | Active    | SINGLE       | 2026-04-29 07:45:00+00 | 2026-04-29 10:00:00+00 | 36.00 | DKK      |
(3 rows)
```

- old_reader virker stadig efter 030, men `product_id` er tom ligesom de gamle tickets.

## 6. new_writer (TICKET-7) og new_reader

output fra: ``select id, product_code, product_id from tickets order by id;``

- id - product_code - product_id
- TICKET-1 - SINGLE - NULL
- TICKET-2 - SINGLE - NULL
- TICKET-3 - DAY - NULL
- TICKET-6 - SINGLE - NULL
- TICKET-7 - SINGLE - d361ee71-126e-479b-8760-ecff30faf420

Trigger virker nu, fordi vi indsætter `product_id`
og `product_code` indsættes automatisk.

output fra new_reader:

```
    id    |         resolved_product_id          | price | currency 

----------+--------------------------------------+-------+----------
TICKET-1 | d361ee71-126e-479b-8760-ecff30faf420 | 36.00 | DKK
TICKET-2 | d361ee71-126e-479b-8760-ecff30faf420 | 36.00 | DKK
TICKET-3 | 2b9ff9b6-0f7a-413f-ad74-7a0db3231613 | 80.00 | DKK
TICKET-6 | d361ee71-126e-479b-8760-ecff30faf420 | 36.00 | DKK
TICKET-7 | d361ee71-126e-479b-8760-ecff30faf420 | 36.00 | DKK
(5 rows)
```

Finder `product_id` ud fra `product_code`, hvis der ikke er et id.
Det betyder at vi kan bruge new_reader efter 030 er kørt, så `product_id` kolonnen eksisterer.
Men new_reader virker også før data er backfilled, fordi den har to conditions,
hvis id ikke er null, bruges det, ellers joiner vi på code.

## 7. 031 backfill

output fra: ``select id, product_code, product_id from tickets order by id;``

- id - product_code - product_id
- TICKET-1 - SINGLE - d361ee71-126e-479b-8760-ecff30faf420
- TICKET-2 - SINGLE - d361ee71-126e-479b-8760-ecff30faf420
- TICKET-3 - DAY - 2b9ff9b6-0f7a-413f-ad74-7a0db3231613
- TICKET-6 - SINGLE - d361ee71-126e-479b-8760-ecff30faf420
- TICKET-7 - SINGLE - d361ee71-126e-479b-8760-ecff30faf420

Efter backfill finder new_reader `product_id` ud fra p_new condition
i stedet for p_old, fordi `product_id` er sat.

## 8. Send ticket fra old_writer_step8.sql, verify, backfill igen, verify

Kør old_writer_step8.sql:
output fra `select id, product_code, product_id from tickets order by id;`

- TICKET-8 - SINGLE - NULL

Den nye række får ikke sat product_id.

Kør verify.sql:
Finder alle rows hvor
`tickets.product_id` er NULL,
`product.id` som en ticket refererer er NULL = produktet findes ikke.
`tickets.product_code` ikke matcher `products.code`

```
    id    | product_code | product_id 
----------+--------------+------------
 TICKET-8 | SINGLE       | 
(1 row)
```

Output er ticket fra old_writer_step8.sql, fordi product_id er NULL

Kør backfill og verify igen:
Output fra 031_backfill:
`UPDATE 1`

Rammer kun TICKET-8 (1 row) fordi de andre har `product_id`:
`where t.product_id is null`

Kør backfill igen:
Output fra 031_backfill:
`UPDATE 0`

Output fra verify.sql:

```
 id | product_code | product_id 
----+--------------+------------
(0 rows)
```

Output fra `select id, product_code, product_id from tickets where id = 'TICKET-8'`:

```
- TICKET-8 - SINGLE - d361ee71-126e-479b-8760-ecff30faf420
```

`product_id` på TICKET-8 er opdateret.

## 9. 032 og old_writer (skal afvises)

Output fra 032:

```
BEGIN
SET
ALTER TABLE
ALTER TABLE
COMMIT
```

Her bliver `t.product_id` altered til not null, hvilket vil få
old_writer til at fejle.

Output old_writer_step9.sql:

```
ERROR:  null value in column "product_id" of relation "tickets" violates not-null constraint
DETAIL:  Failing row contains (TICKET-9, USER-1, TRIP-M2-20260429-0800, CODE-M2-0006, Active, SINGLE, 2026-04-29 07:45:00+00, 2026-04-29 10:00:00+00, 36.00, DKK, null).
```

Trigger virker kun fra id til code.

## 10. 033 drop og triggeren

Output fra 033:

```
ALTER TABLE
```

Fjerner `product_code`, men trigger sætter stadig NEW.product_code, og new_writer
kommer derfor til at fejle, fordi `product_code` ikke eksisterer mere.

Output fra new_writer_step10.sql:

```
ERROR:  record "new" has no field "product_code"
CONTEXT:  PL/pgSQL assignment "NEW.product_code := (SELECT code FROM products WHERE id = NEW.product_id)"
PL/pgSQL function add_product_code() line 5 at assignment
```

Vi kan ikke droppe trigger før 033, for der findes `product_code` stadig og er NOT NULL,
hvis vi først dropper trigger efter 033, vil der være et vindue, hvor new_writer fejler.
Derfor burde trigger fjernes i samme transaktion som 033.

Dropper funktionen `add_product_code()`, det sletter også trigger. Hvis vi kun droppede trigger,
ville funktionen stadig eksisterer.

Kør: `drop_product_code_trigger.sql`

Output fra new_writer_step10.sql efter drop:

```
INSERT 0 1
```

Output fra: `select id, product_id from tickets where id = 'TICKET-10'`

```
- TICKET-10 - d361ee71-126e-479b-8760-ecff30faf420
```

## 11. Priser og valuta før/efter

TODO
