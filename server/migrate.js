const fs = require("fs");
const path = require("path");
const { pool } = require("./db");
const { getSeedQuestions } = require("./questions");

// Run schema.sql, then seed the 50 starter questions if the table is empty.
async function migrateAndSeed() {
  const schema = fs.readFileSync(path.join(__dirname, "schema.sql"), "utf8");
  await pool.query(schema);

  const { rows } = await pool.query("SELECT COUNT(*)::int AS n FROM questions");
  if (rows[0].n > 0) {
    console.log(`DB already has ${rows[0].n} questions — skipping seed.`);
    return;
  }

  const seed = getSeedQuestions();
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    for (const q of seed) {
      await client.query(
        `INSERT INTO questions (option_a, option_b, category, status, is_seed)
         VALUES ($1, $2, $3, 'approved', TRUE)
         ON CONFLICT DO NOTHING`,
        [q.optionA, q.optionB, q.category]
      );
    }
    await client.query("COMMIT");
    console.log(`Seeded ${seed.length} questions.`);
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  } finally {
    client.release();
  }
}

module.exports = { migrateAndSeed };
