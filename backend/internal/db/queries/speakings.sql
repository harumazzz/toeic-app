-- name: CreateSpeakingSession :one
INSERT INTO speaking_sessions (
    user_id,
    session_topic,
    start_time,
    end_time
) VALUES (
    $1, $2, $3, $4
) RETURNING *;

-- name: GetSpeakingSession :one
SELECT * FROM speaking_sessions WHERE id = $1 LIMIT 1;

-- name: ListSpeakingSessionsByUserID :many
SELECT * FROM speaking_sessions WHERE user_id = $1 ORDER BY start_time DESC;

-- name: UpdateSpeakingSession :one
UPDATE speaking_sessions
SET session_topic = $2,
    start_time = $3,
    end_time = $4,
    updated_at = NOW()
WHERE id = $1
RETURNING *;

-- name: DeleteSpeakingSession :exec
DELETE FROM speaking_sessions WHERE id = $1;

-- name: CreateSpeakingTurn :one
INSERT INTO speaking_turns (
    session_id,
    speaker_type,
    text_spoken,
    audio_recording_path,
    "timestamp",
    ai_evaluation,
    ai_score
) VALUES (
    $1, $2, $3, $4, $5, $6, $7
) RETURNING *;

-- name: GetSpeakingTurn :one
SELECT * FROM speaking_turns WHERE id = $1 LIMIT 1;

-- name: ListSpeakingTurnsBySessionID :many
SELECT * FROM speaking_turns WHERE session_id = $1 ORDER BY "timestamp" ASC;

-- name: UpdateSpeakingTurn :one
UPDATE speaking_turns
SET text_spoken = $2,
    audio_recording_path = $3,
    ai_evaluation = $4,
    ai_score = $5,
    "timestamp" = $6
WHERE id = $1
RETURNING *;

-- name: DeleteSpeakingTurn :exec
DELETE FROM speaking_turns WHERE id = $1;
