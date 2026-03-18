# CardTone

CardTone is a dual-app parental control system for children's media consumption. A **parent device** manages cards, settings, and controls. A **kid device** responds to physical NFC card taps by instantly playing the assigned media.

---

## 📱 Apps

### `cardtone-parent` — The Control Center
Everything the parent manages:
| Feature | Details |
|---|---|
| **Link Devices** | Scan a kid device's QR code to pair. The first parent to link becomes the **Master Parent ⭐** |
| **Master Parent** | Only the master parent can approve additional parents — prevents the child from linking unauthorized devices |
| **Card Management** | Create cards and assign NFC tag IDs → media URLs (audio, video, YouTube, Spotify, Google Drive) |
| **Remote Control** | Play, pause, stop playback on the kid's device from anywhere |
| **Volume Limit** | Set the maximum volume the kid's device can reach |
| **Kiosk Mode** | Remotely lock the kid into the CardTone app so they can't exit |
| **Session Limits** | Set a daily time limit; the session auto-locks when the timer runs out |
| **Bedtime** | Define bedtime hours — the kid's device automatically locks itself |
| **Master NFC Cards** | Configure special cards that unlock or lock the session when scanned |
| **PIN Management** | Set a 6-digit PIN for local kiosk unlock |

---

### `cardtone-kid` — The Player
Everything the child sees:
| Feature | Details |
|---|---|
| **NFC → Play** | Tap any configured card to instantly start the assigned media |
| **Now Playing** | Shows the title of the currently active card (e.g. "🎵 Elsa's Song") |
| **Universal Player** | Audio (MP3/AAC), Video (MP4/HLS), YouTube, Spotify/Anghami via WebView, Google Drive |
| **Error Feedback** | If a card has no URL or the URL is invalid, a friendly message is shown instead of crashing |
| **Kiosk Mode** | Locks the device to the app; supports Always-On screen |
| **Master Cards** | Special NFC cards for kiosk unlock or session lock |
| **Bedtime Lock** | Device locks itself automatically at configured bedtime |
| **Pairing** | QR code displayed on first launch for the parent to scan |
| **Master Parent Lock** | Cannot add new parents from the kid device once a master parent exists |

---

## 🗄️ Database (Supabase)

### Tables
- **`kids`** — Kid profiles. Key columns:
  - `id` — unique device ID (generated on first launch)
  - `linked_parents` — array of parent IDs
  - `master_parent_id` — the master parent (set on first link) ⭐
  - `kiosk_locked`, `session_locked`, `bedtime_start`, `bedtime_end`, `session_timeout`, `max_volume`
  - `master_card_kiosk_mode_id`, `master_card_session_lock_id`
- **`parents`** — Parent profiles. Key columns:
  - `id` — email used as identifier
  - `kids` — array of linked kid IDs
- **`cards`** — NFC card definitions. Key columns:
  - `id` — row UUID
  - `card_id` — the physical NFC tag UID
  - `kid_id` — which kid this card belongs to
  - `title`, `uri`, `type`
- **`commands`** — Real-time command queue (play, pause, stop, lock, unlock)

### Migrations
If you are setting up from scratch or upgrading, run the SQL files in `db_migrations/` in order:
- `add_master_parent_id.sql` — adds `master_parent_id` to the `kids` table (required for Master Parent feature)

---

## 🚀 Getting Started

### 1 — Backend
1. Create a [Supabase](https://supabase.com) project.
2. Run the SQL migrations in `db_migrations/`.
3. Copy your **Project URL** and **anon key** into:
   - `cardtone-kid/lib/services/supabase_config.dart`
   - `cardtone-parent/lib/services/supabase_config.dart`

### 2 — First Launch
1. Run `cardtone-parent` on the parent's phone.
2. Run `cardtone-kid` on the child's device.
3. On the kid device, tap the **QR code icon** — a pairing code appears.
4. On the parent app, tap **+** and scan the QR code.
   - The first parent to scan becomes the **Master Parent ⭐**.
5. In the parent app, add cards and assign media URLs.
6. On the kid device, tap an NFC card — content plays immediately!

---

## 🛠 Tech Stack
| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Backend / Realtime | Supabase (PostgreSQL + Realtime) |
| Auth | Supabase Magic Link / OTP |
| State Management | `provider` (`ChangeNotifier`) |
| Local Storage | `shared_preferences` |
| NFC | `nfc_manager` |
| Media | `audioplayers`, `video_player`, `youtube_player_flutter` |
| Web Content | `webview_flutter` |
| QR | `qr_flutter` (generate), `mobile_scanner` (scan) |
| Screen Control | `wakelock_plus` |

---

## 📁 Project Layout
```
CardTone/
├── cardtone-kid/          # Kid app (Flutter)
│   └── lib/
│       ├── models/        # Data models (CardModel)
│       ├── providers/     # AppState (ChangeNotifier)
│       ├── screens/       # KidsScreen, PairingScreen
│       ├── services/      # MediaService, NfcService, SyncService, ...
│       └── theme/         # AppTheme / KidTheme
├── cardtone-parent/       # Parent app (Flutter)
│   └── lib/
│       ├── models/        # CardModel
│       ├── providers/     # AppState (ChangeNotifier)
│       ├── screens/       # ParentScreen, QRScannerScreen
│       ├── services/      # SyncService, SupabaseConfig
│       └── widgets/       # KioskModeControl, SessionLockControl, ...
├── db_migrations/         # SQL files for Supabase schema updates
└── README.md              # ← you are here
```

---

*Last updated: March 2026*