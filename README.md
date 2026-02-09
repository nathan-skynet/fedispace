<p align="center">
  <img src="https://raw.githubusercontent.com/nathan-skynet/fedispace/master/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="120" alt="FediSpace Logo"/>
</p>

<h1 align="center">🚀 FediSpace</h1>

<p align="center">
  <strong>An AI-enhanced, modern Pixelfed client built with Flutter</strong>
</p>

<p align="center">
  <a href="https://github.com/nathan-skynet/fedispace/releases"><img src="https://img.shields.io/github/v/release/nathan-skynet/fedispace?style=for-the-badge&color=00d4ff&labelColor=0a0e1a" alt="Release"></a>
  <a href="https://github.com/nathan-skynet/fedispace/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge&color=00d4ff&labelColor=0a0e1a" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white&labelColor=0a0e1a" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white&labelColor=0a0e1a" alt="Dart"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/🤖_AI_Powered-OpenAI-ff6b6b?style=for-the-badge&labelColor=0a0e1a" alt="AI Powered">
  <img src="https://img.shields.io/badge/🌍_16_Languages-Supported-success?style=for-the-badge&color=00ff88&labelColor=0a0e1a" alt="16 Languages">
  <img src="https://img.shields.io/badge/📱_Android-Ready-success?style=for-the-badge&color=3ddc84&labelColor=0a0e1a" alt="Android">
  <img src="https://img.shields.io/badge/🔔_Push_Notifications-UnifiedPush-blueviolet?style=for-the-badge&labelColor=0a0e1a" alt="Push Notifications">
</p>

---

## ✨ About

**FediSpace** is an **AI-supercharged**, Instagram-inspired client for [Pixelfed](https://pixelfed.org/) — the federated, privacy-friendly image sharing platform. It takes the original Pixelfed experience and **boosts it with artificial intelligence**: real-time post translation, AI-powered image editing, smart content discovery, and more — all wrapped in a **cyberpunk-inspired dark theme** with smooth animations.

> *The Fediverse has never looked this good — or this smart.*

---

## 🤖 AI-Powered Features

FediSpace goes beyond a standard Pixelfed client by integrating **AI at the core of the experience**:

| Feature | What it does |
|---|---|
| 🌐 **Auto-Translate Posts** | Instantly translate any post into your language using OpenAI — read the global Fediverse without language barriers |
| 🎨 **AI Image Editing** | Describe what you want changed and AI transforms your photos before posting — creative filters, style transfer, enhancements |
| 🔄 **Smart Translation Settings** | Configure auto-translate for all posts, choose your target language, or translate on demand |
| 🌍 **16 Language UI** | The entire app interface adapts to your language — powered by a comprehensive i18n system |

> **How it works:** FediSpace connects to the OpenAI API (configurable in Settings) to provide translation and image editing capabilities. Your API key stays on your device — no data passes through third-party servers.

---

## 🎨 Features

### 📸 Timeline & Posts
- **Instagram-style feed** with infinite scroll and blur hash placeholders
- **Full-screen image viewer** with pinch-to-zoom
- **Video playback** with custom player controls
- **Carousel/gallery posts** support
- **Like, comment, share, bookmark** — full social interactions
- **Post detail page** with threaded replies
- **View edit history** of modified posts

### 📖 Stories
- **Story bar** with avatar bubbles matching Instagram UX
- **Full-screen story viewer** with progress indicators
- **Story creation** — capture from camera or pick from gallery
- **AI-powered image editing** with creative filters
- **Viewer count and list** for your own stories
- **Story replies** — interact directly with stories
- **Auto-advance** and tap-to-skip navigation

### 🔍 Discover & Search
- **Explore page** with trending content
- **User search** with real-time results
- **Hashtag search** and tag-based timelines
- **Account discovery** across the Fediverse

### 💬 Direct Messages
- **Conversation list** with unread indicators
- **Real-time messaging** interface
- **Image sharing** in conversations
- **New message** with user search and recipient picker
- **Delete conversations** with confirmation dialogs

### 🔔 Notifications
- **Real-time push notifications** via [UnifiedPush](https://unifiedpush.org/)
- **Notification types**: follows, likes, boosts, mentions, polls
- **Clear all** with confirmation
- **Tap to navigate** directly to relevant content

### 👤 Profile & Social
- **Rich user profiles** with stats (posts, followers, following)
- **Profile editing** capabilities
- **Follow / Unfollow / Mute / Block** actions
- **Report users** with reason description
- **Follow requests** management (accept/reject)
- **Followers & following lists** with pagination

### ⚙️ Settings & Privacy
- **Content filters** — create and manage keyword filters
- **Muted & blocked accounts** management
- **Domain blocks** — block entire instances
- **Bookmarks** — save posts for later
- **Liked posts** — view your like history
- **Archived posts** — archive and restore posts
- **Collections** — organize posts into collections

### 🌍 Internationalization (i18n)
Full multi-language support with **16 languages**:

| | Language | | Language | | Language | | Language |
|---|---|---|---|---|---|---|---|
| 🇬🇧 | English | 🇫🇷 | Français | 🇪🇸 | Español | 🇩🇪 | Deutsch |
| 🇮🇹 | Italiano | 🇧🇷 | Português | 🇳🇱 | Nederlands | 🇷🇺 | Русский |
| 🇨🇳 | 中文 | 🇯🇵 | 日本語 | 🇰🇷 | 한국어 | 🇸🇦 | العربية |
| 🇮🇳 | हिन्दी | 🇹🇷 | Türkçe | 🇵🇱 | Polski | 🇺🇦 | Українська |

- **In-app language picker** — switch languages instantly
- **System locale detection** — auto-detects device language
- **Persistent preference** — remembers your language choice

### 🎭 UI & Design
- **Cyberpunk dark theme** — neon accents, glassmorphism, gradients
- **Instagram-inspired layout** — familiar, intuitive navigation
- **Custom bottom navigation** with animated transitions
- **Pull-to-refresh** on all list views
- **Smooth loading indicators** and skeleton screens
- **Responsive design** across different screen sizes

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter / Dart** | Cross-platform framework |
| **OAuth2** | Secure authentication |
| **UnifiedPush** | Decentralized push notifications |
| **SharedPreferences** | Local settings persistence |
| **CachedNetworkImage** | Image caching & blur hash |
| **Camera** | Photo & video capture |
| **Audioplayers** | Audio playback |
| **Flutter Secure Storage** | Encrypted credential storage |

---

## 📦 Installation

### Prerequisites
- Flutter SDK `>=2.18.0`
- Android SDK (API 21+)
- A Pixelfed instance account

### Build from source

```bash
# Clone the repository
git clone https://github.com/nathan-skynet/fedispace.git
cd fedispace

# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

### Download
Check the [Releases](https://github.com/nathan-skynet/fedispace/releases) page for pre-built APKs.

---

## 🏗️ Project Structure

```
lib/
├── core/                    # API, auth, notifications, logging
│   ├── api.dart             # Pixelfed API service
│   ├── notification.dart    # Push notification handling
│   └── logger.dart          # App-wide logging
├── l10n/                    # Internationalization
│   ├── app_localizations.dart
│   └── translations.dart    # 16 language maps
├── models/                  # Data models
│   ├── account.dart
│   ├── status.dart
│   ├── story.dart
│   └── ...
├── routes/                  # Pages & screens
│   ├── bookmarks/
│   ├── followers/
│   ├── liked/
│   ├── messages/            # DMs, conversations
│   ├── notifications/
│   ├── post/                # Post detail, creation
│   ├── profile/             # Profile, collections, archives
│   ├── search/
│   ├── settings/            # Settings, filters, blocks
│   └── timeline/
├── themes/
│   └── cyberpunk_theme.dart # Custom dark theme
├── widgets/                 # Reusable components
│   ├── instagram_post_card.dart
│   ├── story_bar.dart
│   ├── story_viewer.dart
│   └── ...
└── main.dart                # App entry point
```

---

## 🤝 Contributing

**Everyone is welcome to contribute!**

| 🎨 **Designers** | 💻 **Developers** | 🌍 **Translators** | 🐛 **Testers** |
|---|---|---|---|
| Help improve UI/UX and animations | Pick an issue and submit a PR | Add or improve language translations | Report bugs and verify fixes |

### How to contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feat/amazing-feature`)
3. **Commit** your changes (`git commit -m 'feat: Add amazing feature'`)
4. **Push** to the branch (`git push origin feat/amazing-feature`)
5. **Open** a Pull Request

---

## 📜 Credits

| Resource | Description |
|---|---|
| [Pixelfed](https://pixelfed.org/) | The federated image sharing platform |
| [UnifiedPush](https://unifiedpush.org/) | Decentralized push notification protocol |
| [Feathr](https://github.com/feathr-space/feathr) | Original project base |
| [Drissas](https://drissas.com/tuto-flutter-instagram) | Stories & Posts inspiration |

> A huge thank you to **[Dansup](https://pixelfed.social/dansup)** — the creator of Pixelfed — for building an amazing platform for the Fediverse. 💜

---

## 📄 License

This project is licensed under the **[MIT License](https://opensource.org/licenses/MIT)** — free and open source.

```
MIT License — Copyright (c) 2024 nathan-skynet

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.
```

---

<p align="center">
  <sub>Built with ❤️ for the Fediverse</sub><br>
  <sub>⭐ Star this repo if you find it useful!</sub>
</p>
