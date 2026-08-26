create type weekday as enum ('MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY');

create table availability_slot (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  weekday weekday not null,
  start_time varchar(5) not null,
  end_time varchar(5) not null,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now()
);
alter table availability_slot enable row level security;
grant select on availability_slot to anon;

alter table "order" add column pickup_scheduled_at timestamptz;
grant select (pickup_scheduled_at) on "order" to anon;
