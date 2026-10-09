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