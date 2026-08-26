create type product_order_status as enum ('PENDING','PAID','FULFILLED','CANCELLED');

create table product_order (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  customer_id uuid not null references customer(id),
  status product_order_status not null default 'PENDING',
  subtotal numeric(8,2) not null,
  tps numeric(8,2) not null,
  tvq numeric(8,2) not null,
  total numeric(8,2) not null,
  ordered_at timestamptz not null default now(),
  paid_at timestamptz,
  fulfilled_at timestamptz
);

create table product_order_item (
  id uuid primary key default gen_random_uuid(),
  product_order_id uuid not null references product_order(id),
  product_id uuid not null references product(id),
  quantity int not null default 1,
  price numeric(8,2) not null
);

alter table product_order enable row level security;
alter table product_order_item enable row level security;

-- Same pattern as "order": Commandes UI needs status but not raw totals
-- exposed to a deliverer/employee view via the anon key.
grant select (id, venture, customer_id, status, ordered_at, paid_at, fulfilled_at) on product_order to anon;
grant select on product_order_item to anon;
grant select on product to anon;
