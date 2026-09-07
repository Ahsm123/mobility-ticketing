-- Run: docker compose exec -T postgres psql -U mobility -d mobility -f /tests/negative_tests.sql

-- Rule 1: capacity cannot be negative and reserved seats
DO
$$
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
    END
$$;

-- Rule 2: Reserved seats cannot be negative or > capacity

DO
$$
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
    END
$$;

-- Positive 
DO
$$
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
    END
$$;

-- Rule 3: Price and payment amount not negative

DO
$$
    BEGIN
        UPDATE products
        SET price = -1
        WHERE code = 'SINGLE';
        RAISE EXCEPTION 'expected products_price_not_negative to be rejected, but it was accepted';
    EXCEPTION
        WHEN check_violation THEN
            IF SQLSTATE <> '23514' THEN
                RAISE EXCEPTION 'wrong SQLSTATE: got %', SQLSTATE;
            END IF;
            RAISE NOTICE 'ok: product price rejected with %', SQLSTATE;
    END
$$;

-- Positive 
DO
$$
    BEGIN
        BEGIN
            UPDATE products
            SET price = 100
            WHERE code = 'SINGLE';
            RAISE NOTICE 'ok: product price valid';
        EXCEPTION
            WHEN check_violation THEN
                -- If it triggers a check_violation, then it's wrong
                RAISE EXCEPTION 'expected to be accepted but was rejected %', SQLSTATE;
        END;
        ROLLBACK;
    END
$$;

-- Rule 4: Ticket must reference user, trip, product
DO
$$
    BEGIN
        INSERT INTO tickets (id, user_id, trip_id, ticket_code, status, product_code,
                             valid_from_utc, valid_to_utc, price, currency)
        VALUES ('TICKET-4', 'USER-1', 'TRIP-M2-20260429-0800', 'CODE-M2-0002', 'Active', '',
                '2026-04-29 07:45:00+00', '2026-04-29 10:00:00+00', 36.00, 'DKK');
        RAISE EXCEPTION 'expected tickets_product_code_fk to be rejected, but it was accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            IF SQLSTATE <> '23503' THEN
                RAISE EXCEPTION 'wrong SQLSTATE: got %', SQLSTATE;
            END IF;
            RAISE NOTICE 'ok: tickets fk integrity %', SQLSTATE;
    END
$$;






