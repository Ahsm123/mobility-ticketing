BEGIN;

ALTER TABLE trips
    ALTER COLUMN capacity SET NOT NULL,
    ALTER COLUMN reserved_seats SET NOT NULL,
    ADD CONSTRAINT trips_capacity_non_negative CHECK (capacity >= 0),
    ADD CONSTRAINT trips_reserved_seats_within_capacity
        CHECK (reserved_seats BETWEEN 0 AND capacity),
    ADD CONSTRAINT trips_status_allowed
        CHECK (status IN ('Scheduled', 'Cancelled', 'Completed'));

ALTER TABLE products
    ALTER COLUMN name SET NOT NULL,
    ALTER COLUMN price SET NOT NULL,
    ALTER COLUMN currency SET NOT NULL,
    ADD CONSTRAINT products_price_not_negative CHECK (price >= 0),
    ADD CONSTRAINT products_currency_iso4217 CHECK (currency ~ '^[A-Z]{3}$');

ALTER TABLE users
    ALTER COLUMN email SET NOT NULL,
    ALTER COLUMN full_name SET NOT NULL,
    ALTER COLUMN is_disabled SET NOT NULL,
    ADD CONSTRAINT users_email_unique UNIQUE (email);

ALTER TABLE tickets
    ALTER COLUMN user_id SET NOT NULL,
    ALTER COLUMN trip_id SET NOT NULL,
    ALTER COLUMN ticket_code SET NOT NULL,
    ALTER COLUMN status SET NOT NULL,
    ALTER COLUMN product_code SET NOT NULL,
    ALTER COLUMN valid_from_utc SET NOT NULL,
    ALTER COLUMN valid_to_utc SET NOT NULL,
    ALTER COLUMN price SET NOT NULL,
    ALTER COLUMN currency SET NOT NULL,
    ADD CONSTRAINT tickets_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT tickets_trip_id_fk FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT tickets_valid_status CHECK (status IN ('Active', 'Validated', 'Cancelled')),
    ADD CONSTRAINT tickets_product_code_fk FOREIGN KEY (product_code) REFERENCES products (code) ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT tickets_valid_period CHECK (valid_to_utc > valid_from_utc),
    ADD CONSTRAINT tickets_price_not_negative CHECK (price >= 0),
    ADD CONSTRAINT tickets_currency_iso4217 CHECK (currency ~ '^[A-Z]{3}$'),
    ADD CONSTRAINT tickets_ticket_code_unique UNIQUE (ticket_code),
    ADD CONSTRAINT tickets_id_ticket_code_uniq UNIQUE (id, ticket_code);

ALTER TABLE payments
    ALTER COLUMN user_id SET NOT NULL,
    ALTER COLUMN ticket_id SET NOT NULL,
    ALTER COLUMN amount SET NOT NULL,
    ALTER COLUMN currency SET NOT NULL,
    ALTER COLUMN status SET NOT NULL,
    ADD CONSTRAINT payments_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT payment_ticket_id_fk FOREIGN KEY (ticket_id) REFERENCES tickets (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT payments_amount_not_negative CHECK (amount >= 0),
    ADD CONSTRAINT payments_currency_iso4217 CHECK (currency ~ '^[A-Z]{3}$'),
    ADD CONSTRAINT payments_valid_status CHECK ( status IN ('Captured', 'Failed', 'Refunded') );

CREATE UNIQUE INDEX payments_external_reference_unique
    ON payments (external_payment_reference)
    WHERE status IN ('Captured', 'Refunded');

ALTER TABLE validations
    ALTER COLUMN ticket_id SET NOT NULL,
    ALTER COLUMN ticket_code SET NOT NULL,
    ALTER COLUMN vehicle_id SET NOT NULL,
    ALTER COLUMN stop_id SET NOT NULL,
    ALTER COLUMN device_id SET NOT NULL,
    ALTER COLUMN result SET NOT NULL,
    -- ADD CONSTRAINT validations_vehicle_id_fk FOREIGN KEY (vehicle_id) REFERENCES,
    ADD CONSTRAINT validations_stop_id_fk FOREIGN KEY (stop_id) REFERENCES stops (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    -- ADD CONSTRAINT validations_device_id_fk FOREIGN KEY (device_id) REFERENCES,
    ADD CONSTRAINT validations_valid_result CHECK ( result IN ('Accepted', 'Rejected') ),
    ADD CONSTRAINT validations_ticket_id_ticket_code_reference_same_ticket FOREIGN KEY (ticket_id, ticket_code)
        REFERENCES tickets (id, ticket_code) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE route_stops
    DROP CONSTRAINT route_stops_route_id_fkey,
    DROP CONSTRAINT route_stops_stop_id_fkey,
    ADD CONSTRAINT route_stops_route_id_fk FOREIGN KEY (route_id) REFERENCES routes (id) ON DELETE CASCADE ON UPDATE RESTRICT,
    ADD CONSTRAINT route_stops_stop_id FOREIGN KEY (stop_id) REFERENCES stops (id) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE trips
    DROP CONSTRAINT trips_route_id_fkey,
    ADD CONSTRAINT trips_route_id_fk FOREIGN KEY (route_id) REFERENCES routes (id) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE routes
    DROP CONSTRAINT routes_operator_id_fkey,
    ADD CONSTRAINT routes_operator_id_fk FOREIGN KEY (operator_id) REFERENCES operators (id) ON DELETE RESTRICT ON UPDATE RESTRICT;

COMMIT;
