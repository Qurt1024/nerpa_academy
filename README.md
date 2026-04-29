# nerpa_academy

# 🦭 Nerpa Academy

An educational mobile app built with Flutter. Learn subjects through structured lessons, test your knowledge with quizzes, and challenge other students in real-time multiplayer matches — all in English, Russian, or Kazakh.

---

## ✨ Features

### 📚 Lessons & Quizzes
- Browse subjects and lessons tailored to your selection
- Theory screens before each quiz for concept review
- Multiple-choice and free-text answer question types
- Heart-based life system (3 hearts per quiz)
- Instant feedback with correct answer reveal
- Score grading (2–5 scale) on quiz completion

### 🎮 Multiplayer
- **Create a private room** — share a 6-character code with friends
- **Quick Match** — auto-match with another player on the same subject
- Real-time score leaderboard updated as players answer
- 20-second countdown timer per question
- Speed bonus points — answer faster, score higher
- In-room and post-game chat

### 🌐 Multilingual
- Full UI support for **English**, **Russian**, and **Kazakh**
- Language preference persisted across sessions
- Lesson and question content served in the selected language

### 🔐 Authentication
- Email & password sign-up / login
- Google Sign-In
- Subject selection flow for new users
- Profile screen with stats: total score, subjects, completed lessons

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| State Management | flutter_bloc (BLoC + Cubit) |
| Navigation | go_router |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Realtime Multiplayer | Firebase Realtime Database |
| Dependency Injection | Manual (repository pattern) |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/       # Colors, dimensions, string constants
│   ├── l10n/            # Localization (EN / RU / KZ) + LanguageCubit
│   ├── router/          # go_router configuration & auth guards
│   └── theme/           # App theme (light)
├── data/
│   ├── models/          # UserModel, SubjectModel, LessonModel, QuestionModel, RoomModel
│   └── repositories/    # AuthRepository, ContentRepository, MultiplayerRepository
├── features/
│   ├── auth/            # Login, Sign-up, Subject selection screens + AuthBloc
│   ├── home/            # Home screen, Lesson list screen
│   ├── lessons/         # Theory, Quiz, Results screens + LessonBloc
│   ├── multiplayer/     # Hub, Waiting room, Game, Results screens + RoomBloc
│   └── chat/            # Room chat + Profile screens
└── shared/
    └── widgets/         # NerpaButton, NerpaMascot, HeartBar, QuizProgressBar, etc.
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or later)
- A Firebase project with **Authentication**, **Firestore**, and **Realtime Database** enabled
- `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from your Firebase console

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/nerpa-academy.git
   cd nerpa-academy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   Place your Firebase config files in the appropriate directories:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

   Then run FlutterFire CLI to regenerate `lib/firebase_options.dart`:
   ```bash
   flutterfire configure
   ```

4. **Set up environment variables**

   Create a `.env` file in the project root:
   ```env
   # Add any API keys or environment-specific config here
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔥 Firebase Setup

### Firestore Collections

| Collection | Description |
|---|---|
| `users` | User profiles, selected subjects, scores |
| `subjects` | Subject metadata (titles per language, emoji) |
| `lessons` | Lessons under each subject |
| `questions` | Questions per lesson (multilingual, image support) |

### Realtime Database

Used exclusively for multiplayer room state:
- Room status (`waiting` → `playing` → `finished`)
- Player presence, ready state, and scores
- Current question index (host-controlled)



---

## 🌍 Localization

Language strings live in `lib/core/l10n/app_localizations.dart`. Each string is defined once with all three translations:

```dart
String get createRoom => _s(
  en: 'Create Room',
  ru: 'Создать комнату',
  kz: 'Бөлме жасау',
);
```

The active language is managed by `LanguageCubit` and persisted via `SharedPreferences`. To add a new language, extend the `AppLanguage` enum and add a case to each `_s()` call.

---

