create extension if not exists pgcrypto;

-- ── enums ────────────────────────────────────────────────────────
create type venture as enum ('LE_SHOE_SHOP','CUIR_ESTHETICA','LIONS_BASKETBALL','SHARED_WORKSPACE');
create type service_tier as enum ('REFRESH','RESET','RENEW');
create type order_status as enum ('PENDING','DEPOSIT_PAID','IN_PROGRESS','CLEANED','DELIVERED','PAID','CANCELLED');
create type order_item_type as enum ('ADDON','PRODUCT');
create type payment_kind as enum ('DEPOSIT','BALANCE','FULL');
create type payable_status as enum ('PLANNED','PO_ISSUED','AWAITING_DELIVERY','RECEIVED','PAID');
create type payment_source as enum ('BUSINESS_ACCOUNT','PERSONAL_DEBIT','PERSONAL_CREDIT','CASH','TRANSFER');
create type deductible_status as enum ('YES','NO','PARTIAL');

-- ── shared ───────────────────────────────────────────────────────
create table subcontractor (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  name text not null,
  email text,
  phone text,
  commission numeric(5,2),
  created_at timestamptz not null default now()
);

-- ── sales domain ─────────────────────────────────────────────────
create table customer (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  name text not null,
  email text,
  phone text,
  address text,
  created_at timestamptz not null default now()
);

create table "order" (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  customer_id uuid not null references customer(id),
  tier service_tier not null,
  pair_count int not null default 1,
  status order_status not null default 'PENDING',
  pickup_distance_km numeric(5,2),
  pickup_fee numeric(6,2) not null default 0,
  runner_id uuid references subcontractor(id),
  referral_source text,
  subtotal numeric(8,2) not null,
  volume_discount_pct numeric(4,2) not null default 0,
  tps numeric(8,2) not null,
  tvq numeric(8,2) not null,
  total numeric(8,2) not null,
  booked_at timestamptz not null default now(),
  deposit_paid_at timestamptz,
  cleaned_at timestamptz,
  delivered_at timestamptz,
  paid_at timestamptz
);
create index order_venture_tier_booked_idx on "order"(venture, tier, booked_at);

create table product (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  sku text not null unique,
  name text not null,
  price numeric(8,2) not null,
  category text not null
);

create table order_item (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references "order"(id),
  type order_item_type not null,
  code text not null,
  product_id uuid references product(id),
  quantity int not null default 1,
  price numeric(8,2) not null
);

create table payment (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references "order"(id),
  kind payment_kind not null,
  amount numeric(8,2) not null,
  stripe_payment_id text,
  paid_at timestamptz not null default now()
);

-- ── payables domain ──────────────────────────────────────────────
create table vendor (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  name text not null,
  contact text,
  currency text not null default 'CAD',
  lead_time_days int
);

-- ── stock / par levels ───────────────────────────────────────────
create table stock_item (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  name text not null,
  category text not null,
  unit text not null,
  par_level numeric(10,2) not null,
  current_qty numeric(10,2) not null default 0,
  tiers_consumed_by service_tier[] not null default '{}',
  vendor_id uuid references vendor(id),
  lead_time_days int,
  updated_at timestamptz not null default now()
);
create index stock_item_venture_qty_idx on stock_item(venture, current_qty);

create table requisition (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  stock_item_id uuid references stock_item(id),
  description text not null,
  quantity numeric(8,2) not null,
  requested_by text,
  purchase_order_id uuid,
  created_at timestamptz not null default now()
);

create table purchase_order (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  vendor_id uuid not null references vendor(id),
  status payable_status not null default 'PLANNED',
  currency text not null default 'CAD',
  issued_at timestamptz,
  expected_at timestamptz,
  received_at timestamptz
);

alter table requisition
  add constraint requisition_purchase_order_fkey foreign key (purchase_order_id) references purchase_order(id);

create table purchase_order_item (
  id uuid primary key default gen_random_uuid(),
  purchase_order_id uuid not null references purchase_order(id),
  stock_item_id uuid references stock_item(id),
  description text not null,
  quantity_units numeric(10,2),
  quantity_liters numeric(10,2),
  unit_price numeric(10,2) not null
);

create table payable (
  id uuid primary key default gen_random_uuid(),
  purchase_order_id uuid not null unique references purchase_order(id),
  amount numeric(10,2) not null,
  currency text not null default 'CAD',
  status payable_status not null default 'PLANNED',
  due_at timestamptz,
  paid_at timestamptz
);

-- ── expense reconciliation ───────────────────────────────────────
-- Mirrors the informal "Dépenses / Payables" Notion ledger, plus the
-- two fields that ledger never had: which pocket the money actually
-- came from, and whether the owner has been paid back for it.
create table expense (
  id uuid primary key default gen_random_uuid(),
  venture venture not null,
  description text not null,
  category text not null,
  spent_on date not null,
  amount_ht numeric(10,2) not null,
  tps numeric(10,2) not null default 0,
  tvq numeric(10,2) not null default 0,
  total_paid numeric(10,2) not null,
  vendor text,
  payment_source payment_source not null,
  deductible deductible_status,
  reimbursed boolean not null default false,
  reimbursed_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);
create index expense_venture_reimbursed_idx on expense(venture, reimbursed);

-- Money that crosses venture lines (e.g. Lions -> Le Shoe Shop) needs
-- to be recorded once and mirrored on both sides' books, not left as
-- a single unmatched row on whichever side happened to log it.
create table inter_venture_transfer (
  id uuid primary key default gen_random_uuid(),
  from_venture venture not null,
  to_venture venture not null,
  amount numeric(10,2) not null,
  transferred_on date not null,
  reason text,
  created_at timestamptz not null default now()
);
