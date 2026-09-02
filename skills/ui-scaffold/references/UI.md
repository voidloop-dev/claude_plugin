# UI conventions

## Design tokens

Source of truth: `src/styles/tokens.css`. Components reference semantic tokens
(`var(--bg)`, `var(--primary)`, `var(--space-4)`, …) — never raw hex, never the
primitive palette.

| Group | Tokens |
|---|---|
| Color | `--bg`, `--bg-subtle`, `--surface`, `--fg`, `--fg-muted`, `--border`, `--primary`, `--primary-fg`, `--primary-hover`, `--danger`, `--success`, `--warning`, `--focus-ring` |
| Space | `--space-1 … --space-16` (4-point) |
| Radius | `--radius-sm/md/lg/full` |
| Type | `--text-xs … --text-3xl`, `--font-sans` |
| Elevation | `--shadow-sm/md` |
| Z-index | `--z-dropdown/sticky/modal/toast` |

## Theming

Three states: explicit `data-theme="light"` / `"dark"` on `<html>`, or nothing =
follow `prefers-color-scheme`. Light is the base `:root`; dark only overrides.
Toggle: `src/components/ui/theme-toggle.tsx`. No-flash script goes in `<head>`.

## Folder layout

```
src/
  styles/tokens.css
  components/
    ui/          # thin wrappers over the component library — app imports from here
    <feature>/   # app-specific components
  app/ | pages/  # routes
```

App code imports from `components/ui/`, never the raw library — keeps it swappable.

## Add a component

1. If it's a primitive (button, input, dialog) → wrap the library version in
   `components/ui/`, themed via tokens.
2. If it's app-specific → `components/<feature>/`.
3. Keyboard reachable + visible focus. Semantic HTML first.
4. Color never the only signal. Body text ≥ 4.5:1 contrast.
5. Animations respect `prefers-reduced-motion`.

## Accessibility checklist (per screen)

- [ ] One `<h1>`, logical heading order
- [ ] Landmarks (`<header> <nav> <main> <footer>`), skip link
- [ ] All interactive elements keyboard reachable, visible focus ring
- [ ] Inputs have `<label>`; errors via `aria-describedby`
- [ ] Contrast AA; color not sole signal
- [ ] `prefers-reduced-motion` honored
- [ ] a11y linter green
