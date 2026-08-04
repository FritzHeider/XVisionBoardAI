# ManifestMe — App Store Listing Copy

Draft metadata for App Store Connect. Character limits noted in (parens). Review
and tweak the voice before submitting.

---

> **ASO strategy: dual-locale. Read this before editing any field below.**
> Apple indexes the Spanish (Mexico) localization for *US* App Store search. The US
> and ES-MX fields below are chosen to have **zero overlapping terms**, which buys
> roughly +260 indexed characters. If you edit one locale, check the other for
> duplication — a term repeated across locales is a wasted term.
> `app-marketing-context.md` is the source of truth for these values.

## App Name (30 chars) — English (U.S.)
**ManifestMe: AI Future Self** (26) — decided, and already the name on the App
Store Connect record (Apple ID 6751253658). Do **not** rename this to a
vision-board title: "vision board" is deliberately captured by the ES-MX title
instead, and duplicating it here would forfeit "future self" for nothing.

## Subtitle (30 chars) — English (U.S.)
**Visualize Wealth & Abundance** (28)

## Spanish (Mexico) localization — indexes for US search
This localization is **load-bearing for ASO, not a translation**. Fields are in
English on purpose. Without it, "vision board" and "manifestation" go uncaptured.
- ES-MX Name (27): **Vision Board: Manifestation**
- ES-MX Subtitle (30): **Daily Motivation & Inspiration**
- ES-MX Keywords (100): `positive,meditation,success,creator,maker,wallpaper,spiritual,wellness,intention,attract,habit,focus`
- ES-MX Description: reuse the US description below.

## Promotional Text (170 chars — updatable anytime without review)
Turn a selfie into a stunning AI vision board and see yourself already living your dream life. New styles and daily manifestation reminders to keep you inspired.

## Keywords (100 chars, comma-separated, no spaces between) — English (U.S.)
```
law,of,attraction,money,loa,mindset,affirmations,gratitude,journal,goals,dream,collage,photo,visual
```
(99/100). Deliberately contains **no** term already in the US name/subtitle or in
the ES-MX fields — Apple recombines terms across all of them, so repeating any of
`AI`, `future`, `self`, `visualize`, `wealth`, `abundance`, `vision`, `board`,
`manifestation`, `daily`, `motivation`, `inspiration` here would waste characters.
Phrases are split on commas (`law,of,attraction`) because Apple recombines tokens;
that is intentional, not a typo.

## Description (4000 chars)
See yourself already living the life you're manifesting.

ManifestMe turns a single selfie into a personalized AI vision board — cinematic, photorealistic images of you achieving your goals, living your dream life, and stepping into the future you're calling in.

HOW IT WORKS
• Take or choose a selfie
• Tell ManifestMe your goals and the life you're manifesting
• Pick a style and layout
• Watch your personalized vision board come to life in seconds

FEATURES
• Personalized AI imagery — your face, your dream life, generated with cutting-edge AI
• AI-written affirmations tailored to your specific goals
• Manifestation goal tracking — mark goals achieved and watch your progress
• Six visual styles — Cinematic, Luxurious, Minimalist, Natural, Futuristic, Artistic
• Multiple layouts — 3×3 grid, collage, or single poster
• Daily visualization reminders to keep your vision front of mind
• Save your board as wallpaper or share it for accountability
• Your boards and profile are stored on your device, not on our servers

HOW YOUR DATA IS USED
Generating a board sends your selfie to fal.ai (for the imagery) and your goals to
Google Gemini (for the affirmations). ManifestMe asks for your explicit permission
before this happens the first time. Nothing is sold or used for advertising, and
your email, profile, and finished boards never leave your device.

WHY IT WORKS
Visualization is one of the most powerful tools for manifestation. When you can actually see yourself living your dream life — not a stranger, not a stock photo, but you — your goals become real, emotional, and achievable. ManifestMe makes that vision vivid every single day.

Start manifesting the life you deserve. Your future self is waiting.

—

ManifestMe Pro
Unlock unlimited vision boards, HD watermark-free exports, and audio affirmations.
(Free includes one vision board with standard-resolution, watermarked exports.)
• Weekly — $4.99/week
• Monthly — $9.99/month
• Yearly — $49.99/year (with a 3-day free trial)

Subscriptions auto-renew unless cancelled at least 24 hours before the end of the period. Manage or cancel anytime in your App Store account settings.
Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://manifestme.fritzthatcat.com/privacy-policy.html

## What's New (v1.0)
Welcome to ManifestMe! Turn a selfie into your personalized AI vision board and start manifesting your dream life.

---

## URLs
- Privacy Policy URL: `https://manifestme.fritzthatcat.com/privacy-policy.html`
- Support URL: `https://manifestme.fritzthatcat.com/`
- Marketing URL (optional): `https://manifestme.fritzthatcat.com/`

## Category
- Primary: **Lifestyle**
- Secondary (optional): **Health & Fitness**

## Age Rating
Complete the questionnaire. Expected result **4+** (no objectionable content;
Nano Banana / Gemini image generation is safety-filtered by the provider). If
you answer "yes" to unrestricted user-generated content it may bump to 12+ —
answer accurately based on the constrained, personal (non-social) nature of the app.

---

## Per-subscription localization (App Store Connect requires Display Name + Description for each)

**Subscription Group Display Name:** ManifestMe Pro

| Product ID | Reference Name | Duration | Price | Display Name | Description |
|---|---|---|---|---|---|
| com.xvisionboardai.pro.weekly | Pro Weekly | 1 week | $4.99 | Weekly | Unlimited AI vision boards and HD exports, billed weekly. |
| com.xvisionboardai.pro.monthly | Pro Monthly | 1 month | $9.99 | Monthly | Unlimited AI vision boards and HD exports, billed monthly. |
| com.xvisionboardai.pro.yearly | Pro Yearly | 1 year | $49.99 | ManifestMe Pro — Annual | Unlimited boards, HD export & AI affirmations. Save 58% |

**Yearly introductory offer:** Free trial · 3 days · New subscribers.

---

## App Privacy answers (the "nutrition label" questionnaire)
Declare **Data Not Used to Track You**. Data types collected & linked to the user,
used for **App Functionality** only:
- Contact Info → **Email Address** (account)
- User Content → **Photos** (selfies) and **Other User Content** (goals, reflections, boards)
- Purchases → **Purchase History** (subscription status via RevenueCat)
Everything else: not collected. No third-party advertising, no tracking.

---

## App Review notes (paste into "Notes" for the reviewer)
- **No sign-in is required.** Tap "Continue without an account" on the welcome
  screen to use the full app. No demo credentials are needed.
- If you'd rather test the account path, any email/password works: accounts are
  stored locally on the device and there is no server behind them. A guest can
  also convert later via Profile → Create an Account.
- To see the core feature: allow camera or pick a photo, enter a goal, tap generate.
  A one-time consent screen explains that the selfie goes to fal.ai and the goal
  text to Google Gemini; tap "I Agree" to proceed. Generation takes 30s–3min and
  requires network.
- Free tier includes 1 vision board so the full flow can be exercised without purchasing.
- Pro unlocks exactly three things, each verifiable in sandbox: unlimited boards,
  HD watermark-free exports (free exports are watermarked "Made with ManifestMe"
  at standard resolution — export the same board before and after purchase to compare),
  and audio affirmations ("Read Aloud" on a board's detail screen).
- Privacy Policy and Terms of Use are linked in-app at Profile → Legal, and on the paywall.
- Account deletion is available in Profile → Delete Account.
- Contact: support@fritzthatcat.com

## Assets you still need to produce
- App preview screenshots: **6.9"/6.7" iPhone required** (1290×2796 or 1320×2868). 3–10 shots: onboarding, a finished vision board, the styles picker, affirmations, the paywall.
- **No iPad screenshots needed.** The app target is `TARGETED_DEVICE_FAMILY = 1`
  and the built binary declares `UIDeviceFamily = [1]`, so this ships iPhone-only.
  It still installs on iPad in scaled compatibility mode, but iPad support is not
  advertised and review won't hold it to an iPad-native standard.
  If you ever go universal, budget for it first: only 3 of 12 view files respond
  to `horizontalSizeClass`, there are ~48 hardcoded pixel widths in Views and no
  `maxWidth` caps, and no orientation keys are declared anywhere. A phone layout
  stranded on a 13" canvas is what Guideline 4.0 gets cited for.
- (Optional) an app preview video.
