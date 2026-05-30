# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode project targeting iOS 26+. There is no separate build script — use Xcode 26+ or `xcodebuild` from the command line:

```bash
# Build for simulator
xcodebuild -project XVisionBoardAI.xcodeproj -scheme XVisionBoardAI -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests (no test targets currently exist)
xcodebuild test -project XVisionBoardAI.xcodeproj -scheme XVisionBoardAI -destination 'platform=iOS Simulator,name=iPhone 17'
```

To enable auto-login in debug builds, set the environment variable `DEBUG_AUTO_LOGIN=1` in the Xcode scheme (Edit Scheme → Run → Arguments → Environment Variables). This bypasses auth and uses `InMemoryTokenStore` instead of Keychain.

## Architecture

MVVM with three `@MainActor ObservableObject` view models injected app-wide via `environmentObject`:

- **`StoreManager`** — StoreKit 2 wrapper; owns product loading, purchase flow, and entitlement checks. Source of truth for `SubscriptionType`.
- **`UserManager`** — Auth state, user profile, onboarding flag. Persists `User` to `UserDefaults`; stores the auth token in `KeychainTokenStore` (production) or `InMemoryTokenStore` (DEBUG).
- **`VisionBoardManager`** — CRUD for `VisionBoard` objects; drives the async AI-generation flow (currently simulated). Persists boards via `JSONEncoder` → `UserDefaults`.

### Navigation flow

`ContentView` is the root router:
1. Onboarding (`OnboardingView`) — shown first run until `UserManager.hasCompletedOnboarding`
2. Auth wall (`WelcomeView` / `AuthViews`) — shown when `isLoggedIn == false`
3. Main app (`MainTabView`) — four tabs: Home, Create, Gallery, Profile

### Key patterns

- `@AppStorage("isLoggedIn")` is the shared auth gate; both `ContentView` and `UserManager` bind to it.
- All view models are `@MainActor`; async work uses `Task {}` / `await`.
- Dark-only UI — `preferredColorScheme(.dark)` set at the root, tab bar and nav bar painted `UIColor.black` via `UIAppearance`.

### Design system (`Utils/ColorScheme.swift`)

All colors are in the "cosmic" palette (`Color.cosmicPurple`, `.cosmicBlack`, `.cosmicGold`, etc.). Reusable view modifiers: `.cosmicCard()`, `.cosmicButton(isEnabled:)`, `.pulsing()`, `.manifestationTitle()`, etc.

### Models

- `VisionBoard` — `Codable/Identifiable` struct; contains `[VisionBoardImage]`, `[String]` affirmations, `VisionBoardLayout` (grid3x3/collage/singlePoster), `VisionBoardStyle` (cinematic/luxurious/minimalist/natural/futuristic/artistic).
- `User` — `Codable/Identifiable` struct; owns `SubscriptionType` (.free / .pro / .premium) and `UserPreferences`.

### AI generation (stub)

`VisionBoardManager.createVisionBoard(...)` simulates multi-step generation with `Task.sleep`. Image URLs are currently hardcoded to `picsum.photos` placeholders. Affirmations are generated locally from templates. Replacing these with real API calls is the main integration gap.

### StoreKit product IDs

```
com.xvisionboardai.pro.monthly / .yearly
com.xvisionboardai.premium.monthly / .yearly
com.xvisionboardai.credits.small / .medium / .large
```

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- iOS quality audit → invoke /ios-polish
