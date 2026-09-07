# Integrity map

| Invariant                                    | Affected tables and columns                                  | Current protection              | Missing protection or limitation        | Expected failure behaviour | Evidence |
|----------------------------------------------|--------------------------------------------------------------|---------------------------------|-----------------------------------------|----------------------------|----------|
| Valuta must be present and correct (iso4217) | products.currency<br/>tickets.currency<br/>payments.currency | NOT NULL,<br/>CHECK (iso regex) | Can not protect against things like XXX | Rejects INSERT/UPDATE      |          |
|                                              |                                                              |                                 |                                         |                            |          |
|                                              |                                                              |                                 |                                         |                            |          |

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

## State-transition trace

### Ticket purchase

1. Needs a user, trip, and product to exist

2. Then we need a ticket

- INSERT INTO tickets
- UPDATE trips SET reserved_seats

3. Then we can insert payment

- INSERT INTO payments
- Payment state: Pending > Authorized > Captured

### Ticket validation

1. 
2.
3.
