create table owner_loan (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  amount numeric(10,2) not null,
  amount_accounted_for numeric(10,2) not null default 0,
  taken_on date not null,
  reason text,
  repaid boolean not null default false,
  repaid_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);

alter table owner_loan enable row level security;
