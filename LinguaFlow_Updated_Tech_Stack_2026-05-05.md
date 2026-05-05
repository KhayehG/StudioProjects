# LinguaFlow - Complete Updated Tech Stack (Verified)

Verified against:
- `pubspec.yaml`
- `pubspec.lock` (resolved versions)
- Key implementation files in `lib/services` and `lib/screens`

## Frontend
- Flutter: >=3.38.4 (SDK constraint from lockfile)
- Dart: >=3.11.5 <4.0.0
- flutter_riverpod: 2.6.1
- go_router: 14.8.1
- fl_chart: 0.68.0

## Backend and Database
- firebase_auth: 5.7.0
- cloud_firestore: 5.6.12
- firebase_messaging: 15.2.10
- sqflite: 2.4.2+1

## AI and Machine Learning
- Groq-compatible chat completions endpoint via `OpenAiService`
  - Endpoint: `https://api.groq.com/openai/v1/chat/completions`
  - Model: `llama-3.1-8b-instant`
- SM-2 style spaced repetition algorithm (`calculateSrs`)
- Levenshtein distance for pronunciation similarity scoring
- MediaPipe hand models:
  - `assets/models/hand_landmark.tflite`
  - `assets/models/palm_detection.tflite`
- Geometric/rule-based ASL letter classification in sign detector logic

## Speech and Audio
- speech_to_text: 7.3.0
- flutter_tts: 4.2.5

## Computer Vision
- camera: 0.10.6
- tflite_flutter: 0.11.0
- image: 4.8.0

## Document Generation
- pdf: 3.12.0
- printing: 5.14.3
- intl: 0.19.0

## Storage and Preferences
- sqflite: 2.4.2+1
- shared_preferences: 2.5.5
- path_provider: 2.1.5

## Notifications
- flutter_local_notifications: 17.2.4
- firebase_messaging: 15.2.10
- timezone: 0.9.4

## Networking and APIs
- http: 1.6.0
- cached_network_image: 3.4.1

## Architecture and Patterns in Codebase
- Service-oriented architecture (service classes for auth, lessons, quiz, vocab, notifications, certificate, chatbot)
- Offline-first lessons flow (local SQLite + Firestore sync path)
- Seeder pattern (`SeederService`) for lessons/quizzes/sign lessons
- Singleton usage where applicable (e.g., NotificationService, LocalStorageService)
- SRS-based vocabulary review scheduling

## Core Firestore Collections (Observed)
- `users/{uid}`
- `users/{uid}/vocabulary`
- `users/{uid}/quizResults`
- `users/{uid}/chatHistory`
- `lessons`
- `quizzes`
- `sign_lessons`

## Accuracy Corrections Compared to Provided Draft
- Corrected package versions to resolved lockfile values where they differed:
  - `speech_to_text`: 7.3.0 (not 7.0.0)
  - `camera`: 0.10.6 (not 0.10.5+9)
  - `image`: 4.8.0 (not 4.1.7)
  - `cached_network_image`: 3.4.1 (not 3.3.1)
  - `path_provider`: 2.1.5 (not 2.1.2)
  - `sqflite`: 2.4.2+1 (not 2.4.2 exact)
- Preserved accurate entries that already matched lockfile:
  - `firebase_auth` 5.7.0
  - `cloud_firestore` 5.6.12
  - `firebase_messaging` 15.2.10
  - `flutter_local_notifications` 17.2.4
  - `go_router` 14.8.1
  - `flutter_riverpod` 2.6.1
  - `pdf` 3.12.0
  - `printing` 5.14.3
  - `shared_preferences` 2.5.5
  - `http` 1.6.0
  - `timezone` 0.9.4

