begin;
alter table public.profiles
  add column if not exists display_name text not null default '',
  add column if not exists farm_name text not null default '',
  add column if not exists district text not null default '',
  add column if not exists farm_area_hectares numeric check (farm_area_hectares > 0),
  add column if not exists is_test_profile boolean not null default false;
grant update(display_name,farm_name,district,farm_area_hectares) on public.profiles to authenticated;

alter table public.crop_configs
  add column if not exists varieties text[] not null default '{}',
  add column if not exists reference_temperature_c double precision,
  add column if not exists parameter_basis text not null default '',
  add column if not exists is_placeholder boolean not null default false;

-- These explicit planning fixtures are the only crop placeholders. The rate is
-- -ln(0.8)/shelf_life_hours: an assumed 20% quality loss, NOT a measured rate.
-- Keep reviewed=false until field calibration validates temperature/condition.
insert into public.crop_configs(id,name,variety,varieties,base_decay_per_hour,shelf_life_hours,
 reference_temperature_c,source_reference,parameter_basis,is_placeholder,reviewed)
values
 ('tomato','Tomato','Arka Rakshak',array['Arka Rakshak','Pusa Ruby','Roma'], -ln(0.8)/192,192,12.5,
 'https://postharvest.ucdavis.edu/produce-facts-sheets/tomato','Planning assumption: 80% retention at 8 days; cultivar-specific validation required.',true,false),
 ('okra','Okra','Arka Anamika',array['Arka Anamika','Pusa Sawani','Parbhani Kranti'], -ln(0.8)/168,168,10,
 'https://postharvest.ucdavis.edu/produce-facts-sheets/okra','Planning assumption: 80% retention at 7 days under cool storage.',true,false),
 ('brinjal','Brinjal','Pusa Purple Long',array['Pusa Purple Long','Arka Navneet','Bhagyamati'], -ln(0.8)/168,168,12,
 'https://postharvest.ucdavis.edu/produce-facts-sheets/eggplant','Planning assumption: 80% retention at 7 days under cool storage.',true,false),
 ('onion','Onion','Nashik Red',array['Nashik Red','Agrifound Dark Red','Bhima Shakti'], -ln(0.8)/720,720,0,
 'https://postharvest.ucdavis.edu/produce-facts-sheets/onions-dry','Planning assumption: 80% retention at 30 days for cured bulbs under dry cold storage.',true,false),
 ('potato','Potato','Kufri Jyoti',array['Kufri Jyoti','Kufri Pukhraj','Kufri Bahar'], -ln(0.8)/336,336,10,
 'https://postharvest.ucdavis.edu/produce-facts-sheets/potato','Planning assumption: 80% retention at 14 days; maturity and intended use must be verified.',true,false)
on conflict(id) do update set name=excluded.name,variety=excluded.variety,varieties=excluded.varieties,
 base_decay_per_hour=excluded.base_decay_per_hour,shelf_life_hours=excluded.shelf_life_hours,
 reference_temperature_c=excluded.reference_temperature_c,source_reference=excluded.source_reference,
 parameter_basis=excluded.parameter_basis,is_placeholder=true
where not crop_configs.reviewed;

alter table public.harvest_cases add column if not exists variety text not null default '';
create table if not exists public.buyer_options (
 id uuid primary key default gen_random_uuid(),
 destination_id uuid not null references public.destinations(id),
 crop_id text not null references public.crop_configs(id),
 capacity_kg numeric not null check (capacity_kg > 0),
 price_per_kg numeric not null check (price_per_kg > 0),
 accepted_conditions text[] not null,
 available boolean not null default false,
 observed_at timestamptz not null,
 valid_until timestamptz not null,
 source_name text not null,
 accepted_grade text,
 check(valid_until > observed_at)
);
-- Reconcile installations where the earlier buyer adapter created this table
-- manually. Existing observations are retained but require availability review.
alter table public.buyer_options
 add column if not exists accepted_conditions text[] not null default '{}',
 add column if not exists available boolean not null default false,
 add column if not exists valid_until timestamptz;
update public.buyer_options set accepted_conditions=array[accepted_grade]
 where cardinality(accepted_conditions)=0 and accepted_grade in ('Ready','Ripe','Very ripe','Mixed','Damaged');
update public.buyer_options set valid_until=observed_at+interval '24 hours' where valid_until is null;
alter table public.buyer_options alter column valid_until set not null;
alter table public.buyer_options enable row level security;
drop policy if exists read_buyers on public.buyer_options;
create policy read_buyers on public.buyer_options for select to authenticated using (true);
revoke all on public.buyer_options from anon,authenticated;
grant select on public.buyer_options to authenticated;
grant all on public.buyer_options to service_role;

-- Preserve the transactional contract while accepting the farmer's variety.
create or replace function public.save_harvest_case(payload jsonb) returns void language plpgsql security invoker set search_path = '' as $$
begin
  insert into public.harvest_cases(id,crop_id,variety,quantity_kg,location_label,latitude,longitude,harvest_status,harvested_at,urgency,farmer_condition,current_plan)
  values(payload->>'id',payload->>'crop_id',coalesce(payload->>'variety',''),(payload->>'quantity_kg')::numeric,payload->>'location_label',
    (payload->>'latitude')::double precision,(payload->>'longitude')::double precision,payload->>'harvest_status',
    (payload->>'harvested_at')::timestamptz,payload->>'urgency',payload->>'farmer_condition',payload->>'current_plan')
  on conflict (id) do update set crop_id=excluded.crop_id,variety=excluded.variety,quantity_kg=excluded.quantity_kg,
    location_label=excluded.location_label,latitude=excluded.latitude,longitude=excluded.longitude,
    harvest_status=excluded.harvest_status,harvested_at=excluded.harvested_at,urgency=excluded.urgency,
    farmer_condition=excluded.farmer_condition,current_plan=excluded.current_plan;
  delete from public.harvest_case_constraints where harvest_case_id=payload->>'id';
  insert into public.harvest_case_constraints(harvest_case_id,constraint_type,value,is_hard)
    select payload->>'id',x->>'type',x->>'value',coalesce((x->>'is_hard')::boolean,true)
    from jsonb_array_elements(coalesce(payload->'constraints','[]'::jsonb)) x;
end;
$$;
commit;
