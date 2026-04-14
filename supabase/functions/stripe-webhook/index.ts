import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@12.0.0?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
  apiVersion: "2022-11-15",
  httpClient: Stripe.createFetchHttpClient(),
});

const cryptoProvider = Stripe.createSubtleCryptoProvider();

const toIso = (timestamp?: number | null) =>
  timestamp ? new Date(timestamp * 1000).toISOString() : null;

const isPremium = (status: string) => status === "active" || status === "trialing";

serve(async (req) => {
  const signature = req.headers.get("Stripe-Signature");
  if (!signature) return new Response("Stripe signature missing", { status: 400 });

  const body = await req.text();
  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "",
      undefined,
      cryptoProvider,
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : "Invalid webhook signature";
    return new Response(`Webhook Error: ${message}`, { status: 400 });
  }

  const supabaseAdminClient = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  const upsertSubscriptionAndPremium = async (subscription: Stripe.Subscription, userId?: string) => {
    let resolvedUserId = userId;

    if (!resolvedUserId) {
      const { data: existingSub } = await supabaseAdminClient
        .from("subscriptions")
        .select("user_id")
        .eq("stripe_subscription_id", subscription.id)
        .maybeSingle();
      resolvedUserId = existingSub?.user_id;
    }

    if (!resolvedUserId) {
      const { data: dbUser } = await supabaseAdminClient
        .from("users")
        .select("id")
        .eq("stripe_customer_id", String(subscription.customer))
        .maybeSingle();
      resolvedUserId = dbUser?.id;
    }

    if (!resolvedUserId) return;

    const premiumUntil = toIso(subscription.current_period_end);

    await supabaseAdminClient.from("subscriptions").upsert(
      {
        user_id: resolvedUserId,
        stripe_customer_id: String(subscription.customer),
        stripe_subscription_id: subscription.id,
        status: subscription.status,
        current_period_end: premiumUntil,
      },
      { onConflict: "stripe_subscription_id" },
    );

    await supabaseAdminClient
      .from("users")
      .update({
        is_premium: isPremium(subscription.status),
        premium_until: premiumUntil,
      })
      .eq("id", resolvedUserId);
  };

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        if (session.mode !== "subscription" || !session.subscription) break;

        const subscription = await stripe.subscriptions.retrieve(String(session.subscription));
        const userId =
          session.metadata?.supabase_user_id ||
          session.client_reference_id ||
          undefined;

        await upsertSubscriptionAndPremium(subscription, userId);
        break;
      }

      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        await upsertSubscriptionAndPremium(subscription);
        break;
      }
    }

    return new Response(JSON.stringify({ received: true }), { status: 200 });
  } catch (error) {
    console.error(error);
    const message = error instanceof Error ? error.message : "Webhook processing failed";
    return new Response(`Error processing webhook: ${message}`, { status: 500 });
  }
});
