-- 1,2,9
ALTER TABLE trips
    ALTER COLUMN capacity SET NOT NULL,
    ALTER COLUMN reserved_seats SET NOT NULL,
    ADD CONSTRAINT trips_capacity_non_negative CHECK (capacity >= 0),
    ADD CONSTRAINT trips_reserved_seats_within_capacity
        CHECK (reserved_seats BETWEEN 0 AND capacity),
    ADD CONSTRAINT trips_status_allowed
        CHECK (status IN ('Scheduled', 'Cancelled', 'Completed'));

-- 3,4,8,9
ALTER TABLE tickets
    ALTER COLUMN price SET NOT NULL,
    ADD CONSTRAINT tickets_price_non_negative CHECK (price >= 0),

    ALTER COLUMN user_id SET NOT NULL,
    ADD CONSTRAINT tickets_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id),

    ALTER COLUMN trip_id SET NOT NULL,
    ADD CONSTRAINT tickets_trip_id_fk FOREIGN KEY (trip_id) REFERENCES trips (id),

    ALTER COLUMN product_code SET NOT NULL,
    ADD CONSTRAINT tickets_product_code_fk FOREIGN KEY (product_code) REFERENCES products (code),

    ADD CONSTRAINT tickets_valid_period CHECK (valid_to_utc > valid_from_utc),

    ALTER COLUMN status SET NOT NULL,
    ADD CONSTRAINT tickets_status_allowed
        CHECK (status IN ('Active', 'Validated'));

-- 7
ALTER TABLE tickets
    ALTER COLUMN ticket_code SET NOT NULL,
    ADD CONSTRAINT tickets_ticket_code_unique UNIQUE (ticket_code);

-- 3,5,9
ALTER TABLE payments
    ALTER COLUMN amount SET NOT NULL,
    ADD CONSTRAINT payments_amount_non_negative CHECK (amount >= 0),

    ALTER COLUMN ticket_id SET NOT NULL,
    ADD CONSTRAINT payments_ticket_id_fk FOREIGN KEY (ticket_id) REFERENCES tickets (id),

    ALTER COLUMN status SET NOT NULL,
    ADD CONSTRAINT payments_status_allowed
        CHECK (status IN ('Pending', 'Authorized', 'Captured', 'Failed', 'Cancelled'));

-- 10: a failed or cancelled attempt can reuse the reference on retry.
CREATE UNIQUE INDEX payments_external_reference_unique
    ON payments (external_payment_reference)
    WHERE status IN ('Pending', 'Authorized', 'Captured');

-- 6,9
ALTER TABLE validations
    ALTER COLUMN ticket_id SET NOT NULL,
    ADD CONSTRAINT validations_ticket_id_fk FOREIGN KEY (ticket_id) REFERENCES tickets (id),

    ALTER COLUMN result SET NOT NULL,
    ADD CONSTRAINT validations_result_allowed
        CHECK (result IN ('Accepted', 'Rejected'));

-- 12: a ticket can be rejected many times but accepted once.
CREATE UNIQUE INDEX validations_one_accepted_per_ticket
    ON validations (ticket_id)
    WHERE result = 'Accepted';

-- 11
ALTER TABLE users
    ALTER COLUMN email SET NOT NULL,
    ADD CONSTRAINT users_email_unique UNIQUE (email);
