begin;
insert into payments (id, user_id, ticket_id, external_payment_reference, amount, currency, status)
values ('PAY-RETRY-1', 'USER-1', 'TICKET-1', 'retry-1', 36, 'DKK', 'Failed');   -- accepted
insert into payments (id, user_id, ticket_id, external_payment_reference, amount, currency, status)
values ('PAY-RETRY-2', 'USER-1', 'TICKET-1', 'retry-1', 36, 'DKK', 'Captured'); -- accepted: retry
insert into payments (id, user_id, ticket_id, external_payment_reference, amount, currency, status)
values ('PAY-RETRY-3', 'USER-1', 'TICKET-1', 'retry-1', 36, 'DKK', 'Captured'); -- 23505
rollback;