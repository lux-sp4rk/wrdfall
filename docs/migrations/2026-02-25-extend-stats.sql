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
