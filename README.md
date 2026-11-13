# Territory

A colourful region-painting puzzle game built with Flutter.

## How it plays (current rules)

- The board is a 7x7 grid with black blocked cells.
- A numbered cell is a clue: that colour's region must contain exactly that many cells.
- Drag from a number to paint its region. Tap a painted cell to erase it.
- The eye button shows or hides the symbols (square, circle, triangle, heart, sparkle) that make colours readable without relying on colour alone.
- Press **Check** once every cell is filled. Each region must be connected and match its number.
- 24 levels, generated from the level number, so each one is always solvable.

The rules live in `lib/game/` and are separate from the UI, so they are easy to change.

## Run it

```bash
flutter create . --platforms=android,ios   # generates the platform folders (first time only)
flutter pub get
flutter run
flutter test
```

## Structure

```
lib/
  main.dart               app entry
  theme.dart              colours + font
  storage.dart            saved progress (shared_preferences)
  game/level.dart         level model + generator
  game/game_controller.dart  board state, timer, check logic
  screens/                home, levels, game
  widgets/                board, shape painter, buttons, dialogs
test/level_test.dart
```
