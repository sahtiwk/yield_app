-- Keep historical plans, but do not require a plan for harvest registration.
alter table public.harvest_cases
  drop constraint if exists harvest_cases_current_plan_check;
alter table public.harvest_cases
  add constraint harvest_cases_current_plan_check
  check (length(trim(current_plan)) <= 100);
alter table public.harvest_cases alter column current_plan set default '';
