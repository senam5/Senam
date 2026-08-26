create type campaign_channel as enum ('META_ADS','GOOGLE_ADS','INSTAGRAM_ORGANIC','SPONSORSHIP','REFERRAL','OTHER');
create type campaign_status as enum ('PLANNED','ACTIVE','PAUSED','ENDED');

create table campaign (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  channel campaign_channel not null,
  name text not null,
  budget numeric(10,2),
  start_date date,
  end_date date,
  status campaign_status not null default 'PLANNED',
  sponsorship_deal_id uuid references sponsorship_deal(id),
  created_at timestamptz not null default now()
);

create table ad_spend (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references campaign(id),
  spent_on date not null,
  amount numeric(10,2) not null,
  channel campaign_channel not null
);

alter table "order" add column campaign_id uuid references campaign(id);
create index order_campaign_idx on "order"(campaign_id);

alter table campaign enable row level security;
alter table ad_spend enable row level security;

-- Running total of what a venture owes its owner for personally-funded
-- expenses that haven't been paid back yet. Query this instead of
-- re-deriving it by hand each time.
create view reimbursement_balance as
select venture, count(*) as unreimbursed_count, sum(total_paid) as amount_owed
from expense
where reimbursed = false
group by venture;
