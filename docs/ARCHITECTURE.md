# Tech Stack and Constraints
- Swift
- SwiftUI
- SwiftData
- SwiftTesting
- MVVM + Services
- iOS 17+
- Apple Developer Account

**Not using:**
- UIKit
- CoreData
- Combine
- Third-party dependencies
- Cross-platform targets (only iOS)

## Out of Scope
- Cloud sync / iCloud
- Social features
- Coaching or AI-generated plans
- Notifications

---

# Architecture Overview
## Chosen Architecture
MVVM + Services + Shared SwiftData Models

## Concurrency Model
Use Swift Concurrency (async/await, @MainActor, Task { }, actors, Sendable)

### SwiftData Concurrency Rules
- `ModelContext` and SwiftData `@Model` types are **not `Sendable`**
- `@Model` instances must never cross actor or thread boundaries
- The main `ModelContext` must only be accessed from the `MainActor`
- SwiftUI views and `@Query` always operate on the main context
- Background persistence work must be performed in a dedicated `@ModelActor`
  with its own `ModelContext`
- Models are transferred between contexts using `PersistentIdentifier`,
  never by passing model instances directly
- Enable **Strict Concurrency Checking: Complete** in build settings

### Background Operations
- Use `@ModelActor` to isolate all background SwiftData access
- Each `@ModelActor` owns exactly one `ModelContext`
- Do not access SwiftData from arbitrary background tasks
- Avoid `Task {}` for background persistence work if it inherits `MainActor`
- Use `Task.detached` only when actor inheritance must be explicitly avoided;
  prefer actor-based isolation over manual task management

**ViewModels:**
- Annotated with @MainActor
- Expose async intent methods
- Own UI-only state

**Services:**
- Expose async APIs
- Perform all persistence and business logic

**SwiftUI:**
- Reacts to state changes via @Observable
- No Combine

---

# MVVM Rules
## 1. Views
### Rules
- No business logic
- No data mutation
- No direct SwiftData access

### Allowed
- Formatting and presentation logic
- View-only state (@State for UI toggles)
- Calling ViewModel intent methods

### Not Allowed
- Writing to models
- Fetching or mutating persisted data
- Performing business or analytics logic

---

## 2. ViewModels
### Rules
- Annotated with @MainActor
- Own UI state only
- Call services for all mutations
- Never fetch directly from SwiftData

### Responsibilities
- Managing screen-specific state (loading, error, selection)
- Coordinating user interactions
- Exposing data in a UI-friendly form

### Not Responsible For
- Persistence logic
- Business rules
- Data consistency or validation

---

## 3. Services
### Rules
- Own all business logic
- Own all SwiftData access
- Reused across ViewModels
- Mocked in tests via protocols

### Responsibilities
- Enforcing business rules
- Centralizing all persistence access
- Preventing logic duplication across screens
- Acting as the primary unit of testing

---

## 4. Models
### Rules
- SwiftData models are the single source of truth
- Shared across tabs and flows

### Intent
- There must be exactly one authoritative representation of:
- Exercises
- Exercise categories
- Workout templates
- Active workout sessions
- Completed workouts
- Logged exercise sets

---

# Performance Optimization Fields
## Decision
The schema includes denormalized and cached fields for query performance

## Exercise Cache Fields
The Exercise model includes denormalized fields for performance:
- `lastPerformedAt: Date?` — Quick access to last workout date
- `hasCompletedWorkout: Bool` — Fast history check for archive logic
- `totalVolume: Double` — Cached total volume across all workouts
- PR fields (prWeight, prReps, prTime, prDistance, prEstimated1RM, prAchievedAt) — Cached personal records

## LoggedSet Denormalization
The LoggedSet model includes:
- `exerciseId: UUID?` — Direct exercise reference for efficient queries
- `completedAt: Date?` — Timestamp for workout completion queries

## Rationale
These fields enable fast analytics queries without complex relationship traversals. Updated by WorkoutService.complete() to maintain consistency.

## Trade-off
Adds some schema complexity but provides significant performance benefit for analytics features.

---

# SwiftData Predicate Limitations
## WorkoutStatus Enum Storage Workaround
- SwiftData #Predicate macros cannot query enum values directly
- Workout model uses `statusValue: String` for persistence
- Public API exposes computed `status: WorkoutStatus` property
- This workaround required until SwiftData supports enum predicates

## Rationale
Querying workouts by status is essential (completed workouts, active workout detection). String-based storage enables predicate queries while maintaining type-safe public API.

---

# Analytics Modeling
## Decision
Analytics use a hybrid approach: some data is cached for performance, some is derived on-demand

## Rules
- Personal records, volume, and last performed dates are **cached** on Exercise model
- Exercise performance data is **denormalized** on LoggedSet (exerciseId, completedAt) for efficient queries
- Cache fields are updated by WorkoutService when workouts are completed
- AnalyticsService provides aggregations and calculations beyond cached data
- ViewModels only format analytics for presentation, never perform calculations

---

# Dependency Injection
## Decision
Use manual dependency injection with a grouped composition root (DependencyContainer)

## Rules
- Services are injected via protocols
- No dependency injection frameworks
- No runtime resolution or service lookup
- No global service access or singletons

## Why Not @Environment/@EnvironmentObject
- ViewModels cannot access @Environment properties directly
- Missing @EnvironmentObject causes runtime crashes (not compile-time errors)
- Manual injection provides compile-time safety and testability

The DependencyContainer:
- Exists only to group dependency creation
- Does not perform lazy resolution
- Does not act as a service locator

---

# Navigation Pattern
## Decision
Use NavigationStack with enum-based routing and per-tab Routers

## Structure

**Route Enums:**
- One `Hashable` enum per tab defining all navigable destinations
- Associated values for passing data between screens
- Naming convention: `WorkoutsRoute`, `ExercisesRoute`, etc.

**Routers:**
- One `@Observable` router class per tab
- Created in `DependencyContainer`, injected into ViewModels
- Owns a `[Route]` array representing the navigation stack
- Exposes methods: `push(_:)`, `pop()`, `popToRoot()`
- Naming convention: `WorkoutsRouter`, `ExercisesRouter`, etc.

**NavigationStack:**
- One per tab root view, bound to the router's path
- Uses `navigationDestination(for:)` modifier to map routes to views

## Rules
- Views never push views directly—they call ViewModel intent methods
- ViewModels call router methods to navigate
- Routes are exhaustively handled via switch statements
- Use `NavigationLink(value:)`, not `NavigationLink(destination:)` with inline views

## Implementation Notes
- Router path binding: `NavigationStack(path: $router.path)`
- ViewModel receives router via initializer, not environment
- Tab root view receives router from parent (which gets it from DependencyContainer)

---

# ModelContainer Ownership
## Decision
DependencyContainer creates and owns the ModelContainer

## Rationale
- Consistent with existing DI pattern—ModelContainer is just another dependency
- Services receive `ModelContext` via initializer, not environment
- ViewModels remain unaware of SwiftData (they only talk to services)
- Enables straightforward testing with in-memory containers

## Structure
- `DependencyContainer` creates `ModelContainer` at app launch
- `DependencyContainer` passes `container.mainContext` to services that need persistence
- Views do not use `@Query`—all data flows through ViewModels and services

## Testing
- Unit tests create an in-memory `ModelContainer` via `ModelConfiguration(isStoredInMemoryOnly: true)`
- Pass the in-memory context to services under test
- Each test gets an isolated, empty database
- Alternatively, mock the service protocol entirely (no real SwiftData needed)

## Previews
- Use in-memory container with sample data seeded for preview purposes

---

# Error Handling Strategy
## Decision
Services use `async throws`; ViewModels catch and translate to UI state

## Service Layer
- All fallible service methods are declared `async throws`
- Services throw domain-specific errors (e.g., `WorkoutServiceError`)
- Error enums conform to `Error` and `LocalizedError` for user-friendly messages

## ViewModel Layer
- ViewModels call services in `do/catch` blocks
- Errors are caught and translated to UI state (e.g., `errorMessage: String?`, or a `LoadingState` enum)
- ViewModels never expose raw `Error` types to views—they expose user-friendly representations

## LoadingState Pattern (optional, per-screen)
For screens with async data loading, use a state enum:
- `.idle` – not yet started
- `.loading` – in progress
- `.failed(Error)` – operation failed
- `.loaded(T)` – success with data

Views switch on this state to show spinners, error views, or content.

## Rules
- Services throw; ViewModels catch
- No `Result` types—use native throws with async/await
- Views never see `Error` directly—only formatted messages or state enums

---

# Data Seeding Strategy
## Decision
Seed default data from bundled JSON at app launch

## What Gets Seeded
- Default exercise categories (~7)
- Default exercises (~20-50)

## When
- During `DependencyContainer` initialization, after `ModelContainer` is created
- Before any ViewModels or UI are instantiated

## How
- Default data defined in JSON files bundled with the app
- `DependencyContainer` calls seeding methods on services
- Services check if seeding has already run (via UserDefaults flag or similar)
- If first launch, services load JSON, parse, and insert
- Seeding order: categories first, then exercises (due to relationships)

## Rules
- Seeding runs once—on first launch only
- Users can delete any or all defaults; they will not be re-created
- Tests can choose whether to seed or start empty
- Previews seed sample data into in-memory containers

## Placeholder Data (temporary)
- Categories: Category 1, Category 2, ... Category 7
- Exercises: Exercise 1, Exercise 2, ... Exercise 50
- Replace with real fitness data before release

---

# Schema Versioning
## Decision
Use VersionedSchema and SchemaMigrationPlan from day one

## Rationale
- Retrofitting versioned schemas to an unversioned app causes migration failures
- Starting with VersionedSchema has minimal overhead

## Rules
- All `@Model` classes must be registered in the current schema version
- When modifying models, create a new schema version and add a migration stage
- Use lightweight migrations when possible; use custom migrations for data transformations
- `DependencyContainer` creates `ModelContainer` with the current schema and migration plan

## File Organization
- `Schema/SchemaV1.swift`, `SchemaV2.swift`, etc.
- `Schema/MigrationPlan.swift`

---

# Testing Strategy
## Decision
Focus tests on Services and ViewModels

## Rules
- Use SwiftTesting as the default framework
- Services are the primary test surface
- ViewModels tested for state transitions and intent handling
- No SwiftUI view tests initially

---

# Domain Model Reference
## Exercise Library
- Exercise
- ExerciseCategory
- ExerciseType (weight/reps, time, distance, bodyweight)

## Workout Planning
- WorkoutTemplate
- Ordered list of exercises

## Workout Logging
- Workout (with WorkoutStatus: active, completed, cancelled)
- LoggedExercise
- LoggedSet

## Analytics
- Derived from logged data (not persisted)

## App Management
- User settings (units, etc.)
