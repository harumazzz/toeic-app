-- Add enum type for exam status
CREATE TYPE exam_status_enum AS ENUM (
    'in_progress',
    'completed',
    'abandoned'
);

-- Create exam_attempts table
CREATE TABLE exam_attempts (
    attempt_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exam_id INTEGER NOT NULL REFERENCES exams(exam_id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    score NUMERIC(5, 2),
    status exam_status_enum NOT NULL DEFAULT 'in_progress',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    CONSTRAINT valid_score CHECK (score IS NULL OR (score >= 0 AND score <= 990)),
    CONSTRAINT valid_end_time CHECK (end_time IS NULL OR end_time >= start_time)
);

-- Create user_answers table
CREATE TABLE user_answers (
    user_answer_id SERIAL PRIMARY KEY,
    attempt_id INTEGER NOT NULL REFERENCES exam_attempts(attempt_id) ON DELETE CASCADE,
    question_id INTEGER NOT NULL REFERENCES questions(question_id) ON DELETE CASCADE,
    selected_answer TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    answer_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE (attempt_id, question_id),
    CONSTRAINT non_empty_answer CHECK (length(trim(selected_answer)) > 0)
);

-- Create indexes for better performance
CREATE INDEX idx_exam_attempts_user_id ON exam_attempts(user_id);
CREATE INDEX idx_exam_attempts_exam_id ON exam_attempts(exam_id);
CREATE INDEX idx_exam_attempts_status ON exam_attempts(status);
CREATE INDEX idx_exam_attempts_start_time ON exam_attempts(start_time);
CREATE INDEX idx_user_answers_attempt_id ON user_answers(attempt_id);
CREATE INDEX idx_user_answers_question_id ON user_answers(question_id);

-- Create trigger for updating updated_at column on exam_attempts
CREATE TRIGGER update_exam_attempts_updated_at
BEFORE UPDATE ON exam_attempts
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE exam_attempts IS 'Track user exam attempts with timing and scoring';
COMMENT ON TABLE user_answers IS 'Store user answers for each question in an exam attempt';
COMMENT ON TYPE exam_status_enum IS 'Status of an exam attempt';
COMMENT ON COLUMN exam_attempts.score IS 'TOEIC score (0-990), NULL if not completed';
COMMENT ON COLUMN user_answers.selected_answer IS 'User selected answer text';
COMMENT ON COLUMN user_answers.is_correct IS 'Whether the answer is correct';
