-- Would You Rather schema

CREATE TABLE IF NOT EXISTS questions (
  id          SERIAL PRIMARY KEY,
  option_a    TEXT NOT NULL,
  option_b    TEXT NOT NULL,
  category    TEXT NOT NULL DEFAULT 'Community',
  -- 'approved' = live in the game; 'pending' = waiting for admin review
  status      TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('approved', 'pending')),
  votes_a     INTEGER NOT NULL DEFAULT 0,
  votes_b     INTEGER NOT NULL DEFAULT 0,
  is_seed     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_questions_status ON questions (status);
CREATE INDEX IF NOT EXISTS idx_questions_category ON questions (category);

-- Prevent exact duplicate submissions (case-insensitive on the pair).
CREATE UNIQUE INDEX IF NOT EXISTS uniq_question_pair
  ON questions (lower(option_a), lower(option_b));
