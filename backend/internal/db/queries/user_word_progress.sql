-- name: CreateUserWordProgress :one
INSERT INTO user_word_progress (
  user_id,
  word_id,
  last_reviewed_at,
  next_review_at,
  interval_days,
  ease_factor,
  repetitions
) VALUES (
  $1, $2, $3, $4, $5, $6, $7
)
RETURNING *;

-- name: GetUserWordProgress :one
SELECT * FROM user_word_progress
WHERE user_id = $1 AND word_id = $2;

-- name: UpdateUserWordProgress :one
UPDATE user_word_progress
SET
  last_reviewed_at = $3,
  next_review_at = $4,
  interval_days = $5,
  ease_factor = $6,
  repetitions = $7,
  updated_at = NOW()
WHERE user_id = $1 AND word_id = $2
RETURNING *;

-- name: ListUserWordProgressByNextReview :many
SELECT * FROM user_word_progress
WHERE user_id = $1 AND next_review_at <= $2
ORDER BY next_review_at;

-- name: DeleteUserWordProgress :exec
DELETE FROM user_word_progress
WHERE user_id = $1 AND word_id = $2;

-- name: GetWordsForReview :many
SELECT sqlc.embed(words), sqlc.embed(user_word_progress)
FROM words
JOIN user_word_progress ON words.id = user_word_progress.word_id
WHERE user_word_progress.user_id = $1
  AND user_word_progress.next_review_at <= NOW()
ORDER BY user_word_progress.next_review_at;

-- name: GetWordWithProgress :one
SELECT sqlc.embed(words), sqlc.embed(user_word_progress)
FROM words
LEFT JOIN user_word_progress ON words.id = user_word_progress.word_id AND user_word_progress.user_id = $2
WHERE words.id = $1;
