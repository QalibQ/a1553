-- Public display name for account screen (also passed in auth signUp metadata as "username").
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username TEXT;

-- Keep profile row editable by owner (e.g. change username later).
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, created_at, username)
  VALUES (
    new.id,
    new.email,
    new.created_at,
    NULLIF(trim(COALESCE(new.raw_user_meta_data->>'username', '')), '')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
