# Bayan Sunnah · بيان السنة

An offline-first, ad-free Hadith reader from the **Bayan Islamic Suite**.
Arabic (RTL) is the primary language, the palette is the deep emerald of Bayan
Quran, and everything ships in the app bundle — no accounts, no ads, no network
calls, no tracking.

## Features

- **Collections** — Sahih al-Bukhari, Sahih Muslim, 40 Hadith Nawawi,
  Riyad as-Salihin and Mishkat al-Masabih.
- **Chapter (*kitab*) index** per collection, with per-chapter hadith counts.
- **Hadith reader** — Arabic matn as the primary text, English translation,
  narrator and reference, with copy / share / bookmark actions.
- **Colour-coded authentication badges** — sahih (green), hasan (amber) and
  da'if (red, always shown with its `grade_source`, e.g. "Al-Albani").
- **"Sahih & Hasan only" filter** — a persistent toggle that hides weak
  narrations from the reader, the chapter counts and search results.
- **Full-text search** over the Arabic matn, normalising diacritics and letter
  variants so `الأَعْمَال` and `الاعمال` find the same narrations.
- **Bookmarks** saved locally with `shared_preferences`.
- **Light and dark themes**, plus a configurable Arabic text size.

## Architecture

Feature-first clean architecture with BLoC/Cubit state management:

```
lib/
  app_dependencies.dart          # composition root
  core/
    constants/                   # app + grade constants
    database/                    # DatabaseHelper, HadithQuery
    di/                          # DependencyScope
    extensions/  models/  settings/  theme/  utils/  widgets/
  features/
    books/  chapters/  hadith_reader/  search/  bookmarks/
      data/                      # repositories
      presentation/
        cubit/                   # Cubit + State
        screens/  widgets/
```

Each feature owns its `data` and `presentation` layers; the core layer holds
cross-cutting concerns only. Repositories are injected through
`AppDependencies` and read from the widget tree via `context.deps`, so tests can
substitute their own container.

## Offline database

`assets/sunnah.db` is a pre-populated SQLite database copied to the app's
databases directory on first launch. It is ~5.4 MB and contains 1,897 hadiths
across 5 collections and 70 chapters.

| table      | columns |
| ---------- | ------- |
| `books`    | `id`, `name_ar`, `name_en`, `author`, `total_hadiths` |
| `chapters` | `id`, `book_id`, `chapter_number`, `title_ar`, `title_en` |
| `hadiths`  | `id`, `book_id`, `chapter_id`, `hadith_number`, `narrator`, `matn_ar`, `matn_en`, `grade`, `grade_source`, `matn_search` |

`matn_search` holds the Arabic-normalised matn and is what search queries
against, so matching is diacritic- and variant-insensitive without any runtime
text processing cost.

Regenerate the database with:

```bash
python3 tools/build_db.py
```

## Development

```bash
flutter pub get
flutter analyze   # must be clean
flutter test      # 81 tests
```

The tests run against the real bundled database through `sqflite_common_ffi`,
so the schema, seed data and SQL are exercised directly rather than mocked.

## Verification status

- `flutter analyze` — no issues.
- `flutter test` — 81 tests passing.
- `flutter build web --release` — full app compiles in AOT.
