# Ops Dashboard — handoff for integration into leshoeshop.ca

Design concept: `Main.dc.html` in this folder (also published at
https://claude.ai/code/artifact/dbe0d82e-ef93-431b-995c-b35e255470d2 for
reference — static mockup, placeholder data).

## Data source

Supabase project `le-shoe-shop` (ref `yvymhjtswcneouvvgfbc`).

- REST URL: `https://yvymhjtswcneouvvgfbc.supabase.co/rest/v1/`
- Anon (publishable) key — safe for client-side use, RLS-scoped:
  `sb_publishable_TFJxA1R5m5aGAlAWZKLpRQ_bPNg9MWK`
- Full schema: `prisma/schema.prisma` in this repo. Table names are
  snake_case (e.g. `order`, `stock_item`, `customer`) — see each
  migration under `supabase/migrations/` for exact columns.

RLS currently allows public **read** on `customer`, `order`, `order_item`,
`stock_item`, `subcontractor` only — nothing else is queryable with the
anon key (financials, expenses, sponsorship, invoices stay
service-role-only). **No auth exists yet** — this was fine to open up
because `customer`/`order` are still empty, but flag it before real
customer data starts flowing; add proper RLS scoping (e.g. per-logged-in-
user, or restrict `customer` fields) once orders are live.

## Sections and their queries

**Orders pipeline** — group by `status`, show `tier`, `pair_count`,
customer name/address (join `customer`):
```
GET /order?select=*,customer(name,address)&order=booked_at.desc
```

**Inventory / par levels** — `stock_item` is currently empty; par level
numbers discussed in this project (laces, cleaning solution, deodorizer,
crease protectors, waterproof spray, brushes) still need to be entered
as real rows before this section has anything to show:
```
GET /stock_item?select=*
```
Flag `current_qty <= par_level` client-side for the at/below-par warning.

**Deliveries** — no dedicated delivery/route model exists yet; the
mockup inferred a zone from `customer.address` text. If the real
dashboard needs zone grouping, that likely wants either a real `zone`
column added to `customer`/`order`, or geocoding — flag back to this
project if so, since it's a schema decision, not just a frontend one.

## Design notes carried from the concept

- Prices/dollar amounts were deliberately left out — deliverers/employees
  may get access to this view, and pricing isn't something they need to
  see.
- Sponsorship + owner-reimbursement are a de-emphasized "annexe" row, not
  the focus — orders/inventory/deliveries are what this screen is for.
- Type: Space Grotesk (headers) + IBM Plex Sans (body), both via Google
  Fonts. Warm amber accent, semantic red/amber/green for stock and
  delivery status. No existing brand system to match against at the time
  this was drafted — your developer should swap in the real leshoeshop.ca
  design tokens if they differ.
