# Contributing to Clarity

Thanks for your interest in contributing! Clarity is a small, focused macOS app —
contributions should keep it that way.

## Ground rules

- Keep the app **menu-bar first**. Do not introduce a normal application window.
- Keep **SwiftData** as the persistence layer. Do not add a second persistence store.
- Keep **`MenuBarExtra`** as the menu bar mechanism. Do not replace it with
  `NSStatusItem`, Electron, or a web view.
- Keep the UI **native**: use system materials, fonts, and controls. No fake glass,
  no heavy custom backgrounds.
- Preserve existing functionality: tasks, nudges, Pomodoro, and Siri/Shortcuts.

## Getting set up

1. Fork and clone the repository.
2. Open `Clarity.xcodeproj` in Xcode.
3. Build with the **Clarity** scheme.

## Conventions

- Swift concurrency is checked strictly (`SWIFT_STRICT_CONCURRENCY = complete`).
  Do not silence diagnostics with `@unchecked Sendable`.
- When touching SwiftData queries, prefer `@Query(sort: \ClarityTask.createdAt, ...)`
  and in-memory partitioning over sorting a `Bool` key path (see the note in
  `Views/Tasks/TasksView.swift`).
- Commit messages follow the
  [Conventional Commits](https://www.conventionalcommits.org/) style
  (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`).

## Before you submit

- Run a clean build and fix every compiler error and warning.
- Test in both Light and Dark appearance.
- Test task creation, completion, deletion, nudges, and Pomodoro transitions.
- Make sure the popover stays compact with few tasks and scrolls only the list with
  many tasks.

## Commit message format

```
<type>: <short summary>

<optional body>
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`, `style`, `test`.
