# Design decision

# Published plan

Header + Detail rows vs. JSON document

Choice: Header + Detail rows
Both would only require 1 read, but the Header would require a join.
The upside to the document is that everything is stored together, and we only have one table,
we would also not have to think about migrating the table in the database if we get a new format,
but we would have to manage that in the app now. The unique ID would also only come up when we write.
The header would require two tables, and a migration if we change, but we can get unique and null checks,
we also get the huge upside, that we can enforce the rules in 1 place, and not several apps, and make a primary key
of planId, routeId for a window.
The published plan saves a copy of all the values from the board, which makes it preserved and not current. We have to
include the route name, so that a rename or cancel does not change it.

# Add your sketch of the command/query paths and the tables they use.

```text
Tables:
  routes      (id(pk), name)
  trips       (id, route_id, scheduled, status)
  bookings    (request_id, trip_id, bookedAtUtc)
  snapshots
    header    (plan_id(pk), window, publishedAt)
    rows      ((plan_id, route_id)(pk), route_name, count, nextScheduled)

Queries:
  ReadOverviewAsync(windows)
      reads: routes, trips

  ReadSnapShotAsync(id)
      reads: header, rows

Commands:
  CancelTripAsync(id)
      writes: tx [ lock trip row, update status ] commit

  RenameRouteAsync(id, name)
      writes: tx [ lock route row, update name ] commit

  BookTripAsync(trip, request)
      writes: tx key=req [
          trip with request exist > return it / conflict
        > lock trip row > Scheduled or reject
        > insert booking
      ] commit

  PublishSnapshotAsync(id, windows)
      writes: tx key=id [
          header exists with same window > AlreadyPublished / SnapshotConflictException
        > read overview values > insert header + rows
        > hook
      ] commit
```

Compare two designs in about 150 words. Explain your choice, what a cancellation
would update, and how a published plan keeps its original values. Mark the
transaction boundaries for booking and publication.

# A = request

# B = summary table

Cancellation would update:

- A: The trip
- B: The trip, and the summary table, in one transaction and the Route count and maybe the Min

Rename updates:

- A: The route
- B: The route and the summary table

Another time window:

- A: Nothing, it's a parameter
- B: Needs to calculate for that time window, since summary is only the standard from the start

Published plan is kept by:

- No one, we need a snapshot

Read cost:

- A: We need to read everytime someone wants an update, and recalculate, and the work in the DB grows with the number of
  rows.
- B: Low if we have the summary for the window, else we need to calculate for another, but only 1 time for the time
  window

Write cost:

- A: Only update in one table
- B: We have to update more tables each time to keep it in sync.

Based on the above table, i would choose A, the biggest reason is that the contract say we have to be able to show any
windows up until 24 hours, which means, that version b, still have to calculate all the other windows, just like A.
Besides that theres the easy of use.
but for now since read cost is not a problem, this makes sure we only have to keep track of 1 source of truth, and not
keep more tables in sync. It also saves a transaction from updating several tables at once. If this become a problem
later, and we have metrics showing that the call slows down, or takes a lot of resources from the db, due to growth in
the data size, i would use the summary table, and maybe pre-calculate some more time windows.

# Only 1 call:

```
select r.id as "Route", r.short_name as "Name",
    count(t.id) as "Count",
    min(t.scheduled_departure_utc) as "Next UTC"
from routes r
left join trips t
    on t.route_id = r.id
    and t.scheduled_departure_utc >= '2026-10-23T06:00:00Z'
    and t.scheduled_departure_utc < '2026-10-23T07:00:00Z'
    and t.status = 'Scheduled'
group by r.id
order by r.id;
```

routes.asenumerable()r.

# Include vs projection to DTO

Include also makes 1 call, but here it asks for the Route entities and not the values.
So EF has to materialize an object for every route and trip, and then each of them is registered
in the change tracker, unless we use AsNoTracking, since that is default for entities, but it would not
remove the objects. If we instead project to the record, we only ask for values, so then there is nothing to
materialize or track, and also count and min are computed in the database, instead of in memory.

This makes the dto read-only, so if we wanted to rename a route, we could not do that, but would have to go through
the entity instead. This is fine for the live-board, since its read-only.

EF threw an error when the last Select was before OrderBy, because after Select its not Routes anymore, and
then it does not know where r.Id comes from, because after Select, we are working on the DTO.

Also if we want to include R3 and R4 with 0 trips, we need to start from Routes and not Trips, if we start from Trips
there is no matching Routes.

So it would look like this

Include:

- calls: 1
- objects: 8 (4 route + 4 trip)
- columns: 6 (id, name + id, route_id, scheduled.., status)

Projection to DTO:

- calls: 1
- objects: 0
- columns: 4 ( id, name, count, min)
