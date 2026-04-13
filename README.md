<div align="center">

# ✨ FlowBoard

**The Kanban board that syncs. Beautifully simple, surprisingly powerful.**

[![iOS](https://img.shields.io/badge/iOS-17%2B-blue?style=flat&logo=apple)](https://apps.apple.com)
[![macOS](https://img.shields.io/badge/macOS-14%2B-blue?style=flat&logo=apple)](https://apps.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat&logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

*A SwiftUI Trello-style board manager with magical iCloud sync.*

[🚀 Download on the App Store](#) · [📖 Documentation](RELEASES.md) · [🐛 Report Issue](../../issues)

</div>

---

## 🎯 What is FlowBoard?

FlowBoard is the **Kanban board experience your projects deserve** — designed for people who want to stay organized without drowning in complexity. 

Whether you're planning a product launch, managing a content calendar, or just keeping track of your grocery list, FlowBoard adapts to your workflow with:

- ⚡ **Instant iCloud sync** across iPhone, iPad, and Mac
- 🎨 **Beautiful themes** — warm paper aesthetic by default
- 🤖 **AI-powered insights** — automatic tag extraction and sentiment analysis
- 📸 **Image attachments** — add photos to any card
- ⏱️ **Time travel** — full version history with undo/redo

---

## ✨ Features That Make You Smile

### ☁️ Seamless iCloud Sync
Your boards, lists, and cards sync instantly across all your devices. Start on your iPhone, finish on your Mac. No account setup, no configuration — it just works.

| Scenario | What Happens |
|----------|--------------|
| 📱➡️💻 Create on iPhone | Appears on Mac in seconds |
| ✈️ Work offline | Changes sync when you're back online |
| 🔄 Edit on two devices | Last-write-wins, no conflicts |

### 🎨 Three Beautiful Themes

Choose your vibe:

- **☀️ Light** — Warm paper tones with calm indigo accents (default)
- **🌙 Dark** — Warm charcoal for late-night focus sessions  
- **⚙️ System** — Follows your device automatically

*Colors tuned in OKLCH space for perceptually perfect contrast.*

### 🤖 Built-in AI Assistant

Your cards are automatically analyzed using on-device NaturalLanguage framework:

- **🏷️ Smart Tags** — Auto-extract keywords from descriptions
- **💭 Sentiment Analysis** — Know the tone at a glance
- **💡 List Suggestions** — AI suggests where cards belong

*All processing happens on your device. Zero data leaves your phone.*

### 📸 Rich Card Details

Every card is a canvas:

- 📝 **Long-form descriptions** with iA Writer-inspired typography
- 🏷️ **Color-coded tags** with OKLCH perceptual colors
- 📎 **Image attachments** via native PhotosPicker
- 📅 **Due dates** for time-sensitive tasks
- ⏱️ **Full history** — see every change, ever

### ✋ Intuitive Drag & Drop

Reorganize with your fingers:

- Move cards between lists
- Reorder lists within boards
- Cross-board card migration
- Haptic feedback on every drop

---

## 📱 Screenshots

<div align="center">

| Board Grid | Kanban Board | Card Detail |
|:----------:|:------------:|:-----------:|
| *All your boards* | *Drag & drop lists* | *Rich editing* |

</div>

---

## 🛠️ Technical Highlights

```swift
// Built with modern SwiftUI
@Observable class BoardStore { }

// OKLCH color space for perfect contrast
Color.oklch(lightness: 0.98, chroma: 0.004, hue: 85)

// iCloud KVS for instant sync
NSUbiquitousKeyValueStore.default

// On-device NaturalLanguage processing
NLTagger(tagSchemes: [.sentimentScore, .nameType])
```

### Architecture

- **Swift 5.9** with iOS 17+ `@Observable` macro
- **Universal App** — iOS, iPadOS, and macOS native
- **Privacy-First** — No servers, no tracking, no accounts
- **Offline-First** — Works without internet, syncs when available

---

## 🚀 Getting Started

### Download

Available on the App Store for iPhone, iPad, and Mac.

[📲 Download FlowBoard](#)

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/flowboard.git
cd flowboard

# Generate Xcode project with xcodegen
./setup.sh

# Or use flowdeck for device builds
flowdeck build --device senik
```

### Requirements

- iOS 17.0+ / iPadOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- iCloud account (for sync)

---

## 📋 Version History

| Version | Release | Highlights |
|---------|---------|------------|
| **v2.3** | Apr 2026 | 🎨 Theme system, Light mode default |
| v2.2 | Mar 2026 | 🛠️ Fresh-install sync fixes |
| v2.1 | Feb 2026 | 🎨 OKLCH colors, iCloud sync |
| v2.0 | Jan 2026 | 🤖 NaturalLanguage AI |
| v1.3 | Dec 2025 | ⏱️ Version history |
| v1.2 | Nov 2025 | 📸 Image attachments |
| v1.1 | Oct 2025 | ✋ List drag-drop |
| v1.0 | Sep 2025 | 🚀 Initial release |

[See full release notes →](RELEASES.md)

---

## 🎯 Use Cases

FlowBoard shines for:

- **📦 Product Teams** — Sprint planning, backlog grooming, release tracking
- **✍️ Content Creators** — Editorial calendars, idea pipelines, publishing workflows
- **🏠 Personal Projects** — Home renovations, trip planning, hobby tracking
- **📚 Students** — Assignment tracking, research projects, study schedules
- **💼 Freelancers** — Client management, project deliverables, invoicing status

---

## 💬 What Users Say

> *"Finally, a Kanban app that doesn't make me feel like I'm configuring a spaceship."*
> — Early Beta User

> *"The iCloud sync is magical. I add a card on my phone and it's there on my Mac instantly."*
> — Product Manager

> *"That warm paper aesthetic... *chef's kiss* — my eyes thank you."*
> — Designer

---

## 🤝 Contributing

We welcome contributions! Here's how to get involved:

1. 🍴 Fork the repository
2. 🌿 Create a feature branch (`git checkout -b feature/amazing-feature`)
3. 💾 Commit your changes (`git commit -m 'Add amazing feature'`)
4. 📤 Push to the branch (`git push origin feature/amazing-feature`)
5. 🔃 Open a Pull Request

Please read our [Contributing Guide](CONTRIBUTING.md) for details.

---

## 📜 License

FlowBoard is released under the MIT License. See [LICENSE](LICENSE) for details.

```
MIT License

Copyright (c) 2026 FlowBoard Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

## 🙏 Acknowledgments

- **iA Writer** for typography inspiration
- **Things 3** for the warm, inviting design language
- **Notion** for interaction patterns
- **Apple** for the incredible SwiftUI framework

---

<div align="center">

**Made with ❤️ in SwiftUI**

[⬆ Back to Top](#-flowboard)

</div>

---

*FlowBoard is not affiliated with Trello, Atlassian, or any other Kanban product. It's a personal project built with care.*
