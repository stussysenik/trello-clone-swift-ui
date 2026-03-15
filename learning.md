# Learning: iCloud KVS Fresh-Install Sync

A deep-dive into the race condition that prevented fresh Mac installs from receiving iPhone data, and how we fixed it.

---

## The Bug

`NSUbiquitousKeyValueStore` maintains a **local cache** that mirrors iCloud. On a device that has run the app before, this cache is warm — reads return data immediately. But on a fresh install, the cache starts **completely empty**.

The original `BoardStore.init()` did this:

```
1. Read from iCloud KVS cache          → empty (cache is cold)
2. Read from UserDefaults               → empty (fresh install)
3. Fall back to sample data             → ✅ boards = sampleData()
4. Call synchronize()                   → starts async pull from iCloud
5. User touches a card                  → save() writes sample data to iCloud
6. iCloud data arrives                  → too late, already overwritten
```

The critical mistake: **`synchronize()` was called after reading**, so the cache was never primed before the first read attempt. On a warm device this didn't matter (cache already had data), but on a fresh install it caused silent data loss.

## The Fix

A three-part solution:

### 1. Synchronize Before Read

```swift
init() {
    iCloudStore.synchronize()  // ← moved to TOP of init

    if let data = iCloudStore.data(forKey: Self.storageKey) ...
```

This primes the local cache before the first read. On subsequent launches (warm cache), data is available immediately. On first launch, it begins the async pull.

### 2. Delayed Retry

```swift
if loadedFromSample {
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
        self?.retryICloudLoad()
    }
}
```

Because `synchronize()` is **non-blocking** (it returns immediately and pulls data asynchronously), we can't guarantee data is available at init time. The 2-second retry catches data arriving from the server after the initial sync completes.

### 3. Sample-Data Guard

```swift
private var loadedFromSample = false
```

This flag prevents sample data from being written to iCloud. The `save()` method clears the flag on first user mutation, meaning:
- If iCloud data arrives before the user edits → it replaces sample data safely
- If the user edits before iCloud arrives → the user's intent is preserved
- Sample data is never pushed to iCloud unless the user actively changed it

## The Enabler: `NSUbiquitousKeyValueStore.synchronize()`

Key behaviors that make this work:

| Behavior | Implication |
|----------|-------------|
| `synchronize()` is **async** | Returns immediately; data arrives later via notification or cache refresh |
| `synchronize()` **primes the local cache** | Subsequent `data(forKey:)` reads pull from the now-warm cache |
| `didChangeExternallyNotification` fires on incoming data | Covers the case where data arrives after init |
| Cache persists across launches | Only the very first launch has the cold-cache problem |

## Key Insight

> KVS `synchronize()` is a **cache primer**, not a blocking fetch. It tells the system "start syncing now" and updates the local cache in the background. For first-launch scenarios where the cache is guaranteed cold, you need a retry mechanism because data won't be available at the moment you call it.

The fix ordering matters:

```
synchronize()     → "start pulling data"
read cache        → may still be empty on first launch
delayed retry     → catches data that arrived after sync started
observer          → catches data pushed from other devices at any time
```

## Additional Improvements

- **Structured logging** via `os.Logger` — replaces silent failures with visible log lines that appear in Console.app, making sync issues diagnosable without a debugger
- **Quota violation detection** — the iCloud KVS observer now checks `NSUbiquitousKeyValueStoreChangeReasonKey` for quota violations (1MB limit), logging a warning before data loss occurs
- **Entitlements cleanup** — moved KVS entitlement from `CODE_SIGN_ENTITLEMENTS` build setting to the structured `entitlements` block in `project.yml`
