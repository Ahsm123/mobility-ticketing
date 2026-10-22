# Design decision

Add your sketch of the command/query paths and the tables they use.

Compare two designs in about 150 words. Explain your choice, what a cancellation
would update, and how a published plan keeps its original values. Mark the
transaction boundaries for booking and publication.

# Only 1 call:

```
select r.id as "Route", r.short_name as "Name",
    count(t.id) as "Count",
    min(t.scheduled_departure_utc) as "Next UTC"
from routes r
left join trips t
    on t.route_id = r.id
    and t.scheduled_departure_utc >= 	'2026-10-23T06:00:00Z'
    and t.scheduled_departure_utc < '	2026-10-23T07:00:00Z'
    and t.status = 'Scheduled'
group by r.id
order by r.id;
```

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