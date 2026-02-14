# Deployment Guide - Word Loom

## Simple Setup

### 1. Add Your Supabase Credentials

Create `godot/addons/supabase/.env` from the example:

```bash
cp godot/addons/supabase/.env.example godot/addons/supabase/.env
```

Then edit `.env` and add your publishable key:

```ini
[supabase/config]
supabaseUrl="https://szgdvwfqlbixprrygnxg.supabase.co"
supabaseKey="sb_publishable_YOUR_KEY_HERE"
```

**Get your publishable key:**
- Supabase Dashboard → Settings → API → Project API keys → **"publishable"**
- Starts with `sb_publishable_`

**Safe to commit?**
- The `.env` file is gitignored - your credentials won't be committed
- Publishable keys are public-safe anyway (security via RLS)
- [See discussion](https://github.com/orgs/supabase/discussions/29260)

### 2. Set Up Row Level Security (CRITICAL!)

⚠️ **Without RLS, your database is publicly writable!**

See the RLS examples section below.

### 3. Export the Game

1. Open `godot/project.godot` in Godot 4.6+
2. Go to **Project** → **Export**
3. Select **Web** preset
4. Click **Export Project**
5. Export to `godot/dist/`
6. Commit to git:

```bash
git add godot/dist/
git commit -m "Update web export"
```

### 4. Deploy

```bash
git push origin main
```

Netlify will:
1. Run `build.sh` (copies `godot/dist/` → `dist/`)
2. Publish from `dist/`

Done! 🚀

---

## Local Testing

### Option 1: Test in Godot Editor (Fast)

1. Press **F5** in Godot
2. Game runs with your credentials
3. Check console for Supabase connection messages

### Option 2: Test Web Export (Realistic)

```bash
# Export from Godot to godot/dist/ first
cd godot/dist
python3 -m http.server 8000
```

Open http://localhost:8000 in your browser.

---

## Supabase RLS Policy Examples

**You MUST set these up** or your database will be publicly writable!

### `profiles` Table

```sql
-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

-- Users can insert their own profile (on first login)
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);
```

### `leaderboards` Table

```sql
-- Enable RLS
ALTER TABLE leaderboards ENABLE ROW LEVEL SECURITY;

-- Anyone can read leaderboard
CREATE POLICY "Anyone can view leaderboard"
ON leaderboards FOR SELECT
TO public
USING (true);

-- Users can insert their own scores
CREATE POLICY "Users can insert own scores"
ON leaderboards FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Prevent updates/deletes (scores are immutable)
CREATE POLICY "No updates to leaderboard"
ON leaderboards FOR UPDATE
USING (false);

CREATE POLICY "No deletes from leaderboard"
ON leaderboards FOR DELETE
USING (false);
```

### Test Your Policies

```sql
-- Test as anonymous user (should fail or return nothing)
SELECT * FROM profiles;

-- Test as authenticated user (should work)
SELECT * FROM profiles WHERE id = auth.uid();

-- Try to insert someone else's profile (should fail)
INSERT INTO profiles (id, high_score) VALUES ('not-my-id', 100);
```

---

## Troubleshooting

### "Supabase autoload not found"
- Make sure the Supabase plugin is enabled
- Check `project.godot` has the autoload configured

### RLS policy errors
- Check Supabase dashboard → Authentication → Policies
- Verify RLS is enabled on all tables
- Test policies in SQL Editor

### Game works locally but not in production
- Check browser console for errors
- Verify credentials in deployed code
- Check network tab for Supabase API calls

---

## Key Points

✅ **Publishable keys are public** - safe to commit to git
✅ **RLS is your security** - set it up properly
✅ **Simple workflow** - edit code, export, deploy
✅ **No env vars needed** - everything is in the code

🚫 **Never commit service role key** - only use publishable key
🚫 **Don't skip RLS** - your data will be publicly writable

---

## Future Improvements

- **Automated exports:** Use Godot headless mode in CI
- **Backend functions:** Add Netlify Functions for sensitive operations
- **Key rotation:** If needed, just update the code and redeploy
