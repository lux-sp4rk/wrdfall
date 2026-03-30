# Supabase Auth Setup Guide

## What We Built

✅ **Home screen sign-in** - Google, Apple, and Guest buttons
✅ **Play without auth** - Game works immediately, no login required
✅ **Smart UI** - Shows auth buttons when signed out, user status when signed in
✅ **OAuth ready** - Google and Apple sign-in prepared (need Supabase config)

## What You Need to Do

### 1. Add UI Elements to Home.tscn

**Open:** `scenes/Home.tscn` in Godot

**Add these nodes** (see `docs/home-screen-auth-ui.md` for details):
- `%AuthPanel` (VBoxContainer)
  - `%GoogleButton` (Button)
  - `%AppleButton` (Button)
  - `%GuestButton` (Button)
- `%UserStatus` (Label, initially hidden)
- `%SignOutButton` (Button, initially hidden)

**Layout suggestion:**
```
Title
  ↓
Auth Panel (when signed out)
  ↓
User Status (when signed in)
  ↓
Play Button (always visible)
  ↓
Stats | Settings
```

### 2. Enable Auth Methods in Supabase

Go to **Supabase Dashboard → Authentication → Providers**

#### Enable Anonymous Auth (Guest Button)

1. Click **Anonymous**
2. Toggle **Enable Anonymous sign-ins** → ON
3. Save

**Test:** Click "Play as Guest" button on home screen

#### Enable Google OAuth

1. Click **Google**
2. Toggle **Enable Sign in with Google** → ON
3. **Get OAuth credentials from Google:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a project (or use existing)
   - Go to **APIs & Services → Credentials**
   - Create **OAuth 2.0 Client ID**
   - Application type: **Web application**
   - Authorized redirect URIs:
     ```
     https://szgdvwfqlbixprrygnxg.supabase.co/auth/v1/callback
     https://wordfall.netlify.app/auth/callback
     ```
   - Copy **Client ID** and **Client Secret**
4. **Add to Supabase:**
   - Paste Client ID
   - Paste Client Secret
   - Save

**Test:** Click "Google" button on home screen

#### Enable Apple OAuth (Optional - Harder)

Requires Apple Developer account ($99/year).

1. Click **Apple**
2. Toggle **Enable Sign in with Apple** → ON
3. **Get credentials from Apple:**
   - Go to [Apple Developer](https://developer.apple.com/)
   - Certificates, Identifiers & Profiles
   - Create **Services ID**
   - Enable **Sign in with Apple**
   - Configure domains and return URLs:
     ```
     Domain: wordfall.netlify.app
     Return URL: https://szgdvwfqlbixprrygnxg.supabase.co/auth/v1/callback
     ```
   - Download and configure keys
4. **Add to Supabase:**
   - Add Services ID, Team ID, Key ID, and Private Key
   - Save

**Test:** Click "Apple" button on home screen

### 3. Test the Flow

#### Without Any Auth Enabled
- ✅ Home screen shows auth buttons
- ✅ "Play Game" works without signing in
- ❌ Auth buttons will fail (expected)

#### With Anonymous Enabled
- ✅ "Play as Guest" button works
- ✅ Shows "✓ Anonymous" when signed in
- ✅ Progress saves to Supabase
- ✅ Can sign out

#### With Google Enabled
- ✅ "Google" button opens OAuth popup
- ✅ User signs in via Google
- ✅ Shows "✓ email@gmail.com"
- ✅ Progress saves to Supabase
- ✅ Leaderboard shows real email

### 4. Export and Deploy

**When ready:**
1. Export game from Godot (Project → Export → Web, outputs to `dist/`)
2. Commit and push to git
3. Netlify deploys automatically
4. Test OAuth flow in production (localhost OAuth won't work)

## How It Works

### Code Flow

```
User clicks auth button
  ↓
Home.gd calls StatsManager.login_with_google()
  ↓
Supabase opens OAuth popup
  ↓
User signs in with Google
  ↓
Supabase.auth emits signed_in signal
  ↓
StatsManager stores user, emits auth_completed
  ↓
Home.gd updates UI (hides auth panel, shows user status)
  ↓
User's progress now syncs to Supabase
```

### Auth State Management

- **StatsManager** stores the current user
- **Home.gd** listens to auth state changes
- **UI updates automatically** when auth state changes
- **Game works without auth** - just won't sync/compete

## Troubleshooting

### "Anonymous sign-ins are disabled"
→ Enable Anonymous auth in Supabase dashboard

### "Error parsing URL" in web export
→ Fixed! We added credentials to `project.godot`

### Google OAuth opens but fails
→ Check redirect URIs in Google Cloud Console
→ Must include your Netlify URL

### "Play as Guest" works locally but not in production
→ Anonymous auth must be enabled in Supabase
→ Check browser console for errors

### User status doesn't update
→ Make sure nodes have Unique Names (%)
→ Check Godot debugger output

## Security Notes

✅ **Publishable key in code is safe** - designed to be public
✅ **RLS policies protect data** - set these up (see `deployment.md`)
✅ **OAuth handled by Supabase** - secure by default
❌ **Never commit service role key** - only use publishable key

## Next Steps

1. Add UI elements to Home.tscn (see `home-screen-auth-ui.md`)
2. Enable Anonymous auth in Supabase (quick test)
3. Enable Google OAuth in Supabase (production auth)
4. Test locally (F5 in Godot)
5. Export and test on Netlify
6. Set up RLS policies (see `deployment.md`)

---

*You can play the game immediately without signing in. Auth is optional but enables progress sync and leaderboards.*
