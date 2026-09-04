ALTER TABLE trips
    ALTER COLUMN capacity SET NOT NULL,
    ALTER COLUMN reserved_seats SET NOT NULL,
    ADD CONSTRAINT trips_capacity_non_negative CHECK (capacity >= 0),
    ADD CONSTRAINT reserved_seats_between_within_capacity
        CHECK (reserved_seats BETWEEN 0 AND capacity);

ALTER TABLE payments
    ALTER COLUMN amount SET NOT NULL,
    ADD CONSTRAINT payments_amount_non_negative CHECK (amount >= 0),

    ALTER COLUMN ticket_id SET NOT NULL,
    ADD CONSTRAINT payments_ticket_id_fk FOREIGN KEY (ticket_id) REFERENCES tickets (id);

ALTER TABLE tickets
    ALTER COLUMN price SET NOT NULL,
    ADD CONSTRAINT tickets_price_non_negative CHECK (price >= 0),

    ALTER COLUMN user_id SET NOT NULL,
    ADD CONSTRAINT tickets_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id),

    ALTER COLUMN trip_id SET NOT NULL,
    ADD CONSTRAINT tickets_trip_id_fk FOREIGN KEY (trip_id) REFERENCES trips (id),

    ALTER COLUMN product_code SET NOT NULL,
    ADD CONSTRAINT tickets_product_code_fk FOREIGN KEY (product_code) REFERENCES products (code),

    ADD CONSTRAINT tickets_validation_valid_period CHECK (valid_to_utc > valid_from_utc),

    ALTER COLUMN status SET NOT NULL,
    ADD CONSTRAINT tickets_status_allowed
        CHECK (status IN ('SCHEDULED', 'ACTIVE', 'VALIDATED', 'CAPTURED', 'ACCEPTED'));

ALTER TABLE validations
    ALTER COLUMN ticket_code SET NOT NULL,
    ADD CONSTRAINT validations_ticket_code_unique UNIQUE (ticket_code),
    ALTER COLUMN ticket_id SET NOT NULL,
    ADD CONSTRAINT validations_ticket_id_fk FOREIGN KEY (ticket_id) REFERENCES cast (tickets(id);
    