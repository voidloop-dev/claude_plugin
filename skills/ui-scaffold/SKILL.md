---
name: ui-scaffold
description: >-
  Set up a professional UI foundation in a real codebase: design tokens, theming
  (light/dark), a component library choice, accessibility baseline, and the
  folder/state conventions for a web, mobile, or desktop app. Use when starting
  an app's frontend or when the UI has no system (ad-hoc colors, no tokens, no
  a11y). For visual mockups/wireframes use the built-in `design` skill; for
  charts use `dataviz`; this skill is about wiring a maintainable UI layer in code.
---

# ui-scaffold

Stand up a UI layer a senior frontend engineer would sign off on: one source of
truth for design tokens, theming that works, an accessible baseline, and
conventions that keep the component tree maintainable as it grows.

## Scope boundary — read first

| Need | Use |
|---|---|
| A mockup, wireframe, screen flow, landing-page comp | built-in `design` skill |
| Charts, dashboards, data viz | built-in `dataviz` skill |
| An HTML artifact page | built-in `artifact-design` skill |
| **Wiring tokens/theming/components/a11y into the app's code** | **this skill** |

## Absolute rules

| Rule | Why |
|---|---|
| Never hard-code a color, spacing, radius, or font size in a component. Reference a token. | One theme change shouldn't require a repo-wide find-replace. |
| Define the full light palette on the base `:root` (or base theme object); dark theme only overrides. Never define a color solely inside a dark/media block. | A missing base value renders as nothing in one theme. |
| Every interactive element is keyboard reachable and has a visible focus style. | Keyboard + screen-reader users are not optional. |
| Use semantic HTML / platform-native components before reaching for a custom widget. | Free accessibility, behavior, and platform feel. |
| Color is never the only signal (add icon/text/pattern). Body text meets WCAG AA contrast (4.5:1). | Colorblind and low-vision users. |
| One component library. Don't mix two (e.g. MUI + shadcn). | Double the bundle, clashing theming, inconsistent UX. |

## Procedure

### 1. Detect platform & framework

| Signal | Platform | Recommended UI base |
|---|---|---|
| Next.js / Vite + React | Web | Tailwind + shadcn/ui (or Radix primitives) |
| SvelteKit | Web | Tailwind + Skeleton / bits-ui |
| Flutter | Mobile/desktop | Material 3 `ThemeData` + `ColorScheme.fromSeed` |
| React Native / Expo | Mobile | Tamagui or React Native Paper |
| Electron / Tauri + React | Desktop | Tailwind + shadcn/ui, respect OS theme |

Confirm the choice with the user before installing.

### 2. Design tokens (source of truth)

Create `src/styles/tokens.css` (web) or `lib/theme/tokens.dart` (Flutter) from
`references/`. Token groups: `color` (semantic: `--bg`, `--fg`, `--muted`,
`--primary`, `--border`, `--danger`, `--success`), `space` (4-point scale),
`radius`, `font-size` (type scale), `shadow`, `z`.

Rules:
- Semantic names, not literal (`--primary`, not `--blue-600`).
- Primitive palette (`--blue-600: #...`) may exist but components use semantic.
- Every semantic token defined on the base theme.

### 3. Theming (light/dark + system)

- Base `:root` = full light palette.
- `@media (prefers-color-scheme: dark)` guarded so an explicit choice wins:
  `:root:not([data-theme="light"]) { ... }`.
- `:root[data-theme="dark"] { ... }` so a manual toggle wins both ways.
- Toggle writes `data-theme` and persists to `localStorage` (wrapped in
  try/catch); default = no attribute = follow system.
- Flutter: `MaterialApp(theme:, darkTheme:, themeMode: ThemeMode.system)`.

### 4. Component library setup

- Install the one chosen library; wire its theme to your tokens (shadcn: point
  its CSS vars at yours; Tailwind: map `theme.extend.colors` to the CSS vars;
  Flutter: build `ColorScheme` from tokens).
- Create `src/components/ui/` for library-wrapped primitives, `src/components/`
  for app components. App code imports from `ui/`, never the raw library, so the
  library can be swapped.

### 5. Accessibility baseline

- Global visible `:focus-visible` style from a token.
- `prefers-reduced-motion` respected in all transitions/animations.
- Skip-to-content link; one `<h1>` per page; landmark elements.
- Form inputs have associated `<label>`; errors linked via `aria-describedby`.
- Add an a11y lint: `eslint-plugin-jsx-a11y` (React) / `flutter analyze` a11y
  lints, and optionally axe in the test setup.

### 6. Conventions doc

Write `docs/UI.md` from `references/UI.md`: token list, theming model, folder
layout, "add a component" steps, a11y checklist.

## Verification gate

1. `grep` for hard-coded hex/rgb in `src/components` returns nothing (or only
   the primitive palette file).
2. Toggle to dark: no element is unstyled/invisible; contrast still AA.
3. Tab through a sample page: every interactive element is reachable and shows a
   focus ring.
4. `prefers-reduced-motion: reduce` disables non-essential animation.
5. a11y linter runs in CI with zero errors.
6. App code imports components from `ui/`, not the raw library (grep).
7. `docs/UI.md` exists and matches the actual token file.

Report pass/fail per item.

## Worked example

Next.js + Tailwind, wants light/dark, solo.

1. Platform = Web → Tailwind + shadcn/ui (confirmed).
2. `src/styles/tokens.css`: semantic color tokens + 4pt spacing + type scale.
3. Theming: `:root` light, guarded dark media query, `[data-theme]` overrides,
   `<ThemeToggle>` persisting to `localStorage`.
4. `npx shadcn init`; pointed its `--primary` etc. at the token vars; Tailwind
   `colors` mapped to `var(--*)`. `src/components/ui/` created.
5. Global `:focus-visible` ring token; `prefers-reduced-motion` wrapper;
   `eslint-plugin-jsx-a11y` added to CI lint job.
6. `docs/UI.md` written.
7. Gate: 7/7.
