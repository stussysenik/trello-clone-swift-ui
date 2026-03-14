# TrelloClone

A SwiftUI Trello-style board manager for iOS and macOS with iCloud sync.

## Data Sync

TrelloClone uses **`NSUbiquitousKeyValueStore`** (iCloud Key-Value Storage) to sync boards, lists, and cards across all devices signed into the same iCloud account.

### How it works

Every mutation (create, update, delete, move) triggers a `save()` that:

1. Encodes the entire boards array as JSON
2. Writes to **iCloud KVS** (synced across devices)
3. Writes to **UserDefaults** (local fallback for offline use)

Other devices receive the update via `didChangeExternallyNotification` and reload automatically.

### Data persistence

| Scenario | Boards & Cards | Image Attachments |
|----------|---------------|-------------------|
| App running normally | iCloud + local | Local only |
| Device offline | Local (syncs when back online) | Local only |
| App deleted & reinstalled | Restored from iCloud | Lost |
| iCloud sign-out | Lost (local copy also wiped) | Lost |

### Conflict resolution

The sync model is **last-write-wins** at the whole-blob level. If two devices edit at the same time, the last one to sync overwrites the other. There is no merge or soft-delete/trash — deletions propagate to all devices permanently.

### Limits

- **1 MB total** storage for iCloud KVS (sufficient for typical board usage, not suited for thousands of cards)
- **Image attachments are local-only** — stored in `Documents/TrelloClone/attachments/`, not synced via iCloud
