# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode project with a deployment target of **iOS 18.0**, built with Xcode 26+.
iOS 18 is the floor because `ContentView` uses the iOS 18 `TabView(selection:)` + `Tab`
builder and `.sidebarAdaptable`; dropping to iOS 17 means rewriting the tab bar against
the legacy `TabView`/`.tabItem` API. iOS 26-only Liquid Glass (`glassEffect`) is used in
four places, each already behind `#available(iOS 26, *)` with a `.ultraThinMaterial`
fallback — keep that pattern when adding new iOS 26 APIs.

There is no separate build script — use Xcode 26+ or `xcodebuild` from the command line:

```bash
# Build for simulator
xcodebuild -project XVisionBoardAI.xcodeproj -scheme XVisionBoardAI -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests — XVisionBoardAITests (Swift Testing, hosted by the app target)
xcodebuild test -project XVisionBoardAI.xcodeproj -scheme XVisionBoardAI -destination 'platform=iOS Simulator,name=iPhone 17'
```

To enable auto-login in debug builds, set the environment variable `DEBUG_AUTO_LOGIN=1` in the Xcode scheme (Edit Scheme → Run → Arguments → Environment Variables). This bypasses auth and uses `InMemoryTokenStore` instead of Keychain.

## Architecture

MVVM with three `@Observable` view models injected app-wide via `.environment(_:)` and read with `@Environment(Type.self)`. (`CameraManager` is the one deliberate holdout: still `ObservableObject` + `@StateObject`, because it owns an AVFoundation session tied to the view's lifetime.)

- **`StoreManager`** — RevenueCat wrapper (`import RevenueCat`); owns offering/product loading, purchase flow, and entitlement checks via the `"XVisionBoardAI Pro"` entitlement. Source of truth for `SubscriptionType`.
- **`UserManager`** — Auth state, user profile, onboarding flag. Persists the `User` (email, goals, journal insights) to `KeychainStore` (production) — migrated off UserDefaults for PII safety — and the auth token in `KeychainTokenStore`; both use `InMemoryTokenStore` under DEBUG auto-login.
- **`VisionBoardManager`** — CRUD for `VisionBoard` objects; drives the real async AI-generation pipeline (Gemini text + parallel `FalAIService` image generation via `TaskGroup`, with cancellation cleanup and corrupt-file quarantine). Persists boards as JSON files in `Documents/VisionBoards`, one per board. Concurrent generations are rejected while `isGenerating` is true.

### Navigation flow

`ContentView` is the root router:
1. Onboarding (`OnboardingView`) — shown first run until `UserManager.hasCompletedOnboarding`
2. Auth wall (`WelcomeView` / `AuthViews`) — shown when `isLoggedIn == false`.
   Not actually a wall: "Continue without an account" calls
   `UserManager.continueAsGuest()`, which sets `isLoggedIn` with no credentials
   and flags `isGuest`. Nothing in the app needs an account (boards are
   device-local, subscriptions bill the Apple Account), and requiring signup was
   a Guideline 5.1.1(ii) risk. Guests convert via Profile → Create an Account.
3. Main app (`MainTabView`) — four tabs: Home, Create, Gallery, Profile

### Key patterns

- `UserManager.isLoggedIn` is the single auth gate. It is a plain `@Observable` property that mirrors itself into `UserDefaults` via `didSet`; `ContentView` reads it through `@Environment(UserManager.self)`. There is no `@AppStorage` anywhere in the app — do not reintroduce a second binding to the same key.
- All view models are `@MainActor`; async work uses `Task {}` / `await`.
- Dark-only UI — `preferredColorScheme(.dark)` is set on the root `Group` in `ContentView`. This is load-bearing, not cosmetic: the palette is hardcoded dark, so without it the status bar draws dark glyphs on a near-black background and all system chrome (alerts, keyboard, share sheet, date pickers) renders light over dark content. There is no `UIAppearance` styling; the tab and nav bars are unstyled system chrome.

### Design system (`Utils/ColorScheme.swift`)

All colors are in the "cosmic" palette (`Color.cosmicPurple`, `.cosmicBlack`, `.cosmicGold`, etc.). Reusable view modifiers: `.cosmicCard()`, `.cosmicButton(isEnabled:)`, `.pulsing()`, `.manifestationTitle()`, etc.

### Models

- `VisionBoard` — `Codable/Identifiable` struct; contains `[VisionBoardImage]`, `[String]` affirmations, `VisionBoardLayout` (grid3x3/collage/singlePoster), `VisionBoardStyle` (cinematic/luxurious/minimalist/natural/futuristic/artistic).
- `User` — `Codable/Identifiable` struct; owns `SubscriptionType` (.free / .pro) and `UserPreferences`.

### AI generation

`VisionBoardManager.createVisionBoard(...)` runs a real pipeline, not a stub:
affirmations from `GeminiTextService`, then images from `FalAIService` generated
in parallel with `withTaskGroup`, downloaded, written via `ImageStore`, and
persisted as JSON. It honours `Task.checkCancellation()` and cleans up written
files on cancel.

Requests route through a Cloudflare Worker proxy (`proxy/`, `APIConfig.usesProxy`)
authenticated with App Attest, so provider keys do not ship in the binary.
`Services/GeminiImageService.swift` used to be the one path that still expected a
direct in-binary key; it was dead code and has been deleted. Its `GeminiImageError`
enum was **not** dead — `GeminiTextService` and `VisionBoardManager` both throw it —
so it now lives at the top of `Services/GeminiTextService.swift` under its original
name. Don't be fooled by the "Image" in the name when grepping.

Generation realistically takes 30s-3min, so `CreateVisionBoardView` holds a
`UIApplication` background-task assertion for the duration and cancels its
`generationTask` in `.onDisappear`.

### Subscription products (RevenueCat)

A single "Pro" entitlement (`XVisionBoardAI Pro`) sold in three durations. All
must exist in App Store Connect and be attached to the entitlement + current
Offering in the RevenueCat dashboard. IDs are defined in `StoreManager`:

```
com.xvisionboardai.pro.weekly    — $4.99/wk
com.xvisionboardai.pro.monthly   — $9.99/mo
com.xvisionboardai.pro.yearly    — $49.99/yr, 3-day free trial
```

## Swift Concurrency Patterns

### AVFoundation + @MainActor
`CameraManager` is `@MainActor` but AVFoundation must run on a dedicated background queue. Pattern: capture `@MainActor` AVFoundation properties as local `let` constants before `sessionQueue.async`, pass them into the closure, and use `Task { @MainActor in }` for any UI updates from inside the closure. Always use `@preconcurrency import AVFoundation` to suppress `non-Sendable` type warnings — AVFoundation predates Swift 6 Sendable conformance.

### Agent worktrees
Swarm agent sessions leave worktrees in `.claude/worktrees/`. After any swarm run, check `git worktree list` and remove entries on commits already in `main`: `git worktree remove --force .claude/worktrees/<name>`.

### Health check shortcut
```bash
xcodebuild -project XVisionBoardAI.xcodeproj -scheme XVisionBoardAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED"
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

## API Keys & Secrets

**Never put API keys in `project.pbxproj` buildSettings.** They get committed to the public repo.

The correct pattern:
1. Keys live in `Secrets.xcconfig` (gitignored — never committed)
2. `project.pbxproj` references it via `baseConfigurationReference` for both Debug and Release
3. `Secrets.xcconfig.template` (committed) shows contributors what keys are needed

If a new API key is required, add it to `Secrets.xcconfig` and `Secrets.xcconfig.template`, then reference it as `$(KEY_NAME)` in Info.plist or Swift via `Bundle.main.infoDictionary`.

## Tests

`XVisionBoardAITests` is a Swift Testing unit bundle hosted by the app target,
run via the shared `XVisionBoardAI` scheme. Coverage is deliberately narrow: the
units that are fast and network-free.

- `ColorContrastTests` computes WCAG 2.1 relative luminance from the real token
  values and asserts every text token clears 4.5:1 on every surface. If you
  retune the palette and drop below AA, this fails.
- `ReminderScheduleTests` asserts the user's picked reminder time reaches the
  notification trigger.
- `GenerationConcurrencyTests` asserts a second concurrent `createVisionBoard`
  is rejected and does not disturb the in-flight run's state.
- `AccountDeletionTests` asserts `deleteAccount` actually wipes boards, so a
  deleted account's boards can't reappear for the next account on the device
  (Guideline 5.1.1(v)).
- `AIConsentTests` pins the third-party AI consent gate: denied by default,
  persisted across launch, **not** granted as a side effect of signing up, and
  withdrawn on account deletion (Guideline 5.1.2(i)).
- `GuestModeTests` pins the guest path (Guideline 5.1.1(ii)). The load-bearing
  case is "A guest session survives relaunch": `loadUserData()` treats a missing
  token as a dead session, so `continueAsGuest()` must store one even though a
  guest has nothing to authenticate. Without it, guests are silently returned to
  the welcome screen on the *next* launch — invisible in a single session.

**Three of these suites are destructive.** `AccountDeletionTests` and
`GuestModeTests` wipe `Documents/VisionBoards`, and `AIConsentTests` /
`GuestModeTests` mutate the real `UserDefaults` suite and Keychain (they save and
restore the keys they touch). Fine on a simulator; don't run them against a
device holding real data.

**`GenerationConcurrencyTests` has a `.timeLimit` for a reason.** With the
`isGenerating` guard in place these tests return in milliseconds because
`createVisionBoard` bails out before doing work. Remove the guard and they run a
real fal.ai generation instead — minutes per test, billed to your account. Don't
strip the time limit.

Not covered (needs UI automation this project doesn't have): the launch path,
IAP flows, App Attest, and Dynamic Type layout at accessibility sizes.
