begin;
-- New ingestion uses accepted_conditions; retain the legacy column for older
-- integrations without requiring two representations of the same field.
alter table public.buyer_options alter column accepted_grade drop not null;
alter table public.buyer_options add constraint buyer_offer_window check(valid_until > observed_at);
commit;
