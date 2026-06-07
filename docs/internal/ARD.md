# Architecture Requirements Document

## 🧱 System Overview
FlowState is a macOS menu bar application that functions as an adaptive focus engine, using activity awareness to intelligently extend Pomodoro-style work sessions and providing subtle visual feedback through screen tinting rather than audio notifications.

## 🏗 Architecture Style
Single-process macOS application with menu bar presence, background activity monitoring, and system-level accessibility integration

## 🎨 Frontend Architecture
- **Framework:** SwiftUI 6 with MenuBarExtra for menu bar presence and Settings scene for preferences
- **State Management:** SwiftUI @Observable macro with @Environment for dependency injection, centralized app state via singleton or environment object
- **Routing:** Settings scene navigation via SwiftUI TabView, no complex routing required for menu bar app
- **Build Tooling:** Xcode with Swift Package Manager for dependencies, notarization workflow for direct distribution or App Store submission

## 🧠 Backend Architecture
- **Approach:** Monolithic single-process architecture with distinct service layers for timer management, activity detection, and visual effects
- **API Style:** Internal Swift protocols and async/await for inter-service communication, no external API
- **Services:**
- TimerService - Core timer logic with pause/resume/extend capabilities
- ActivityMonitorService - DeviceActivity framework integration for typing rhythm and app usage detection
- FocusScoreEngine - Calculates focus intensity from activity metrics to drive UI brightness and timer extensions
- ScreenTintController - AppKit/Accessibility API integration for peripheral vignetting and desaturation effects
- GlobalShortcutHandler - Carbon/AddingMachine API wrapper for system-wide keyboard shortcuts
- LoginItemManager - ServiceManagement framework integration for launch-at-login support

## 🗄 Data Layer
- **Primary Store:** UserDefaults for preferences and timer state, JSON files for session history, Keychain for any sensitive configuration
- **Relationships:** Flat data model with no complex relationships - timer sessions, user preferences, and focus metrics stored independently
- **Migrations:** Version key in UserDefaults to handle schema changes, simple conditional migration on app launch

## ☁️ Infrastructure
- **Hosting:** Local macOS application distributed via Mac App Store or direct download with notarization
- **Scaling Strategy:** Not applicable - single-user desktop application with no server components
- **CI/CD:** Xcode Cloud or GitHub Actions for automated builds, testing, notarization, and App Store submission

## ⚖️ Key Trade-offs
- MenuBarExtra limits UI complexity but ensures unobtrusive presence - accepted for core product philosophy
- DeviceActivity framework requires user permission and may have limited metrics - fallback to simpler heuristics if needed
- Screen tinting via Accessibility APIs may require elevated permissions or be restricted on some displays - graceful degradation to menu bar glow only
- App Store sandbox restrictions may limit system-level features - notarized direct distribution as alternative path
- Carbon APIs for global shortcuts are legacy but stable - acceptable for keyboard shortcut requirements

## 📐 Non-Functional Requirements
- CPU usage under 1% during background monitoring
- Memory footprint under 50MB during normal operation
- Swift 6 strict concurrency compliance with no data races
- App launch to ready state under 500ms
- Graceful handling of permission denials with user guidance
- Support for macOS 14 Sonoma and later
- Accessibility API compliance for VoiceOver users
- Dark mode and light mode support for all UI elements