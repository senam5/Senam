# Senam — cross-venture ops & finance backend

**Lost track of priorities across all this?** See `ROADMAP.md` — the
one thing that's actually urgent, what's running on its own slow track,
and what's correctly parked for later.

Data model and automation backing Le Shoe Shop (and, where money crosses
lines, Lions Basketball). Schema lives in `prisma/schema.prisma`; the
source of truth at runtime is the `le-shoe-shop` Supabase project
(`yvymhjtswcneouvvgfbc`, ca-central-1) — migrations in `supabase/migrations/`
mirror what's actually been applied there.

Lions Basketball has its own, separate Supabase project (the live team
training app — shots, runs, attendance). This project intentionally does
**not** touch that one; Lions only shows up here where money or content
crosses into Le Shoe Shop (sponsorship, the fund-flush debt, shared
subcontractors).

**Schema diagram**: `design/schema-erd.png` / `.pdf` (source:
`design/schema-erd.mmd`, a Mermaid ER diagram — regenerate with
`mmdc -i design/schema-erd.mmd -o design/schema-erd.png` after schema
changes if you want it to stay current; it's illustrative, not
auto-synced).

## Setup

```bash
npm install prisma --save-dev
npm install @prisma/client
cp .env.example .env   # fill in the real DATABASE_URL from Supabase dashboard
npx prisma generate
```

Migrations are applied directly to Supabase (via the Supabase MCP tools /
dashboard), not via `prisma migrate` — `supabase/migrations/*.sql` is kept
as the readable, version-controlled record of what ran.

## What's modeled

- **Sales**: `Customer`, `Order` (tier: Refresh/Reset/Renew, status
  pipeline PENDING → ... → PAID), `OrderItem`, `Product`, `Payment`
  (Stripe-linked).
- **Payables**: `Vendor`, `Requisition`, `PurchaseOrder`,
  `PurchaseOrderItem`, `Payable`.
- **Stock**: `StockItem` — par levels tied to which `ServiceTier`s consume
  each item, so reorder floors can be recalculated from real order volume
  instead of guessed.
- **Expense reconciliation**: `Expense` (tracks `paymentSource` — personal
  debit/credit, cash, transfer, business account — and `reimbursed`) plus
  the `reimbursement_balance` view (excludes anything `deductible = NO`,
  since that's the owner's own money, not a business debt).
- **OwnerLoan**: the reverse of `Expense` — money the *owner* took out of
  a venture (a cash flush, a withdrawal) that they owe back or intend to
  reinvest. `amountAccountedFor` + `notes` track partial reconciliation
  honestly rather than forcing a number that isn't actually known.
- **InterVentureTransfer**: money moved between ventures, recorded once so
  it's matched on both sides instead of appearing on only one.
- **Sponsorship**: `SponsorshipDeal` (+ `brandingLine`, e.g. "Lions
  Basketball powered by Le Shoe Shop"), `SponsorshipDeliverable`,
  `SponsorshipReachSnapshot`. `Game` is the actual per-game content-cost
  unit — sponsoring a game (`sponsorAmount`, `brandingIncluded = true`)
  is what makes that game's content carry the sponsor.
- **Marketing attribution**: `Campaign` + `AdSpend`, with `Order.campaignId`
  for last-touch attribution back to a campaign or sponsorship.
- **Subcontractor invoicing**: `SubcontractorInvoice` — subcontractors
  (drivers, coaches, media team — contractors, not employees) submit an
  invoice (number, date, amount, optional `kmDriven`/`kmRate` for their
  *own* CRA/RQ mileage deduction — not necessarily billed to the shop),
  owner approves/rejects/pays. `attachmentPath` points at the
  `subcontractor-invoices` Storage bucket so submitter and owner share one
  copy of the file instead of keeping separate ones.

All tables have RLS enabled with no public policies — locked to
service-role/backend access only until a client-facing app is built and
needs its own policies.

## Automation

`supabase/functions/send-order-update` emails the customer from
`senam@leshoeshop.ca` (via Zoho SMTP) whenever `Order.status` changes,
fired by a `pg_net` trigger (`supabase/migrations/20260827_add_order_status_webhook.sql`).
**Not yet live** — needs three function secrets set directly in Supabase
(never in git or chat):

```bash
npx supabase secrets set --project-ref yvymhjtswcneouvvgfbc \
  ZOHO_SMTP_USER=senam@leshoeshop.ca \
  ZOHO_SMTP_PASS=<a Zoho app-specific password, not the account password> \
  ORDER_WEBHOOK_SECRET=db3dc2208205e2040494a9aad3e5b368842e46ede4025e65
```

Zoho app passwords require 2FA turned on first (accounts.zoho.com →
Security). No urgency while order volume is still zero.

## Design

`design/ops-dashboard/` — a Claude Design canvas concept for a single
operations screen (orders pipeline, stock par levels, delivery schedule
up top; sponsorship + reimbursement counts as a de-emphasized annex,
dollar amounts deliberately stripped since deliverers may get access to
this view). Static concept, not wired to live data. Edit the `.dc.html`/
`canvas.json` sources and re-seed via the `design` skill to update it —
the seeded `.html` build output is gitignored.

## Known open items

- **$374.24 unreconciled** in the Lions `owner_loan` record — $657 was
  taken as an end-of-summer fund flush, $282.76 is accounted for
  (CapCut + the $157 forwarded to Le Shoe Shop for rent), the rest isn't
  matched to anything yet.
- **$5.52 Anthropic e-transfer** — unclear whether it came from a personal
  or business bank account; changes the exact reimbursement total either
  way.
- **Sponsorship deal amount** — the Lions deal (`sponsorship_deal`) is
  `PROPOSED` with `amount = 0`; real number and deliverable due-dates
  still TBD.
- **GST/QST registration** — the schema now properly computes and stores
  TPS/TVQ per order (Stripe collects it), which creates a remittance
  obligation. Worth confirming Le Shoe Shop is actually registered before
  real order volume starts.
- **Par levels** (`StockItem.parLevel`) are first-guess estimates, not
  derived from real order volume yet — recalculate once a few real weeks
  of data exist.
- **The bundled $265 Lions media cost** (Limoilou + Ste-Foy + 5 edits) has
  no per-game breakdown in the source data — left unlinked to any `Game`
  row rather than guessing a split. Ask for itemized invoices going
  forward if per-game sponsorship needs this.
