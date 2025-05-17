CREATE TABLE writing_prompts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    prompt_text TEXT NOT NULL,
    topic VARCHAR(255),
    difficulty_level VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE user_writings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    prompt_id INTEGER REFERENCES writing_prompts(id) ON DELETE SET NULL,
    submission_text TEXT NOT NULL,
    ai_feedback JSONB,
    ai_score NUMERIC(5, 2),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    evaluated_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL 
);

CREATE TRIGGER update_user_writings_updated_at
BEFORE UPDATE ON user_writings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_writing_prompts_user_id ON writing_prompts(user_id);

CREATE INDEX idx_user_writings_user_id ON user_writings(user_id);
CREATE INDEX idx_user_writings_prompt_id ON user_writings(prompt_id);