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

## Lab 06 section 5: cancel a cached departure (2026-10-12)

Status: Build checkpoint pending. Waiting for the learner's approach.

Spec (pasted by learner): reset Mongo and delete the morning key; TTL 5 min; run the morning search; cancel every copy of LAB05-T-OK in Mongo using last week's update; uncached search should give []; cached search should still give LAB05-T-OK; delete the morning key; cached search should give []. Explain what the passenger sees, the case where Mongo hasn't received the cancel yet, and the in-progress write-back race (quiz question 6, not in the repo; asked learner to paste it). Afterwards, restore the 20 s TTL and reset Mongo.

Risk flagged: lab 05 `updates.js` updates `journey_search_by_trip` (model 2), but `MongoJourneySearch` reads `journey_search` (model 1, filters on `departures.status: "Scheduled"`), so the uncached search would still return LAB05-T-OK.

Open questions to the learner: manual or code (TestE); 5 min TTL via Program `ttl` or a separate instance; what "uncached search" calls; how to keep the cancellation from leaking into tests A–D.

Learner skipped the Build checkpoint by explicit request ("just tell me what to run, I'll see the results and conclude myself"). AI gave a manual run plan: Program `ttl` set to 5 min, an `args` switch (`cached` / `uncached`) that returns early, `cancel.js` (journey_search + arrayFilters, status Cancelled), and PowerShell steps 1–7 plus cleanup. The learner pasted the code; AI then fixed the formatting on request. The section 5 block now sits right after `request` in Program, `ttl` on line 13 is 5 min (marked to restore), and `cancel.js` is clean. Build 0 errors. The learner ran it but found it confusing (output not shared). AI explained the step table (Mongo = source, Redis = snapshot). Learner's conclusion: "the point is that you have to invalidate the cache" (covers 5.1). AI asked when DEL is not enough (5.2 ordering, 5.3 write-back race); the learner had AI write these as TODO questions in README section 5, without answers. The learner wrote answers to 5.1–5.3 and revised them after feedback. In conversation they explained the 5.3 race correctly: the read happened before the cancel, so the value was already stale. AI then gave solution options on request (short TTL, double delete, versioning, lease); the choice is the learner's, and no implementation is required. AI ran steps 1–7 on request; all matched the expected results. AI wrote the result table into README section 5, then cleaned up: `ttl` back to 20 s, Mongo reset, morning key deleted (the uncached search returns `[LAB05-T-OK]` again). The `args` block is kept in Program. Still open: link quiz question 6 into 5.3 (question not shared). Previously: waiting for the learner's results, their conclusions and quiz question 6.

## Lab 06 section 6: stop Redis (2026-10-12)

Learner asked whether the current approach is a problem. AI's assessment: the core (`CachedJourneySearch`) is fine; the issue is that Program is a full test runner that assumes all services are up, while the lab expects one search per run. Learner decided to just follow the lab. They added a stopwatch to the `cached` branch (AI gave the snippet) and ran it: A `cache unavailable` + MongoDB 59 ms; B unhandled `InvalidOperationException` after the 2 s Mongo timeout; after restore, MongoDB 82 ms then Redis 33 ms. The unhandled exception is accepted as "fails visibly". AI tidied README section 6 on request (6.1–6.3).

## Lab 06 section 7: concurrent searches / stampede (2026-10-12)

The learner added the `batch` arg branch (AI gave the snippet). Result at 10 requests / 200 ms: batch 1 = 10 calls, batch 2 = 0. The learner experimented on their own: 2000 and 20k requests at 1 ms also missed every time; 20k gave many `cache unavailable` (client timeouts / likely thread-pool starvation, not Redis down; batch 2 = 0 proves Redis was up). AI wrongly explained a "1 ms" result that was really a stale `--no-build` binary; the learner caught it.

Optional part: single-flight. Learner decisions (own reasoning): in-process, because worst case = one call per server, which is good enough; a field on the class; checked only after a miss; the first request starts the fetch, others await the same Task; the entry is removed afterwards (after AI corrected the why: it would otherwise be a stale cache with no expiry). Misconception corrected: "they share a connection" — sharing the pipe does not dedupe the work.
AI-proposed additions, accepted at Implementation checkpoint: `ConcurrentDictionary<string, Lazy<Task<List<Journey>>>>`, removal in `finally` (success and failure), SET inside the shared work, waiters get Source `MongoDB`, the Redis-down path also goes through single-flight.
Implemented by AI in `CachedJourneySearch.cs` (`inFlight` field, `FetchAndCache`). Build 0/0. Batch run twice: batch 1 = 1 call, batch 2 = 0. Full run of sections 2–4 unchanged (Test C run 3 refetches after expiry, so removal works). Not verified: failure path / Redis-down batch (the batch branch's KeyDelete throws when Redis is down). README section 7 not written yet.
The learner then said the concept made sense and asked to remove it. `CachedJourneySearch.cs` restored to HEAD; build 0/0; batch back to 10 / 0. Single-flight was understood and tried, not kept.

## Lab 06 section 8: seat counter (2026-10-13)

Ran by hand after AI removed a UTF-8 BOM from `decrement_if_positive.lua` (Rider added it; Redis Lua failed with `unexpected symbol`). Path differs from the spec: `/scripts/decrement_if_positive.lua`. Results as expected: 0, -1, DEL 1, `availability unknown`.
Learner's reasoning (own words, after feedback): the key must be per trip ID, because one key = one value; missing ≠ 0 (unknown vs sold out, don't guess, the caller checks the source). They first said the script "reserved a seat", then corrected it: it only DECRs Redis. First proposed compensating Redis with a rollback; after the explanation, concluded that Redis is an estimate, the purchase is decided in a Postgres transaction, and Redis is updated afterwards (not critical if it is off). README section 8 part 1 written by the learner (mixed DA/EN, no heading/output); part 2 pending in the README.

## Lab 06 section 9: what belongs in Redis (2026-10-13)

Learner's decisions (own reasoning): search 30 s (hot keys stay alive at Rejseplanen-scale traffic; a 30 min TTL would show departed or cancelled trips); counts per trip, not route/day, at 30 s; route/stop 24 h plus invalidation on change; search TTL capped at the first departure; keys `route:LAB06:LINE-M2`, `stop:LAB06:STOP-AIRPORT` (the city was dropped after AI showed that `routes.id` is a PK on its own).
Corrected along the way: a trip ID was used as the route key; "who updates" was first answered about the sources, not Redis; LRU was proposed as cleanup (it is memory, not correctness); "everything must be invalidated" was refined to "invalidate when the key can be derived from the object, else TTL". The learner related it to cache warming in their happy-headlines project. Two passengers: answered TTL first; AI added the key-granularity point.
AI ran the route/stop SET/GET/DEL (the learner found the commands not useful) and wrote README section 9 (9.1–9.4) in the learner's wording on request. Lab 06 is complete apart from quiz Q6 in 5.3.

## Lab 06: split tests out of Program.cs (2026-10-12)

Status: Design confirmed. Learner implements.

Learner decisions: one test class per lab section; setup stays in Program and is passed in; Program = setup + one call per section.

AI-proposed additions, accepted: `KeyTests` (sec 2, only `request`, takes `Check` helper), `CacheTests` (sec 3), `SearchTests` (sec 4) in own files; primary-constructor dependency injection like `CachedJourneySearch`; run order 2, 3, 4. Pure move, output unchanged.

Implemented by AI on explicit request ("du flytter test, jeg skriver efter"): KeyTests.cs, CacheTests.cs, Program.cs trimmed. Build 0/0; output identical to baseline except section order (Docker was off, so only the Redis/Mongo-down path was compared). Learner writes SearchTests / Test A next.
