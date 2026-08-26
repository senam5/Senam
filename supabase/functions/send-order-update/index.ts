// Sends a customer order-status email from senam@leshoeshop.ca via Zoho SMTP.
// Triggered by a Postgres trigger (pg_net) on UPDATE of the "order" table's
// status column — see supabase/migrations/*_add_order_status_webhook.sql.
//
// verify_jwt is OFF for this function (a DB trigger has no user JWT to send).
// Instead it checks a shared secret header set by the trigger, so this is
// not an open unauthenticated endpoint.
//
// Required secrets (set via `supabase secrets set`, never hardcoded):
//   ZOHO_SMTP_USER    = senam@leshoeshop.ca
//   ZOHO_SMTP_PASS    = a Zoho app-specific password (Zoho Mail > Security >
//                       App Passwords) — NOT the real account password.
//   ORDER_WEBHOOK_SECRET = any random string; the same value is baked into
//                       the trigger's request header (see the migration).

import { SmtpClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

const STATUS_MESSAGES: Record<string, (tier: string) => string> = {
  DEPOSIT_PAID: (tier) =>
    `We've received your deposit — your ${tier} order is booked in.`,
  IN_PROGRESS: (tier) =>
    `Your ${tier} pair is in the shop and being cleaned right now.`,
  CLEANED: (tier) =>
    `Your ${tier} pair is cleaned and ready — delivery is being scheduled.`,
  DELIVERED: () =>
    `Your pair has been delivered. Thanks for choosing Le Shoe Shop!`,
};

Deno.serve(async (req) => {
  const secret = req.headers.get("x-webhook-secret");
  if (secret !== Deno.env.get("ORDER_WEBHOOK_SECRET")) {
    return new Response("unauthorized", { status: 401 });
  }

  const payload = await req.json();
  // pg_net trigger payload shape: { record, old_record }
  const order = payload.record;
  const previous = payload.old_record;

  if (!order || order.status === previous?.status) {
    return new Response(JSON.stringify({ skipped: true }), { status: 200 });
  }

  const messageBuilder = STATUS_MESSAGES[order.status];
  if (!messageBuilder) {
    return new Response(JSON.stringify({ skipped: "no template for status" }), { status: 200 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const customerRes = await fetch(
    `${supabaseUrl}/rest/v1/customer?id=eq.${order.customer_id}&select=name,email`,
    { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } },
  );
  const [customer] = await customerRes.json();
  if (!customer?.email) {
    return new Response(JSON.stringify({ skipped: "no customer email" }), { status: 200 });
  }

  const client = new SmtpClient();
  await client.connect({
    hostname: "smtp.zoho.com",
    port: 465,
    tls: true,
    auth: {
      username: Deno.env.get("ZOHO_SMTP_USER")!,
      password: Deno.env.get("ZOHO_SMTP_PASS")!,
    },
  });

  await client.send({
    from: "Le Shoe Shop <senam@leshoeshop.ca>",
    to: customer.email,
    subject: "Update on your Le Shoe Shop order",
    content: `Hi ${customer.name},\n\n${messageBuilder(order.tier)}\n\n— Le Shoe Shop`,
  });
  await client.close();

  return new Response(JSON.stringify({ sent: true, to: customer.email }), { status: 200 });
});
