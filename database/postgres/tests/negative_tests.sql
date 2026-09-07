-- Run: docker compose exec -T postgres psql -U mobility -d mobility -f /tests/negative_tests.sql

-- Rule 1: capacity cannot be negative and reserved seats
DO $$
BEGIN
    UPDATE trips
    SET capacity = -1
    WHERE route_id = 'LINE-M2';
    RAISE EXCEPTION 'expected trips_capacity_non_negative to be rejected, but it was accepted';
EXCEPTION
    WHEN check_violation THEN
        IF SQLSTATE <> '23514' THEN
            RAISE EXCEPTION 'wrong SQLSTATE: got %', SQLSTATE;
        END IF;
        RAISE NOTICE 'ok: capacity rule rejected with %', SQLSTATE;
END $$;

-- Rule 2: Reserved seats cannot be negative or > capacity

DO $$
    BEGIN
        UPDATE trips
        SET reserved_seats = 10000
        WHERE route_id = 'LINE-M2';
        RAISE EXCEPTION 'expected trips_reserved_seats_within_capacity to be rejected, but it was accepted';
    EXCEPTION
        WHEN check_violation THEN
            IF SQLSTATE <> '23514' THEN
                RAISE EXCEPTION 'wrong SQLSTATE: got %', SQLSTATE;
            END IF;
            RAISE NOTICE 'ok: reserved seats rejected with %', SQLSTATE;
    END $$;

-- Positive 
DO $$
    BEGIN
        BEGIN
            UPDATE trips
            SET reserved_seats = 100
            WHERE route_id = 'LINE-M2';
            RAISE NOTICE 'ok: reserved seats valid';
        EXCEPTION
            WHEN check_violation THEN
                -- If it triggers a check_violation, then it's wrong
                RAISE EXCEPTION 'expected to be accepted but was rejected %', SQLSTATE;
        END;
        ROLLBACK;
    END $$;
