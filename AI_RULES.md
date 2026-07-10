# AI Rules

## Goal

Generate production-ready Flutter code for ZTC.

Never generate demo code.

Every feature must be ready to ship.

---

# Architecture

Use:

- Clean Architecture
- Feature-first structure
- Riverpod
- GoRouter
- Material 3

Never break the architecture.

---

# Code Quality

Always write:

- Null-safe code
- Readable code
- Modular code
- Reusable widgets
- Responsive layouts

No duplicated code.

---

# UI Rules

Every screen must support:

- Light Mode
- Dark Mode

Animations must be smooth.

Use consistent spacing.

Use reusable buttons.

Use reusable cards.

Use reusable dialogs.

---

# State Management

Use Riverpod only.

Never use setState unless absolutely necessary.

---

# Routing

Use GoRouter.

Never hardcode routes.

---

# Repository Pattern

Every API call must go through:

Repository

↓

Datasource

↓

Model

Never call APIs directly from UI.

---

# Security

Never store secrets in source code.

Use secure storage.

Validate all user input.

Protect sensitive data.

---

# Performance

Avoid unnecessary rebuilds.

Lazy load data.

Paginate long lists.

Optimize images.

Cache network requests where appropriate.

---

# Code Generation Rules

When generating code:

- Complete the whole feature.
- Include every required file.
- Update routing if needed.
- Update dependency injection if needed.
- Update providers if needed.
- Ensure the project compiles.

Never leave TODOs.

Never leave placeholder implementations.

Never generate incomplete files.

---

# Output Rules

When implementing a feature:

1. List every file to create.
2. List every file to modify.
3. Provide complete code.
4. Ensure no compile errors.
5. Keep the existing project style.
