# TrelloClone Releases

A complete version history of TrelloClone, tracking every release from initial commit to latest.

---

## v2.3.0 — Theme System & Light Mode Default ✨ *Current Release*

**Release Date:** April 13, 2026

### What's New

- **🎨 New Theme System** — Complete overhaul of the theming architecture with a dedicated `ThemeStore`
- **☀️ Light Mode Default** — Beautiful warm paper aesthetic now loads by default for a fresh, clean look
- **🌗 Theme Toggle** — Quick-access theme picker in the toolbar with three modes:
  - **System** — Follows your device settings
  - **Light** — Warm paper tones with indigo accents
  - **Dark** — Warm charcoal with soft contrasts
- **💾 Persistent Preferences** — Your theme choice is saved and remembered across launches

### Technical Changes

- Added `ThemeStore.swift` — Observable state management for theme preferences
- Added `ThemePickerSheet` — Native SwiftUI bottom sheet for theme selection
- Updated `TrelloApp.swift` — Injected theme store with `.preferredColorScheme()` binding
- Enhanced `BoardSwitcherView` — Added theme toggle button and picker integration

### Design Notes

The light theme draws inspiration from iA Writer's editorial minimalism and Things' warm, inviting interface. Colors are tuned in OKLCH space for perceptually uniform contrast across both themes.

---

## v2.2.0 — Fresh-Install Sync Fix 🛠️

**Release Date:** March 2026

### What's New

- **🔧 Fresh-Install iCloud Sync** — Fixed a critical bug where new devices couldn't receive existing iCloud data
- **📊 Structured Logging** — Added `os.Logger` support for better debugging
- **⚠️ Quota Detection** — Monitors iCloud KVS quota violations

### Bug Fixes

**Problem:** On fresh installs, `synchronize()` was called *after* reading from the cache, causing the first read to always miss. This meant sample data would overwrite existing iCloud data.

**Solution:**
1. Pre-read `synchronize()` — primes the local cache before first read attempt
2. 2-second delayed retry — re-checks for data arriving from server
3. Sample-data guard — prevents sample data from writing to iCloud until user mutation

---

## v2.1.0 — OKLCH Colors, iCloud Sync & Bounce Animations 🎨☁️

**Release Date:** February 2026

### What's New

- **🎨 OKLCH Color System** — Perceptually uniform color palette using OKLCH color space
- **☁️ iCloud Key-Value Sync** — Seamless sync across all your Apple devices
- **✨ Bounce Animations** — Playful spring animations on card interactions
- **🏷️ Smart Tag Colors** — Deterministic OKLCH tag colors with golden-angle rotation

### Technical Changes

- `NSUbiquitousKeyValueStore` integration for cross-device sync
- `didChangeExternallyNotification` observers for live updates
- OKLCH → sRGB conversion for SwiftUI Color support

---

## v2.0.0 — Ambient NaturalLanguage AI 🤖

**Release Date:** January 2026

### What's New

- **🧠 Natural Language Processing** — Automatic tag extraction via Apple's NaturalLanguage framework
- **💭 Sentiment Analysis** — Emotional tone detection on card descriptions
- **💡 Smart Suggestions** — AI-powered list recommendations based on card content

### Features

- On-device processing — no data leaves your device
- Real-time analysis as you type
- Privacy-first AI using Apple's native frameworks

---

## v1.3.0 — HyperTime Version History ⏱️

**Release Date:** December 2025

### What's New

- **⏱️ Timeline View** — Visual history of all board changes
- **↩️ Snapshot-Based Undo** — Roll back to any previous state
- **📜 Activity Feed** — Chronological view of all mutations

### Features

- Track who did what and when
- Browse history by board
- Restore deleted cards and lists

---

## v1.2.0 — Image Attachments 📸

**Release Date:** November 2025

### What's New

- **📸 PhotosPicker Integration** — Native iOS photo selection
- **🖼️ Thumbnail Grid** — Visual attachment display in card detail
- **💾 Local Storage** — Images stored in `Documents/TrelloClone/attachments/`

### Technical Notes

- Image attachments are local-only (not synced via iCloud due to KVS size limits)
- Supports JPEG, PNG, and HEIC formats
- Automatic thumbnail generation

---

## v1.1.0 — List Drag-Drop ✋

**Release Date:** October 2025

### What's New

- **✋ Drag-and-Drop Lists** — Reorder lists within a board with haptic feedback
- **🎯 Drop Target Highlights** — Visual indicators for valid drop zones
- **⚡ Smooth Animations** — 60fps spring animations during reordering

---

## v1.0.0 — Initial Commit 🚀

**Release Date:** September 2025

### Core Features

- **📋 Board/List/Card Hierarchy** — Classic Kanban structure
- **📝 Full-Viewport Card Detail** — Distraction-free editing experience
- **✏️ iA Writer Typography** — Editorial-quality text rendering
- **🎨 Clean Minimalist Design** — Focus on your work, not the interface

### Technical Stack

- SwiftUI with iOS 17+ features
- `@Observable` macro for state management
- Universal app (iOS + macOS)

---

## Version History Summary

| Version | Date | Highlights |
|---------|------|------------|
| v2.3.0 | Apr 2026 | 🎨 Theme system, Light default |
| v2.2.0 | Mar 2026 | 🛠️ Fresh-install sync fix |
| v2.1.0 | Feb 2026 | 🎨 OKLCH colors, iCloud sync |
| v2.0.0 | Jan 2026 | 🤖 NaturalLanguage AI |
| v1.3.0 | Dec 2025 | ⏱️ Version history |
| v1.2.0 | Nov 2025 | 📸 Image attachments |
| v1.1.0 | Oct 2025 | ✋ List drag-drop |
| v1.0.0 | Sep 2025 | 🚀 Initial release |

---

## Roadmap

- **v2.4** — Board templates and import/export
- **v2.5** — Collaborative boards via CloudKit
- **v3.0** — Widgets and Live Activities

---

*Built with ❤️ using SwiftUI and flowdeck*
