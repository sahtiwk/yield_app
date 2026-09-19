-- LOCAL TEST FIXTURE ONLY. Never execute this seed file on a production project.
-- The crop catalog is versioned in migration 20260919000300.
-- No prices, weather, routes, buyers, storage offers or recommendations are seeded.
begin;
insert into auth.users(id,instance_id,aud,role,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
values('a5a00000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000',
 'authenticated','authenticated','asha.reddy@example.test',now(),
 '{"provider":"email","providers":["email"]}', '{"display_name":"Asha Reddy"}',now(),now())
on conflict(id) do nothing;
update public.profiles set display_name='Asha Reddy',farm_name='Srinivasa Farm',district='Madanapalle, Andhra Pradesh',
 farm_area_hectares=2.4,language_preference='Telugu',is_onboarded=true,is_test_profile=true
where id='a5a00000-0000-4000-8000-000000000001';
commit;
