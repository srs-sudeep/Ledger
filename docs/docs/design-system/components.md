---
sidebar_position: 2
---

# UI Components

All components are in `web/components/ui/` and follow a Shadcn-style pattern using `class-variance-authority` (CVA) for variant management.

## Button

| Variant | Style |
|---------|-------|
| `default` | Surface tint fill, white text |
| `gradient` | Black-to-navy CTA gradient |
| `secondary` | Surface container background |
| `outline` | Subtle border, transparent background |
| `ghost` | No background, hover to reveal |
| `destructive` | Error red |
| `link` | Text only with underline |

Sizes: `default` (h-10), `sm` (h-8), `lg` (h-12), `icon` (h-10 w-10).

All buttons include `focus-visible` ring, `active:scale` feedback, and 150ms transitions.

## Card

- Background: `surface-container-lowest`
- Padding: `p-8` (2rem minimum per design spec)
- Shadow: ambient
- Hover: stronger shadow + surface color shift
- Radius: `rounded-xl`

## Input

- Floating label pattern
- Surface container background
- Focus ring with primary color
- No visible border (ghost-border on focus)

## Dialog

- Overlay with backdrop blur
- Glass-style background
- Close button (X) in top-right
- Smooth scale-in animation

## Select

- Custom styled select matching Input appearance
- Chevron indicator
- Same label pattern as Input

## Skeleton

- Animated pulse placeholder for loading states
- Used in all `loading.tsx` files

## Spinner

- Circular border animation
- Three sizes: `sm`, `md`, `lg`
- Primary color accent

## Avatar

- Circular image with fallback initials
- Calculated from user's full name

## Badge / Tabs

- Standard Shadcn-style implementations
- Tabs with underline active indicator
