# Results

| Data size                  | Read       | Executed commands | Route entities | Trip entities | Logs                                                         |
|----------------------------|------------|------------------:|---------------:|--------------:|--------------------------------------------------------------|
| 4 routes / 9 trips         | Baseline   |                 5 |              4 |             9 | [SQL](logs/20261021T1917541895113Z-baseline-dc7e8848.sql) · [output](logs/20261021T1917541895113Z-baseline-dc7e8848.json)    |
| 4 routes / 9 trips         | Live board |                 1 |              0 |             0 | [SQL](logs/20261021T1914313704401Z-live-23930fb5.sql) · [output](logs/20261021T1914313704401Z-live-23930fb5.json)        |
| 200 routes / 100,000 trips | Baseline   |               201 |            200 |        100000 | [SQL](logs/20261021T1918030864693Z-baseline-198cfc21.sql) · [output](logs/20261021T1918030864693Z-baseline-198cfc21.json)    |
| 200 routes / 100,000 trips | Live board |                 1 |              0 |             0 | [SQL](logs/20261021T1916030491086Z-live-58ba04eb.sql) · [output](logs/20261021T1916030491086Z-live-58ba04eb.json)        |

## Live board output after reset

Window 2026-10-23 06:00 to 07:00 UTC. Baseline and live board return the same rows, which match the contract.

| Route | Name            | Count | Next UTC |
|-------|-----------------|------:|----------|
| R1    | City Loop       |     2 | 06:00    |
| R2    | Campus Line     |     2 | 06:10    |
| R3    | Airport Express |     0 | null     |
| R4    | Harbour Shuttle |     0 | null     |

The 200 route output is in the linked JSON.

Show the cancellation, rename, rejected booking and unchanged snapshot. Link to the output and your tests. Put the
design sketch and a short explanation in `docs/design.md`.