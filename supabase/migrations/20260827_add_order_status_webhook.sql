create extension if not exists pg_net with schema extensions;

-- Fires the send-order-update Edge Function whenever an order's status
-- changes, so the customer gets an automatic email from senam@leshoeshop.ca
-- (via Zoho SMTP) without anyone touching Notion or sending it by hand.
--
-- The shared secret below is not an account credential — it's a random
-- token this trigger and the function both check, since a DB trigger has
-- no user JWT to authenticate with. Rotate it by updating both this
-- function and the ORDER_WEBHOOK_SECRET function secret together.
create or replace function notify_order_status_change()
returns trigger
language plpgsql
security definer
as $$
begin
  perform net.http_post(
    url := 'https://yvymhjtswcneouvvgfbc.supabase.co/functions/v1/send-order-update',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', 'db3dc2208205e2040494a9aad3e5b368842e46ede4025e65'
    ),
    body := jsonb_build_object('record', to_jsonb(new), 'old_record', to_jsonb(old))
  );
  return new;
end;
$$;

create trigger order_status_email_webhook
  after update of status on "order"
  for each row
  when (old.status is distinct from new.status)
  execute function notify_order_status_change();
