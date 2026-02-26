-- Profiles table linked to auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  display_name TEXT,
  high_score INTEGER DEFAULT 0,
  total_words INTEGER DEFAULT 0,
  last_sync TIMESTAMPTZ DEFAULT NOW()
);

-- Leaderboards table (simplified for this context)
-- Since high_score is in profiles, a "Leaderboard" can just be a view or a separate table if we want historical ones.
-- The user said "leaderboards table", so maybe they want a table that tracks entries.
CREATE TABLE IF NOT EXISTS public.leaderboards (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  score INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboards ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Users can view all profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Policies for leaderboards
CREATE POLICY "Users can view all leaderboard entries" ON public.leaderboards FOR SELECT USING (true);
CREATE POLICY "Users can insert own leaderboard entry" ON public.leaderboards FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Trigger to create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (new.id, new.raw_user_meta_data->>'display_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- Migration: 2026-02-25-extend-stats
-- ============================================================

-- Extend profiles table with richer stats columns
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS longest_word TEXT,
  ADD COLUMN IF NOT EXISTS max_wpm FLOAT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_tiles INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_time FLOAT DEFAULT 0;

-- Session history table (for React Stats history chart)
CREATE TABLE IF NOT EXISTS public.sessions (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  score INTEGER NOT NULL DEFAULT 0,
  wpm FLOAT DEFAULT 0,
  words_found INTEGER DEFAULT 0,
  duration FLOAT DEFAULT 0,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  difficulty TEXT,
  language TEXT
);

-- RLS for sessions
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own sessions"
  ON public.sessions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions"
  ON public.sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
