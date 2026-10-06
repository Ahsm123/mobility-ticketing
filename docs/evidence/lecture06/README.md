# Lab 06: Redis

## 2. Choose a cache key

### 2.1 Gem morgensøgningen under en ufuldstændig nøgle

Søgning uden cache, 2/10 06:00–07:00:

```
[{"cityId":"CPH","routeId":"LINE-M2","fromStopId":"STOP-NORREPORT","toStopId":"STOP-AIRPORT","price":{"$numberDecimal":"36.00"},"currency":"DKK","tripId":"LAB05-T-OK","departureUtc":"2026-10-02T06:20:00.000Z","arrivalUtc":"2026-10-02T06:40:00.000Z","availableSeats":10}]
```

Gemt i Redis med 5 min. TTL:

```
127.0.0.1:6379> SET search:LAB06:CPH:STOP-NORREPORT:STOP-AIRPORT '[{"cityId":"CPH","routeId":"LINE-M2","fromStopId":"STOP-NORREPORT","toStopId":"STOP-AIRPORT","price":{"$numberDecimal":"36.00"},"currency":"DKK","tripId":"LAB05-T-OK","departureUtc":"2026-10-02T06:20:00.000Z","arrivalUtc":"2026-10-02T06:40:00.000Z","availableSeats":10}]' EX 300
OK
127.0.0.1:6379> TTL search:LAB06:CPH:STOP-NORREPORT:STOP-AIRPORT
(integer) 271
```

### 2.2 Aftensøgning uden cache

2/10 18:00–19:00:

```
[]
```

### 2.3 Hent værdien under incomplete key

```
127.0.0.1:6379> GET search:LAB06:CPH:STOP-NORREPORT:STOP-AIRPORT
"[{\"cityId\":\"CPH\",\"routeId\":\"LINE-M2\",\"fromStopId\":\"STOP-NORREPORT\",\"toStopId\":\"STOP-AIRPORT\",\"price\":{\"$numberDecimal\":\"36.00\"},\"currency\":\"DKK\",\"tripId\":\"LAB05-T-OK\",\"departureUtc\":\"2026-10-02T06:20:00.000Z\",\"arrivalUtc\":\"2026-10-02T06:40:00.000Z\",\"availableSeats\":10}]"
```

### 2.4 Resultat

| Søgning                | Key                                            | Resultat                 |
|------------------------|------------------------------------------------|--------------------------|
| Uden cache 06:00–07:00 | -                                              | `[LAB05-T-OK]`           |
| Uden cache 18:00–19:00 | -                                              | `[]`                     |
| Redis for 18:00–19:00  | `search:LAB06:CPH:STOP-NORREPORT:STOP-AIRPORT` | `[LAB05-T-OK]` (forkert) |

