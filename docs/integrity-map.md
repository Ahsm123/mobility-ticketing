# Integrity map

| Invariant                                    | Affected tables and columns                                  | Current protection              | Missing protection or limitation        | Expected failure behaviour | Evidence |
|----------------------------------------------|--------------------------------------------------------------|---------------------------------|-----------------------------------------|----------------------------| --- |
| Valuta must be present and correct (iso4217) | products.currency<br/>tickets.currency<br/>payments.currency | NOT NULL,<br/>CHECK (iso regex) | Can not protect against things like XXX | Rejects INSERT/UPDATE      |  |
|                                              |                                                              |                                 |                                         |                            |  |
|                                              |                                                              |                                 |                                         |                            |  |

## Issue register

### Issue 1

- Evidence:
- Problem:
- Consequence:
- Specific improvement:
- Open question:

### Issue 2

- Evidence:
- Problem:
- Consequence:
- Specific improvement:
- Open question:

## State-transition trace

### Ticket purchase

1.
2.
3.

### Ticket validation

1.
2.
3.
