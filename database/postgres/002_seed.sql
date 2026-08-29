insert into operators (id, name) values
    ('OP-METRO', 'City Metro'),
    ('OP-BUS', 'City Bus')
on conflict do nothing;

insert into routes (id, operator_id, city_id, mode, short_name) values
    ('LINE-M2', 'OP-METRO', 'CPH', 'metro', 'M2'),
    ('LINE-5C', 'OP-BUS', 'CPH', 'bus', '5C')
on conflict do nothing;

insert into stops (id, city_id, name) values
    ('STOP-NORREPORT', 'CPH', 'Nørreport'),
    ('STOP-KONGENS-NYTORV', 'CPH', 'Kongens Nytorv'),
    ('STOP-AIRPORT', 'CPH', 'Copenhagen Airport'),
    ('STOP-CENTRAL', 'CPH', 'Copenhagen Central Station')
on conflict do nothing;

insert into route_stops (route_id, stop_sequence, stop_id) values
    ('LINE-M2', 1, 'STOP-NORREPORT'),
    ('LINE-M2', 2, 'STOP-AIRPORT'),
    ('LINE-M2', 3, 'STOP-CENTRAL'),
    ('LINE-M2', 4, 'STOP-NORREPORT')
on conflict do nothing;

insert into trips (id, route_id, service_date, scheduled_departure_utc, status) values
    ('TRIP-M2-001', 'LINE-M2', '2026-08-17', '2026-08-17 05:42:00+00', 'completed'),
    ('TRIP-M2-002', 'LINE-M2', '2026-08-17', '2026-08-17 06:12:00+00', 'completed'),
    ('TRIP-M2-003', 'LINE-M2', '2026-08-17', '2026-08-17 06:42:00+00', 'delayed'),
    ('TRIP-M2-004', 'LINE-M2', '2026-08-17', '2026-08-17 07:12:00+00', 'cancelled'),
    ('TRIP-M2-005', 'LINE-M2', '2026-08-17', '2026-08-17 07:42:00+00', 'scheduled'),
    ('TRIP-M2-006', 'LINE-M2', '2026-08-18', '2026-08-18 05:42:00+00', 'scheduled'),
    ('TRIP-M2-007', 'LINE-M2', '2026-08-18', '2026-08-18 06:12:00+00', 'scheduled'),
    ('TRIP-M2-008', 'LINE-M2', '2026-08-18', '2026-08-18 06:42:00+00', 'scheduled')
on conflict do nothing;
