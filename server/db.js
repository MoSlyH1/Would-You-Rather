const { Pool } = require("pg");

// Neon (and most managed Postgres) require SSL. Local dev does not.
// We enable SSL automatically when the connection string asks for it,
// or when running against a non-localhost host.
const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error("FATAL: DATABASE_URL is not set.");
  process.exit(1);
}

const needsSsl =
  /sslmode=require/.test(connectionString) ||
  (!/localhost|127\.0\.0\.1/.test(connectionString) &&
    process.env.PGSSL !== "disable");

const pool = new Pool({
  connectionString,
  ssl: needsSsl ? { rejectUnauthorized: false } : false,
  max: 5, // Render free tier + Neon: keep the pool small
});

pool.on("error", (err) => {
  console.error("Unexpected idle client error", err);
});

module.exports = { pool };
