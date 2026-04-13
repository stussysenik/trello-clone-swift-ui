# FlowBoard — Progress Log

Version history tracking each major milestone.

---

## v2.3 — Theme System & Light Mode Default 🎨☀️

**Release Date:** April 13, 2026

### New Features
- **Theme System** — Complete theming architecture with `ThemeStore`
- **Light Mode Default** — Beautiful warm paper aesthetic as default
- **Theme Toggle** — Quick-access picker with System/Light/Dark modes
- **Persistent Preferences** — Theme choice saved across launches

### Technical Changes
- Added `ThemeStore.swift` — Observable theme state management
- Added `ThemePickerSheet` — Native SwiftUI bottom sheet UI
- Updated `TrelloApp.swift` — Theme injection with `.preferredColorScheme()`
- Enhanced `BoardSwitcherView` — Theme toggle button and picker integration

---

## v2.2 — Fresh-Install Sync Fix 🛠️

- **Bug**: Fresh installs couldn't receive iCloud data because `synchronize()` was called after the cache read, not before
- **Fix**: Pre-read synchronize + 2-second delayed retry + sample-data guard
- Structured logging via `os.Logger` in BoardStore
- Quota violation detection in iCloud KVS observers (BoardStore + HistoryStore)
- Entitlements config cleanup in `project.yml`

---

## v2.1 — OKLCH Colors, iCloud KVS Sync, Bounce Animations 🎨☁️

- OKLCH perceptual color palette for boards and labels
- iCloud Key-Value Storage sync across devices
- Spring bounce animations on card interactions

---

## v2.0 — Ambient NaturalLanguage AI 🤖

- Automatic tag extraction via NaturalLanguage framework
- Sentiment analysis on card descriptions
- Smart list suggestions based on content

---

## v1.3 — HyperTime Version History ⏱️

- Timeline view showing board change history
- Snapshot-based undo/redo

---

## v1.2 — Image Attachments 📸

- PhotosPicker integration for adding images to cards
- Thumbnail grid display in card detail view
- Local-only storage in `Documents/TrelloClone/attachments/`

---

## v1.1 — List Drag-Drop ✋

- Drag-and-drop reordering of lists within a board

---

## v1.0 — Initial Commit 🚀

- SwiftUI board/list/card hierarchy
- Basic CRUD operations
- Full-viewport card detail with iA Writer typography
