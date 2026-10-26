# MindCore AI

Tactical, strict-offline Android assistant prototype built with Flutter. This directory currently contains the UI prototype, not a complete local AI runtime.

## Current prototype features
- Tactical dashboard, chat shell, app-control screen, model bay, privacy screen.
- No cloud API integration or analytics code in this prototype.
- UI labels distinguish unconnected features from working controls.
- App selection, Accessibility integration, local inference, encryption, voice recognition and retention are not implemented yet.

## Build APK with GitHub Actions
Open the repository Actions tab and run **Build MindCore AI Android APK** (or push changes under mindcore_ai/). The workflow scaffolds the Android host with Flutter, resolves dependencies and builds a debug APK artifact.

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
