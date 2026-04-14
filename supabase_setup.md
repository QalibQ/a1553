# Supabase and Stripe Freemium Setup Guide

This document outlines the steps to deploy your backend and how to interact with the API endpoints from your Flutter mobile app.

## 1. Prerequisites

- A Supabase project (create one at database.supabase.com).
- A Stripe account with a configured Product and Price for the subscription.
- Supabase CLI installed on your local machine (`npm install -g supabase`).

## 2. Deploying the Backend

### Link your project
Link this local repository to your Supabase project:
```bash
supabase link --project-ref <your-project-ref>
```

### Apply Database Migrations
Push the database schema (tables, RLS policies, triggers) to your Supabase instance:
```bash
supabase db push
```

### Configure Edge Function Secrets
Set your Stripe API keys as secrets in your Supabase project:
```bash
supabase secrets set STRIPE_SECRET_KEY=sk_test_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```
*(You can get your STRIPE_WEBHOOK_SECRET from the Stripe dashboard after creating your webhook endpoint).*

### Deploy Edge Functions
Deploy the functions to Supabase:
```bash
supabase functions deploy create-checkout-session
supabase functions deploy stripe-webhook
```

---

## 3. Stripe Configuration

1. In the Stripe Dashboard, go to **Developers > Webhooks**.
2. Add an endpoint pointing to your deployed Edge Function: 
   `https://<project-ref>.supabase.co/functions/v1/stripe-webhook`
3. Select the following events to listen to:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
4. Copy the Webhook Secret and update your Supabase secret (`STRIPE_WEBHOOK_SECRET`).

---

## 4. Flutter Integration & API Endpoints

### Using Supabase Auth
Users can sign up and sign in using the standard Supabase Flutter SDK:
```dart
// Sign Up
await supabase.auth.signUp(
  email: 'user@example.com',
  password: 'password123',
);

// Sign In
await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'password123',
);
```

### Checking Premium Status
You can check a user's premium status directly from the `users` table:
```dart
final response = await supabase
  .from('users')
  .select('is_premium')
  .eq('id', supabase.auth.currentUser!.id)
  .single();

final isPremium = response['is_premium'] as bool;
```

### Upgrading to Premium
To initiate a Stripe Checkout session, call the Edge Function from your Flutter app:
```dart
import 'package:url_launcher/url_launcher.dart';

final response = await supabase.functions.invoke(
  'create-checkout-session',
  body: {
    'priceId': 'price_12345xxxxxxxx', // Your Stripe Price ID
    'successUrl': 'yourapp://premium/success', // Deep link to your app
    'cancelUrl': 'yourapp://premium/cancel',   // Deep link to your app
  },
);

final checkoutUrl = response.data['url'];
if (checkoutUrl != null) {
  // Launch the Stripe Checkout URL in the browser
  await launchUrl(Uri.parse(checkoutUrl));
}
```

### Accessing Content
Any authenticated user can fetch free content. Premium content requires `is_premium = true`. Your RLS policies will automatically handle this based on the authenticated user.

```dart
// Fetch all content the user is allowed to see
final content = await supabase
  .from('content')
  .select('*')
  .order('created_at', ascending: false);
```
