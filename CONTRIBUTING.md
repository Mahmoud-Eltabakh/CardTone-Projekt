# Contributing to CardTone

<p align="center">
  <img src="assets/logo-shared.svg" width="120" alt="CardTone Logo"/>
</p>

Thank you for your interest in CardTone! This guide covers everything you need to go from zero to submitting your first pull request.

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Setting Up Your Environment](#2-setting-up-your-environment)
3. [Backend — Supabase](#3-backend--supabase)
4. [Working with Submodules](#4-working-with-submodules)
5. [Running Tests & Linting](#5-running-tests--linting)
6. [Building a Release APK](#6-building-a-release-apk)
7. [Code Conventions](#7-code-conventions)
8. [Submitting a Pull Request](#8-submitting-a-pull-request)
9. [Security Policy](#9-security-policy)
10. [Reporting Issues](#10-reporting-issues)

---

## 1. Project Structure

CardTone is a **monorepo** — the `CardTone-Projekt` repository links four independent repos as git submodules:

```
CardTone-Projekt/               ← you are here (umbrella repo)
├── cardtone-kid/               ← Flutter app for the child's device
├── cardtone-parent/            ← Flutter app for the parent's phone
├── cardtone-box/               ← KiCad PCB design (ESP32-S3 NFC reader)
├── cardtone-website/           ← Marketing & download website (HTML/CSS)
├── Dockerfile.flutter          ← Shared build image (Flutter + Android SDK)
├── docker-compose.yml          ← Dev services (kid, parent, website)
├── .env.example                ← Credential template for contributors
├── build_release.ps1           ← Windows release build script
├── SUPABASE_SETUP.md           ← SQL schema for the Supabase backend
└── THREAT_ANALYSIS.md          ← Known security risks & remediation plan
```

Each submodule has its own GitHub repository and its own commit history. **Contributions to an app go to that app's repo**, not here.

---

## 2. Setting Up Your Environment

### Option A — Docker (recommended, no local installs needed)

**Requirements:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows / macOS / Linux)

```bash
# 1. Clone the monorepo with all submodules
git clone --recurse-submodules https://github.com/Mahmoud-Eltabakh/CardTone-Projekt.git
cd CardTone-Projekt

# 2. Create your .env file (see Section 3 for where to get the values)
cp .env.example .env
# → open .env and fill in SUPABASE_URL and SUPABASE_ANON_KEY

# 3. Build the Flutter image (one-time, ~10 minutes)
docker compose build

# 4. Install Dart packages for the app you want to work on
docker compose run --rm kid    flutter pub get
docker compose run --rm parent flutter pub get

# 5. Run tests
docker compose run --rm kid    flutter test
docker compose run --rm parent flutter test

# 6. Serve the website locally
docker compose up website        # → http://localhost:8080
```

> The `pub-cache` and `gradle-cache` Docker volumes persist between runs so packages are only downloaded once.

---

### Option B — Native (Flutter installed locally)

**Requirements:**
- [Flutter stable](https://docs.flutter.dev/get-started/install) (Dart SDK `>=3.0.0`)
- [Android Studio](https://developer.android.com/studio) with Android SDK 34
- Java 17

```bash
git clone --recurse-submodules https://github.com/Mahmoud-Eltabakh/CardTone-Projekt.git
cd CardTone-Projekt

cp .env.example .env   # fill in your Supabase credentials

cd cardtone-kid
flutter pub get
flutter run            # requires a connected Android device or emulator
```

```bash
cd cardtone-parent
flutter pub get
flutter run
```

> NFC scanning and kiosk mode require a **physical Android device** — they do not work in emulators.

---

## 3. Backend — Supabase

Both Flutter apps connect to a [Supabase](https://supabase.com) project for data and real-time sync. Each contributor sets up their own free project.

**Steps:**

1. Create a free project at [supabase.com](https://supabase.com).
2. Open the **SQL Editor** and paste the full schema from [SUPABASE_SETUP.md](SUPABASE_SETUP.md). Run it.
3. Go to **Settings → API** and copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon / public key** → `SUPABASE_ANON_KEY`
4. Paste these values into your `.env` file.

The app reads credentials at build time via `--dart-define`. Your `.env` is never committed (it is in `.gitignore`).

> **Security:** The default Supabase schema uses open RLS policies (`using (true)`) for development ease. Before any real-world deployment, follow the hardening steps in [THREAT_ANALYSIS.md](THREAT_ANALYSIS.md).

---

## 4. Working with Submodules

If you are contributing to a specific app, work in that submodule's folder and submit a PR to **that app's repository**:

| What you want to change | Repository to fork & PR |
|---|---|
| Kid app (Flutter) | [CardTone-Kid](https://github.com/Mahmoud-Eltabakh/CardTone-Kid) |
| Parent app (Flutter) | [CardTone-Parent](https://github.com/Mahmoud-Eltabakh/CardTone-Parent) |
| PCB hardware | [CardTone-Box](https://github.com/Mahmoud-Eltabakh/CardTone-Box) |
| Website | [CardTone-Website](https://github.com/Mahmoud-Eltabakh/CardTone-Website) |
| Docs, Docker, build scripts | [CardTone-Projekt](https://github.com/Mahmoud-Eltabakh/CardTone-Projekt) ← here |

**Typical submodule workflow:**

```bash
# Enter the submodule directory
cd cardtone-kid

# Create a feature branch
git checkout -b feat/your-feature-name

# Make changes, test, commit
git add -p
git commit -m "feat: describe what you changed"

# Push to your fork of CardTone-Kid
git remote add fork https://github.com/YOUR_USERNAME/CardTone-Kid.git
git push fork feat/your-feature-name

# Open a PR on github.com/Mahmoud-Eltabakh/CardTone-Kid
```

After a submodule PR is merged, a separate PR on CardTone-Projekt can bump the submodule pointer.

---

## 5. Running Tests & Linting

### Docker
```bash
docker compose run --rm kid    flutter test
docker compose run --rm parent flutter test

docker compose run --rm kid    flutter analyze
docker compose run --rm parent flutter analyze
```

### Native
```bash
cd cardtone-kid    && flutter test && flutter analyze
cd cardtone-parent && flutter test && flutter analyze
```

All PRs are expected to pass `flutter analyze` with zero issues. Add or update tests for any logic you change.

---

## 6. Building a Release APK

Release builds inject Supabase credentials at compile time — they are never baked into the source code.

### With Docker (Linux/macOS)
```bash
docker compose run --rm kid flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

### With PowerShell (Windows)
```powershell
# From the project root — reads .env automatically
.\build_release.ps1 -App kid    -Apk
.\build_release.ps1 -App parent -Apk
```

Output: `cardtone-kid/build/app/outputs/flutter-apk/app-release.apk`

> Release builds also require a signing keystore (`android/key.properties` + `android/app/upload-keystore.jks`). These are **not included** in the repo — generate your own with `keytool` for local testing.

---

## 7. Code Conventions

| Convention | Rule |
|---|---|
| Language | Dart — follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guide |
| Linting | `flutter_lints` — fix all warnings before submitting |
| State management | `provider` / `ChangeNotifier` — don't introduce other state packages |
| File naming | `snake_case.dart` |
| Class naming | `PascalCase` |
| Commits | [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `refactor:`, `test:` |
| Branch naming | `feat/short-description`, `fix/short-description` |
| Credentials | **Never** hardcode Supabase URLs or keys — use `String.fromEnvironment()` |

---

## 8. Submitting a Pull Request

1. Fork the relevant sub-repository.
2. Create a branch: `feat/your-feature` or `fix/your-bug`.
3. Make your changes and commit using Conventional Commits.
4. Run `flutter test` and `flutter analyze` — both must pass cleanly.
5. Open a PR against the `main` branch of the target repository.
6. Fill in the PR description: **what** changed and **why**.

**PR checklist:**
- [ ] `flutter analyze` reports zero issues
- [ ] `flutter test` passes
- [ ] No credentials, keystore files, or `.env` files committed
- [ ] New features include at least one test
- [ ] Existing tests are not broken

---

## 9. Security Policy

- **Do not open public issues for security vulnerabilities.** Report them privately to the repository owner via GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability).
- The current RLS setup is development-grade only. See [THREAT_ANALYSIS.md](THREAT_ANALYSIS.md) for the full risk assessment and the recommended hardening steps before any production deployment.
- Never commit secrets: API keys, passwords, keystore files, or `.env` files.

---

## 10. Reporting Issues

Open an issue on the relevant repository:

- App bugs → [CardTone-Kid issues](https://github.com/Mahmoud-Eltabakh/CardTone-Kid/issues) or [CardTone-Parent issues](https://github.com/Mahmoud-Eltabakh/CardTone-Parent/issues)
- Hardware / PCB → [CardTone-Box issues](https://github.com/Mahmoud-Eltabakh/CardTone-Box/issues)
- Website → [CardTone-Website issues](https://github.com/Mahmoud-Eltabakh/CardTone-Website/issues)
- Docs, Docker, build → [CardTone-Projekt issues](https://github.com/Mahmoud-Eltabakh/CardTone-Projekt/issues)

When filing a bug, include: Flutter version (`flutter --version`), Android version, device model, and steps to reproduce.

---

*Happy hacking!*
