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
Include would also make 1 query, which satifies one part of the contract,
but include would also have 4 routes and 4 trips before scale, because it returns
entities which result in tracking, because it has to materialize the entities in memory.
This is avoided with projection to a record, beacuse we only get the values, and compute it in the db.

So it would look like this

Include:
- calls: 1
- objects: 8 (4 route + 4 trip)
- columns: 6 (id, name + id, route_id, scheduled.., status)

Projection to DTO:
- calls: 1
- objects: 0
- colums: 4 ( id, name, count, min)