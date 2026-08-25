# AHNI Mobile Design System

## 0. Reference contract

- Product references: the supplied AHNI wireframe, use-case specification, ERD, DFD, and mini specification.
- This harness branch implements only a development-ready shell. Product screens remain feature work.
- The wireframe's student-first information architecture is authoritative for future flows; it is not copied into placeholder UI.

## 1. Direction

AHNI is a calm, trustworthy academic tool. The surface is light and restrained, with one blue accent that connects the product to its Inha University origin without hard-coding university-specific behavior.

The signature detail is a thin accent rule near the top of the shell. It suggests academic progress without adding a decorative illustration or fake product data.

## 2. Tokens

### Color

| Role | Value |
| --- | --- |
| Canvas | `#F7F8FA` |
| Surface | `#FFFFFF` |
| Primary text | `#18202A` |
| Secondary text | `#5B6470` |
| Accent | `#1558A6` |
| Accent soft | `#EAF2FC` |
| Divider | `#DDE2E8` |

Only status semantics may add colors beyond this set in future feature branches.

### Type

- Use the platform system sans-serif so Korean and Latin text render consistently without a network font dependency.
- Display: 28/36, weight 700.
- Title: 20/28, weight 700.
- Body: 16/24, weight 400.
- Supporting: 14/20, weight 400.

### Space and shape

- Base spacing unit: 4 logical pixels.
- Screen gutter: 24.
- Content gaps: 8, 12, 16, 24, 32.
- Small control radius: 6.
- Surface radius: 12.
- Dialog radius: 16.

## 3. Layout

- Respect safe areas and one-handed mobile use.
- Keep the primary message above the fold on compact phones.
- Prefer open spacing over wrapping each section in a card.
- Future navigation follows the supplied wireframe and must be implemented per feature, not pre-created as inactive controls.

## 4. Components

### App shell

- Material 3 root with `AHNI` as the semantic application title.
- Neutral canvas, restrained top bar, and one accent rule.
- The environment label is supporting developer information, not a user-facing production badge.

## 5. Motion

- No decorative motion in the harness shell.
- Future state transitions must communicate navigation or status, use opacity/transform, and honor reduced-motion preferences.

## 6. Accessibility constraints

- Text contrast must meet WCAG AA.
- Touch targets must be at least 44 logical pixels when interactions are introduced.
- Content order must remain meaningful for screen readers and large text.
- Do not convey status by color alone.

## 7. Responsive behavior

- Compact phones: single reading column with 24-pixel gutters.
- Tablets: center content with a readable maximum width rather than stretching copy edge to edge.
- Landscape: preserve safe areas and avoid vertically centering content that can be clipped.

## 8. Accepted debt

- No dark theme is defined in the harness branch.
- No reusable feature components are created until a real flow needs them.
- Visual fidelity for individual wireframe screens is deferred to their feature branches.
