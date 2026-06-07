# Tasks Plan — FLOWSTATE - The Adaptive Focus Engine

## 📌 Global Assumptions
- Developer has Apple Developer Program membership for code signing and notarization
- Development machine runs macOS 14+ with Xcode 16+
- Swift 6 language mode is enabled for strict concurrency
- App targets macOS 14+ (Sonoma) as minimum deployment target
- DeviceActivity framework may not be available without FamilyControls entitlement, IOKit fallback is primary approach
- User will grant Accessibility permission for full feature set
- App Store sandbox limitations may prevent some features (screen tinting), notarized direct distribution as fallback

## ⚠️ Risks
- Accessibility permission requirement may deter some users from enabling activity monitoring
- Screen tinting via NSPanel may not work reliably in full-screen apps or on all macOS versions
- App Store review may reject app due to Accessibility API usage for non-accessibility purposes
- Focus score algorithm may need significant tuning to feel accurate to users
- Carbon API for global shortcuts is deprecated; may need migration in future macOS versions
- Multi-display support complexity may introduce edge case bugs
- Competition from Apple's built-in Focus modes may reduce perceived value

## 🧩 Epics
## Epic 1: Core App Infrastructure
**Goal:** Establish the foundational macOS menu bar app structure with proper lifecycle management

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Create SwiftUI 6 Menu Bar App Shell (S)

Initialize Xcode project with SwiftUI App lifecycle, configure MenuBarExtra for menu bar presence, hide dock icon via Info.plist LSUIElement, set deployment target to macOS 14+

**Acceptance Criteria**
- App launches and appears only in menu bar
- No dock icon visible
- MenuBarExtra displays placeholder icon
- App quits cleanly from menu bar

**Dependencies**
_None_

### ✅ Implement AppState Observable (S)

Create @Observable AppState class to hold global app state including timer state, focus score, session history reference. Wire to SwiftUI environment.

**Acceptance Criteria**
- AppState is @Observable and propagates changes
- All child views can access via @Environment
- State persists correctly during app lifecycle

**Dependencies**
- Create SwiftUI 6 Menu Bar App Shell

### ✅ Implement UserPreferences with @AppStorage (S)

Create UserPreferences struct/class using @AppStorage for work duration, break duration, auto-extension enabled, vignette enabled, vignette intensity, shortcuts config, launch at login toggle

**Acceptance Criteria**
- All preferences persist across app launches
- Default values are sensible (25min work, 5min break)
- Changes reflect immediately in UI
- Migration path exists for future schema changes

**Dependencies**
- Create SwiftUI 6 Menu Bar App Shell

### ✅ Create Settings Window with Settings Scene (M)

Implement Settings scene accessible via menu bar menu and Cmd+, shortcut. Include tabs for Timer, Focus Detection, Appearance, Shortcuts, About

**Acceptance Criteria**
- Settings opens via Cmd+, or menu item
- Tab navigation works correctly
- Window appears in front when opened
- Changes save immediately without explicit save button

**Dependencies**
- Implement UserPreferences with @AppStorage

### ✅ Implement LoginItemManager (S)

Create LoginItemManager using SMAppService to register/unregister app as login item. Expose toggle in settings with current status display

**Acceptance Criteria**
- Toggle in settings enables/disables login item
- Current status accurately reflects SMAppService state
- Works correctly after app restart
- Handles errors gracefully (shows guidance if fails)

**Dependencies**
- Create Settings Window with Settings Scene

## Epic 2: Timer Core
**Goal:** Implement the foundational Pomodoro timer with state machine and persistence

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Design TimerService State Machine (M)

Define timer states (idle, working, onBreak, paused) and valid transitions. Create TimerState enum and TimerService actor with async methods for start, pause, resume, stop, skip

**Acceptance Criteria**
- State machine prevents invalid transitions
- All transitions emit state change notifications
- Thread-safe via Swift actor isolation
- Unit tests cover all state transitions

**Dependencies**
- Implement AppState Observable

### ✅ Implement Timer Countdown Logic (M)

Create async timer using Task and Clock.sleep for countdown. Track remaining seconds, emit tick updates, handle completion transition to break/idle

**Acceptance Criteria**
- Timer counts down accurately (within 100ms)
- Works correctly after app backgrounding
- Pause/resume maintains correct remaining time
- Completion triggers correct next state

**Dependencies**
- Design TimerService State Machine

### ✅ Add Timer Persistence for Crash Recovery (S)

Persist active timer state (start time, duration, state) to UserDefaults on each state change. On app launch, detect and optionally resume interrupted sessions

**Acceptance Criteria**
- Timer survives app crash/force quit
- User prompted to resume or discard on relaunch
- No stale timers from days ago auto-resume
- Clean persistence on normal session end

**Dependencies**
- Implement Timer Countdown Logic

### ✅ Implement Timer Extension Logic (S)

Add method to extend current work session by configurable increment (default 5min). Extension triggered by FocusScoreEngine when score exceeds threshold during work period

**Acceptance Criteria**
- Extension adds time to remaining duration
- Extension count tracked per session
- Maximum extension limit configurable
- Extension logged for analytics

**Dependencies**
- Implement Timer Countdown Logic

## Epic 3: Menu Bar UI
**Goal:** Create the menu bar interface with dynamic glow indicator and session controls

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Design Menu Bar Icon with SF Symbols (S)

Create base menu bar icon using SF Symbol (e.g., flame, circle, custom). Icon should be template image for automatic dark/light mode

**Acceptance Criteria**
- Icon visible in menu bar in both light and dark mode
- Icon size matches system menu bar items
- Icon is recognizable and distinct

**Dependencies**
- Create SwiftUI 6 Menu Bar App Shell

### ✅ Implement Dynamic Glow Effect on Icon (M)

Create animated glow/brightness effect on menu bar icon that intensifies with focus score. Use Core Animation or SwiftUI animation on icon opacity/blur

**Acceptance Criteria**
- Glow intensity maps to focus score 0-100
- Animation is smooth (60fps)
- Effect visible but not distracting
- Respects reduce motion accessibility setting

**Dependencies**
- Design Menu Bar Icon with SF Symbols

### ✅ Build Menu Bar Dropdown UI (M)

Create MenuBarExtra content view with: current timer display (MM:SS), session type label, start/pause/stop buttons, skip break button, quick stats, settings access

**Acceptance Criteria**
- Timer updates every second when active
- Buttons reflect current state (pause vs resume)
- UI fits within reasonable menu dropdown size
- Keyboard navigation works within menu

**Dependencies**
- Implement Timer Countdown Logic
- Design Menu Bar Icon with SF Symbols

### ✅ Add Focus Score Display to Menu (S)

Show current focus intensity in menu dropdown as progress bar or numeric percentage. Include brief explanation tooltip

**Acceptance Criteria**
- Score updates in near real-time
- Visual clearly indicates high vs low focus
- Tooltip explains what affects score

**Dependencies**
- Build Menu Bar Dropdown UI

### ✅ Implement Session History Quick View (S)

Add 'Today' section to menu showing completed sessions count, total focus time, average focus score

**Acceptance Criteria**
- Stats reflect current day only
- Resets at midnight
- Shows encouraging message if no sessions yet

**Dependencies**
- Build Menu Bar Dropdown UI

## Epic 4: Activity Monitoring & Focus Detection
**Goal:** Implement user activity monitoring to calculate focus score and drive auto-extension

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Research DeviceActivity Framework Access (S)

Investigate DeviceActivity framework requirements. Determine if FamilyControls entitlement is mandatory. Document findings and decide on primary vs fallback approach

**Acceptance Criteria**
- Clear documentation of framework requirements
- Decision made on primary monitoring approach
- Fallback strategy defined if DeviceActivity unavailable

**Dependencies**
_None_

### ✅ Implement IOKit HID Event Monitoring Fallback (L)

Create ActivityMonitorService using IOKit to monitor keyboard/mouse activity. Track events per time window. Requires Accessibility permission

**Acceptance Criteria**
- Detects keyboard and mouse activity
- Sampling rate configurable (default 1s)
- Low CPU overhead (<1% when monitoring)
- Gracefully handles permission denial

**Dependencies**
- Research DeviceActivity Framework Access

### ✅ Implement Accessibility Permission Flow (M)

Create permission request UI explaining why Accessibility access needed. Detect current permission state, guide user to System Settings if needed, detect when granted

**Acceptance Criteria**
- Clear explanation of why permission needed
- Direct link to System Settings Accessibility pane
- App detects permission grant without restart
- Feature gracefully disabled if permission denied

**Dependencies**
- Implement IOKit HID Event Monitoring Fallback

### ✅ Design FocusScoreEngine Algorithm (M)

Create FocusScoreEngine that converts activity metrics into 0-100 focus score. Consider: typing rhythm consistency, mouse idle periods, activity gaps. Make thresholds configurable

**Acceptance Criteria**
- Score 0-100 calculated from activity data
- High consistent typing = high score
- Long idle gaps = lower score
- Algorithm documented for future tuning

**Dependencies**
- Implement IOKit HID Event Monitoring Fallback

### ✅ Implement Focus Score to Timer Extension Bridge (M)

Wire FocusScoreEngine to TimerService. When work timer has <2min remaining and focus score >80, auto-extend. Show subtle notification of extension

**Acceptance Criteria**
- Auto-extension triggers at correct threshold
- User notified of extension (non-intrusively)
- Extension can be disabled in settings
- Maximum extensions per session respected

**Dependencies**
- Design FocusScoreEngine Algorithm
- Implement Timer Extension Logic

### ✅ Add Active App Tracking (Optional Enhancement) (M)

Track which app is frontmost. Allow user to define 'productive' apps. Factor app category into focus score calculation

**Acceptance Criteria**
- Frontmost app detected correctly
- User can mark apps as productive/distracting
- App category influences focus score
- Feature can be disabled

**Dependencies**
- Design FocusScoreEngine Algorithm

## Epic 5: Screen Tinting & Peripheral Nudges
**Goal:** Implement subtle screen desaturation/vignette for break notifications

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Research Screen Overlay Approaches (M)

Evaluate NSPanel with nonactivatingPanel vs CGDisplayStream overlay vs color profile manipulation. Test on multiple displays. Document approach with tradeoffs

**Acceptance Criteria**
- Approach works on built-in and external displays
- Overlay doesn't block mouse/keyboard input
- Compatible with full-screen apps
- Decision documented with rationale

**Dependencies**
_None_

### ✅ Implement ScreenTintController with NSPanel (L)

Create borderless, transparent NSPanel covering screen. Panel ignores mouse events, sits above all windows. Apply Core Image filter for desaturation

**Acceptance Criteria**
- Overlay covers entire screen
- All input passes through to apps below
- Overlay level correct (above most windows)
- Works with multiple displays

**Dependencies**
- Research Screen Overlay Approaches

### ✅ Implement Desaturation Animation (M)

Create smooth animation from full color to grayscale using CIFilter saturation adjustment. Animation duration configurable (default 30s ease-in)

**Acceptance Criteria**
- Animation is smooth and gradual
- Final state is noticeable grayscale
- Duration configurable in settings
- Respects reduce motion (instant change option)

**Dependencies**
- Implement ScreenTintController with NSPanel

### ✅ Implement Vignette Edge Effect (M)

Add vignette effect (darkened edges) as alternative or addition to desaturation. Use CIFilter vignette or custom gradient overlay

**Acceptance Criteria**
- Vignette visible at screen edges
- Intensity configurable
- Can be used alone or with desaturation
- Performance impact minimal

**Dependencies**
- Implement ScreenTintController with NSPanel

### ✅ Integrate Tint with Break Notification Flow (S)

Wire ScreenTintController to TimerService. Start tint animation when break is due (work timer expires). Clear tint when break starts or user acknowledges

**Acceptance Criteria**
- Tint begins automatically at work end
- Starting break clears tint immediately
- Dismissing notification clears tint
- Tint disabled option works correctly

**Dependencies**
- Implement Desaturation Animation
- Implement Timer Countdown Logic

### ✅ Handle Multi-Display Configuration (M)

Extend ScreenTintController to create overlay for each connected display. Handle display connect/disconnect events

**Acceptance Criteria**
- Tint appears on all connected displays
- New displays get overlay when connected
- Disconnected displays clean up properly
- Performance acceptable with 3+ displays

**Dependencies**
- Implement ScreenTintController with NSPanel

## Epic 6: Global Keyboard Shortcuts
**Goal:** Allow users to control FlowState without clicking the menu bar

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Implement GlobalShortcutHandler with Carbon API (L)

Create GlobalShortcutHandler using RegisterEventHotKey (Carbon) or modern alternative. Support configurable shortcuts for: start/pause, stop, skip break

**Acceptance Criteria**
- Shortcuts work when any app is focused
- Shortcuts configurable in settings
- Conflicts with system shortcuts detected
- Shortcuts persist across app restart

**Dependencies**
- Create Settings Window with Settings Scene

### ✅ Build Shortcut Recording UI (M)

Create settings UI component to record custom keyboard shortcuts. Show current binding, allow re-recording, handle conflicts

**Acceptance Criteria**
- Click field then press keys to record
- Shows modifier keys correctly (⌘⇧⌥⌃)
- Warns on conflict with common shortcuts
- Clear button to remove shortcut

**Dependencies**
- Implement GlobalShortcutHandler with Carbon API

### ✅ Add Default Shortcuts with First-Run Setup (S)

Define sensible default shortcuts (e.g., ⌘⇧F for toggle). On first launch, show shortcuts to user. Allow skipping shortcut setup

**Acceptance Criteria**
- Defaults are memorable and unlikely to conflict
- User informed of shortcuts on first run
- User can change or disable defaults

**Dependencies**
- Build Shortcut Recording UI

## Epic 7: Session History & Analytics
**Goal:** Store and display session history for user insights

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Design Session Data Model (S)

Define FocusSession struct with: id, startTime, endTime, plannedDuration, actualDuration, extensionCount, averageFocusScore, sessionType (work/break), completed bool

**Acceptance Criteria**
- Model is Codable for JSON persistence
- All relevant session data captured
- Model is Sendable for Swift 6 concurrency

**Dependencies**
_None_

### ✅ Implement SessionHistoryStore (M)

Create SessionHistoryStore to save/load sessions from JSON file in Application Support. Support queries: today, this week, date range

**Acceptance Criteria**
- Sessions persist across app launches
- File stored in appropriate App Support directory
- Query methods work correctly
- Large history (1000+ sessions) performs well

**Dependencies**
- Design Session Data Model

### ✅ Integrate Session Recording with Timer (S)

Wire TimerService to SessionHistoryStore. Save session on completion (work or break). Include focus metrics in saved session

**Acceptance Criteria**
- Every completed session is saved
- Cancelled sessions optionally saved (configurable)
- Session includes accurate focus score data

**Dependencies**
- Implement SessionHistoryStore
- Implement Timer Countdown Logic

### ✅ Build History View in Settings (L)

Create History tab in Settings showing: daily/weekly charts, session list, totals. Use Swift Charts for visualization

**Acceptance Criteria**
- Chart shows focus time per day
- Session list is scrollable and filterable
- Totals update correctly
- Empty state shows helpful message

**Dependencies**
- Integrate Session Recording with Timer
- Create Settings Window with Settings Scene

### ✅ Add Data Export Functionality (S)

Add export button in History view to save data as CSV or JSON. Use NSSavePanel for file destination

**Acceptance Criteria**
- Export produces valid CSV/JSON
- User chooses save location
- All session fields included in export
- Large exports don't freeze UI

**Dependencies**
- Build History View in Settings

## Epic 8: Logging & Observability
**Goal:** Implement comprehensive logging for debugging and analytics

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Set Up Unified Logging (os_log) (S)

Create logging infrastructure using os_log with subsystem 'com.flowstate.app'. Define categories: timer, activity, focus, tint, shortcuts, lifecycle

**Acceptance Criteria**
- Logs appear in Console.app filtered by subsystem
- Categories allow granular filtering
- Log levels used appropriately (debug/info/error)

**Dependencies**
_None_

### ✅ Add Logging Throughout App (M)

Instrument key code paths with appropriate logging: state transitions, permission changes, errors, significant user actions

**Acceptance Criteria**
- Timer state changes logged at info level
- Activity samples logged at debug level
- Errors logged with context
- No sensitive data in logs

**Dependencies**
- Set Up Unified Logging (os_log)

### ✅ Create In-App Debug View (Development) (S)

Add hidden debug view (accessible via secret shortcut) showing: current state, focus metrics, recent logs, permission status

**Acceptance Criteria**
- Debug view shows real-time state
- Recent log entries visible
- Permission status clear
- Only accessible in debug builds or via secret

**Dependencies**
- Add Logging Throughout App

## Epic 9: Testing & Quality
**Goal:** Ensure app reliability through comprehensive testing

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Write Unit Tests for FocusScoreEngine (M)

Create XCTest suite for FocusScoreEngine. Test score calculation with known inputs, boundary conditions, threshold triggers

**Acceptance Criteria**
- Tests cover normal inputs
- Tests cover edge cases (no activity, constant activity)
- Tests verify thresholds trigger correctly
- Tests run in <1s

**Dependencies**
- Design FocusScoreEngine Algorithm

### ✅ Write Unit Tests for TimerService (M)

Create XCTest suite for TimerService. Test state machine transitions, pause/resume accuracy, extension logic, persistence

**Acceptance Criteria**
- All state transitions tested
- Invalid transitions verified to fail
- Time calculations accurate
- Persistence/recovery tested with mocks

**Dependencies**
- Implement Timer Countdown Logic

### ✅ Write Unit Tests for SessionHistoryStore (S)

Create XCTest suite for SessionHistoryStore using temporary directory. Test CRUD operations, queries, data integrity

**Acceptance Criteria**
- Save and load roundtrip works
- Queries return correct results
- Empty state handled correctly
- Corrupted file handled gracefully

**Dependencies**
- Implement SessionHistoryStore

### ✅ Create Integration Test for Full Session Flow (M)

Write integration test simulating full session: start timer, inject activity data, verify extension triggers, complete session, verify history saved

**Acceptance Criteria**
- Test covers happy path end-to-end
- Uses mock activity data
- Verifies all components integrate correctly
- Test completes in <5s

**Dependencies**
- Write Unit Tests for TimerService
- Write Unit Tests for FocusScoreEngine

### ✅ Manual Test Plan for Visual Features (S)

Document manual test procedures for: menu bar glow, screen tinting, multi-display, accessibility settings respect, permission flows

**Acceptance Criteria**
- Test plan covers all visual features
- Steps are reproducible
- Expected results clearly stated
- Covers light/dark mode, reduce motion

**Dependencies**
- Implement Dynamic Glow Effect on Icon
- Implement Desaturation Animation

## Epic 10: Distribution & Release
**Goal:** Prepare app for distribution via App Store or direct download

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Configure App Sandbox Entitlements (M)

Set up sandbox entitlements for App Store: user-selected file access (export), network (none needed), accessibility (for monitoring/tinting)

**Acceptance Criteria**
- App runs correctly with sandbox enabled
- All features work within sandbox limits
- Entitlements minimized to necessary set

**Dependencies**
_None_

### ✅ Create App Icons and Assets (S)

Design app icon in all required sizes for macOS. Create menu bar icon variants. Add to asset catalog

**Acceptance Criteria**
- App icon at all required resolutions
- Menu bar icon is template image
- Icons look good in light and dark mode
- Icon reflects app purpose (focus/flow)

**Dependencies**
_None_

### ✅ Set Up Code Signing and Notarization (M)

Configure Xcode for Developer ID signing. Set up notarization workflow for direct distribution. Document steps

**Acceptance Criteria**
- App is signed with valid Developer ID
- Notarization succeeds
- App opens without Gatekeeper warnings
- Process documented for future releases

**Dependencies**
- Configure App Sandbox Entitlements

### ✅ Create DMG Installer for Direct Distribution (S)

Create branded DMG with app and Applications folder alias. Add background image and license if needed

**Acceptance Criteria**
- DMG opens with clear install instructions
- Drag-to-Applications works correctly
- DMG is notarized along with app
- File size reasonable (<20MB)

**Dependencies**
- Set Up Code Signing and Notarization

### ✅ Prepare App Store Submission (If Pursuing) (L)

Create App Store Connect entry, write description, take screenshots, submit for review. Handle review feedback

**Acceptance Criteria**
- All App Store metadata complete
- Screenshots show key features
- Privacy policy URL provided
- Ready to submit for review

**Dependencies**
- Configure App Sandbox Entitlements
- Create App Icons and Assets

## ❓ Open Questions
- Should the app support different timer profiles (e.g., 'Deep Work' vs 'Regular') with different durations and extension rules?
- How should break reminder escalation work if user ignores desaturation for extended period?
- Should we include any sound/haptic options for users who prefer audible notifications alongside visual?
- What should happen if user is in a video call (camera active)? Should tinting be suppressed?
- Should session history sync via iCloud for multi-Mac users?
- How do we handle the app being open but user is away (no activity)? Should idle detection pause/reset timers?