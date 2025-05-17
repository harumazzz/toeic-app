DROP INDEX IF EXISTS idx_speaking_turns_timestamp;
DROP INDEX IF EXISTS idx_speaking_turns_speaker_type;
DROP INDEX IF EXISTS idx_speaking_turns_session_id;

DROP INDEX IF EXISTS idx_speaking_sessions_user_id;
DROP TABLE IF EXISTS speaking_turns;

DROP TRIGGER IF EXISTS update_speaking_sessions_updated_at ON speaking_sessions;
DROP TABLE IF EXISTS speaking_sessions;