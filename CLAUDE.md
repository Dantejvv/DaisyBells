# DaisyBells

A workout tracking iOS app for logging exercises, creating workout templates, and viewing analytics.

## Tech Stack
- Swift, SwiftUI, SwiftData, SwiftTesting
- iOS 17+
- MVVM + Services architecture

## Do Not Use
- UIKit
- CoreData
- Combine
- Third-party dependencies
- @EnvironmentObject for dependency injection

## Documentation
- `docs/ARCHITECTURE.md` — Architecture decisions, MVVM rules, concurrency model
- `docs/MODELS.md` — Data model definitions and relationships
- `docs/FEATURES.md` — Feature specifications
- `docs/CONTRACTS.md` — View-ViewModel contracts (state, intents, side effects)
- `docs/USERFLOWS.md` — User flows and model lifecycle mappings

## Architecture Rules
- Views: No business logic, no SwiftData access, call ViewModel intents only
- ViewModels: @MainActor, @Observable, call services for all data operations
- Services: Own all business logic and SwiftData access, injected via protocols
- Navigation: Enum-based routing with per-tab Routers
- Models: Use VersionedSchema from day one
- Settings: Access UserDefaults only through SettingsService, never use @AppStorage in Views

## File Structure
- `DaisyBells/App/` — App entry point and DependencyContainer
- `DaisyBells/Models/` — SwiftData @Model classes, shared across features
- `DaisyBells/Schema/` — VersionedSchema and MigrationPlan
- `DaisyBells/Services/` — Business logic and persistence, shared across features
- `DaisyBells/Features/{Feature}/` — Views, ViewModels, Routers per feature
- `DaisyBells/Components/` — Reusable UI components used by 2+ features
- `DaisyBells/Extensions/` — Swift type extensions (e.g., Date+Formatting, Double+Units)
- `DaisyBells/Resources/` — Assets.xcassets and SeedData/ JSON files
- `DaisyBellsTests/` — Tests for Services and ViewModels

## SwiftData Concurrency
- ModelContext and @Model types are NOT Sendable
- Use @MainActor for ViewModels
- Use @ModelActor for background SwiftData work
- Transfer models between contexts via PersistentIdentifier

## Avoid
- Do not use @Query in views—fetch through services
- Do not use singletons or global state
- Do not add third-party packages
- Do not create new features without updating docs/FEATURES.md
