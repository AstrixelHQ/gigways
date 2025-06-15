# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Flutter Development
- `flutter pub get` - Install dependencies
- `flutter pub run build_runner build --delete-conflicting-outputs` - Run code generation (Riverpod, Freezed, JSON serialization)
- `flutter run` - Run the app on connected device/emulator
- `flutter clean` - Clean build artifacts
- `flutter test` - Run unit tests

### Code Generation (Required after model/provider changes)
- `flutter pub run build_runner build` - Generate code
- `flutter pub run build_runner watch` - Watch for changes and generate code automatically

### Firebase Cloud Functions
- `cd functions && npm run build` - Build TypeScript functions
- `cd functions && npm run serve` - Run local emulator
- `cd functions && npm run deploy` - Deploy functions to Firebase

### Asset Generation
- Assets are automatically generated via `flutter_gen` to `lib/core/assets/`
- Run `flutter pub get` after adding new assets to regenerate

## Architecture Overview

### Flutter App Structure
- **Feature-First Architecture**: Organized by business domains rather than technical layers
- **State Management**: Riverpod with code generation for providers and notifiers
- **Navigation**: GoRouter with type-safe routing
- **Dependency Injection**: Riverpod providers for services and repositories

### Core Directories
- `lib/features/` - Business feature modules (auth, tracking, insights, etc.)
- `lib/core/` - Shared infrastructure (services, widgets, theme, utils)
- `lib/routers/` - Navigation configuration
- `functions/` - Firebase Cloud Functions (TypeScript)

### Key Patterns
- Each feature contains: `screens/`, `notifiers/`, `widgets/`, `models/`, `repositories/`
- Models use Freezed for immutability and JSON serialization
- Notifiers extend Riverpod's `AsyncNotifier` or `Notifier`
- Services are provided via Riverpod providers in `lib/core/providers/`

### Data Flow
1. UI widgets consume Riverpod providers
2. Notifiers manage state and business logic
3. Repositories handle data access (Firebase, local storage)
4. Services provide external integrations (location, notifications)

### Firebase Integration
- Authentication via multiple providers (Google, Apple, Facebook)
- Firestore for real-time data
- Cloud Functions for server-side logic
- Firebase Storage for file uploads

### Location & Activity Tracking
- Background location tracking with `flutter_background_geolocation`
- Activity recognition for driving detection
- Location permissions handled via `permission_handler`

### Code Generation Dependencies
- Run code generation after changes to:
  - `@riverpod` annotated providers
  - `@freezed` annotated models  
  - `@JsonSerializable` classes
  - Router configurations

### Things to Remember
- Use Shared Theme for consistent styling
- Follow naming conventions for files and classes
- Build best UI/UX and make it intuitive
- Write bug-free, maintainable code and handle edges gracefully
- Seperate out widget in classes for better reusability
- Reuse widgets and components where possible