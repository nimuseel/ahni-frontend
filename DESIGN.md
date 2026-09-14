# AHNI Mobile Design System

## 0. Reference contract

- Product references: the supplied AHNI wireframe, use-case specification, ERD, DFD, and mini specification.
- Visual reference: [Student Portal Dashboard Mobile App UI Design](https://dribbble.com/shots/26239990-Student-Portal-Dashboard-Mobile-App-UI-Design) by Ronas IT.
- Reuse the reference's calm dashboard hierarchy, inset content cards, compact segmented controls, and profile-summary composition. Do not copy its brand assets, sample data, or purple/green palette.
- This harness branch implements only a development-ready shell. Product screens remain feature work.
- The wireframe's student-first information architecture is authoritative for future flows; it is not copied into placeholder UI.

## 1. Direction

AHNI is a calm, trustworthy academic tool. The surface is light and restrained, with one blue accent that connects the product to its Inha University origin without hard-coding university-specific behavior. Information is grouped like a student portal dashboard: clear screen title, one dominant task or summary, then quiet supporting cards.

The signature detail is an accent-soft summary surface that gives the current task or student identity visual priority without decorative illustration or fake product data.

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
| Shadow | `#0F18202A` |

Only status semantics may add colors beyond this set in future feature branches.

### Type

- Use the platform system sans-serif so Korean and Latin text render consistently without a network font dependency.
- Display: 24/32, weight 700.
- Title: 20/28, weight 700.
- Body: 16/24, weight 400.
- Supporting: 14/20, weight 400.

### Space and shape

- Base spacing unit: 4 logical pixels.
- Screen gutter: 24.
- Content gaps: 8, 12, 16, 24, 32.
- Small control radius: 10.
- Input and button radius: 12.
- Surface radius: 20.
- Dialog radius: 24.

## 3. Layout

- Respect safe areas and one-handed mobile use.
- Keep the primary message above the fold on compact phones.
- Use cards only to group a complete task, summary, or related data set. Do not wrap individual labels or every section in separate cards.
- Keep screen titles and primary actions outside cards; place form controls and profile details inside one dominant content card.
- Future navigation follows the supplied wireframe and must be implemented per feature, not pre-created as inactive controls.

## 4. Components

### App shell

- Material 3 root with `AHNI` as the semantic application title.
- Neutral canvas, dark system status icons, and a restrained text-first top bar.
- The environment label is supporting developer information, not a user-facing production badge.
- Keep onboarding copy warm, specific, and concise. Do not repeat the app or screen purpose in an eyebrow label.
- Wrap Korean headings and explanatory copy only at whitespace boundaries with `WhitespaceWrappedText`; never add manual line breaks for a viewport. Identifiers and other unbroken values must use explicit overflow handling instead.

### Segmented control

- Use for two to four peer filters or modes such as login/sign-up and enrollment status.
- Selected state uses the white surface and primary text; unselected state stays on the neutral canvas with secondary text.
- Every segment keeps a 44-pixel minimum touch target and visible selected semantics.
- Authentication modes do not share entered credentials, validation state, or feedback messages.

### Section card

- White surface, 20-pixel radius, 20-pixel internal padding, and the declared low shadow.
- A card groups one complete user task. Nested cards are not allowed.
- Passive loading indicators are not cards; show them directly on the canvas.

### Form field

- Neutral filled resting state with no decorative border.
- Focus state uses the accent outline. Error text remains inline and is never communicated by color alone.

### Department selector

- Use one labeled dropdown for each major type instead of combining multiple meanings in one control.
- The primary department is required. Double-major and minor selectors are explicitly marked as optional and include `선택 안 함`.
- Prevent the same department from being assigned to more than one major type, and preserve all selections when a server request fails.

### Profile summary

- Accent-soft surface containing the student's display identity, primary department, and account or enrollment status.
- Use only real profile data; omit unavailable dashboard metrics rather than inventing placeholders.

### Status message

- Inline live region within the related task card.
- Informational messages use accent soft; errors use semantic error colors with readable text.

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
- Bottom navigation is deferred until at least two real destinations exist; inactive reference navigation is not reproduced.
