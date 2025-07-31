-- Study Sets Table
CREATE TABLE study_sets (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Study Set Words Junction Table
CREATE TABLE study_set_words (
  study_set_id INTEGER NOT NULL REFERENCES study_sets(id) ON DELETE CASCADE,
  word_id INTEGER NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  PRIMARY KEY (study_set_id, word_id)
);

-- Learning Sessions Table
CREATE TABLE learning_sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  study_set_id INTEGER REFERENCES study_sets(id) ON DELETE SET NULL,
  session_type VARCHAR(50) NOT NULL, -- 'flashcard', 'match', 'quiz', 'type'
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE,
  total_questions INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  session_data JSONB -- Store session-specific data
);

-- Learning Attempts Table (individual question attempts within a session)
CREATE TABLE learning_attempts (
  id SERIAL PRIMARY KEY,
  session_id INTEGER NOT NULL REFERENCES learning_sessions(id) ON DELETE CASCADE,
  word_id INTEGER NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  attempt_type VARCHAR(50) NOT NULL, -- 'flashcard', 'multiple_choice', 'type', 'match'
  user_answer TEXT,
  correct_answer TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  response_time_ms INTEGER, -- Time taken to answer in milliseconds
  difficulty_rating INTEGER, -- User's difficulty rating (1-5)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Vocabulary Learning Statistics Table
CREATE TABLE vocabulary_stats (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word_id INTEGER NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  total_attempts INTEGER DEFAULT 0,
  correct_attempts INTEGER DEFAULT 0,
  total_response_time_ms BIGINT DEFAULT 0, -- Total time spent on this word
  mastery_level INTEGER DEFAULT 1, -- 1-10 scale
  last_attempt_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(user_id, word_id)
);

-- Create indexes for better performance
CREATE INDEX idx_study_sets_user_id ON study_sets(user_id);
CREATE INDEX idx_study_sets_public ON study_sets(is_public) WHERE is_public = TRUE;
CREATE INDEX idx_study_set_words_study_set_id ON study_set_words(study_set_id);
CREATE INDEX idx_study_set_words_word_id ON study_set_words(word_id);
CREATE INDEX idx_learning_sessions_user_id ON learning_sessions(user_id);
CREATE INDEX idx_learning_sessions_type ON learning_sessions(session_type);
CREATE INDEX idx_learning_attempts_session_id ON learning_attempts(session_id);
CREATE INDEX idx_learning_attempts_word_id ON learning_attempts(word_id);
CREATE INDEX idx_vocabulary_stats_user_id ON vocabulary_stats(user_id);
CREATE INDEX idx_vocabulary_stats_mastery ON vocabulary_stats(mastery_level);
