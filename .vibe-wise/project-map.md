# Project Map

## Purpose
Course project (database labs, one per lecture) for a public-transport ticketing domain: journey search, ticket purchase, validation, timetables, availability and operator reporting. README.md is the review guide for Compulsory Assignment 1 (lectures 1-4).

## Requirements
Workloads from docs/access-patterns.md:
- Journey search: customer, read heavy, low latency, stale acceptable.
- Ticket purchase: read/write, seconds, strong/critical consistency.
- Ticket validation: read/write, low latency, strong (reporting side may be eventual).
- Timetable maintenance: operator writes, eventual.
- Real-time availability: read heavy, good enough for search, trustworthy enough for purchase.
- Reporting: operator reads, minutes, eventual.
Integrity rules and A/B/C/D classification in docs/dossier.md and docs/integrity-map.md.

## Components
- PostgreSQL 17 (authoritative relational model): database/postgres/init (schema + seed), migrations (011 integrity, 020-022 reporting, 030-033 product identity expand/contract), queries, tests/test_suite.sql, experiments/lab_02..lab_04.
- MongoDB 8 (lab 05, journey_search read model): database/mongodb/lab_05/*.js.
- Redis 7 (lab 06, cache, no persistence): labs/lab06-redis-cache/CacheLab, a .NET 8 console app. Lab write-up in labs/lab06-redis-cache/README.md (sections 2-3 done).
  - MongoJourneySearch.cs: Fetch(SearchRequest) runs an aggregation on mobility.journey_search, counts calls, optional artificial delay.
  - CacheKey.cs: Build(SearchRequest) -> `search:LAB06:v2:{city}:{from}:{to}:{startUtc}:{endUtc}`, IDs escaped, validates input.
  - CachedJourneySearch.cs: cache-aside, 20 s TTL, versioned CacheEntry JSON, invalid = miss, FailFast on Redis down, Mongo failure -> InvalidOperationException. Prints miss/hit/invalid to console (source not returned to caller).
  - Program.cs: runs morning x2 and evening x2 through CachedJourneySearch, prints JSON + Mongo call count + ms; then key checks.
- pgweb on :8080 for browsing Postgres.

## Main Flow
Lab 06 (implemented):
  Program -> CachedJourneySearch.Search -> CacheKey.Build -> Redis GET
    hit -> return; miss/invalid/unavailable -> MongoJourneySearch.Fetch -> Redis SET EX 20
Section tests: KeyTests (2), CacheTests (3), SearchTests (4, Test A implemented; later tests pending).

## Data and Trust Boundaries
- Postgres `payments` is the authority for revenue (README decision).
- Mongo journey_search is a derived read model; Redis would be a further derived copy.
- Local dev credentials in compose.yaml (mobility/mobility); Redis and Mongo bound to 127.0.0.1.

## Build and Deployment
- `docker compose up` (compose.yaml): redis, postgres, mongo, pgweb.
- Reset/setup steps: docs/setup-and-reset.md.
- `dotnet run --project database/redis/lecture06/CacheLab`.

## Unknowns
- Lab 06 remaining sections (lab description for lecture 06 not in docs/lab_descriptions; only lab1-4 there).
- Stampede handling and invalidation not designed yet (MongoJourneySearch.DelayMilliseconds marked "only for section 7").
