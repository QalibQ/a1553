-- 1. Create users table (Extends auth.users to store public profile and premium status)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL PRIMARY KEY,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  is_premium BOOLEAN DEFAULT FALSE NOT NULL,
  premium_until TIMESTAMPTZ,
  stripe_customer_id TEXT
);

-- 2. Create subscriptions table
CREATE TABLE public.subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  stripe_customer_id TEXT NOT NULL,
  stripe_subscription_id TEXT UNIQUE NOT NULL,
  status TEXT NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 3. Create content table
CREATE TABLE public.content (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  premium_only BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content ENABLE ROW LEVEL SECURITY;

-- -------------------------
-- RLS POLICIES
-- -------------------------

-- Users can only view and update their own profile
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

-- Subscriptions can only be viewed by the owner
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions
  FOR SELECT USING (auth.uid() = user_id);

-- Anyone authenticated can view non-premium content
CREATE POLICY "Anyone can view non-premium content" ON public.content
  FOR SELECT USING (premium_only = false);

-- Premium users can view premium content
CREATE POLICY "Premium users can view premium content" ON public.content
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE public.users.id = auth.uid() 
      AND public.users.is_premium = true
      AND (public.users.premium_until IS NULL OR public.users.premium_until > NOW())
    )
  );

-- Admins can manage content
CREATE POLICY "Admins can manage content" ON public.content
  FOR ALL USING (auth.jwt() ->> 'email' = 'admin@yourdomain.com');

-- -------------------------
-- TRIGGERS & FUNCTIONS
-- -------------------------

-- Automatically create a user record when they sign up via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, created_at)
  VALUES (new.id, new.email, new.created_at);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
