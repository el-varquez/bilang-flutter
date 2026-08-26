# Bilang

Scan a barcode, the quantity ticks up. An offline stock-counting app for any store — the phone does the job a hardware inventory terminal does, and the finished count leaves as a CSV, Excel, or JSON file.

Store listing name: **Inventory Scanner**. In-app identity: **Bilang**.

## Commands

`make` from the repo root is the entry point; `make` with no target lists everything.

```bash
make run        # run on the connected device (debug)
make release    # run in release mode — real scanning speed
make gates      # everything CI runs: analyze, test, architecture, design
make apk        # build the release APK for sideloading
make devices    # list connected devices
make setup      # restore packages
make doctor     # flutter doctor -v
make clean      # drop build output
```

`make gates` is what to run before calling work done. The underlying commands stay available directly: `flutter run`, `flutter analyze`, `flutter test`, `node scripts/check-architecture.mjs`, `node scripts/check-design.mjs`, `node scripts/check-conventions.mjs` (conventions is PR-only in CI).

## CI

Four single-concern GitHub Actions workflows, job `checks` each: **Build CI** (`flutter pub get`, `analyze`, `test`), **Architecture CI**, **Design System CI**, **Conventions CI** (PR-only).

## Architecture

Feature slices under `lib/features/<feature>/{screens,components,services}`, mirroring the POS register's grammar. Shared ground outside `features/`:

- `theme/` — `tokens.dart` holds every color; `app_theme.dart` builds the `ThemeData`.
- `types/` — the data model. Bilang counts three columns and only three: `name`, `barcode`, `qty`.
- `store/` — state two features both read (`CountStore`, a `ChangeNotifier`).
- `shell/` — `AppShell`: the tab bar and which screen is on it.
- `services/` — plugin-facing wrappers (local storage, file share, live connection). Reserved; created when the first service lands.

`scripts/check-architecture.mjs` enforces four rules: **R1** `pubspec.yaml` dependencies match `architecture/dependencies.json` · **R2** every file under `lib/features/` sits in `screens|components|services` · **R3** third-party packages are imported only under a `services/` folder · **R4** a feature never imports another feature.

## Design system

Follows the POS product's Design System v2 (white / green) so both heads look like one product. Every color lives in `lib/theme/tokens.dart`, machine-checked against `design/tokens.json`; a raw `Color(0x…)` or a `Colors.*` reach anywhere else fails `check-design.mjs`. Green is the only primary-action color; red means destructive; gold means warning.

The canonical design is the interactive mockup in the workspace at `../output/design/2026-08-26-inventory-scanner-mockup.html`.
