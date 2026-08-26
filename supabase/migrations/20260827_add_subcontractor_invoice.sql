create type invoice_status as enum ('SUBMITTED','APPROVED','REJECTED','PAID');

create table subcontractor_invoice (
  id uuid primary key default gen_random_uuid(),
  subcontractor_id uuid not null references subcontractor(id),
  venture venture not null,
  invoice_number text not null,
  issued_on date not null,
  amount numeric(10,2) not null,
  km_driven numeric(8,2),
  km_rate numeric(6,3),
  description text,
  attachment_path text,
  status invoice_status not null default 'SUBMITTED',
  submitted_at timestamptz not null default now(),
  approved_at timestamptz,
  paid_at timestamptz,
  rejection_reason text,
  notes text,
  created_at timestamptz not null default now(),
  unique (subcontractor_id, invoice_number)
);
create index subcontractor_invoice_venture_status_idx on subcontractor_invoice(venture, status);

alter table subcontractor_invoice enable row level security;

insert into storage.buckets (id, name, public)
values ('subcontractor-invoices', 'subcontractor-invoices', false)
on conflict (id) do nothing;
