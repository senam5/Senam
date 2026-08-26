alter table "order" add column notes text;

create table shop_location (
  id uuid primary key default gen_random_uuid(),
  venture venture not null unique,
  name text not null,
  address text not null,
  lat numeric(9,6),
  lng numeric(9,6)
);
alter table shop_location enable row level security;
create policy "public read: shop_location" on shop_location for select using (true);

insert into shop_location (venture, name, address)
values ('LE_SHOE_SHOP'::venture, 'Le Shoe Shop', '11 rue Langevin');

-- Deliverers/employees can read order status, customer info, and whether
-- an order is paid (paid_at is non-null) via the anon key, but NOT the
-- dollar amounts. Column-level grant, not just a frontend convention —
-- the anon key literally cannot select these columns. Verified with
-- `set role anon` — allowed columns succeed, `total` is rejected with a
-- permission error.
revoke select on "order" from anon;
grant select (
  id, venture, customer_id, tier, pair_count, status, pickup_distance_km,
  runner_id, referral_source, campaign_id, notes, booked_at,
  deposit_paid_at, cleaned_at, delivered_at, paid_at
) on "order" to anon;
