# Agent Prompts — FLOWSTATE

## 🧭 Global Rules

### ✅ Do
- Use Swift 6 strict concurrency with @Observable and actors
- Target macOS 14+ (Sonoma) as minimum deployment
- Use MenuBarExtra for menu bar presence with LSUIElement=true
- Apply SF Symbols for all iconography

### ❌ Don't
- Do not create dock icon - menu bar only app
- Do not use third-party timer libraries
- Do not store sensitive data outside Keychain
- Do not block main thread with activity monitoring

## 🧩 Task Prompts
## Core App Infrastructure & Menu Bar Shell

**Context**
Initialize SwiftUI 6 menu bar app with Observable state, UserDefaults preferences, and Settings window

### Universal Agent Prompt
```
_No prompt generated_
```