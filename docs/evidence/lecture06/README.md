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

[CacheKey.cs](../../../database/redis/lecture06/CacheLab/CacheKey.cs) builds the key as
`search:LAB06:v2:{city}:{from}:{to}:{start}:{end}`. Each ID goes through `Uri.EscapeDataString`, and both
times are converted to UTC in ISO 8601 (`"O"`). Empty IDs and an end time that is not after the start
throw an `ArgumentException`.

### 2.6 Check the key function

The checks are in [Program.cs](../../../database/redis/lecture06/CacheLab/Program.cs). Run them with:

```
dotnet run --project database/redis/lecture06/CacheLab
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
