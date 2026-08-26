// Lets a deliverer trigger a payment reminder to a customer WITHOUT the
// deliverer ever seeing the dollar amount — they only pass an orderId
// (something their app already has from the order list); this function
// looks up the balance and customer contact info server-side.
//
// verify_jwt is OFF (same reasoning as send-order-update — the caller is
// a deliverer's app using the anon key, not a logged-in Supabase user
// yet). Protected instead by requiring the order to actually be unpaid;
// there's no destructive action here, just sending a reminder, so this
// is a low-risk endpoint even before real auth exists.
//
// Required secrets: same ZOHO_SMTP_* / TWILIO_* as send-order-update.

import { SmtpClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

async function sendSms(to: string, body: string) {
  const sid = Deno.env.get("TWILIO_ACCOUNT_SID");
  const token = Deno.env.get("TWILIO_AUTH_TOKEN");
  const from = Deno.env.get("TWILIO_FROM_NUMBER");
  if (!sid || !token || !from) return { skipped: "twilio not configured" };

  const res = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
    {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${sid}:${token}`)}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({ To: to, From: from, Body: body }),
    },
  );
  return { sent: res.ok, status: res.status };
}

Deno.serve(async (req) => {
  const { orderId, channel } = await req.json(); // channel: "email" | "sms" | "both"
  if (!orderId) {
    return new Response(JSON.stringify({ error: "orderId required" }), { status: 400 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const headers = { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` };

  const orderRes = await fetch(
    `${supabaseUrl}/rest/v1/order?id=eq.${orderId}&select=id,total,paid_at,customer:customer_id(name,email,phone)`,
    { headers },
  );
  const [order] = await orderRes.json();
  if (!order) {
    return new Response(JSON.stringify({ error: "order not found" }), { status: 404 });
  }
  if (order.paid_at) {
    return new Response(JSON.stringify({ skipped: "already paid" }), { status: 200 });
  }

  const balanceLine = `You have a balance of $${order.total} due for your Le Shoe Shop order.`;
  const wantEmail = channel !== "sms";
  const wantSms = channel !== "email";

  let emailResult: unknown = { skipped: true };
  let smsResult: unknown = { skipped: true };

  if (wantEmail && order.customer?.email) {
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
      to: order.customer.email,
      subject: "Payment reminder — Le Shoe Shop",
      content: `Hi ${order.customer.name},\n\n${balanceLine}\n\n— Le Shoe Shop`,
    });
    await client.close();
    emailResult = { sent: true, to: order.customer.email };
  }

  if (wantSms && order.customer?.phone) {
    smsResult = await sendSms(order.customer.phone, `Le Shoe Shop: ${balanceLine}`);
  }

  return new Response(JSON.stringify({ email: emailResult, sms: smsResult }), { status: 200 });
});
