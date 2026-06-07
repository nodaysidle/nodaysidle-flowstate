# FLOWSTATE

## 🎯 Product Vision
An adaptive focus engine that intelligently extends work sessions when users are in deep focus, using subtle peripheral visual cues instead of disruptive notifications to create a premium, non-intrusive productivity experience.

## ❓ Problem Statement
Traditional Pomodoro timers interrupt users at fixed intervals regardless of their actual focus state, breaking flow precisely when productivity is highest. Existing screen time tools are passive reporters rather than active coaches, and timer apps rely on jarring audio notifications that disrupt concentration.

## 🎯 Goals
- Automatically detect and extend deep work sessions using activity awareness
- Provide subconscious visual feedback through screen tinting and vignetting instead of audio alerts
- Display a menu bar widget that reflects focus intensity in real-time
- Run unobtrusively as a menu bar application without dock presence
- Coach users toward better focus habits without being annoying

## 🚫 Non-Goals
- Replacing Apple Screen Time or competing as a device usage reporter
- Providing detailed analytics dashboards or productivity reports
- Supporting platforms other than macOS
- Integrating with third-party task management or calendar apps
- Blocking apps or enforcing restrictions

## 👥 Target Users
- Knowledge workers who experience frequent interruptions during deep work
- Developers and writers who need extended uninterrupted focus sessions
- Pomodoro technique users frustrated by rigid timer interruptions
- Professionals seeking a premium, subtle productivity tool over gamified alternatives

## 🧩 Core Features
- Menu bar Live Activity widget that glows brighter with sustained deep work
- Activity-aware timer extension using DeviceActivity framework for typing rhythm and app usage detection
- Peripheral nudges via screen edge desaturation and vignetting for break reminders
- Global keyboard shortcuts for timer control via Carbon/AddingMachine APIs
- Settings scene for configuring nudge intensity, detection sensitivity, and timer defaults
- Login item support for automatic startup
- Invisible-until-needed design philosophy with minimal UI chrome

## ⚙️ Non-Functional Requirements
- Runs exclusively in menu bar with no dock icon using MenuBarExtra
- Sandboxed for App Store distribution or notarized for direct distribution
- Minimal CPU and memory footprint during background activity monitoring
- Swift 6 concurrency compliance for all async operations
- SwiftUI 6 for all UI components with AppKit integration where necessary
- Accessibility API usage for system-level screen tinting effects
- Data persistence via UserDefaults and JSON files with Keychain for sensitive data

## 📊 Success Metrics
- Average deep work session duration increases compared to fixed Pomodoro intervals
- Users report fewer perceived interruptions during focus sessions
- High retention rate indicating the subtle UX is valued over competitors
- Low system resource usage during continuous background monitoring
- Positive App Store reviews highlighting the non-intrusive notification approach

## 📌 Assumptions
- DeviceActivity framework provides sufficient signal for detecting deep work states
- Screen tinting via Accessibility APIs is permitted within App Store sandbox or notarization
- Users prefer visual peripheral cues over audio notifications for break reminders
- Typing rhythm and app usage are reliable proxies for focus intensity
- macOS users are the primary market for a premium focus tool

## ❓ Open Questions
- What specific DeviceActivity metrics best indicate deep work versus shallow work?
- How will screen tinting interact with external displays and color profiles?
- What is the optimal brightness curve for the menu bar glow indicator?
- Should users be able to manually override automatic timer extensions?
- How to handle scenarios where DeviceActivity permissions are denied?
- What is the minimum macOS version required for all planned features?