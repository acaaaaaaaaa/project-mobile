---
name: Kerkom Dark Focus System
colors:
  surface: '#111317'
  surface-dim: '#111317'
  surface-bright: '#37393e'
  surface-container-lowest: '#0c0e12'
  surface-container-low: '#1a1c20'
  surface-container: '#1e2024'
  surface-container-high: '#282a2e'
  surface-container-highest: '#333539'
  on-surface: '#e2e2e8'
  on-surface-variant: '#c4c9ae'
  inverse-surface: '#e2e2e8'
  inverse-on-surface: '#2f3035'
  outline: '#8e937a'
  outline-variant: '#444934'
  surface-tint: '#aad600'
  primary: '#ffffff'
  on-primary: '#283500'
  primary-container: '#c5f331'
  on-primary-container: '#556d00'
  inverse-primary: '#506600'
  secondary: '#c4c6d0'
  on-secondary: '#2d3038'
  secondary-container: '#44474f'
  on-secondary-container: '#b3b5be'
  tertiary: '#ffffff'
  on-tertiary: '#68000b'
  tertiary-container: '#ffdad7'
  on-tertiary-container: '#c31f29'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#c5f331'
  primary-fixed-dim: '#aad600'
  on-primary-fixed: '#161f00'
  on-primary-fixed-variant: '#3b4d00'
  secondary-fixed: '#e0e2ec'
  secondary-fixed-dim: '#c4c6d0'
  on-secondary-fixed: '#191c22'
  on-secondary-fixed-variant: '#44474f'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ae'
  on-tertiary-fixed: '#410004'
  on-tertiary-fixed-variant: '#930014'
  background: '#111317'
  on-background: '#e2e2e8'
  surface-variant: '#333539'
typography:
  timer-display:
    fontFamily: Nunito Sans
    fontSize: 64px
    fontWeight: '900'
    lineHeight: 72px
    letterSpacing: -1.5px
  headline-lg:
    fontFamily: Nunito Sans
    fontSize: 28px
    fontWeight: '900'
    lineHeight: 36px
    letterSpacing: -0.5px
  headline-md:
    fontFamily: Nunito Sans
    fontSize: 22px
    fontWeight: '800'
    lineHeight: 28px
    letterSpacing: -0.3px
  headline-sm:
    fontFamily: Nunito Sans
    fontSize: 18px
    fontWeight: '800'
    lineHeight: 24px
  body-lg:
    fontFamily: Nunito Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Nunito Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  body-sm:
    fontFamily: Nunito Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-lg:
    fontFamily: Nunito Sans
    fontSize: 16px
    fontWeight: '800'
    lineHeight: 20px
  label-md:
    fontFamily: Nunito Sans
    fontSize: 13px
    fontWeight: '800'
    lineHeight: 16px
    letterSpacing: 0.4px
  label-sm:
    fontFamily: Nunito Sans
    fontSize: 11px
    fontWeight: '800'
    lineHeight: 14px
    letterSpacing: 0.6px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system powers a focused, high-stakes productivity environment engineered specifically for university group study sessions. The core philosophy centers on collective accountability and uncompromised focus: students lock their phones face-down or stationary to study together without digital friction.

The aesthetic blends **Modern Utilitarianism** with high-contrast tactical minimalism. It rejects gamified gimmicks—there are no playful mascots, juvenile XP meters, or distracting badges. Instead, the UI projects the deliberate, disciplined aura of a mission-critical tool:
- **Tone:** Authoritative, clean, contemporary, and dependable.
- **Emotion:** Deep calm during focus intervals, absolute urgency during alarm states (e.g., when a device is moved or lifted), and quiet satisfaction upon session completion.
- **Visual Stance:** Deep near-black obsidian foundations, dense tactile charcoal surfaces, and razor-sharp electric lime highlights. Every visual element exists to serve task clarity, timer visibility, and peer presence.

## Colors

The palette is tuned specifically for low-light study halls and late-night library rooms. High contrast ratios preserve legibility without causing retinal fatigue.

### Core Swatches
- **Base Canvas (`#0F1115`):** The absolute foundational background tone. Neutral-cool deep black that ensures high OLED power efficiency.
- **Surface Layer (`#1A1D24`):** Elevated card and container background. Warm graphite with zero borders to maintain a seamless, organic visual flow.
- **Surface Dim / Navigation Bar (`#13161C`):** Sub-surface baseline tone reserved for navigation structures and persistent toolbars.
- **Primary Accent (`#C6F432`):** Acid Lime. Represents active study states, primary affirmative calls-to-action, active participant indicators, and success thresholds. High energy against deep dark values.
- **Primary Action Solid Shadow (`#9EC41C`):** Darker lime tone used exclusively for the physical 4px bottom drop on interactive primary buttons.
- **On-Lime Contrast Text (`#10140A`):** Deep blackened olive ink formulated to guarantee WCAG AAA legibility against the `#C6F432` primary fill.

### Functional Alerts & Feedback
- **Destructive / Alarm (`#FF4D4D`):** Crimson alert used immediately when a student breaks focus, lifts their phone, or attempts to abandon an active session.
- **Destructive Soft Base (`rgba(255, 77, 77, 0.12)`):** Tonal red backdrop for emergency alert banners and countdown warnings.
- **Warning (`#FFC83D`):** Warm amber for connection drops, idle reminders, or impending study breaks.
- **Success (`#34D399`):** Mint emerald indicating fully synced participants, completed pomodoros, and verified logs.

### Text & Neutral Hierarchy
- **Text High-Contrast (`#FFFFFF`):** Primary headings, main timer readouts, active member names.
- **Text Muted / Subtitle (`#8A8F9C`):** Secondary metadata, inactive states, helper text, and timestamp labels.
- **Border / Divider Subtle (`rgba(255, 255, 255, 0.08)`):** Sparse separator lines for table breakdowns and modal separators.

## Typography

The design system exclusively employs **Nunito Sans** (applied in weights `600` Semi-Bold, `800` Extra-Bold, and `900` Black). This provides rounded, hyper-legible geometric forms that balance the dark interface with warmth without losing authority.

### Tabular Rules for Numeric Clocks
Timers, session countdowns, and real-time session counters must render with OpenType tabular figures enabled (`font-variant-numeric: tabular-nums`). This prevents horizontal jitter and card reflow as seconds tick down during intense focus blocks.

### Hierarchy & Editorial Rules
- **Display Timers (`timer-display`):** Reserved solely for live countdown screens (e.g. `25:00`, `00:42`).
- **Headlines:** Use `font-weight: 900` for primary views and session titles to establish immediate focal clarity upon launching the screen.
- **Labels:** Button copy, chip elements, and pill markers must use uppercase or title-cased `label-md` with `font-weight: 800` to prevent visual mud on small screens.
- **Tone & Copy:** All app copy must follow concise Indonesian (Bahasa Indonesia) terminology: *Mulai Sesi*, *Ruang Fokus*, *Riwayat Belajar*, *Peringatan Gerakan*.

## Layout & Spacing

The layout is optimized for standard modern mobile viewports (baseline target: **390 × 844 pt**), utilizing an unyielding **8px base grid system** (subdivided into 4px micro-steps for tight badge internal padding).

### Layout Rules
- **Screen Margins:** Set to `20px` (`1.25rem`) lateral padding across all main views. This prevents touch interactions from running up against screen bezels.
- **Vertical Flow:** Standard vertical gap between card stacks is `12px` to `16px`. Group headers maintain `24px` top separation from previous clusters.
- **Touch Boundaries:** All clickable elements (buttons, segmented controls, list items, icons) enforce a hard minimum touch target of `44 × 44 pt`, even when visual bounding boxes are smaller.
- **Safe Area Insets:** Dynamic bottom margin padding accounts for iOS Home Indicator and Android navigation bars above the 3-tab navigation bar.

## Elevation & Depth

This system intentionally eliminates traditional blurred drop shadows, glow gradients, and skeuomorphic lighting in favor of **Tonal Layering** coupled with tactile solid offsets.

### Depth Hierarchy
1. **Level 0 (Canvas):** Pure base `#0F1115`. Hosts uncontained headers and background views.
2. **Level 1 (Cards & Lists):** Surface fill `#1A1D24`. Absolute zero border, zero blurry shadow. Contrast against Level 0 is purely tonal.
3. **Level 2 (Modals & Drawers):** Elevated surface `#21252E` paired with a 60% opacity `#000000` backdrop dimming scrim.
4. **Interactive Tactile Elevation (Primary Action Button):** The primary lime button utilizes a **flat solid shadow** (`box-shadow: 0 4px 0 #9EC41C`). On touch active/pressed states, this button translates down by 3px (`transform: translateY(3px)`), collapsing the solid shadow to 1px (`box-shadow: 0 1px 0 #9EC41C`), producing an immediate physical tactile response without soft blur artifacts.
5. **No Borders Policy:** Containers and cards rely strictly on color boundary separation (`#0F1115` vs `#1A1D24`), keeping the interface uncluttered and distraction-free. The only exception is the Destructive Button, which uses a deliberate 2px structural warning stroke.

## Shapes

The design system establishes a consistent geometric curve language that complements the rounded letterforms of the typography.

- **Primary Cards & Containers:** Strict `20px` corner radius. This applies to study group summary cards, session statistics, timer modules, and modal sheets.
- **Interactive Buttons:** Consistent `16px` corner radius for full-width action controls, maintaining clear visual distinctiveness from container cards.
- **Pills & Status Chips:** Fully pill-shaped (`9999px` / full radius) for participant status pills, active tags, and live connection chips.
- **Form Fields & Inputs:** `16px` border-radius to harmonize with buttons.

## Components

### Buttons
- **Primary Action Button:**
  - Layout: Full width (`100%`), fixed height `52px`.
  - Radius: `16px`.
  - Fill: `#C6F432`.
  - Text: `#10140A`, `Nunito Sans` 800 (Extra-Bold), 16px.
  - Shadow: Hard solid offset `0 4px 0 #9EC41C`. No blur.
  - Interaction: 3px downward translation on press.
- **Secondary Action Button:**
  - Layout: Height `52px`, radius `16px`.
  - Fill: `#1A1D24`.
  - Text: `#FFFFFF`, `Nunito Sans` 800, 16px.
  - Press state: Background lightens to `#262B35`.
- **Destructive Button:**
  - Layout: Height `52px`, radius `16px`.
  - Fill: Transparent.
  - Border: `2px solid #FF4D4D`.
  - Text: `#FF4D4D`, `Nunito Sans` 800, 16px.
  - Press state: Background fills with `rgba(255, 77, 77, 0.12)`.

### Cards & Panels
- **Standard Card:**
  - Background `#1A1D24`, `border-radius: 20px`, internal padding `20px` (or `16px` for dense metric rows).
  - Absolutely no outline or border stroke.
- **Active Focus Card (Live Session):**
  - Features a top-right live indicator pill (`#C6F432` background with `#10140A` text: `FOKUS AKTIF`).

### Alarm / Emergency State Overlay
- Triggered instantly when motion sensors detect phone pickup.
- Background transitions to `#0F1115` with an urgent pulse of `rgba(255, 77, 77, 0.20)`.
- Displays critical warning label: `PERINGATAN: PONSEL TERANGKAT!` with a prominent 10-second cancel button before failure is reported to study group peers.

### Bottom Navigation Bar
- **Dimensions & Specs:** Height `68px` + Safe Area inset.
- **Background:** `#13161C` with a fine top divider line (`rgba(255, 255, 255, 0.06)`).
- **Tabs (3 items):**
  1. `Beranda` (Home icon)
  2. `Riwayat` (Clock / Archive icon)
  3. `Profil` (User silhouette icon)
- **State Styling:**
  - Active: Icon and label colored `#C6F432` (`font-weight: 800`).
  - Inactive: Icon and label colored `#8A8F9C` (`font-weight: 600`).

### Iconography Rules
- Use crisp, rounded line icons only (stroke width `2px`, Lucide or Heroicons style).
- **Strict Prohibition:** Absolutely **NO emojis** anywhere in the UI. Emojis break the focused, mature academic atmosphere. Statuses are expressed solely with typographic labels, geometric dots, and line icons.

### Inputs & Study Code Fields
- Height `52px`, radius `16px`, background `#1A1D24`.
- Border: `1.5px solid transparent`.
- Active focus state: Border switches sharply to `1.5px solid #C6F432`.
- Text color `#FFFFFF`, placeholder `#8A8F9C`. Group code entries should display with wide letter spacing (`letter-spacing: 4px`) and uppercase styling.

### Participant Chips & Lists
- Avatar/Initial circle: `36 × 36 pt` filled with `#262B35`, text `#FFFFFF`.
- Status Indicator: `8 × 8 pt` solid dot positioned on the avatar:
  - Lime (`#C6F432`): Phone stationary / focused.
  - Red (`#FF4D4D`): Distraction detected.
  - Amber (`#FFC83D`): Disconnected / idle.