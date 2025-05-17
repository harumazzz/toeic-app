CREATE TABLE speaking_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_topic VARCHAR(255),
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TRIGGER update_speaking_sessions_updated_at
BEFORE UPDATE ON speaking_sessions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE speaking_turns (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL REFERENCES speaking_sessions(id) ON DELETE CASCADE,
    speaker_type VARCHAR(10) NOT NULL CHECK (speaker_type IN ('user', 'ai')),
    text_spoken TEXT,
    audio_recording_path VARCHAR(512),
    "timestamp" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    ai_evaluation JSONB,
    ai_score NUMERIC(5, 2)
);

CREATE INDEX idx_speaking_sessions_user_id ON speaking_sessions(user_id);

CREATE INDEX idx_speaking_turns_session_id ON speaking_turns(session_id);
CREATE INDEX idx_speaking_turns_speaker_type ON speaking_turns(speaker_type);
CREATE INDEX idx_speaking_turns_timestamp ON speaking_turns("timestamp");