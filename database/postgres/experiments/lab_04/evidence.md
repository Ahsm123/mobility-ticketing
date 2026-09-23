# Lab 4 evidence: product identity migration

## Noter

- `product_code_trigger.sql` køres efter 030. Ellers fejler new_writer på `product_code NOT NULL`.
- Åbent: hvad skal der ske med triggeren efter 033?

## Setup

- Starter fra tom db: `docker compose down -v` og `docker compose up -d`
- Migreringer kørt før baseline: 011, 020, 021, 022
- Scripts i `experiments/` køres via stdin, fordi mappen ikke er mountet:
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

TODO: forklaring, hvad triggeren gør, og hvorfor den køres her.

## 4. old_writer (TICKET-6)

TODO: output fra `select id, product_code, product_id from tickets order by id;`

TODO: forklaring, hvorfor `product_id` er tom for TICKET-6.

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

TODO

## 7. 031 backfill

TODO

## 8. Send ticket fra old_writer, verify, backfill igen, verify

TODO

## 9. 032 og old_writer (skal afvises)

TODO

## 10. 033 drop og triggeren

TODO

## 11. Priser og valuta før/efter

TODO
