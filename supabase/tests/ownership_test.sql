begin;
create extension if not exists pgtap with schema extensions;
select plan(12);
insert into auth.users(id,email) values
 ('11111111-1111-4111-8111-111111111111','rls-a@example.test'),
 ('22222222-2222-4222-8222-222222222222','rls-b@example.test');
select is((select count(*)::integer from public.profiles where id in ('11111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222')),2,'profile trigger creates profiles');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',true);
select lives_ok($$select public.save_harvest_case('{"id":"rls-case-a","crop_id":"tomato","quantity_kg":50,"location_label":"Village","harvest_status":"Harvested","harvested_at":"2026-09-19T05:00:00Z","urgency":"Must sell today","farmer_condition":"Ready","current_plan":"Market A","constraints":[{"type":"must_sell_by","value":"Must sell today"}]}')$$,'owner saves case and constraints');
select is((select count(*)::integer from public.harvest_cases),1,'owner can read case');
select is((select count(*)::integer from public.harvest_case_constraints),1,'owner can read constraints');
select lives_ok($$update public.profiles set language_preference='Telugu',is_onboarded=true where id=auth.uid()$$,'owner can onboard');
select lives_ok($$select public.save_harvest_case('{"id":"rls-case-a","crop_id":"tomato","quantity_kg":50,"location_label":"13.55, 78.5","latitude":13.55,"longitude":78.5,"harvest_status":"Harvested","harvested_at":"2026-09-19T05:00:00Z","urgency":"Must sell today","farmer_condition":"Ready","current_plan":"","constraints":[{"type":"must_sell_by","value":"Must sell today"}]}')$$,'GPS harvest saves without a selling plan');
select set_config('request.jwt.claims','{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',true);
select is((select count(*)::integer from public.harvest_cases),0,'other user cannot read case');
select is((select count(*)::integer from public.harvest_case_constraints),0,'other user cannot read constraints');
select is((select count(*)::integer from public.profiles),1,'only own profile visible');
select throws_ok($$select public.save_harvest_case('{"id":"rls-case-a","crop_id":"tomato","quantity_kg":1,"location_label":"Village","harvest_status":"Harvested","harvested_at":"2026-09-19T05:00:00Z","urgency":"Must sell today","farmer_condition":"Ready","current_plan":"Attack"}')$$,'42501',null,'cross-user overwrite rejected');
select throws_ok($$insert into public.market_price_observations(crop_id,destination_id,price_per_kg,observed_for,source_name,source_type) values('tomato',gen_random_uuid(),999,now(),'fake','live')$$,'42501',null,'clients cannot forge prices');
set local role anon;
select is((select count(*)::integer from public.crop_configs where id in ('tomato','okra','brinjal','onion','potato')),5,'public connection probe can read the crop catalog');
select * from finish();
rollback;
