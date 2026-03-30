# Home Screen Auth UI Setup

## What You Need to Add

Open `scenes/Home.tscn` in Godot and add these UI elements:

### 1. Auth Panel (Container)

Create a `VBoxContainer` for the auth buttons:
- **Name:** `AuthPanel`
- **Unique Name:** ✓ (click the % button in the inspector)
- **Position:** Below the title, above play button
- **Layout:** Center horizontally

### 2. Auth Buttons

Add these `Button` nodes as children of `AuthPanel`:

#### Google Button
- **Name:** `GoogleButton`
- **Unique Name:** ✓
- **Text:** " Google" (with icon if you have one)
- **Theme:** Use your spacey theme

#### Apple Button
- **Name:** `AppleButton`
- **Unique Name:** ✓
- **Text:** " Apple"
- **Theme:** Use your spacey theme

#### Guest Button
- **Name:** `GuestButton`
- **Unique Name:** ✓
- **Text:** "👤 Play as Guest"
- **Theme:** Use your spacey theme

### 3. User Status (Shown when signed in)

Add a `Label` node:
- **Name:** `UserStatus`
- **Unique Name:** ✓
- **Text:** "✓ user@example.com" (placeholder)
- **Visible:** false (will be shown/hidden by code)
- **Position:** Where the auth panel is (same spot)

### 4. Sign Out Button

Add a `Button` node:
- **Name:** `SignOutButton`
- **Unique Name:** ✓
- **Text:** "Sign Out"
- **Visible:** false
- **Position:** Below user status

## Suggested Layout

```
┌─────────────────────────────┐
│      Wordfall              │
│        🎮                   │
│                             │
│   AuthPanel (VBoxContainer) │
│   ┌───────────────────┐     │
│   │ Sign in to:       │     │
│   │ • Save progress   │     │
│   │ • Compete         │     │
│   │                   │     │
│   │ [G Google    ]    │     │
│   │ [ Apple     ]    │     │
│   │ [👤 Guest    ]    │     │
│   └───────────────────┘     │
│                             │
│   UserStatus (Label)        │
│   ✓ ulizzle@gmail.com       │
│   [Sign Out]                │
│                             │
│   [▶ Play Game]             │
│   [📊 Stats]  [⚙ Settings]  │
└─────────────────────────────┘
```

## How It Works

1. **Not signed in:** Shows `AuthPanel` with Google/Apple/Guest buttons
2. **Signed in:** Hides `AuthPanel`, shows `UserStatus` + `SignOutButton`
3. **Play button:** Always visible, works without signing in
4. **Guest mode:** Uses anonymous auth (need to enable in Supabase)

## Quick Setup Steps

1. Open `scenes/Home.tscn` in Godot
2. Add the nodes listed above
3. Make sure to check **Unique Name (%)** for each
4. Position them nicely
5. Test by pressing F5

The script (`Home.gd`) will handle showing/hiding automatically based on auth state.

## Testing

1. **Before enabling auth in Supabase:**
   - Buttons will show
   - Guest button will fail (anonymous auth disabled)
   - Google/Apple buttons show "TODO" messages

2. **After enabling anonymous auth:**
   - Guest button works
   - User status shows "✓ Anonymous"
   - Sign out works

3. **After enabling Google OAuth:**
   - Google button opens OAuth flow
   - User status shows "✓ email@gmail.com"

## Next: Enable Auth in Supabase

Go to your Supabase dashboard and enable:
1. **Anonymous** auth (for guest mode)
2. **Google** OAuth (easier than Apple to set up first)
3. **Apple** OAuth (requires Apple Developer account)
