# Results

| Data size                  | Read       | Executed commands | Route entities | Trip entities | SQL log                                                                                                 |
|----------------------------|------------|------------------:|---------------:|--------------:|---------------------------------------------------------------------------------------------------------|
| 4 routes / 9 trips         | Baseline   |                 5 |          R1-R4 |             9 | [labs/lab07-database-design/docs/evidence/lecture07/logs/20261021T1320286555907Z-baseline-ae6d4585.sql] |
| 4 routes / 9 trips         | Live board |                   |                |               |                                                                                                         |
| 200 routes / 100,000 trips | Baseline   |               201 |            200 |        100000 | labs/lab07-database-design/docs/evidence/lecture07/logs/20261021T1324419022761Z-baseline-48974432.sql   |
| 200 routes / 100,000 trips | Live board |                   |                |               |                                                                                                         |

Show the cancellation, rename, rejected booking and unchanged snapshot. Link to the output and your tests. Put the
design sketch and a short explanation in `docs/design.md`.
