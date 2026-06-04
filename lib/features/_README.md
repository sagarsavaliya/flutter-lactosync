# features/

Each top-level subfolder = one product domain (e.g. `customers/`, `deliveries/`, `billing/`).

## Feature folder convention

```
features/
  <feature_name>/
    data/
      models/         Dart data classes (fromJson / toJson)
      repositories/   Concrete Dio implementations of domain interfaces
      sources/        Raw API/local data access objects
    domain/
      entities/       Pure domain objects (no Flutter, no JSON)
      repositories/   Abstract interfaces
      use_cases/      Single-responsibility business logic classes
    presentation/
      pages/          Full-screen route targets
      widgets/        Feature-scoped UI components
      providers/      Riverpod providers for this feature
```

## Rules

1. `presentation/` may import `domain/` — never `data/` directly.
2. `domain/` knows nothing about Flutter or Dio.
3. Use `core/widgets/` for UI primitives — never reimplement AppButton etc.
4. Every provider lives in `presentation/providers/`; no business logic in widgets.
5. Strings go in `core/constants/app_strings.dart`; no string literals in widget files.
