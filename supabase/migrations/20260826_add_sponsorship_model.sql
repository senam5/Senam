create type sponsorship_status as enum ('PROPOSED','ACTIVE','COMPLETED','CANCELLED');

create table sponsorship_deal (
  id uuid primary key default gen_random_uuid(),
  sponsor_venture venture not null,
  sponsored_venture venture not null,
  name text not null,
  amount numeric(10,2) not null,
  currency text not null default 'CAD',
  start_date date not null,
  end_date date,
  status sponsorship_status not null default 'PROPOSED',
  paid boolean not null default false,
  paid_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);
create index sponsorship_deal_ventures_status_idx on sponsorship_deal(sponsor_venture, sponsored_venture, status);

create table sponsorship_deliverable (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references sponsorship_deal(id),
  description text not null,
  due_date date,
  completed boolean not null default false,
  completed_at timestamptz
);

create table sponsorship_reach_snapshot (
  id uuid primary key default gen_random_uuid(),
  deal_id uuid not null references sponsorship_deal(id),
  period_start date not null,
  period_end date not null,
  unique_viewers int,
  total_views int,
  source text,
  notes text,
  created_at timestamptz not null default now()
);

alter table sponsorship_deal enable row level security;
alter table sponsorship_deliverable enable row level security;
alter table sponsorship_reach_snapshot enable row level security;
