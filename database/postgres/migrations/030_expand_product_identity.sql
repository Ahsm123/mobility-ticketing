-- naive version
--    ALTER TABLE tickets
--        DROP COLUMN product_code,
--        ADD COLUMN product_id TEXT NOT NULL;

-- med BEGIN/COMMIT
-- postgres-1  | Running migration: /migrations/030_product_id.sql
-- postgres-1  | BEGIN
-- postgres-1  | psql:/migrations/030_product_id.sql:5: ERROR:  column "product_id" of relation "tickets" contains null values
-- postgres-1  | 2026-09-14 16:04:28.802 UTC [71] ERROR:  column "product_id" of relation "tickets" contains null values
-- postgres-1  | 2026-09-14 16:04:28.802 UTC [71] STATEMENT:  ALTER TABLE tickets
-- postgres-1  |           DROP COLUMN product_code,
-- postgres-1  |           ADD COLUMN product_id TEXT NOT NULL;

-- uden

--postgres-1  | Running migration: /migrations/030_expand_product_identity.sql
--postgres-1  | 2026-09-14 16:53:29.354 UTC [71] ERROR:  column "product_id" of relation "tickets" contains null values
--postgres-1  | 2026-09-14 16:53:29.354 UTC [71] STATEMENT:  ALTER TABLE tickets
--    postgres-1  |           DROP COLUMN product_code,
--postgres-1  |           ADD COLUMN product_id TEXT NOT NULL;
--postgres-1  | psql:/migrations/030_expand_product_identity.sql:4: ERROR:  column "product_id" of relation "tickets" contains null values

-- product_id er required men har ingen default value
-- hvis vi fjerner product_code vil det fjerne referencen til product, som også
-- ville breake vores revenue queries, da vi bruger prisen herfra. 

begin;
set local lock_timeout = '3s';

alter table products add column id uuid;

update products
set id = gen_random_uuid()
where id is null;

alter table products
    alter column id set default gen_random_uuid();

alter table products
    alter column id set not null;

alter table products
    add constraint products_id_unique unique (id);

alter table tickets
    add column product_id uuid;

alter table tickets
    add constraint tickets_product_id_fk
        foreign key (product_id)
            references products(id)
        not valid;

commit;