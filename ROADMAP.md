# Roadmap — how to think about this long term

Written because it's easy to lose the thread across a lot of small
pieces. This is the shape of it, not a task list to execute all at once.

## The one urgent thing

**Real bookings on leshoeshop.ca are already being charged through
Stripe, but none of it lands in the Supabase schema.** Confirmed live:
~14 real payment intents exist in Stripe (multiple real customers,
deposit+balance splits), while `customer`/`order`/`payment` in Supabase
are still at zero rows. Until the booking flow writes into this schema
(or the schema reads from Stripe), the dashboard, reimbursement
tracking, and par-level system all stay theoretical — there's no real
data flowing in automatically.

This is the one thing worth treating as genuinely urgent, and it's a
**developer task** (see `design/ops-dashboard/HANDOFF.md`), not
something to solve personally. Everything else on this list is
downstream of this happening — sequence it first.

## Running on their own slow track (not blocking anything)

Business housekeeping that needs to happen eventually, on whatever
timeline it takes — none of it blocks the rest:

- **Google Business Profile suspension appeal** — submitted or pending;
  needs a business proof document (NEQ registration, lease, etc.)
- **NEQ registration** (Registraire des entreprises du Québec) — not
  done yet as of this writing; solves the Business Profile proof
  problem and generally legitimizes the business (banking, contracts,
  tax filings) regardless
- **GST/QST registration** — the schema properly computes and stores
  TPS/TVQ per order now; collecting it via Stripe creates a remittance
  obligation, worth confirming registration status before volume grows
- **Personal/business reconciliation loose ends**: the $5.52 Anthropic
  e-transfer (personal or business account?), the $374.24 still
  unreconciled from the Lions fund flush — both just need an answer
  whenever it's convenient, not urgently

## Correctly parked — don't let these pull focus yet

Already decided to defer, and that was the right call:

- **Sponsorship** (Lions deal amount, deliverables, per-game branding) —
  the mechanism is built and ready; the real dollar figure and terms
  can wait
- **Marketing attribution** (Campaign/AdSpend linking orders back to
  content) — matters once there's order volume to attribute, not before
- **Native app vs. web dashboard** — explicitly undecided; build the
  web version first regardless, since a native app would likely just
  wrap the same Supabase backend later

## The one-sentence version

Get the real booking flow wired into the database first (developer's
job, documented and ready), let the housekeeping items resolve at their
own pace, and don't let sponsorship/app/marketing questions pull focus
until the core plumbing is actually connected. Nothing built so far is
wasted — it's just sequenced, waiting on that one connection.
