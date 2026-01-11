# Project Context
This project is a high-performance, aesthetically pleasing Markdown Editor built with Flutter, intended for eventual open-sourcing. It aims to provide a premium user experience with a focus on visual excellence, smooth interactions, and robust engineering.

# Tech Stack
- **Framework**: Flutter (Latest Stable)
- **Language**: Dart
- **Testing**: flutter_test, integration_test

# Development Guidelines

## 1. Code Quality & Style
- **Strict Linting**: We adhere to strict linting rules. Ensure `flutter analyze` passes before committing.
- **Documentation**: As an open-source project, all public classes and methods MUST have DartDoc comments (`///`).
- **Immutability**: Prefer immutable state using standard Dart `final` fields. Use `const` constructors wherever possible.
- **Type Safety**: strict type safety. Avoid `dynamic` unless absolutely necessary.

## 2. Architecture
- **Feature-First Structure**: Organize code by features (e.g., `lib/features/editor`, `lib/features/preview`) rather than technical layers.
- **Layered Approach**:
  - **Presentation**: Widgets and State Management (Providers/Controllers).
  - **Domain**: Entities and Business Logic (Pure Dart).
  - **Data**: Repositories and Data Sources.

## 3. Aesthetics & UI
- **Visual Excellence**: The UI should feel premium. Use generous whitespace, subtle shadows, and blurred backgrounds (glassmorphism) where appropriate.
- **Animations**: Interfaces should be dynamic. Use implicit animations to bring static elements to life.
- **Platform Fidelity**: While custom, the app should feel at home on desktop platforms (macOS/Windows/Linux) and Web.

## 4. Testing Strategy
- **Unit Tests**: Verify business logic and ViewModels.
- **Widget Tests**: Verify UI component rendering and basic interactions.
- **Integration Tests**: Verify end-to-end flows.
- **Conformance Testing**: When adding support for new markdown elements, they MUST be added to the spec tests filter in `test/spec_test.dart` and the parser MUST pass the relevant CommonMark conformance tests to ensure spec compliance.

## 5. Git & Workflow
- **AI Agent Restriction**: 
  > [!CRITICAL]
  > **ABSOLUTE RULE**: The AI agent MUST NOT commit changes unless **EXPLICITLY** instructed by the user via a clear and direct command (e.g., `/commit`).
  > - **NO** autonomous commits.
  > - **NO** assuming consent from implied tasks (like "update readme" or "fix lints").
  > - **NO** "cleaning up" after a sync.
  > - **ALWAYS** ask for permission before running `git commit`.
  > **VIOLATION OF THIS RULE IS A CRITICAL FAILURE.**
- **Commits**: Follow <type>(<scope>): <subject> convention.
- **PRs**: Keep PRs focused on single tasks or features.
