-- Parameters: {}
SELECT r.id, r.short_name
FROM lab07.routes AS r
ORDER BY r.id

-- Parameters: {"@__p_0":"R1"}
SELECT t.id, t.scheduled_departure_utc, t.route_id, t.status
FROM lab07.trips AS t
WHERE t.route_id = @__p_0

-- Parameters: {"@__p_0":"R2"}
SELECT t.id, t.scheduled_departure_utc, t.route_id, t.status
FROM lab07.trips AS t
WHERE t.route_id = @__p_0

-- Parameters: {"@__p_0":"R3"}
SELECT t.id, t.scheduled_departure_utc, t.route_id, t.status
FROM lab07.trips AS t
WHERE t.route_id = @__p_0

-- Parameters: {"@__p_0":"R4"}
SELECT t.id, t.scheduled_departure_utc, t.route_id, t.status
FROM lab07.trips AS t
WHERE t.route_id = @__p_0