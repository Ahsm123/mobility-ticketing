# Integrity map

| #  | Invariant                                                                                     | Affected tables and columns                                       | Current protection                                                                                                                                               | Missing protection or limitation                                                                        | Expected failure behaviour                                    | Evidence                                                  |
|----|-----------------------------------------------------------------------------------------------|-------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|---------------------------------------------------------------|-----------------------------------------------------------|
| 1  | Capacity cannot be negative                                                                   | trips.capacity                                                    | NOT NULL,<br/>CHECK `trips_capacity_non_negative` (capacity >= 0)                                                                                                | Vvehicle not modelled yet (issue 2)                                                                     | Rejects INSERT/UPDATE, SQLSTATE 23514 (check_violation)       | test_suite.sql rule 1 (negative)                          |
| 2  | Reserved seats cannot be negative or exceed capacity                                          | trips.reserved_seats<br/>trips.capacity                           | NOT NULL,<br/>CHECK `trips_reserved_seats_within_capacity` (reserved_seats BETWEEN 0 AND capacity)                                                               | Concurrent purchases, needs row lock                                                                    | Rejects INSERT/UPDATE, SQLSTATE 23514                         | test_suite.sql rule 2 (negative + positive)               |
| 3  | Prices and payment amounts cannot be negative                                                 | products.price<br/>tickets.price<br/>payments.amount              | NOT NULL,<br/>CHECK `products_price_not_negative`, `tickets_price_not_negative`, `payments_amount_not_negative` (>= 0)                                           | Cant check amount matches product price (D)                                                             | Rejects INSERT/UPDATE, SQLSTATE 23514                         | test_suite.sql rule 3 (negative + positive, products only |
| 4  | A ticket must reference an existing user, trip and product                                    | tickets.user_id<br/>tickets.trip_id<br/>tickets.product_code      | NOT NULL,<br/>FK `tickets_user_id_fk`, `tickets_trip_id_fk`, `tickets_product_code_fk`, all ON DELETE/UPDATE RESTRICT                                            | Existence only,can sell cancelled trip (D)                                                              | Rejects INSERT/UPDATE, SQLSTATE 23503 (foreign_key_violation) | test_suite.sql rule 4 (negative)                          |
| 5  | A payment must reference an existing ticket                                                   | payments.ticket_id                                                | NOT NULL,<br/>FK `payment_ticket_id_fk` ON DELETE/UPDATE RESTRICT                                                                                                | Ticket owner and payer can be different (D)                                                             | Rejects INSERT/UPDATE, SQLSTATE 23503                         | test_suite.sql rule 5 (negative)                          |
| 6  | A validation must reference an existing ticket, and the code must belong to that ticket       | validations.ticket_id<br/>validations.ticket_code                 | NOT NULL,<br/>composite FK `validations_ticket_id_ticket_code_reference_same_ticket` to tickets(id, ticket_code), backed by UNIQUE `tickets_id_ticket_code_uniq` | No FK on vehicle_id, device_id, tables missing (issue 2)                                                | Rejects INSERT/UPDATE, SQLSTATE 23503                         | test_suite.sql rule 6 (negative)                          |
| 7  | Ticket codes must be unique                                                                   | tickets.ticket_code                                               | NOT NULL,<br/>UNIQUE `tickets_ticket_code_unique`                                                                                                                | No format rule, code generated outside the database                                                     | Rejects INSERT/UPDATE, SQLSTATE 23505 (unique_violation)      | test_suite.sql rule 7 (negative)                          |
| 8  | Ticket validity cant end before it begins                                                     | tickets.valid_from_utc, tickets.valid_to_utc                      | CHECK tickets_valid_period, valid_to_utc > valid_from_utc                                                                                                        | Doesnt check that the period covers the trips departure time (D)                                        | 23514                                                         | No test yet                                               |
| 9  | Status values must come from a set (enums)                                                    | trips.status, tickets.status, payments.status, validations.result | trips_status_allowed, tickets_valid_status, payments_valid_status, validations_valid_result                                                                      | No rule covers transitions: Refunded > Captured is allowed. Adding status required migration.           | 23514                                                         | No test yet                                               |
| 10 | External payments references must not accidentally represent the same payment more than once. | payments.external_payment_reference, payments.status              | payments_external_reference_unique, only 'Captured'/'Refunded'                                                                                                   | Reference with failed status is not unique on purpose, so we can retry                                  | 23505                                                         | No test yet                                               |
| 11 | A users email must be unique                                                                  | users.email                                                       | UNIQUE users_email_unique                                                                                                                                        | Case sensitive                                                                                          | 23505                                                         | No test yet                                               |
| 12 | A used ticket cannot be validated again                                                       | validations.ticket_id, validations.result,   tickets.status       | None                                                                                                                                                             | Depends on the product, SINGLE may be validated once, DAY multiple times. Race between validations. (D) | None, double validation accepted                              | No test yet                                               |
| 13 | Products, tickets and payments must have a valid currency (ISO 4217)                          | products.currency<br/>tickets.currency<br/>payments.currency      | NOT NULL,<br/>CHECK `products_currency_iso4217`, `tickets_currency_iso4217`, `payments_currency_iso4217` (currency ~ '^[A-Z]{3}$')                               | Can not protect against things like non valid currencies, needs a currency table or lib                 | Rejects INSERT/UPDATE, SQLSTATE 23514                         | No test yet                                               |

## Issue register

### Issue 1

- Evidence: 001 baseline: routes:9, stops:16
- Problem: routes and stops references city which are not implemented yet
- Consequence: we cant enforce integrity on names, can have Ålborg or Aalborg
- Specific improvement: implement the city table
- Open question: is city an entity or a label

### Issue 2

- Evidence: 010 ticketing draft: validations:47
- Problem: validations references vehicle id which are not implemented yet
- Consequence: we can have ambigious vehicle names
- Specific improvement: need to map out vehicle
- Open question:

### Issue 3

- Evidence: 011 ticketing integrity:57
- Problem: after altering status and implementing the revenue reporting, the duplicate key didnt catch the refunded case
- Consequence: we can have duplicates of refunded payments, meaning we could refund more than once
- Specific improvement: add 'refunded' to the unique check
- Open question: Solved

### Issue 4

- Evidence: 021 daily revenue trigger
- Problem: Only runs on new inserts, and rolls back the insert if trigger fails.
- Consequence: Data can be incorrect if payment is refunded. Couples database logic to the user flow.
- Specific improvement: If we decide to implement this, we need a backfill mechanism and execute on refund.
- Open question: If this a good idea, since we cant really avoid coupling to the user flow.

## State-transition trace

### Ticket purchase

1. Needs a user, trip, and product to exist

2. Then we need a ticket

- INSERT INTO tickets
- UPDATE trips SET reserved_seats

3. Then we can insert payment

- INSERT INTO payments
- Payment state: Captured

### Ticket validation

1.
2.
3.
