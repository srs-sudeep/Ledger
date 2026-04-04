# Design System Specification: The Architectural Ledger

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Precision Curator."** 

In financial interfaces, the default is often "more is more," leading to cognitive overload. This system rejects that chaos. We move beyond the "template" look by treating data as editorial content. By utilizing intentional asymmetry, expansive breathing room, and a sophisticated layering of surfaces, we transform a standard dashboard into a high-end, authoritative workspace. The goal is to make the user feel like a master of their capital, moving through a space that is as stable as a vault but as fluid as a digital stream.

---

## 2. Colors: Tonal Depth over Structural Lines
We define space through light and weight, not lines. Our palette utilizes the **Material Design 3** logic but applies it with a high-end, bespoke sensitivity.

### The "No-Line" Rule
**Explicit Instruction:** Traditional 1px solid borders are prohibited for sectioning. Boundaries must be defined solely through background color shifts or subtle tonal transitions. For example, a `surface-container-low` widget sits on a `surface` background to create a "felt" boundary rather than a drawn one.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. Use the surface tiers to create "nested" depth:
- **Base Layer:** `surface` (#faf8ff) for the main canvas.
- **Sectional Breaks:** `surface-container-low` (#f2f3ff) for sidebar or utility areas.
- **Interactive Containers:** `surface-container-lowest` (#ffffff) for primary data cards to provide maximum "pop" and perceived elevation.

### The "Glass & Gradient" Rule
To elevate primary actions, avoid flat fills.
- **Signature CTAs:** Use a subtle linear gradient from `primary` (#000000) to `primary_container` (#00174b) to give buttons a "lithic" (stone-like) weight.
- **Floating Elements:** Modals and dropdowns must use `surface_container_lowest` with a 70% opacity and a `20px` backdrop blur (Glassmorphism), allowing the financial data to softly bleed through the container.

---

## 3. Typography: Editorial Authority
We pair **Manrope** for high-impact data visualization and headers with **Inter** for dense utility and labels. This creates a rhythmic "Scale Shift" that guides the eye.

- **Display & Headlines (Manrope):** These are the "anchors." Use `display-lg` (3.5rem) for total portfolio balances. The high x-height of Manrope conveys modern authority.
- **Titles & Labels (Inter):** Use `title-md` (1.125rem) for card headers. Inter is chosen for its mathematical precision in tabular data, ensuring that numbers never "dance" on the page.
- **Numeric Precision:** All numerical data must use `font-variant-numeric: tabular-nums` to ensure columns of figures align perfectly, reinforcing the brand pillar of "Precision."

---

## 4. Elevation & Depth: The Layering Principle
Forget "boxes." Think in "strata." Hierarchy is achieved through **Tonal Layering**.

- **Ambient Shadows:** When an element must float (e.g., a hovered card), use a shadow tinted with `on_surface` (#131b2e). 
  - *Spec:* `box-shadow: 0 12px 40px -12px rgba(19, 27, 46, 0.08);`
- **The "Ghost Border" Fallback:** If accessibility requires a container edge, use a "Ghost Border": the `outline_variant` token (#c6c6cd) at **15% opacity**. Never use a 100% opaque border.
- **Micro-interactions:** On hover, a card should not just change color; it should transition from `surface-container` to `surface-container-lowest` while slightly increasing its ambient shadow, mimicking a physical lift.

---

## 5. Components: Precision Primitives

### Primary Buttons
- **Style:** `surface_tint` (#0053db) fill, `on_primary` (#ffffff) text.
- **Radius:** `md` (0.375rem).
- **Affordance:** A subtle 1px inner glow (top-down) using `primary_fixed_dim` at 20% opacity to create a "pressed" high-end feel.

### Data Cards
- **Structure:** No borders. Use `surface-container-lowest` against a `surface` background.
- **Spacing:** Minimum `2rem` (xl) internal padding to ensure data "breathes."
- **Content:** Titles use `title-sm` (Inter, 1rem, Medium weight).

### Financial Trend Chips
- **Success:** `surface_container` background with `on_tertiary_fixed_variant` (#574425) for a sophisticated "old-money" green-gold, or standard success tokens for "modern" growth. 
- **Error:** `error_container` (#ffdad6) with `on_error_container` (#93000a) for clear but professional warnings.

### Input Fields
- **Background:** `surface_container_low`.
- **Active State:** A transition to `surface_container_lowest` with a `surface_tint` Ghost Border (20% opacity). 
- **Labeling:** `label-md` (Inter, 0.75rem) positioned above the field, never inside as a placeholder.

### Data Tables
- **Rule:** Forbid the use of vertical or horizontal divider lines.
- **Separation:** Use a subtle background toggle—every even row uses `surface_container_low`.
- **Header:** `label-sm` (Inter, 0.6875rem) in Uppercase with `0.05em` letter spacing for an editorial look.

---

## 6. Do's and Don'ts

### Do
- **Do** use white space as a structural element. If a layout feels cluttered, increase padding rather than adding a border.
- **Do** align all text to a 4px baseline grid to ensure "Precision."
- **Do** use `primary` (#000000) sparingly for emphasis; let the `secondary` and `surface` tones do the heavy lifting of the UI.

### Don't
- **Don't** use pure #000000 for text; use `on_surface` (#131b2e) to maintain a premium, deep-navy "ink" feel.
- **Don't** use standard "drop shadows." If a shadow is needed, ensure it is diffused and tinted.
- **Don't** use high-contrast dividers. A change in background color is always the preferred method of separation.