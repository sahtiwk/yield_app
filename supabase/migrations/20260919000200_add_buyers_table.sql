begin;

create table public.buyer_options (
  id uuid primary key default gen_random_uuid(),
  destination_id uuid not null references public.destinations(id),
  crop_id text not null references public.crop_configs(id),
  accepted_grade text not null,
  capacity_kg numeric not null check (capacity_kg >= 0),
  price_per_kg numeric not null check (price_per_kg > 0),
  observed_at timestamptz not null default now(),
  source_name text not null
);

alter table public.buyer_options enable row level security;
create policy read_buyers on public.buyer_options for select to authenticated using (true);

revoke all on public.buyer_options from anon, authenticated;
grant select on public.buyer_options to authenticated;
grant all on public.buyer_options to service_role;

commit;
