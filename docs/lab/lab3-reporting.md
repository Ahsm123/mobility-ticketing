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

### Captured insert

1. Check constraint: Not null, FK, Checks, Unique
2. Trigger executor, opdaterer derived view, hvis den fejler
   vil transaktionen rollback og fejle insert.
3. `payments` og `daily_revenue_by_operator` får write lock,
   og resten read lock fra joinet
4. Returnerer 0 / 1 med antal affected rows.
5. Direct query + function + trigger table vil afspejle det med det samme.
6. Materialized view vil være stale indtil det er refreshed.

## Responsibility matrix

| Criteria               | Direct query             | Function                 | Materialized view                        | Trigger table                                                                                           |
|------------------------|--------------------------|--------------------------|------------------------------------------|---------------------------------------------------------------------------------------------------------|
| Correctness            | Always correct           | Always correct           | Stale but correct after refresh          | Real-time on new data<br/> need backfill<br/> ikke korrekt hvis en status går fra captured til refunded |
| Freshness              | Real-time                | Real-time                | Stale on new inserts                     | Fresh on new inserts                                                                                    |
| Write cost             | None                     | None                     | None initially, only on refresh          | Extra write to table                                                                                    |
| Read cost              | Need to read join tables | Need to read join tables | Low: already indexed                     | Low: already indexed                                                                                    |
| Hidden side effects    | None                     | None                     | Blocks other readers from MV             | If payments are refunded data is incorrect, can abort transaction<br/>if write to derived table fails   |
| Rebuildability         | Nothing to rebuild       | Nothing to rebuild       | Needs refresh                            | If deleted needs to fill in the data manually                                                           |
| Operational complexity | Needs to know the query  | Harder to debug          | Can become slow with size, hard to debug | Needs to be maintained if something changes, like an extra status, hard to debug                        |
| Authority              | Payments                 | Payments                 | Payments                                 | Payments                                                                                                |

## Anbefaling

Payments er authority. Vi har egentlig kun brug for query. Funktionen er en wrapped query. MV og trigger er derived
kopier.
Vil anbefale funktionen, fordi det er samme SQL for alle callers/apps, så de bare skal kalde den, istedet for at bygge
selv.
Derved har vi ikke en kopi liggende som kan være stale (MV) eller ikke korrekt (trigger), og vi styrer logikken et
centralt sted.
Funktionen tager operator og data, som passer med access patterns som siger rapport pr. operatør.

Grunden til vi ikke vælger de derived tables lige nu, er fordi read cost ikke er et problem på nuværende tidspunkt.
Trigger tabellen kan som den er lige nu, ikke garantere at data er korrekt og MV kan blive stale.
Forskellen på de to er, at stale kan vi opdage og rette, vi opdager ikke forkert data.

Hvis read cost bliver et problem

- Skift til MV. Reporting er sat til eventual i access pattern så det er ok.
- Authority forbliver payments. Freshness: scheduled refresh + timestamp for sidste kørsel, så læseren kan se alder.
  Rebuild: refresh fra payments.
- Trigger kræver omskrivning først, så den også dækker refunds.
- Refresh må ikke ligge i en trigger på payments, så betaler den der køber en billet for læserens optimering, og en
  refresh der fejler ruller betalingen tilbage.
