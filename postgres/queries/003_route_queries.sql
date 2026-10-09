-- next 20 trips for a route after a given time - order by, limit
select *
from trips as t
where route_id = 'LINE-M2'
  and t.scheduled_departure_utc > '2026-03-29T08:00:00Z'
  and t.status = 'Scheduled'
order by scheduled_departure_utc asc
limit 20;

-- TRIP-M2-20260429-0800 - 2026-04-29T08:00:00Z - Scheduled
-- TRIP-M2-20260429-1200 - 2026-04-29T00:00:00Z - Scheduled

-- stops on a route, sort stop sequence
select stops.name, stop_id, stop_sequence
from route_stops
         join stops on stops.id = route_stops.stop_id
where route_stops.route_id = 'LINE-M2'
order by stop_sequence asc;

-- Nørreport - 1
-- Kongens Nytorv - 2
-- Copenhagen Airport - 3


-- all routes with trip count on a date, with routes with no trips, left join, date filter in on
select routes.id, count(trips.id)
from routes
         left join trips on trips.route_id = routes.id
    and trips.service_date = '2026-04-29'
    and trips.status = 'Scheduled'
group by routes.id;

-- LINE-5C - 2
-- LINE-M2 - 2
-- LINE-A9 - 0