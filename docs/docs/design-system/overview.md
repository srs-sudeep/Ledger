---
sidebar_position: 1
---

# Design System

The Ledger follows **"The Precision Curator"** design language -- Material Design 3 logic with tonal depth over structural lines.

## Core Principles

- **No-Line Rule**: boundaries defined by background color shifts, not borders
- **Surface Hierarchy**: `surface` > `surface-container-low` > `surface-container` > `surface-container-lowest`
- **Glassmorphism**: subtle glass effects for overlays and modals
- **Ambient Shadows**: soft, tinted shadows instead of harsh drop shadows

## Color Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `surface` | `#faf8ff` | Page background |
| `surface-container-low` | `#f4f3fa` | Sidebar, secondary surfaces |
| `surface-container` | `#efedf5` | Hover states, input backgrounds |
| `surface-container-lowest` | `#ffffff` | Cards, elevated content |
| `primary` | `#415f91` | Primary actions, links |
| `surface-tint` | `#415f91` | Button fills |
| `on-surface` | `#131b2e` | Primary text |
| `secondary` | `#565f71` | Secondary text |
| `error` | `#ba1a1a` | Error states |
| `on-primary` | `#ffffff` | Text on primary surfaces |

## Typography

| Font | Usage |
|------|-------|
| **Manrope** | Display headings, card titles |
| **Inter** | Body text, labels, data |

All financial numbers use `font-variant-numeric: tabular-nums` for aligned columns.

## Elevation

- **Ambient shadow**: `0 12px 40px -12px rgba(19, 27, 46, 0.08)`
- **Ghost border**: `1px solid rgba(198, 198, 205, 0.15)` for subtle card edges
- **Card hover**: shadow strengthens + slight surface color transition
