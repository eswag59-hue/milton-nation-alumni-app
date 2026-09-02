# Known concurrency issues (found 2026-08-25 when CI was repaired)

CI had been broken since mid-July, so these were never surfaced. They are
**pre-existing**, not introduced by the video-portfolio work — the build simply
never got far enough to report them. None is urgent; all are worth fixing before
the project moves to the Swift 6 language mode, where each becomes a hard error.

## Why the tests were flaky

Swift Testing runs suites **in parallel** by default. Several suites share
mutable singletons, so they raced each other and a different random handful
failed on every run — including `OfflineCacheTests`, which no recent change
touched. CI now passes `-parallel-testing-enabled NO`, which makes runs
deterministic. That is a containment measure, not a fix: the races below are
still real at runtime, where the app is genuinely concurrent.

## The races the compiler flags

| File | Line | Warning |
|---|---|---|
| `ViewModels/CommunityViewModel.swift` | 98 | captured var `fetched` referenced in concurrently-executing code |
| `ViewModels/CommunityViewModel.swift` | 488, 490 | captured var `updated` referenced in concurrently-executing code |
| `ViewModels/AppViewModel.swift` | 277 | captured var `user` referenced in concurrently-executing code |
| `ViewModels/ChatViewModel.swift` | 240 | captured var `mediaURL` referenced in concurrently-executing code |
| `Services/DataService.swift` | 864 | `MockMeetingService.meetings` is mutable on a `Sendable` class |
| `Services/OfflineCacheService.swift` | 20 | `fileManager` has non-sendable type `FileManager` |

The `captured var` cases follow one pattern: a `var` is declared outside a
`Task`/`MainActor.run` block and mutated or read inside it. The usual fix is to
capture an immutable copy (`let snapshot = value`) and pass that in, or move the
mutation onto the actor that owns the state.

`OfflineCacheService` writes files from whatever context calls it. It wants
either an internal serial queue or actor isolation — that one has real-world
consequences beyond tests, since chat, posts and profile all cache through it.

## Unrelated smaller finds in the same build

- `Milton_Nation_Alumni_AppApp.swift:228` — `await securityService.evaluate()`
  where nothing async happens; the `await` is a no-op.
- `SupabaseDataService.swift:857` — `??` applied twice to `nextOccurrence`,
  which is non-optional, so both defaults are dead code. Worth checking whether
  the field was meant to be optional, because the sort silently ignores it.

## Suggested order

1. `OfflineCacheService` isolation (touches the most user-visible data).
2. The four `captured var` sites (mechanical, low risk).
3. `MockMeetingService` (test-only surface).
4. Re-enable parallel testing and confirm CI stays green.
