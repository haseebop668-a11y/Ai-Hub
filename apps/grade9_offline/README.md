# Grade 9 Offline Learning

Android-first, offline-first Flutter application for Grade 9 study and active recall.

## Current implementation

- Warm academic Material 3 dashboard.
- Local SQLite schema for subjects, flashcards, review history, study progress and imported-book metadata.
- Deterministic SM-2 scheduling core with input validation.
- Offline Levenshtein spelling suggestion engine.
- Unit tests for scheduling and spelling algorithms.
- No cloud API calls or analytics SDKs in the runtime dependency set.

## Important content policy

The repository does not bundle textbook PDFs or copied textbook answer banks. Official books remain the authoritative source, and their distribution rights must be respected. Curriculum-specific lessons and question banks are added only after their edition, board and source are verified. The app is designed to support local textbook imports in a subsequent reader module.

## Build locally

Requires Flutter stable and Android SDK:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

## Offline guarantees and limitations

SQLite, SM-2 scheduling and dictionary-based spelling suggestions work locally. Speech recognition, speech synthesis and PDF text extraction are not claimed as complete in this initial implementation. Android TTS depends on an installed device voice; offline STT requires a bundled, licensed language model. The Vosk model catalogue currently does not list Urdu, so Vosk is not a valid Urdu STT solution without a separately sourced and tested model.

## Curriculum baseline

Punjab PECTAA Grade IX books are the default source baseline. Keep the academic year and edition attached to every content record. Federal/NCC curriculum material must be a separate curriculum profile, not silently mixed with Punjab Board material.
