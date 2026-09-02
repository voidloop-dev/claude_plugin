// src/components/ui/theme-toggle.tsx
// Default = follow system (no data-theme attribute). Toggle sets an explicit
// choice and persists it. All storage access is guarded.
"use client";

import { useEffect, useState } from "react";

type Theme = "light" | "dark" | "system";

function read(): Theme {
  try {
    const v = localStorage.getItem("theme");
    if (v === "light" || v === "dark") return v;
  } catch {}
  return "system";
}

function apply(theme: Theme) {
  const root = document.documentElement;
  if (theme === "system") root.removeAttribute("data-theme");
  else root.setAttribute("data-theme", theme);
  try {
    if (theme === "system") localStorage.removeItem("theme");
    else localStorage.setItem("theme", theme);
  } catch {}
}

export function ThemeToggle() {
  const [theme, setTheme] = useState<Theme>("system");

  useEffect(() => setTheme(read()), []);
  useEffect(() => apply(theme), [theme]);

  const next: Record<Theme, Theme> = { system: "light", light: "dark", dark: "system" };
  const label = { system: "System", light: "Light", dark: "Dark" }[theme];

  return (
    <button
      type="button"
      aria-label={`Theme: ${label}. Click to change.`}
      onClick={() => setTheme(next[theme])}
    >
      {label}
    </button>
  );
}

// Inline this in <head> before first paint to avoid a flash:
export const noFlashScript = `try{var t=localStorage.getItem('theme');if(t==='dark'||t==='light')document.documentElement.setAttribute('data-theme',t);}catch(e){}`;
