-- Learning Sessions and Attempts Queries

-- name: CreateLearningSession :one
INSERT INTO learning_sessions (
  user_id,
  study_set_id,
  session_type,
  total_questions,
  session_data
) VALUES (
  $1, $2, $3, $4, $5
)
RETURNING *;

-- name: GetLearningSession :one
SELECT * FROM learning_sessions
WHERE id = $1 AND user_id = $2;

-- name: UpdateLearningSession :one
UPDATE learning_sessions
SET
  completed_at = $3,
  total_questions = $4,
  correct_answers = $5,
  session_data = $6
WHERE id = $1 AND user_id = $2
RETURNING *;

-- name: ListUserLearningSessions :many
SELECT * FROM learning_sessions
WHERE user_id = $1
ORDER BY started_at DESC
LIMIT $2 OFFSET $3;

-- name: CreateLearningAttempt :one
INSERT INTO learning_attempts (
  session_id,
  word_id,
  attempt_type,
  user_answer,
  correct_answer,
  is_correct,
  response_time_ms,
  difficulty_rating
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8
)
RETURNING *;

-- name: GetLearningAttempt :one
SELECT * FROM learning_attempts
WHERE id = $1;

-- name: ListSessionAttempts :many
SELECT sqlc.embed(learning_attempts), sqlc.embed(words)
FROM learning_attempts
JOIN words ON learning_attempts.word_id = words.id
WHERE learning_attempts.session_id = $1
ORDER BY learning_attempts.created_at;

-- name: GetSessionStats :one
SELECT 
  COUNT(*) as total_attempts,
  SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) as correct_attempts,
  AVG(response_time_ms) as avg_response_time,
  AVG(difficulty_rating) as avg_difficulty
FROM learning_attempts
WHERE session_id = $1;

-- name: DeleteLearningSession :exec
DELETE FROM learning_sessions
WHERE id = $1 AND user_id = $2;
