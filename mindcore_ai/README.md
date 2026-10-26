# MindCore AI

Tactical, strict-offline Android assistant prototype built with Flutter. This directory currently contains the UI prototype, not a complete local AI runtime.

## Current prototype features
- Tactical dashboard, chat shell, app-control screen, model bay, privacy screen.
- No cloud API integration or analytics code in this prototype.
- UI labels distinguish unconnected features from working controls.
- App selection, Accessibility integration, local inference, encryption, voice recognition and retention are not implemented yet.

## Build APK with GitHub Actions
Open the repository Actions tab and run **Build MindCore AI Android APK** (or push changes under mindcore_ai/). The workflow scaffolds the Android host with Flutter, resolves dependencies and builds a debug APK artifact.

## Automated validation

The GitHub Actions workflow runs strict Dart analysis, widget tests, and a debug APK build. The widget suite checks dashboard rendering, navigation across all five sections, chat input/clear behavior, the Add App prototype notice, the offline preference toggle, and smoke rendering at 320×640, 360×800 and 412×915 logical pixels. APK verification checks that the output exists, passes ZIP integrity validation, and prints a SHA-256 checksum.

These are source/CI tests, not a physical-device installation test. Before daily use, install the debug APK on the target phone and check launch, back navigation, permissions, screen rotation/resize and battery behavior. Since the local LLM, Accessibility executor, offline speech, encrypted storage and retention cleanup are not connected, those capabilities are not validated or available in this prototype.

## Planned integrations
1. Native local LLM runtime (single runtime first; model imported locally).
2. User-enabled AccessibilityService and package allowlist.
3. Confirmation-gated action executor.
4. Offline speech recognition, encrypted history and retention cleanup.
5. Device-specific RAM, thermal and battery testing.

## Security limits
Android does not grant unrestricted control of every installed app. The user must explicitly enable Accessibility access, and apps may hide or protect UI content. Banking/payment actions, purchases, and other sensitive actions must remain blocked from autonomous execution. This prototype does not yet implement device automation or real inference.

## Model files
Model weights are not bundled. Check the model's license and verify memory/runtime compatibility before local import.
