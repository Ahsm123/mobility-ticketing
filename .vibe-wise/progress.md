# Learning Progress

## Lab 06 section 4, Test A: repeat a search (2026-10-12)

Status: Design confirmed. Learner implements; AI reviews afterwards.

Requirement: record cache key, data source, returned trip IDs, MongoDB-call count, elapsed time. Delete exact morning key, run morning search twice within 20 s; first calls MongoDB, second served from Redis without another MongoDB call.

Learner decisions (own reasoning):
- Delete the morning key in the test code before running, so miss-then-hit is reproducible.
- A test record filled per run, printed at the end.
- `Search` returns the data source; MongoDB calls measured as before/after delta of `source.Calls`.

Demonstrated reasoning: chose source reported by `Search` plus independent call delta (after prompt on whether inferring source from count checks the same thing twice).

AI-proposed additions, accepted at confirmation:
- Source values only `Redis` / `MongoDB` (miss, invalid, unavailable all map to `MongoDB`).
- Return shape tuple/record `(Items, Source)`, learner's choice; existing Program loop must adapt.
- Stopwatch around `Search` only, not the delete.
- First-run time includes MongoDB connection warm-up; don't overclaim speedup.

Progress: steps 1-2 done by learner (Search returns `(List<Journey> Items, string Source)`; Program loop adapted after fixing name clash, Serialize overload, WriteLine format overload, double-serialize). AI gave the final line-33-35 fix on explicit request.

Step 3: learner wrote SearchTests skeleton (TestRun record, key delete, Run helper with call delta + stopwatch). AI reviewed (missing await, async return type, TestRun args, trip IDs vs key, no output, not wired in Program); learner then asked AI to fix ("ok ret det til"). AI implemented: KeyDeleteAsync, `Run(key)` awaited twice, trip IDs via Select, Print line, Program calls TestA. Build 0/0. Not run: Docker off.

Open (learner's call, not decided): behaviour when Redis is down at the delete (currently throws, ends the program).

Ran with Docker up: run 1 MongoDB / 1 call / 3 ms, run 2 Redis / 0 calls / 1 ms, both [LAB05-T-OK]. Test A passes.

Learner decision: remove miss/hit console logging from `Search`, because the returned Source covers it (own reasoning, after asking why miss/hit printed before Test A's output). AI implemented; `invalid`, `cache unavailable` and `cache write failed` logging kept, since Source does not distinguish them. Build 0/0.

README section 4 / 4.1 written by AI on request, from the learner's run and confirmed design. Test A complete.

## Lab 06 section 4, Test B: cache an empty result (2026-10-12)

Learner implemented on their own: `TestB` in SearchTests (same shape as TestA), Program builds `emptyRequest` (5/10 18:00–19:00) with `with` and passes it in. Result: run 1 MongoDB / 1 call / `[]`, run 2 Redis / 0 calls / `[]`. Passes.
Open (learner's call): merge TestA/TestB into one method taking the test name.
README 4.2 written by AI on request from the learner's output.

## Lab 06 section 4, Test C: expire a result (2026-10-12)

Status: Design confirmed. Learner implements; AI reviews afterwards.

Requirement (learner's comment in SearchTests): after expiry the search calls MongoDB and saves a new result with a TTL.

Learner decisions (own reasoning, after Build checkpoint questions):
- Separate `CachedJourneySearch` with 2 s TTL, created in Program and passed in.
- Wait 5 s for margin.
- Search before the wait and check source `Redis` + TTL, to prove the key was cached before it expired.
- Check the new TTL with `KeyTimeToLiveAsync`.

Concepts explained: Redis lazy expiry (GET on an expired key always nil, ~1 ms precision); `KeyTimeToLiveAsync` returns null for both missing key and no expiry.

AI-proposed additions, accepted at confirmation:
- Delete the key first, as in A and B (otherwise Test A's 20 s key would survive the 5 s wait).
- Sequence: run 1 MongoDB, run 2 Redis + TTL, wait 5 s, run 3 MongoDB with 1 call + TTL.
- Expected TTL between 0 and 2 s, not null.
- Print TTL beside the run; `TestRun` unchanged.
- `Task.Delay` outside the stopwatch.

Learner started TestC skeleton and the 2 s instance in Program (but passed the 20 s one), then asked AI to write it ("skriv test og program"). AI implemented: TTL reads after run 2 and run 3, `Task.Delay(5 s)`, TTL printed beside runs; Program passes `cachedSearchWithLowTtl`. Ran with Docker: run 1 MongoDB/1 call, run 2 Redis/0 calls, TTL 1.998 s, wait 5 s, run 3 MongoDB/1 call (20 ms), TTL 1.996 s. Passes.

README 4.3 written by AI on request.

## Lab 06 section 4, Test D: store an invalid value (2026-10-12)

Spec (pasted by learner): SET key to `not-json` EX 20, run search; repeat with wrong schemaVersion and with missing items; program identifies invalid, fetches MongoDB, replaces it.

Learner decisions: set values from code; one loop over the three cases; evidence = `invalid` output, then source Redis afterwards.
Explained: Source is `MongoDB` for both miss and invalid, so `invalid` console line is the only marker (visual check, not in TestRun).
AI-proposed additions, accepted at Implementation checkpoint: one fault per value; `StringSetAsync` 20 s; per case SET → run 1 → run 2; 20 s instance + morning request from Program; case label, runs printed immediately.

Implemented by AI; ran with Docker: all 3 cases `invalid` + MongoDB/1 call, then Redis/0 calls, all `[LAB05-T-OK]`. README 4.4 written.

Next: next section 4 test.

## Lab 06: split tests out of Program.cs (2026-10-12)

Status: Design confirmed. Learner implements.

Learner decisions: one test class per lab section; setup stays in Program and is passed in; Program = setup + one call per section.

AI-proposed additions, accepted: `KeyTests` (sec 2, only `request`, takes `Check` helper), `CacheTests` (sec 3), `SearchTests` (sec 4) in own files; primary-constructor dependency injection like `CachedJourneySearch`; run order 2, 3, 4. Pure move, output unchanged.

Implemented by AI on explicit request ("du flytter test, jeg skriver efter"): KeyTests.cs, CacheTests.cs, Program.cs trimmed. Build 0/0; output identical to baseline except section order (Docker was off, so only the Redis/Mongo-down path was compared). Learner writes SearchTests / Test A next.
