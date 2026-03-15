# TrelloClone — Progress Log

Version history tracking each major milestone.

---

## v1.0 — Initial Commit
- SwiftUI board/list/card hierarchy
- Basic CRUD operations
- Full-viewport card detail with iA Writer typography

## v1.1 — List Drag-Drop
- Drag-and-drop reordering of lists within a board

## v1.2 — Image Attachments
- PhotosPicker integration for adding images to cards
- Thumbnail grid display in card detail view
- Local-only storage in `Documents/TrelloClone/attachments/`

## v1.3 — HyperTime Version History
- Timeline view showing board change history
- Snapshot-based undo/redo

## v2.0 — Ambient NaturalLanguage AI
- Automatic tag extraction via NaturalLanguage framework
- Sentiment analysis on card descriptions
- Smart list suggestions based on content

## v2.1 — OKLCH Colors, iCloud KVS Sync, Bounce Animations
- OKLCH perceptual color palette for boards and labels
- iCloud Key-Value Storage sync across devices
- Spring bounce animations on card interactions

## v2.2 — Fresh-Install Sync Fix
- **Bug**: Fresh installs couldn't receive iCloud data because `synchronize()` was called after the cache read, not before
- **Fix**: Pre-read synchronize + 2-second delayed retry + sample-data guard
- Structured logging via `os.Logger` in BoardStore
- Quota violation detection in iCloud KVS observers (BoardStore + HistoryStore)
- Entitlements config cleanup in `project.yml`
