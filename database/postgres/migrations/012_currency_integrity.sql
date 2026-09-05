-- https://www.dst.dk/en/Statistik/dokumentation/nomenklaturer/valuta-iso?id=1aeed3bf-ccaa-43fc-bf79-c50f8820ce35
-- Valuta should be correct format, but we cant check that the currency is real with this. 
BEGIN;

ALTER TABLE products
    ALTER COLUMN currency SET NOT NULL,
    ADD CONSTRAINT products_currency_iso4217 CHECK (currency ~ '^[A-Z]{3}$');

ALTER TABLE tickets
    ALTER COLUMN currency SET NOT NULL,
    ADD CONSTRAINT tickets_currency_iso4217 CHECK (currency ~ '^[A-Z]{3}$');

ALTER TABLE payments
    ALTER COLUMN currency SET NOT NULL,
    ADD CONSTRAINT payments_currency_iso4217 CHECK (currency ~ '^[A-Z]{3}$');

COMMIT;