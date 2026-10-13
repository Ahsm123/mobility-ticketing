# Lab 06: Redis

## 2. Choose a cache key

### 2.1 Store the morning search under an incomplete key

Search without cache, 2/10 06:00–07:00:

```
[{"cityId":"CPH","routeId":"LINE-M2","fromStopId":"STOP-NORREPORT","toStopId":"STOP-AIRPORT","price":{"$numberDecimal":"36.00"},"currency":"DKK","tripId":"LAB05-T-OK","departureUtc":"2026-10-02T06:20:00.000Z","arrivalUtc":"2026-10-02T06:40:00.000Z","availableSeats":10}]
```

Stored in Redis with a 5 min TTL:

```
127.0.0.1:6379> SET search:LAB06:CPH:STOP-NORREPORT:STOP-AIRPORT '[{"cityId":"CPH","routeId":"LINE-M2","fromStopId":"STOP-NORREPORT","toStopId":"STOP-AIRPORT","price":{"$numberDecimal":"36.00"},"currency":"DKK","tripId":"LAB05-T-OK","departureUtc":"2026-10-02T06:20:00.000Z","arrivalUtc":"2026-10-02T06:40:00.000Z","availableSeats":10}]' EX 300
OK
127.0.0.1:6379> TTL search:LAB06:CPH:STOP-NORREPORT:STOP-AIRPORT
(integer) 271
```

### 2.2 Evening search without cache

2/10 18:00–19:00:

```
[]
```

### 2.3 Get the value under the incomplete key

```
127.0.0.1:6379> GET search:LAB06:CPH:STOP-NORREPORT:STOP-AIRPORT
"[{\"cityId\":\"CPH\",\"routeId\":\"LINE-M2\",\"fromStopId\":\"STOP-NORREPORT\",\"toStopId\":\"STOP-AIRPORT\",\"price\":{\"$numberDecimal\":\"36.00\"},\"currency\":\"DKK\",\"tripId\":\"LAB05-T-OK\",\"departureUtc\":\"2026-10-02T06:20:00.000Z\",\"arrivalUtc\":\"2026-10-02T06:40:00.000Z\",\"availableSeats\":10}]"
```

### 2.4 Result

| Search                    | Key                                            | Result                 |
|---------------------------|------------------------------------------------|------------------------|
| Without cache 06:00–07:00 | -                                              | `[LAB05-T-OK]`         |
| Without cache 18:00–19:00 | -                                              | `[]`                   |
| Redis for 18:00–19:00     | `search:LAB06:CPH:STOP-NORREPORT:STOP-AIRPORT` | `[LAB05-T-OK]` (wrong) |

### Why did the incomplete key allow the evening search to receive the morning result?

The cached key did not contain the start and end time, only the stop IDs, and Redis only stores
a key and a value. The two keys were therefore the same. When we fetched the data from Mongo, we
got `[]`, which was correct. The evening search produced the same key, so Redis returned the stored
morning result without asking Mongo.

## 2.5. Build a complete key

[CacheKey.cs](./CacheLab/CacheKey.cs) builds the key as
`search:LAB06:v2:{city}:{from}:{to}:{start}:{end}`. Each ID goes through `Uri.EscapeDataString`, and both
times are converted to UTC in ISO 8601 (`"O"`). Empty IDs and an end time that is not after the start
throw an `ArgumentException`.

### 2.6 Check the key function

The checks are in [KeyTests.cs](./CacheLab/KeyTests.cs). Run them with:

```
dotnet run --project labs/lab06-redis-cache/CacheLab
```

| Test                                   | Expected       | Result         |
|----------------------------------------|----------------|----------------|
| Morning and evening searches           | Different keys | Different keys |
| Origin and destination reversed        | Different keys | Different keys |
| Same instant as 06:00Z and 08:00+02:00 | Same key       | Same key       |
| Stop pairs A:B / C and A / B:C         | Different keys | Different keys |

Output:

```
Expected: not equal.
Was: not equal
Expected: not equal.
Was: not equal
Expected: equal.
Was: equal
Expected: not equal.
Was: not equal
```

Keys per test:

```
Morning:   search:LAB06:v2:CPH:STOP-NORREPORT:STOP-AIRPORT:2026-10-02T06:00:00.0000000Z:2026-10-02T07:00:00.0000000Z
Evening:   search:LAB06:v2:CPH:STOP-NORREPORT:STOP-AIRPORT:2026-10-02T18:00:00.0000000Z:2026-10-02T19:00:00.0000000Z

Reversed:  search:LAB06:v2:CPH:STOP-AIRPORT:STOP-NORREPORT:2026-10-02T06:00:00.0000000Z:2026-10-02T07:00:00.0000000Z

06:00Z:    search:LAB06:v2:CPH:STOP-NORREPORT:STOP-AIRPORT:2026-10-02T06:00:00.0000000Z:2026-10-02T07:00:00.0000000Z
08:00+02:  search:LAB06:v2:CPH:STOP-NORREPORT:STOP-AIRPORT:2026-10-02T06:00:00.0000000Z:2026-10-02T07:00:00.0000000Z

A:B / C:   search:LAB06:v2:CPH:A%3AB:C:2026-10-02T06:00:00.0000000Z:2026-10-02T07:00:00.0000000Z
A / B:C:   search:LAB06:v2:CPH:A:B%3AC:2026-10-02T06:00:00.0000000Z:2026-10-02T07:00:00.0000000Z
```

`08:00+02:00` is the same instant as `06:00Z`, so both become `06:00:00.0000000Z` in the key. Without
`EscapeDataString`, both stop pairs would become `A:B:C` and share a key. Escaping turns the `:` inside an
ID into `%3A`, so the two keys stay different.

## 3 Cache the journey search

[CachedJourneySearch.cs](./CacheLab/CachedJourneySearch.cs) wraps the MongoDB search
with cache-aside: build key > Redis `GET` > on miss/invalid/unavailable call MongoDB > `SET` with a 20 s TTL.

Cache value:

    {

        schemaVersion:2,

        cachedAtUtc:"...",

        items":[...]

    }

Anything else counts as `invalid`.

The `miss` / `hit` output below was printed by `Search` when these runs were made. `Search` now returns the
data source instead (`Redis` or `MongoDB`, see section 4) and no longer prints `miss` / `hit`. `invalid`,
`cache unavailable` and `cache write failed` are still printed.

### 3.1 Miss, then hit

Morning search twice, evening search (empty result) twice:

```
miss                              MongoDB calls: 1
hit   [LAB05-T-OK]                MongoDB calls: 1
miss                              MongoDB calls: 2
hit   []                          MongoDB calls: 2
```

The empty result is cached too:
`{"schemaVersion":2,"cachedAtUtc":"2026-10-09T09:37:06.6642231+00:00","items":[]}`

### 3.2 Invalid cached values

| Value in Redis              | Output            | MongoDB calls |
|-----------------------------|-------------------|---------------|
| `invalid`                   | `invalid` > `hit` | 1             |
| `schemaVersion: 1`          | `invalid` > `hit` | 1             |
| `items: "x"`                | `invalid` > `hit` | 1             |
| `items: [{"cityId":"CPH"}]` | `invalid` > `hit` | 1             |

Invalid is treated as a miss, and `SET` overwrites the bad value.

### 3.3 Expiry

| Run             | Output         | TTL after |
|-----------------|----------------|-----------|
| 1 (empty cache) | `miss` > `hit` | 20        |
| 2 (2 s later)   | `hit` > `hit`  | 18        |
| 20 s later      | key expired    | -2        |

Reads do not renew the TTL.

### 3.4 Redis unavailable

| Version                                 | Output                                    | Time (4 searches) |
|-----------------------------------------|-------------------------------------------|-------------------|
| First                                   | `cache unavailable`, `cache write failed` | 45.5 s            |
| `FailFast` + no write after failed read | `cache unavailable`                       | 2.3 s             |

Correct results both times, but `AsyncTimeout = 500` did not limit the wait: StackExchange.Redis held commands in
its backlog for ~5 s, once for the read and once for the write. `BacklogPolicy.FailFast` fails immediately, and the
write is skipped because Redis just failed.

### 3.5 MongoDB unavailable

```
miss
search error: MongoDB search failed
```

A search error, not `[]`, so a failure is not mistaken for "no departures".

## 4 Test the cached search

The tests are in [SearchTests.cs](./CacheLab/SearchTests.cs). `Search` returns the data source (`Redis` or
`MongoDB`), and MongoDB calls are counted separately as the change in `source.Calls` around each search, so the
two checks do not depend on each other. The stopwatch only covers `Search`.

### 4.1 Test A: repeat a search

The exact morning key is deleted first, then the morning search runs twice within the 20 s TTL.

| Run | Data source | Trip IDs       | MongoDB calls | Time |
|-----|-------------|----------------|---------------|------|
| 1   | MongoDB     | `[LAB05-T-OK]` | 1             | 3 ms |
| 2   | Redis       | `[LAB05-T-OK]` | 0             | 1 ms |

Key: `search:LAB06:v2:CPH:STOP-NORREPORT:STOP-AIRPORT:2026-10-02T06:00:00.0000000Z:2026-10-02T07:00:00.0000000Z`

The first search misses and calls MongoDB. The second is served from Redis with the same trip IDs and no extra
MongoDB call.

### 4.2 Test B: cache an empty result

Same test as A, but with a search that returns no journeys: 5/10 18:00–19:00. The key is deleted first, then the search
runs twice within the 20 s TTL.

| Run | Data source | Trip IDs | MongoDB calls | Time |
|-----|-------------|----------|---------------|------|
| 1   | MongoDB     | `[]`     | 1             | 2 ms |
| 2   | Redis       | `[]`     | 0             | 0 ms |

Key: `search:LAB06:v2:CPH:STOP-NORREPORT:STOP-AIRPORT:2026-10-05T18:00:00.0000000Z:2026-10-05T19:00:00.0000000Z`

An empty result is a valid answer, so it is cached like any other but with no items. A missing key means nothing is
cached. Without that difference every search with no departures would call MongoDB each time.

### 4.3 Test C: expire a result

Morning search through a second `CachedJourneySearch` with a 2 s TTL, so the test does not wait 20 s. The key is
deleted first. Two searches, TTL read, 5 s wait, a third search, TTL read again.

| Run        | Data source | Trip IDs       | MongoDB calls | TTL after |
|------------|-------------|----------------|---------------|-----------|
| 1          | MongoDB     | `[LAB05-T-OK]` | 1             |           |
| 2          | Redis       | `[LAB05-T-OK]` | 0             | 1.998 s   |
| (wait 5 s) |             |                |               |           |
| 3          | MongoDB     | `[LAB05-T-OK]` | 1             | 1.996 s   |

Run 2 shows the result was in the cache before the wait. Run 3 calls MongoDB again, so the key expired, and the TTL
is back at almost 2 s, so the new result was saved with a new TTL instead of being kept alive.

### 4.4 Test D: store an invalid value

The test writes each invalid value under the morning key, then runs the
morning search twice. Each value has only one fault:

| Input               | Redis value                                        | Run 1                      | Run 2          |
|---------------------|----------------------------------------------------|----------------------------|----------------|
| Not JSON            | `not-json`                                         | `invalid`, MongoDB, 1 call | Redis, 0 calls |
| Wrong schemaVersion | `{"schemaVersion":1,"cachedAtUtc":"…","items":[]}` | `invalid`, MongoDB, 1 call | Redis, 0 calls |
| Missing items       | `{"schemaVersion":2,"cachedAtUtc":"…"}`            | `invalid`, MongoDB, 1 call | Redis, 0 calls |

All runs returned `[LAB05-T-OK]`. Run 1 prints `invalid` and calls MongoDB, so the value was found and rejected. Run 2
is a hit, so the `SET` after the MongoDB call replaced the invalid value.

## 5 Cancel a cached departure

TTL set to 5 min.
Before step 1 Mongo was reset and the morning key was deleted.

| Step | Action                       | Result                                | TTL after |
|------|------------------------------|---------------------------------------|-----------|
| 2    | Cached search                | MongoDB, `[LAB05-T-OK]`               | 300 s     |
| 3    | `cancel.js`                  | `matchedCount: 2`, `modifiedCount: 2` |           |
| 4    | Uncached search (Fetch)      | MongoDB, `[]`                         |           |
| 5    | Cached search, before expiry | Redis, `[LAB05-T-OK]`                 | 298 s     |
| 6    | `DEL` morning key            | `1` (key removed)                     |           |
| 7    | Cached search again          | MongoDB, `[]`                         | 300 s     |

Steps 4 and 5 ran right after each other and gave different answers to the same search: MongoDB knows the trip is
cancelled, but the cache still returns it. After the `DEL`, step 7 is a miss and caches the new `[]` with a new TTL.

### 5.1 What the passenger saw before and after deletion

After 2, the morning search is SET in redis, when the the trip is cancelled, but we do the cached search,
we still get the trip returned from redis, even thought uncached returs [].

After deleting the key or it expires from the cache, the cached search will fetch from Mongo again,
and return [].

### 5.2 What would happen if MongoDB had not yet received the cancellation

If the cancellation hadn't reached Mongo yet, the search would fetch from Mongo,
and store the stale trip again for a full TTL.
This means we need to update the source first, and invalidate after that

### 5.3 Why an in-progress search could write an old result back after deletion

Order is: read from Mongo, cancel, DEL, then the slow search SET.
If the SET was done before the DEL, the DEL would have removed it. The problem is that SET comes after DEL.

## 6 Stop Redis

Each test is one morning search per run with `dotnet run -- cached`, which prints the data source, trip IDs and the
time.

### 6.1 Test A: Redis is unavailable

`docker compose stop redis`

```
cache unavailable
MongoDB: [LAB05-T-OK], 59 ms
```

The cache failure is reported, and the search still returns the MongoDB result. 59 ms.

### 6.2 Test B: Redis and MongoDB are unavailable

`docker compose stop mongo` (Redis still stopped)

```
cache unavailable
Unhandled exception. System.InvalidOperationException: search error: MongoDB search failed
 ---> System.TimeoutException: A timeout occurred after 2010ms selecting a server ...
```

The search fails visibly after the 2 s `ServerSelectionTimeout` instead of returning `[]`, so a failure is not
mistaken for "no departures".

### 6.3 Restore the services

`docker compose start mongo redis`

| Run | Result                          |
|-----|---------------------------------|
| 1   | MongoDB, `[LAB05-T-OK]`, 82 ms  |
| 2   | Redis, `[LAB05-T-OK]`, 33 ms    |

Both services work again: run 1 is a miss and fills the cache, run 2 is a hit.

## 7 Send several searches at once

`dotnet run -- batch` deletes the morning key, adds a 200 ms delay before the MongoDB query and sends two batches of
ten concurrent searches.

| Requests | Delay  | Batch 1                                        | Batch 2 |
|----------|--------|------------------------------------------------|---------|
| 10       | 200 ms | 10 MongoDB calls                               | 0       |
| 2,000    | 1 ms   | 2,000 MongoDB calls                            | 0       |
| 20,000   | 1 ms   | 20,000 MongoDB calls, many `cache unavailable` | 0       |

All requests send their Redis `GET` before the first MongoDB query is done, so they all miss and all query MongoDB.
This is a cache stampede. Batch 2 runs after the `SET`, so every request is a hit. At 20,000 the client timed out on
Redis and fell back to MongoDB, adding even more load.

## 8 Try a seat counter

### 8.1 Store two counts
A key has only one value. Trup 1 has 0 seats and trip 2 has 10.
We can only save one count on a key, so if we save count on that key, one of the trips would have a wrong number,
or maybe both if counts are summed, it could be an issue aswell. Seat count belongs on a specific trip / the trip-id-

0 = known, means sold out.
Missing value is ambigious, it could be 0, it could also be the counter was not read or key was expired.
We should not guess, if we interpret unkown as sold out, trips are showns as sold out, even if they might not be,
and if we interpret it as not sold out, since its not 0, we could oversell. The script returns availability unkown,
which means the caller has to check at the source. 

### 8.2 Decrease only a positive count

| Step          | Result                 |
|---------------|------------------------|
| `SET` 1       | `OK`                   |
| Script        | `0`                    |
| Script again  | `-1`                   |
| `DEL`         | `1`                    |
| Script        | `availability unknown` |

The first run passes all checks and `DECR` takes the count from 1 to 0. The second run hits `current == 0` and
returns -1 early, without decreasing. After the `DEL`, `GET` returns nothing, so the script stops at the first check.

The script did nothing in PostgreSQL. No seat was reserved, no ticket created and no payment. It only ran `GET`
and `DECR` on a Redis counter.

The difference is that Redis is only an estimate, and it must not be responsible for a purchase. A purchase must
always be checked against the database in a transaction, and only after that can we try to update Redis. It is not
critical that Redis is 100% synced with the database, it is just an estimate. The script is still atomic, so
two requests at the same time cannot both read 1 and decr the count to -1.

## 9 Decide what belongs in Redis

Proposed expiries: search results 30 min is too long, it can show cancelled or departed trips. Route/day seat counts
do not work, counts belong to one trip (8.1). 24 h for routes and stops is fine, since they rarely change and are
invalidated when they do. `SET`/`GET`/`DEL` on the route and stop keys below worked as expected.

| Data              | Example key / value                                      | Source               | Expiry                        | Updated by                     | Deleted when            |
|-------------------|----------------------------------------------------------|----------------------|-------------------------------|--------------------------------|-------------------------|
| Search results    | `search:LAB06:v2:CPH:…` / cache entry with items         | MongoDB              | 30 s, capped at 1st departure | The search, on a miss          | TTL                     |
| Trip availability | `availability:LAB06:TRIP-ONE` / `10`                     | PostgreSQL `trips`   | 30 s                          | The purchase, after commit     | TTL                     |
| Route information | `route:LAB06:LINE-M2` / route row as JSON                | PostgreSQL `routes`  | 24 h                          | The reader, on a miss          | Route changed, or TTL   |
| Stop information  | `stop:LAB06:STOP-AIRPORT` / stop row as JSON             | PostgreSQL `stops`   | 24 h                          | The reader, on a miss          | Stop changed, or TTL    |

If Redis has no usable copy, each value is fetched from its source. Routes, stops and counts can be invalidated,
because the key is the object's ID. Search results cannot: one trip is in many searches, and nothing knows which
keys exist, so they rely on a short TTL.

Outside the lab I would use 30 s for journey search, capped at the first departure. Reads do not renew the TTL
(3.3), so a hot search still expires every 30 s, but with traffic like Rejseplanen the next request refills it
right away, and every other request in those 30 s is a hit. Within those 30 s a cancellation, sold seats or a delay can still make a result
out of date, which is fine since a purchase always checks PostgreSQL.

Two passengers searching a minute apart do not share an entry: the 30 s key has expired, and if the app uses "now"
as the start time, the key is different anyway.
