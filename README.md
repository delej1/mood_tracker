# Mood Tracker

A Flutter web app for logging daily moods, with a horizontal scrollable timeline
and 'hand-drawn' emoji faces built with `CustomPainter`.

---

## Features

- **Log a mood** — tap one of three faces (happy, neutral, sad)
- **Timeline** — last 7 entries in a horizontal scrollable list with date, face, and colour accent
- **Tap to animate** — tapping a timeline entry triggers a pulse animation on the face
- **Persistent** — entries survive page refresh via `localStorage` (SharedPreferences)

---

## Architecture

```
lib/
├── data/repositories/       → LocalMoodRepository (SharedPreferences)
├── domain/
│   ├── enums/               → MoodType (+ accentColor, label extensions)
│   ├── models/              → MoodEntry (immutable, Equatable, JSON)
│   └── repositories/        → MoodRepository (abstract interface)
├── presentation/
│   ├── cubit/               → MoodCubit + MoodState
│   ├── screens/             → MoodTrackerScreen (BlocConsumer)
│   └── widgets/
│       ├── mood_face_painter.dart   ← CustomPainter faces
│       ├── mood_picker.dart         ← three tap buttons
│       └── timeline_card.dart       ← horizontal list item
└── main.dart                → BlocProvider root
```

**State management choice — Cubit:**  
All interactions are simple imperative method calls (`logMood`, `selectEntry`).
There are no async event streams needing buffering or transformation.
Cubit's lightweight model keeps the code clear without sacrificing power.

**CustomPainter faces:**  
`MoodFacePainter` uses only `drawCircle`, `drawArc`, and `drawLine`/`drawPath`.
No images, emoji, or icon fonts. Each mood differs through:
- Mouth: upward arc (happy) / flat line (neutral) / downward arc (sad)
- Eyebrows: gentle arc up / flat / angled V inward

---

## Getting started

**Live demo:** https://mood-tracker-2dac9.web.app 
**Loom walkthrough:** https://www.loom.com/share/184fbeba5a6044ba8466e9b992feade2

## Running tests

```bash
flutter test
```

---

## If I had more time

1. **Mood notes** — a text field on the log action so users can capture *why* they feel that way, turning the log into a journal.
2. **Hive instead of SharedPreferences** — for larger datasets, Hive's box-based storage handles binary serialisation more efficiently than a single JSON string in localStorage.
3. **Trend chart** — a simple 7-day line chart (using `fl_chart`) showing mood over time.