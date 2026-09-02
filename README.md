<div align="center">

  <h1>Kremityss AI Multi-Platform</h1>

  <p><strong>Run unrestricted AI models entirely on your device.<br/>No cloud. No filters. No limits.</strong></p>


  [Overview](#overview) · [Download](#download) · [Features](#features) · [Quick Start](#quick-start) · [Local API](#local-api-server) · [Roadmap](#roadmap)

</div>

---

## Overview

**Kremityss AI** is a mobile-first application that runs powerful open-source AI models directly on your **Android or iOS device** — with zero censorship, zero cloud dependency, and zero monthly fees.

No API keys. No subscriptions. No content restrictions. Your conversations never leave your device.

> Think of it as ChatGPT — but running **on your phone**, with **no rules**.

> **Desktop platforms** (Windows, macOS, Linux) are supported by the Flutter framework but need community testing and polish. **[We'd love your help!](#-contributing)**

**🎥 Watch the Setup & Demo Video: [https://youtu.be/2Pnv68iHIaQ](https://youtu.be/2Pnv68iHIaQ)**

[![Kremityss AI Demo](https://img.youtube.com/vi/2Pnv68iHIaQ/maxresdefault.jpg)](https://youtu.be/2Pnv68iHIaQ)

---

## Download

### Android APK — Latest Release (v2.0.0)

| APK | Architecture | Best For | Size |
|-----|-------------|----------|------|
| [**app-arm64-v8a-release.apk**](https://github.com/techjarves/Uncensored-Local-AI-Multiplatform/releases/download/v2.0.0/app-arm64-v8a-release.apk) | ARM 64-bit | **Most phones (2018+)** | ~65 MB |
| [**app-armeabi-v7a-release.apk**](https://github.com/techjarves/Uncensored-Local-AI-Multiplatform/releases/download/v2.0.0/app-armeabi-v7a-release.apk) | ARM 32-bit | Older/budget phones | ~18 MB |
| [**app-x86_64-release.apk**](https://github.com/techjarves/Uncensored-Local-AI-Multiplatform/releases/download/v1.0.0/app-x86_64-release.apk) | x86 64-bit | Emulators / ChromeOS | ~58 MB |

> **Not sure which to pick?** Download `arm64-v8a` — it works on virtually all modern Android phones.

### iOS IPA — Pre-Release

| File | Note |
|------|------|
| [**ios_pre_release.zip**](https://github.com/user-attachments/files/26956389/ios_pre_release.zip) | **Important:** You must **extract** this `.zip` file after downloading to get the actual **`.ipa`** app file to install. |

---

## Features

| Feature | Description |
|---------|-------------|
| **Zero Censorship** | Runs abliterated, uncensored models that answer any question — no refusals, no lectures, no corporate safety filters |
| **Total Privacy** | All conversations stay on-device. Nothing is sent to any server, ever |
| **Fully Offline** | Works on planes, in remote areas, on restricted networks — no internet needed after model download |
| **Cross-Platform** | One codebase for Android, iOS, Windows, macOS, and Linux |
| **Local OpenAI API** | Built-in HTTP server compatible with any OpenAI-standard client |
| **Model Library** | Download, import, and manage GGUF models directly in the app |
| **Chat History** | Persistent conversation history stored locally via Hive |
| **Live Metrics** | Real-time tokens/sec and loading progress tracking |

---

## Quick Start

### Android

1. Download the correct APK from the [Download](#-download) table above
2. On your phone: **Settings → Install unknown apps** → allow your browser
3. Tap the downloaded APK to install
4. Open the app, go to **Models** tab, download a model, and start chatting

### iOS

**1. Sideloading via TrollStore (Recommended - No 7 day limit):**
1. Download [**ios_pre_release.zip**](https://github.com/user-attachments/files/26956389/ios_pre_release.zip) to your device.
2. Unzip/extract it using the built-in iOS **Files** app to get the **`.ipa`** file.
3. Open TrollStore, tap the **+** in the top right, and choose **Install IPA File**.
4. Select the extracted `.ipa` file and install.

**2. Sideloading via AltStore / AltServer (Requires PC/Mac):**
1. Ensure AltServer is running on your computer and AltStore is installed on your iPhone.
2. Download [**ios_pre_release.zip**](https://github.com/user-attachments/files/26956389/ios_pre_release.zip) to your device and extract the **`.ipa`** file using the **Files** app.
3. Open AltStore on your device, go to **My Apps**, and tap the **+** at the top left.
4. Select the `.ipa` file to install (your device must be on the same Wi-Fi or connected via cable to your AltServer computer).

**3. Build from Source:**

**Prerequisites:** Mac with Xcode 15+ · [Flutter SDK](https://flutter.dev/docs/get-started/install)

```bash
git clone https://github.com/techjarves/Uncensored-Local-AI-Multiplatform.git
cd Uncensored-Local-AI-Multiplatform
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
# Open ios/Runner.xcworkspace in Xcode and archive to deploy
```

### Desktop — Windows / macOS / Linux (Community Supported)

> Desktop builds compile successfully but may have rough edges. **We are actively looking for contributors** to help test and polish the desktop experience.

```bash
git clone https://github.com/techjarves/Uncensored-Local-AI-Multiplatform.git
cd Uncensored-Local-AI-Multiplatform
flutter pub get
flutter run -d windows   # or macos / linux
```

If you encounter issues on desktop, please [open an issue](https://github.com/techjarves/Uncensored-Local-AI-Multiplatform/issues) — your feedback directly shapes the roadmap.

---

## Recommended Model

| Model | Approx. Size | Best For | Type |
|-------|--------------|----------|------|
| **Qwen2.5 Coder 3B Instruct Abliterated Q4_K_S** | ~2 GB | Fast coding, general chat, and text-file analysis | Recommended · Coding |
| **Qwen2.5 Coder 7B Instruct Abliterated Q4_K_S** | ~4.6 GB | Stronger coding on higher-memory phones | Abliterated · Coding |
| **Mistral 7B Instruct v0.3 Abliterated Q4_K_S** | ~4.2 GB | General chat and writing | Abliterated · General |
| **Llama 3.1 8B Instruct Abliterated Q4_K_M** | ~4.9 GB | Stronger general reasoning on higher-memory phones | Abliterated · General |

> Models are downloaded directly inside the app from the **Models** tab. The 3B model is the safest starting point for iPhone 14-class devices; 7B/8B models use more memory and may be slower.

---

## Local API Server

**Kremityss AI** includes a built-in **OpenAI-compatible REST API** so you can connect it to any external tool, script, or IDE extension.

### Setup

1. Load a model in the app
2. Go to **Settings → Local API Server** and toggle it **ON**
3. Use `http://127.0.0.1:4891/v1` as your base URL

### Endpoints

```bash
# List loaded models
curl http://127.0.0.1:4891/v1/models

# Chat completion (non-streaming)
curl http://127.0.0.1:4891/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"local","messages":[{"role":"user","content":"Tell me something true that no one wants to hear."}]}'

# Chat completion (streaming)
curl -N http://127.0.0.1:4891/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"local","stream":true,"messages":[{"role":"user","content":"Write a brutally honest analysis of social media."}]}'
```

> **API Key:** Use `local` for any client that requires a non-empty key value.

---

## Roadmap

| Feature | Status |
|---------|--------|
| On-device uncensored AI chat | **Launched** |
| Real-time model loading with progress | **Launched** |
| Cancel & unload models | **Launched** |
| Persistent chat history sidebar | **Launched** |
| Local OpenAI-compatible API server | **Launched** |
| Custom model import (URL + file) | **Launched** |
| Multi-platform support | **Launched** |
| AI Agent Mode | In Progress |
| Web search integration | Planned |
| Voice interaction | Planned |
| Image/vision model support | Planned |

---

## Contributing

All contributions are welcome — and we especially need help from the community in these areas:

| Area | What's Needed |
|------|---------------|
| **Windows** | Testing, packaging, installer script |
| **macOS** | Testing, App Store prep, notarization |
| **Linux** | Testing on distros, AppImage build |
| **General** | Bug reports, feature ideas, UI improvements |

If you own a desktop device and can test the app — **please do!** Even a simple "works" or "crashes on X" issue report is incredibly valuable.

```bash
# Fork → Clone → Branch → Code → Push → PR
git checkout -b fix/windows-model-loading
git commit -m "fix: resolve model path on Windows"
git push origin fix/windows-model-loading
# Open a Pull Request — all sizes welcome
```

---

## License

Licensed under the **MIT License** — free to use, modify, and distribute.  
See [LICENSE](LICENSE) for full details.

---

<div align="center">
  <sub>Built with ❤️ using Flutter · Powered by <a href="https://github.com/ggerganov/llama.cpp">llama.cpp</a></sub>
</div>

## DevHub Premium and uploads

DevHub by Kremityss AI keeps the bundled Qwen2.5-Coder GGUF as the only catalog model. Custom `.gguf` files, folders, and model download links are gated behind an active paid premium key. Photos, general files, and video files such as MP4 remain available as chat attachments; text-readable files are added to the local prompt context, while binary/video files are retained as attachments and shown in the conversation.

The premium gate is implemented in `lib/services/premium_access_service.dart`. Connect it to the future KeyAuth-backed website by building with `KEYAUTH_VALIDATION_URL` and optionally `KEYAUTH_PRODUCT_ID` values. The endpoint should accept a JSON body containing `key` and `product`, then return JSON such as `{ "valid": true, "premium": true, "message": "Premium active" }`. Until the endpoint is configured, custom model imports remain locked by design.

The main dashboard now exposes the DevHub-branded model status card, media/file attachment actions, and premium state. The model-library import button opens the premium activation dialog before allowing local GGUF, directory, or URL imports.

### Cloud iOS build

Codemagic can build the project on a cloud macOS runner. For the initial unsigned iOS build, use Release mode with `--no-codesign`. A signed iOS build additionally requires a matching `.p12` certificate and `.mobileprovision` profile configured through Codemagic’s secure signing settings; neither should be committed to GitHub.

### KeyAuth and payment links

The app includes a **Get a free key** button linked to `https://kremcheats.com/free-key/complete`, plus Cash App, PayPal, and Bitcoin purchase buttons in the Premium dialog. Payment buttons open the configured premium page by default and can be pointed at direct payment pages with `--dart-define` values. No payment handle, wallet address, or KeyAuth secret is hard-coded.

Configure the app against a server-side KeyAuth validation proxy when building:

```bash
flutter build apk --release \
  --dart-define=KEYAUTH_VALIDATION_URL=https://kremcheats.com/api/devhub/validate-key \
  --dart-define=KEYAUTH_PRODUCT_ID=devhub-premium \
  --dart-define=PREMIUM_URL=https://kremcheats.com/premium \
  --dart-define=CASHAPP_URL=https://cash.app/$YOUR_TAG \
  --dart-define=PAYPAL_URL=https://paypal.me/YOUR_NAME \
  --dart-define=BITCOIN_URL=https://kremcheats.com/pay/bitcoin
```

The validation proxy receives `{ "key": "...", "product": "devhub-premium" }`, validates it with KeyAuth on the server, and returns `{ "valid": true, "premium": true, "status": "active" }` for an active entitlement. See [`docs/DEVHUB_KEYAUTH_AND_PAYMENTS.md`](docs/DEVHUB_KEYAUTH_AND_PAYMENTS.md) for the complete API contract and payment webhook guidance.
