# LactoSync full redesign — design gaps & decisions

**Design source:** `briefs/redesign app screen - lactosync/LactoSync Routes Redesign.dc.html`  
**Checkpoint commit:** `4e603ee` on `main`

## Not in design file (implemented with owner DNA)

| Area | Decision |
|------|----------|
| Customer app (login, OTP, bills, profile, vacation) | Same palette, cards, section labels as owner frames |
| Delivery boy app (login, home, route sheet) | Mirrors owner routes/packing patterns |
| Auth + onboarding flows | Clean forms on `#F4F6EE` background |
| Owner: Activity, Delivery boys, Route sheet print | Functional screens styled to match; no HTML frame |
| Subscription suspended overlay | Warning banner pattern |

## Popups / sheets (no dedicated frames — unified style)

- Generate bill (frame 10 reference)
- Collect payment (frame 13 reference)
- Add / edit customer (frame 7 reference)
- Vacation, subscription edit, sort menus, confirm dialogs
- All use: white surface, 24px top radius, drag handle, `#ECEFE5` borders

## Icons

- `lucide_icons` package used where it matches HTML strokes
- Material `Icons.*_outlined` fallback elsewhere

## API note

Customer `consumption` on dashboard/orders requires Laravel deploy (included in checkpoint).
