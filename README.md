# XVisionBoardAI

XVisionBoardAI is a SwiftUI-based iOS application that helps you create and manage
AI-generated vision boards. The app guides users through onboarding, allows them
to build boards with personalized images and affirmations, and integrates StoreKit
for in-app subscriptions.

## Features

- **Onboarding** – Introduces new users to the app experience.
- **Vision Board Creation** – Capture or generate images and affirmations for your board.
- **Gallery & Detail Views** – Browse, view, and manage saved boards.
- **Profile Management** – Update user information and preferences.
- **StoreKit Integration** – Handle in-app purchases and subscriptions.

## Getting Started

1. Open the project in Xcode (Xcode 15 or later recommended).
2. Select the `XVisionBoardAI` target.
3. Build and run the app on an iOS 17 simulator or device.

### Sora API (video generation)

Sora-powered video previews are supported through the `SoraAPIClient`. To enable them, provide credentials via either **Info.plist** entries or environment variables:

- `SORA_API_KEY` (required)
- `SORA_BASE_URL` (defaults to `https://api.openai.com/v1`)
- `SORA_ORG_ID` (optional)
- `SORA_PROJECT_ID` (optional)

Without these values the app will continue to work, but Sora video generation buttons will show a configuration error.

## Contributing

Contributions are welcome! Feel free to fork the repository and open a pull request with your changes.

## License

This project is released under the MIT License. See the `LICENSE` file for more information if available.
