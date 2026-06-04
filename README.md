# LactoSync — Flutter App

Dairy farm and milk delivery management app.  
Stack: Flutter 3 · Material 3 · Riverpod · go_router · Dio

---

## Architecture

```
lib/
  core/
    theme/       Design tokens + MaterialApp theme wiring
    widgets/     Shared UI primitives (use these, never raw widgets)
    router/      go_router configuration
    constants/   App-wide string constants (i18n-ready)
  features/      One sub-folder per product domain (see features/_README.md)
  showcase/      Design-system gallery page (dev tool)
  main.dart      ProviderScope -> MaterialApp.router entry point
```

## Token rule (non-negotiable)

**No widget may ever hardcode a raw number, color, font size, radius, or padding.**  
Every value comes from `core/theme/`:

| Token file         | What it contains                              |
|--------------------|-----------------------------------------------|
| `app_spacing.dart` | `AppSpace.*` — all gaps and paddings          |
| `app_radius.dart`  | `AppRadius.*` — all corner radii              |
| `app_sizes.dart`   | `AppSize.*` — fixed heights / icon sizes      |
| `app_colors.dart`  | `AppColors.*` — light + dark semantic palette |
| `app_typography.dart` | `AppText.*` — all text styles             |
| `app_theme.dart`   | Wires all tokens into `ThemeData`             |
| `theme_provider.dart` | Riverpod `ThemeMode` provider, persisted  |

Change one token → propagates everywhere automatically.

## Shared widgets

Use the widgets in `core/widgets/` everywhere. Never write `ElevatedButton`,
`SizedBox(height: 8)`, `Card(...)`, or `showDialog(...)` directly in feature code.

| Widget               | Purpose                                       |
|----------------------|-----------------------------------------------|
| `AppGap`             | Token-sized vertical/horizontal spacers       |
| `AppButton`          | Primary / secondary / text, loading state     |
| `AppTextField`       | Label-above input, error, prefix/suffix icons |
| `AppCard`            | Standard section container                    |
| `AppSection`         | Titled section with header + child            |
| `AppChip`            | Status badge (success / warning / danger)     |
| `showAppDialog`      | All modals — consistent shape & padding       |
| `showAppBottomSheet` | All bottom sheets — consistent shape          |

## Adding a new feature

See `features/_README.md` for the feature folder convention.

## Running

```bash
flutter pub get
flutter run
```

Showcase page (design-system gallery) is the home route `/`.
