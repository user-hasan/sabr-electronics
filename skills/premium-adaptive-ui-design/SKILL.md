---
name: premium-adaptive-ui-design
description: Design premium mobile and responsive application interfaces in a consistent adaptive glassmorphism style with reusable design tokens, multiple switchable themes, Arabic RTL support, and screen-specific prompts. Use when creating, redesigning, or extending UI screens, dashboards, design systems, or visual interface prompts that must preserve a unified brand while supporting light, dark, and alternate themes.
---

# Premium Adaptive UI Design

Use this skill to create implementation-ready interface specifications or visual design prompts—not merely decorative mockups. Preserve existing product features when redesigning; improve hierarchy and presentation without removing functionality unless the user explicitly approves removal.

## Core visual language

Apply a premium, calm, mobile-first visual system:

- Use floating cards, soft rounded corners, restrained glassmorphism, subtle depth, and generous spacing.
- Combine pearl light surfaces, midnight indigo surfaces, cyan/blue accents, and occasional violet accents.
- Use blurred photographic or abstract backgrounds only where they support the screen purpose; add a readable gradient overlay.
- Prefer one clear primary action per section and secondary outlined actions.
- Use simple line icons with consistent stroke weight.
- Keep the interface functional, scannable, and feasible to implement.
- Support Arabic RTL by default when the request is Arabic; mirror layout, alignment, navigation order, and icon direction where appropriate.
- Prefer IBM Plex Sans Arabic, Tajawal, or Cairo for Arabic interfaces.

## Layout tokens

Use these defaults unless the product context requires otherwise:

- Mobile-first canvas; responsive up to tablet and desktop.
- 4px/8px spacing grid.
- 20–24px page gutters.
- 20–32px card radius; 14–18px controls.
- 16–24px card padding.
- At most 4–5 bottom navigation destinations.
- One dominant CTA per screen or major section.
- Three primary text sizes maximum per screen, plus a small metadata size.

## Glass treatment

Use glassmorphism with restraint. Maintain text contrast and do not make every element translucent.

Light glass:

```css
background: rgba(255, 255, 255, 0.62);
border: 1px solid rgba(255, 255, 255, 0.72);
backdrop-filter: blur(24px);
box-shadow: 0 12px 36px rgba(37, 99, 235, 0.12);
```

Dark glass:

```css
background: rgba(17, 28, 50, 0.72);
border: 1px solid rgba(148, 163, 184, 0.16);
backdrop-filter: blur(24px);
box-shadow: 0 16px 42px rgba(0, 0, 0, 0.28);
```

Use opaque surfaces behind dense tables, forms, or critical status messages when glass would reduce legibility.

## Theme architecture

Never hardcode brand colors inside individual screens. Define semantic design tokens and let screens consume them:

- `background`, `surface`, `surfaceElevated`, `surfaceGlass`
- `primary`, `primaryStrong`, `secondary`, `accent`
- `success`, `warning`, `danger`, `info`
- `textPrimary`, `textSecondary`, `textMuted`
- `border`, `divider`, `shadow`
- `radiusCard`, `radiusControl`, `spacingUnit`

Every theme must preserve the same component structure and interaction hierarchy. Changing a theme changes tokens, imagery treatment, and contrast—not the product’s information architecture.

Required starter themes:

1. **Pearl Light** — pearl background, white surfaces, royal blue primary, cyan secondary.
2. **Midnight Indigo** — deep navy background, indigo surfaces, sky/cyan primary, violet accent.
3. **Aqua Breeze** — pale aqua background, white glass, teal primary, blue secondary.
4. **Royal Violet** — lavender background, white surfaces, violet primary, pink accent.

Include a theme picker with live preview, active-state indicator, system preference option, light/dark options, local persistence, and a soft transition. Do not use accent colors for small text if contrast is insufficient.

## Component rules

### Header
Use a compact header with brand/title, optional context or branch, notifications, and account/menu. Avoid overcrowding with multiple unrelated icons.

### Summary cards
Show the number first, then a concise label and optional trend/status. Use semantic status colors sparingly: green for ready/success, orange for pending/payment, purple/blue for processing/info, red only for urgent/error states.

### Actions
Make the primary action visually dominant. Use short labels and familiar icons. Secondary actions should use outlines or quiet surfaces.

### Lists and data
Provide a recent activity or latest items section when it reduces navigation. On mobile, convert rows to cards with title, metadata, status chip, and one clear action.

### Navigation
Use a bottom navigation bar for core mobile destinations and a side navigation/drawer for larger layouts. Keep labels short and consistent.

### States
Specify loading, empty, success, warning, error, offline, and disabled states whenever the screen contains data or mutations.

## Screen workflow

For every new screen:

1. Identify the user goal, primary task, secondary tasks, and preserved existing features.
2. Define the information hierarchy before choosing decoration.
3. Select components from the system and map them to semantic tokens.
4. Describe responsive behavior and Arabic RTL behavior.
5. Define all relevant interaction and data states.
6. Provide the selected theme plus how the screen changes across the other themes.
7. Use the screen prompt template in `templates/screen-prompt.md`.
8. Reject visual choices that harm readability, accessibility, or task completion.

## Output format

When asked for a design or prompt, return:

- Screen objective and user flow.
- Layout hierarchy from top to bottom.
- Component inventory.
- Theme/token mapping.
- Responsive and RTL behavior.
- Interaction, loading, empty, error, and offline states.
- A final copy-ready screen prompt.

If the user asks for implementation, convert the specification into the target framework while retaining existing features and token-based theming.

## Quality checklist

Before finalizing, verify:

- The primary action is obvious within the first viewport.
- No important feature from the existing screen was removed.
- Text remains readable in every supplied theme.
- Cards, icons, radii, and spacing are consistent.
- Theme switching does not change information architecture.
- Arabic text is correctly RTL and does not collide with icons.
- Mobile content does not require horizontal scrolling unless explicitly intended.
- Every data-driven screen has empty, loading, error, and offline behavior.
- The result feels premium through hierarchy and restraint, not excessive blur or decoration.
