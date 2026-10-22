-- Design persistent storage for published dispatch plans in lab07.
-- Include the plan identity, time window, publication time and displayed values.
-- The contract defines behavior; the table layout is your choice.

create table lab07.snapshot_header
(
    plan_id          text primary key,
    from_utc         timestamptz not null,
    to_utc           timestamptz not null,
    published_at_utc timestamptz not null
);


create table lab07.snapshot_rows
(
    plan_id            text not null references lab07.snapshot_header (plan_id),
    route_id           text not null,
    route_name         text not null,
    count              int  not null,
    next_departure_utc timestamptz,
    primary key (plan_id, route_id)
);