const express = require("express");
const crypto = require("crypto");
const path = require("path");
const { pool } = require("./db");
const { migrateAndSeed } = require("./migrate");

const app = express();
app.use(express.json({ limit: "64kb" }));

// ----------------------------- config -----------------------------
const PORT = process.env.PORT || 3000;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "WouldYouRather123";
const MAX_APPROVED = parseInt(process.env.MAX_APPROVED || "250", 10); // hard cap on live questions
const MAX_PENDING = parseInt(process.env.MAX_PENDING || "500", 10); // anti-spam cap on the queue
const ALLOWED_CATEGORIES = [
  "Football",
  "Lebanon",
  "Lebanese Politics",
  "Technology",
  "Food",
  "Community",
];

// ------------------------- admin sessions -------------------------
// Simple in-memory bearer tokens. They reset on restart (fine for a hobby app).
const sessions = new Map(); // token -> expiresAt (ms)
const SESSION_TTL = 1000 * 60 * 60 * 8; // 8 hours

function issueToken() {
  const token = crypto.randomBytes(24).toString("hex");
  sessions.set(token, Date.now() + SESSION_TTL);
  return token;
}

function requireAdmin(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  const exp = token && sessions.get(token);
  if (!exp || exp < Date.now()) {
    if (token) sessions.delete(token);
    return res.status(401).json({ error: "Unauthorized. Please sign in as admin." });
  }
  next();
}

// --------------------------- validation ---------------------------
const BANNED = ["fuck", "shit", "bitch", "nigger", "faggot", "http://", "https://", "www."];

function cleanOption(raw) {
  if (typeof raw !== "string") return null;
  let s = raw.replace(/\s+/g, " ").trim();
  // be forgiving if a user pasted the whole "Would you rather ..." prefix
  s = s.replace(/^would you rather\s+/i, "");
  s = s.replace(/[?]+$/, "").trim();
  return s;
}

// Returns { ok: true, value } or { ok: false, error }
function validateSubmission(body) {
  const a = cleanOption(body.optionA);
  const b = cleanOption(body.optionB);
  let category = (body.category || "Community").toString().trim();

  if (!a || !b) return { ok: false, error: "Both options are required." };
  if (a.length < 3 || b.length < 3)
    return { ok: false, error: "Each option must be at least 3 characters." };
  if (a.length > 200 || b.length > 200)
    return { ok: false, error: "Each option must be under 200 characters." };
  if (a.toLowerCase() === b.toLowerCase())
    return { ok: false, error: "The two options must be different." };

  const blob = (a + " " + b).toLowerCase();
  if (BANNED.some((w) => blob.includes(w)))
    return { ok: false, error: "Submission contains blocked words or links." };

  if (!ALLOWED_CATEGORIES.includes(category)) category = "Community";

  return { ok: true, value: { optionA: a, optionB: b, category } };
}

// ============================== API ==============================

app.get("/api/health", (_req, res) => res.json({ ok: true }));

// Distinct categories that currently have approved questions
app.get("/api/categories", async (_req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT category, COUNT(*)::int AS n
         FROM questions WHERE status = 'approved'
        GROUP BY category ORDER BY category`
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

// All approved questions (optionally filtered). Small dataset (<=250) so this is fine.
app.get("/api/questions", async (req, res, next) => {
  try {
    const category = req.query.category;
    const params = [];
    let where = "status = 'approved'";
    if (category && category !== "All") {
      params.push(category);
      where += ` AND category = $${params.length}`;
    }
    const { rows } = await pool.query(
      `SELECT id, option_a, option_b, category, votes_a, votes_b
         FROM questions WHERE ${where} ORDER BY random()`,
      params
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

// A single random approved question
app.get("/api/questions/random", async (req, res, next) => {
  try {
    const category = req.query.category;
    const params = [];
    let where = "status = 'approved'";
    if (category && category !== "All") {
      params.push(category);
      where += ` AND category = $${params.length}`;
    }
    const { rows } = await pool.query(
      `SELECT id, option_a, option_b, category, votes_a, votes_b
         FROM questions WHERE ${where} ORDER BY random() LIMIT 1`,
      params
    );
    if (!rows.length) return res.status(404).json({ error: "No questions available." });
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

// Cast a vote: { choice: 'a' | 'b' }
app.post("/api/questions/:id/vote", async (req, res, next) => {
  try {
    const id = parseInt(req.params.id, 10);
    const choice = (req.body.choice || "").toLowerCase();
    if (!Number.isInteger(id)) return res.status(400).json({ error: "Bad id." });
    if (choice !== "a" && choice !== "b")
      return res.status(400).json({ error: "choice must be 'a' or 'b'." });

    const col = choice === "a" ? "votes_a" : "votes_b";
    const { rows } = await pool.query(
      `UPDATE questions SET ${col} = ${col} + 1
        WHERE id = $1 AND status = 'approved'
        RETURNING id, votes_a, votes_b`,
      [id]
    );
    if (!rows.length) return res.status(404).json({ error: "Question not found." });
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

// Submit a question -> goes to the pending queue
app.post("/api/submit", async (req, res, next) => {
  try {
    const v = validateSubmission(req.body || {});
    if (!v.ok) return res.status(400).json({ error: v.error });

    const pend = await pool.query(
      "SELECT COUNT(*)::int AS n FROM questions WHERE status = 'pending'"
    );
    if (pend.rows[0].n >= MAX_PENDING)
      return res.status(429).json({ error: "The review queue is full. Try again later." });

    try {
      const { rows } = await pool.query(
        `INSERT INTO questions (option_a, option_b, category, status)
         VALUES ($1, $2, $3, 'pending') RETURNING id`,
        [v.value.optionA, v.value.optionB, v.value.category]
      );
      res.status(201).json({
        ok: true,
        id: rows[0].id,
        message: "Thanks! Your question is pending review and may go live soon.",
      });
    } catch (err) {
      if (err.code === "23505")
        return res.status(409).json({ error: "That question already exists." });
      throw err;
    }
  } catch (e) {
    next(e);
  }
});

// Public stats
app.get("/api/stats", async (_req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT
         COUNT(*) FILTER (WHERE status='approved')::int AS approved,
         COUNT(*) FILTER (WHERE status='pending')::int  AS pending,
         COALESCE(SUM(votes_a + votes_b),0)::int        AS total_votes
       FROM questions`
    );
    res.json({ ...rows[0], max_approved: MAX_APPROVED });
  } catch (e) {
    next(e);
  }
});

// ----------------------------- admin -----------------------------

app.post("/api/admin/login", (req, res) => {
  const password = (req.body && req.body.password) || "";
  if (password !== ADMIN_PASSWORD)
    return res.status(401).json({ error: "Wrong password." });
  res.json({ token: issueToken() });
});

app.get("/api/admin/pending", requireAdmin, async (_req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, option_a, option_b, category, created_at
         FROM questions WHERE status = 'pending' ORDER BY created_at ASC`
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

// Full management list (approved + pending counts)
app.get("/api/admin/questions", requireAdmin, async (_req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, option_a, option_b, category, status, votes_a, votes_b, is_seed, created_at
         FROM questions ORDER BY status DESC, created_at DESC`
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

// Approve a pending question (enforces the 250 cap)
app.post("/api/admin/questions/:id/approve", requireAdmin, async (req, res, next) => {
  try {
    const id = parseInt(req.params.id, 10);
    const cnt = await pool.query(
      "SELECT COUNT(*)::int AS n FROM questions WHERE status = 'approved'"
    );
    if (cnt.rows[0].n >= MAX_APPROVED)
      return res.status(409).json({
        error: `Live question cap reached (${MAX_APPROVED}). Delete some before approving more.`,
      });

    const { rows } = await pool.query(
      `UPDATE questions SET status = 'approved'
        WHERE id = $1 AND status = 'pending' RETURNING id`,
      [id]
    );
    if (!rows.length)
      return res.status(404).json({ error: "Pending question not found." });
    res.json({ ok: true, id: rows[0].id });
  } catch (e) {
    next(e);
  }
});

// Edit a question (fix typos / rephrase), works on pending or approved
app.put("/api/admin/questions/:id", requireAdmin, async (req, res, next) => {
  try {
    const id = parseInt(req.params.id, 10);
    const v = validateSubmission(req.body || {});
    if (!v.ok) return res.status(400).json({ error: v.error });
    const { rows } = await pool.query(
      `UPDATE questions SET option_a = $1, option_b = $2, category = $3
        WHERE id = $4 RETURNING id, option_a, option_b, category, status`,
      [v.value.optionA, v.value.optionB, v.value.category, id]
    );
    if (!rows.length) return res.status(404).json({ error: "Question not found." });
    res.json(rows[0]);
  } catch (e) {
    if (e.code === "23505")
      return res.status(409).json({ error: "That question already exists." });
    next(e);
  }
});

// Delete / reject a question
app.delete("/api/admin/questions/:id", requireAdmin, async (req, res, next) => {
  try {
    const id = parseInt(req.params.id, 10);
    const { rowCount } = await pool.query("DELETE FROM questions WHERE id = $1", [id]);
    if (!rowCount) return res.status(404).json({ error: "Question not found." });
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

// ----------------------- static Flutter web -----------------------
// In the Docker image the built Flutter web app is copied to ./public
const PUBLIC_DIR = path.join(__dirname, "public");
app.use(express.static(PUBLIC_DIR));
// SPA fallback for any non-API route
app.get(/^\/(?!api\/).*/, (_req, res) => {
  res.sendFile(path.join(PUBLIC_DIR, "index.html"), (err) => {
    if (err) res.status(404).json({ error: "Frontend not built." });
  });
});

// --------------------------- error handler ------------------------
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: "Internal server error." });
});

// ----------------------------- startup ----------------------------
async function start() {
  await migrateAndSeed();
  app.listen(PORT, () => console.log(`WYR server listening on :${PORT}`));
}

if (require.main === module) {
  start().catch((e) => {
    console.error("Startup failed:", e);
    process.exit(1);
  });
}

module.exports = { app, validateSubmission };
