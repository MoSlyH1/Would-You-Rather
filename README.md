# Would You Rather — Lebanese Edition

A "Would You Rather" game. Players pick a side, see live vote percentages, and
move to the next question — no sign-in needed. Anyone can submit a new question;
submissions land in a **pending queue** that only an admin (you) can see, approve,
edit, or delete. Ships with 50 seed questions across Football, Lebanon, Lebanese
Politics, Technology, and Food.

## Stack
- **Frontend:** Flutter web (responsive — phone & desktop), bottom nav: Play / Submit / Admin
- **Backend:** Node.js + Express
- **Database:** PostgreSQL (Neon in production)
- **Deploy:** single Docker image on Render free tier (Flutter built in-image, served by Express)

## How the approval queue works (Strategy 1 — manual curation)
1. A visitor submits a question → it's stored with `status = 'pending'`. Players never see it.
2. You open **Admin**, sign in with the password, and review the queue.
3. For each one you can **Approve** (goes live), **Edit** (fix typos / rephrase, then approve), or **Delete**.
4. Live questions are hard-capped at **250** (`MAX_APPROVED`). At the cap, approvals are blocked until you delete some.

Basic automatic checks run before anything even reaches the queue: both options
required, 3–200 chars, must differ, no links, simple bad-word filter, and exact
duplicates are rejected.

## Admin password
Default: `WouldYouRather123` — set via the `ADMIN_PASSWORD` env var.
Players need **no** account; only the Admin tab asks for the password.

## Project layout
```
.
├── Dockerfile            # multi-stage: build Flutter web -> run Node
├── docker-compose.yml    # local Postgres + app
├── render.yaml           # Render blueprint
├── server/               # Express API + static host
│   ├── index.js          # all routes
│   ├── db.js             # pg pool (auto SSL for Neon)
│   ├── migrate.js        # creates tables + seeds 50 questions on boot
│   ├── schema.sql
│   └── questions.js      # the 50 seed questions
└── app/                  # Flutter project
    ├── lib/
    │   ├── main.dart
    │   ├── api.dart      # talks to /api on the same origin
    │   ├── models.dart
    │   ├── theme.dart
    │   └── screens/{game,submit,admin}_screen.dart
    └── web/
```

## Run locally (Docker — easiest)
```bash
docker compose up --build
# open http://localhost:3000
```

## Run locally (without Docker)
```bash
# 1. a Postgres running somewhere, then:
cd server
export DATABASE_URL="postgresql://user:pass@localhost:5432/wyr"
export PGSSL=disable
npm install
npm start            # serves API on :3000 (frontend must be built into ./public)

# 2. for the frontend during dev, run it separately and point it at the API:
cd ../app
flutter run -d chrome --dart-define=API_BASE=http://localhost:3000
```

## Deploy to Render (free) + Neon
1. **Create the database (Neon).**
   - Sign up at neon.tech → New Project → copy the connection string
     (looks like `postgresql://user:pass@ep-xxx.neon.tech/db?sslmode=require`).
2. **Push this repo to GitHub.**
3. **Create the web service on Render.**
   - New → Web Service → connect the repo.
   - Runtime: **Docker** (Render auto-detects the `Dockerfile`). Plan: **Free**.
   - Add environment variables:
     - `DATABASE_URL` = your Neon connection string
     - `ADMIN_PASSWORD` = `WouldYouRather123` (change if you like)
     - `MAX_APPROVED` = `250` (optional)
   - Create. First build takes a few minutes (it compiles Flutter web inside the image).
4. On boot the server creates the tables and seeds the 50 questions automatically.
   Visit the Render URL — the game is live. Tap **Admin** to curate submissions.

> Note: SSL to Neon is enabled automatically (the connection string includes
> `sslmode=require`, and the server also turns SSL on for any non-localhost host).

## API reference
Public:
- `GET  /api/questions?category=` — approved questions
- `GET  /api/questions/random?category=`
- `POST /api/questions/:id/vote` — body `{ "choice": "a" | "b" }`
- `POST /api/submit` — body `{ "optionA", "optionB", "category" }` → pending
- `GET  /api/categories`, `GET /api/stats`, `GET /api/health`

Admin (send `Authorization: Bearer <token>` from login):
- `POST   /api/admin/login` — body `{ "password" }` → `{ token }`
- `GET    /api/admin/pending`
- `GET    /api/admin/questions`
- `POST   /api/admin/questions/:id/approve`
- `PUT    /api/admin/questions/:id` — edit
- `DELETE /api/admin/questions/:id`
