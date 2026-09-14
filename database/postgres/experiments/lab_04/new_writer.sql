insert into tickets (
    id, user_id, trip_id, ticket_code, status, product_id,
    valid_from_utc, valid_to_utc, price, currency, product_code
) values
    ('TICKET-7', 'USER-1', 'TRIP-M2-20260429-0800', 'CODE-M2-0004', 'Active', 'd25788a4-eb4a-4e4d-bc79-ef7ffbbc01fc',
     '2026-04-29 07:45:00+00', '2026-04-29 10:00:00+00', 36.00, 'DKK',
     (SELECT code from products where id = 'd25788a4-eb4a-4e4d-bc79-ef7ffbbc01fc'))


CREATE OR REPLACE FUNCTION add_product_code()
    RETURNS TRIGGER AS $$
begin
    if NEW.product_id is not null
    then
        NEW.product_code := (SELECT code FROM products WHERE id = NEW.product_id);
    end if;
    RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER tickets_trigger
    BEFORE INSERT ON tickets
    FOR EACH row
execute FUNCTION add_product_code();