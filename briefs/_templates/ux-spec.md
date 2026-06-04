# UX Spec — <feature / flow>

> Author: UX/UI Designer · Source: PRD + `briefs/client-input/` assets · Date: <date>
> Implemented by: React Engineer / Flutter Engineer

## Flow
<How the user reaches this feature, what they can do, where each action leads. A simple
step/arrow map is fine.>

## Design tokens (define once, reference everywhere)
- **Colours:** <primary, surface, text, success/warn/error, plus any role-differentiated set>
- **Typography:** <font family, sizes, weights>
- **Spacing scale:** <e.g. 4/8/12/16/24/32>
- **Radii / elevation:** <…>

## Screens
For each screen:

### <Screen name>
- **Purpose:** <one line>
- **Layout & components:** <what's on screen, arrangement, at which breakpoints / platform>
- **States:** _(all of them — a missing state is where implementers guess)_
  - Loading: <…>
  - Empty: <…>
  - Error: <message + recovery>
  - Success / default: <…>
  - Edge cases: <…>
- **Interactions:** <on tap/click/submit; validation behaviour; transitions; waiting/failure
  feedback>
- **Content:** <real labels, button text, empty/error copy — not lorem ipsum>
- **Accessibility:** <contrast, focus order, labels, anything beyond defaults>
