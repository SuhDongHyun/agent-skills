# Global Agent Instructions

Prefer minimal, maintainable changes. Do not add optional features unless explicitly requested.
Use skills selectively. For small edits, avoid heavy workflows.

## Superpowers

- `systematic-debugging`: bugs, failing tests, API/DB errors, PySpark issues, unclear root causes.
- `brainstorming`: vague requirements, UI direction, API design, or analysis scope.
- `writing-plans`: multi-file changes or backend/frontend/data-flow changes.
- `executing-plans`: implementing a defined plan.
- `verification-before-completion`: before saying work is done.
- `requesting-code-review`: after meaningful code changes.

## gstack

Use only for deeper review, QA, browser validation, or risky operations.

- `/investigate`: difficult cross-stack bugs.
- `/review`: before commits, PRs, or risky changes.
- `/qa-only`: frontend/browser issue report without edits.
- `/qa`: browser-based frontend testing and fixes.
- `/design-review`: React UI, layout, spacing, usability, visual polish.
- `/browse`: real browser navigation or screenshots.
- `/health`: tests, lint, typecheck, dead code, dependencies.
- `/ship`: only when asked to push, release, or prepare a PR.
- `/careful`: production, deployment, DB, destructive, or credential-related work.

Prefer project-local instructions over this file.