# Learner Profile

Learning mode: active
Onboarding: complete

## Project
Situation: Known
Building: Database course labs on a mobility ticketing domain (Postgres, MongoDB, Redis); currently lecture 06 Redis cache lab
Codebase familiarity: Known (self-reported)
Learning scope: Not specified

## Experience
Overall programming: Intermediate (self-reported)
Stack familiarity: Intermediate across Postgres, MongoDB, Redis, C#/.NET (self-reported)

## Goals
Primary: Both understand the lab concepts and practice making and justifying design decisions
Capability goal: Not specified

## Preferences
Checkpoint frequency: Normal
Question style: Open-ended
Implementation style: Learner reasons and writes the code. AI helps put ideas into words, asks questions that make the learner think, and polishes README/docs after the learner has done the work.

## Strong Concepts
No demonstrated understanding recorded yet.

## Developing Concepts
- Cache vs source of truth (lab 06 sec 8): in their own words, Redis is an estimate and must not decide a purchase; the purchase is decided in a Postgres transaction and Redis is updated afterwards. Their first idea was a Redis "rollback", so cross-system atomicity is still being consolidated.
- Cache invalidation and staleness (lab 06 sec 5): explained the read-before-cancel write-back race in their own words. Summarised the trade-off as active invalidation vs passive expiry, and staleness vs effort. First attempt blamed a missing DB lock, so the cross-system gap is newly understood.

## Revisit
None recorded yet.
