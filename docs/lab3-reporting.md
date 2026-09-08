# Lab 3: reporting

Alle tal er for revenue_date 2026-04-29. Celleformat: `OP-BUS beløb/antal | OP-METRO beløb/antal`.
`—` betyder at mekanismen slet ikke har en række for den operator.

| Tilstand                  | Direct query                                                                                                                  | Function            | Materialized view                                         | Trigger table |
|---------------------------|-------------------------------------------------------------------------------------------------------------------------------|---------------------|-----------------------------------------------------------|---------------|
| Baseline                  | 36.00/1 \| 36.00/1                                                                                                            | 36.00/1 \| 36.00/1  | ERROR 55000                                               | 0 rækker      |
| Baseline efter MV refresh | 36.00/1 \| 36.00/1                                                                                                            | 36.00/1 \| 36.00/1  | 36.00/1 \| 36.00/1                                        | 0 rækker      |
| 1 captured insert         | 36.00/1 \| 72.00/2                                                                                                            | 36.00/1 \| 72.00/2  | 36.00/1 \| 36.00/1<br/>efter refresh: 36.00/1 \| 72.00/2  | - \| 36.00/1  |
| 2 failed insert           | 36.00/1 \| 72.00/2                                                                                                            | 36.00/1 \| 72.00/2  | 36.00/1 \| 36.00/1<br/>efter refresh: 36.00/1 \| 72.00/2  | - \| 36.00/1  |
| 3 Failed > Captured       | 36.00/1 \| 108.00/3                                                                                                           | 36.00/1 \| 108.00/3 | 36.00/1 \| 72.00/2<br/>efter refresh: 36.00/1 \| 108.00/3 | - \| 36.00/1  |
| 4 Captured > Refunded     | 36.00/1 \| 72.00/2                                                                                                            | 36.00/1 \| 72.00/2  | 36.00/1 \| 108.00/3<br/>efter refresh: 36.00/1 \| 72.00/2 | - \| 36.00/1  |
| 5 delete                  | 36.00/1 \| 36.00/1                                                                                                            | 36.00/1 \| 36.00/1  | 36.00/1 \| 72.00/2<br/>efter refresh: 36.00/1 \| 36.00/1  | - \| 36.00/1  |
| 6 duplikat external ref   | unique constraint<br/>`23505: ERROR: pq: duplicate key value violates unique constraint "payments_external_reference_unique"` | -                   | -                                                         | -             |

## Noter

- MV oprettes uden data. Første select fejler i stedet for at give nul rækker:
  `ERROR: materialized view "daily_captured_revenue" has not been populated`, SQLSTATE 55000.
  Rapporten er utilgængelig og vil få appen til at crashe.
- Funktionen tager én operator og én dato, så caller skal kende operator-listen og kalde N gange.
  Direct query giver alle operatører i ét resultat.

- Trigger kører ved hvert insert selvom status ikke er captured

- UPDATE fra 'failed' til 'captured' bumpede ikke trigger tabellen, og MV var stadig stale før update.
- Kan være trigger skal være på alle ændringer, og i stedet trigger en refresh på MV?

## Uenighed mellem to mekanismer

MV og trigger er ikke enige, fordi triggeren kun kører på inserts, ikke på seed data.
Da payments er authority, er det MV der er korrekt, og trigger-tabellen der er forkert.

## Side-effect trace

## Responsibility matrix

## Anbefaling
