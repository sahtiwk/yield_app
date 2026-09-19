begin;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  language_preference text not null default 'English' check (language_preference in ('English','Hindi','Tamil','Telugu')),
  is_onboarded boolean not null default false,
  created_at timestamptz not null default now()
);
create function public.create_profile() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id) values(new.id) on conflict do nothing;
  return new;
end;
$$;
create trigger create_user_profile after insert on auth.users for each row execute function public.create_profile();
insert into public.profiles(id) select id from auth.users on conflict do nothing;

create table public.crop_configs (
  id text primary key,
  name text not null,
  variety text not null,
  base_decay_per_hour double precision check (base_decay_per_hour between 0 and 1),
  shelf_life_hours double precision check (shelf_life_hours > 0),
  source_reference text,
  reviewed boolean not null default false,
  check (not reviewed or (base_decay_per_hour is not null and shelf_life_hours is not null and length(source_reference) > 0))
);
insert into public.crop_configs(id,name,variety) values
 ('tomato','Tomato','Hybrid red'),('okra','Okra','Fresh green'),('brinjal','Brinjal','Purple long');

create table public.harvest_cases (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  crop_id text not null references public.crop_configs(id),
  quantity_kg numeric not null check (quantity_kg > 0 and quantity_kg <= 100000),
  location_label text not null check (length(trim(location_label)) between 1 and 120),
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  harvest_status text not null check (harvest_status in ('Harvested','Harvest planned','Standing crop')),
  harvested_at timestamptz not null,
  urgency text not null check (urgency in ('Must sell today','Within 2 days','Within 3 days')),
  farmer_condition text not null check (farmer_condition in ('Ready','Ripe','Very ripe','Mixed','Damaged')),
  current_plan text not null check (length(trim(current_plan)) between 1 and 100),
  status text not null default 'active' check (status in ('active','completed','cancelled')),
  created_at timestamptz not null default now(),
  check ((latitude is null) = (longitude is null))
);
create index on public.harvest_cases(user_id, created_at desc);
create table public.harvest_case_constraints (
  id bigint generated always as identity primary key,
  harvest_case_id text not null references public.harvest_cases(id) on delete cascade,
  constraint_type text not null,
  value text not null,
  is_hard boolean not null default true,
  source text not null default 'farmer' check (source = 'farmer')
);
create index on public.harvest_case_constraints(harvest_case_id);
create table public.destinations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  source_name text not null,
  market_code text,
  transport_cost_per_km numeric check (transport_cost_per_km >= 0),
  updated_at timestamptz not null default now()
);
create table public.market_price_observations (
  id uuid primary key default gen_random_uuid(),
  crop_id text not null references public.crop_configs(id),
  destination_id uuid not null references public.destinations(id),
  price_per_kg numeric not null check (price_per_kg > 0),
  observed_for timestamptz not null,
  source_name text not null,
  source_type text not null check (source_type in ('live','cache','seed')),
  fetched_at timestamptz not null default now()
);
create index on public.market_price_observations(crop_id, observed_for desc);
create table public.weather_observations (
  id uuid primary key default gen_random_uuid(),
  harvest_case_id text not null references public.harvest_cases(id) on delete cascade,
  temperature_c double precision not null,
  humidity_percent double precision check (humidity_percent between 0 and 100),
  observed_at timestamptz not null,
  source_name text not null
);
create table public.storage_options (
  id uuid primary key default gen_random_uuid(),
  destination_id uuid not null references public.destinations(id),
  crop_id text not null references public.crop_configs(id),
  capacity_kg numeric not null check (capacity_kg >= 0),
  rate_per_kg_day numeric not null check (rate_per_kg_day >= 0),
  available boolean not null default false,
  observed_at timestamptz not null,
  source_name text not null
);

alter table public.profiles enable row level security;
alter table public.harvest_cases enable row level security;
alter table public.harvest_case_constraints enable row level security;
alter table public.crop_configs enable row level security;
alter table public.destinations enable row level security;
alter table public.market_price_observations enable row level security;
alter table public.weather_observations enable row level security;
alter table public.storage_options enable row level security;
create policy own_profile_read on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy own_profile_update on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy own_cases on public.harvest_cases for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy own_constraints on public.harvest_case_constraints for all to authenticated
 using (exists(select 1 from public.harvest_cases c where c.id = harvest_case_id and c.user_id = (select auth.uid())))
 with check (exists(select 1 from public.harvest_cases c where c.id = harvest_case_id and c.user_id = (select auth.uid())));
create policy read_crops on public.crop_configs for select to anon, authenticated using (true);
create policy read_destinations on public.destinations for select to authenticated using (true);
create policy read_prices on public.market_price_observations for select to authenticated using (true);
create policy read_storage on public.storage_options for select to authenticated using (true);
create policy own_weather on public.weather_observations for select to authenticated
 using (exists(select 1 from public.harvest_cases c where c.id = harvest_case_id and c.user_id = (select auth.uid())));

revoke all on public.profiles, public.harvest_cases, public.harvest_case_constraints, public.crop_configs,
 public.destinations, public.market_price_observations, public.weather_observations, public.storage_options from anon, authenticated;
grant select on public.crop_configs to anon, authenticated;
grant select, update(language_preference,is_onboarded) on public.profiles to authenticated;
grant select, insert, update, delete on public.harvest_cases, public.harvest_case_constraints to authenticated;
grant usage on sequence public.harvest_case_constraints_id_seq to authenticated;
grant select on public.destinations, public.market_price_observations, public.weather_observations, public.storage_options to authenticated;
grant all on public.profiles, public.harvest_cases, public.harvest_case_constraints, public.crop_configs,
 public.destinations, public.market_price_observations, public.weather_observations, public.storage_options to service_role;

-- One transaction prevents a partially saved case when constraints fail validation.
create function public.save_harvest_case(payload jsonb) returns void language plpgsql security invoker set search_path = '' as $$
begin
  insert into public.harvest_cases(id,crop_id,quantity_kg,location_label,latitude,longitude,harvest_status,harvested_at,urgency,farmer_condition,current_plan)
  values(payload->>'id',payload->>'crop_id',(payload->>'quantity_kg')::numeric,payload->>'location_label',
    (payload->>'latitude')::double precision,(payload->>'longitude')::double precision,payload->>'harvest_status',
    (payload->>'harvested_at')::timestamptz,payload->>'urgency',payload->>'farmer_condition',payload->>'current_plan')
  on conflict (id) do update set crop_id=excluded.crop_id,quantity_kg=excluded.quantity_kg,
    location_label=excluded.location_label,latitude=excluded.latitude,longitude=excluded.longitude,
    harvest_status=excluded.harvest_status,harvested_at=excluded.harvested_at,urgency=excluded.urgency,
    farmer_condition=excluded.farmer_condition,current_plan=excluded.current_plan;
  delete from public.harvest_case_constraints where harvest_case_id=payload->>'id';
  insert into public.harvest_case_constraints(harvest_case_id,constraint_type,value,is_hard)
    select payload->>'id',x->>'type',x->>'value',coalesce((x->>'is_hard')::boolean,true)
    from jsonb_array_elements(coalesce(payload->'constraints','[]'::jsonb)) x;
end;
$$;
revoke all on function public.save_harvest_case(jsonb) from public, anon;
grant execute on function public.save_harvest_case(jsonb) to authenticated;
revoke all on function public.create_profile() from public, anon, authenticated;
commit;
