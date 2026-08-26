create table game (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  description text not null,
  played_on date not null,
  media_cost numeric(10,2),
  sponsorship_deal_id uuid references sponsorship_deal(id),
  sponsor_amount numeric(10,2),
  branding_included boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);
create index game_venture_played_idx on game(venture, played_on);

alter table sponsorship_deal add column branding_line text;
alter table expense add column game_id uuid references game(id);

alter table game enable row level security;
