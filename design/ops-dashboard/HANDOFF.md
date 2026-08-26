# Le Shoe Shop — Ops Dashboard: integration brief

For whoever (or whichever AI) is wiring this into leshoeshop.ca. This
doc is self-contained — you shouldn't need anything else from this
project to build against it.

## Context

Le Shoe Shop is a sneaker/shoe cleaning business (pickup + delivery,
Québec City area). A separate project (this repo) built out the backend
data model and a static design concept for an internal operations
dashboard. That work is done; **this brief is the task**: build the real
dashboard on leshoeshop.ca's existing site/admin area, wired to live
data instead of the mockup's placeholder rows.

**Scope for this integration — orders, inventory, deliveries only.**
Sponsorship (a separate Lions Basketball cross-venture feature) and
owner reimbursement/expense tracking exist in the schema but are
explicitly **out of scope** for this dashboard right now — not essential
yet, leave them alone. Don't build UI for `sponsorship_deal`,
`sponsorship_deliverable`, `sponsorship_reach_snapshot`, `game`,
`expense`, or `owner_loan`.

## Design reference

Static concept: `Main.dc.html` in this folder, also viewable at
https://claude.ai/code/artifact/dbe0d82e-ef93-431b-995c-b35e255470d2
(placeholder data — layout/hierarchy is the point, not the sample rows).

Three sections, in priority order: **Orders** (pipeline by status:
pending → deposit paid → in progress → cleaned → delivered → paid, tier
badges for Refresh/Reset/Renew), **Inventory** (par-level bars per stock
item, flag anything at/below par), **Deliveries** (upcoming pickups/
drop-offs). No dollar amounts anywhere in this dashboard — deliverers/
employees may get access to it, and pricing isn't something they need to
see.

Type: Space Grotesk (headers) + IBM Plex Sans (body), Google Fonts. Warm
amber accent, semantic red/amber/green for status. No leshoeshop.ca
design system was available when this was drafted — **use the site's
real tokens instead of these if they conflict**; this palette was a
placeholder, not a mandate.

## Data source

Supabase project `le-shoe-shop` (ref `yvymhjtswcneouvvgfbc`).

- REST URL: `https://yvymhjtswcneouvvgfbc.supabase.co/rest/v1/`
- Anon (publishable) key — safe for client-side use, RLS already scopes
  what it can read: `sb_publishable_TFJxA1R5m5aGAlAWZKLpRQ_bPNg9MWK`
- Full schema: `prisma/schema.prisma` in the source repo. Table names
  are snake_case (`order`, `stock_item`, `customer`, `order_item`,
  `subcontractor`) — columns are listed in
  `supabase/migrations/20260826130013_init_sales_payables_stock_expenses.sql`.

RLS currently grants public **read only** on `customer`, `order`,
`order_item`, `stock_item`, `subcontractor` — nothing else is reachable
with this key (financials, expenses, sponsorship, invoices are
service-role-only, and out of scope here anyway).

**No auth exists yet.** This is fine only because `customer`/`order` are
still empty (checked at time of writing — 0 rows). Before real customer
data goes live: either add row-level scoping (e.g. per logged-in staff
user) or move `customer` fields with personal info (email/phone/address)
behind an authenticated read instead of the public anon key. Flag this
back to the source repo if you need help deciding — it's a schema/access
decision, not a frontend one.

## Queries per section

**Orders** — group client-side by `status`:
```
GET /order?select=*,customer(name,address)&order=booked_at.desc
```
`tier` is `REFRESH` | `RESET` | `RENEW`. `status` is `PENDING` |
`DEPOSIT_PAID` | `IN_PROGRESS` | `CLEANED` | `DELIVERED` | `PAID` |
`CANCELLED`.

**Inventory** —
```
GET /stock_item?select=*
```
Flag `current_qty <= par_level` for the at/below-par warning.
**This table is currently empty** — someone needs to enter real par
levels (laces, cleaning solution, deodorizer, crease protectors,
waterproof spray, brushes) before this section shows anything. Not a
frontend problem — ping the source repo owner to seed it, or seed it
yourselves if you have the numbers.

**Deliveries** — no dedicated delivery/route/zone model exists in the
schema yet. The mockup invented zone grouping (Sainte-Foy, Lévis, etc.)
from `customer.address` text for illustration only — there is no real
`zone` column to query. If zone-grouped deliveries are wanted for real,
that's a schema addition (a `zone` field, or geocoding), not something
to fake client-side. Flag it back rather than guessing a parsing scheme.

## Known gaps (already flagged, not yours to solve silently)

- `stock_item` and `order`/`customer` are empty — dashboard will show
  real structure but no data until orders start flowing and par levels
  are entered.
- No zone/route field for deliveries.
- No auth — see above.

If anything here doesn't match what you find in the live database
(schema drift, a renamed column, etc.), trust the live database and
flag the mismatch — this doc describes it as of when it was written.
