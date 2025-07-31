-- Study Sets Queries

-- name: CreateStudySet :one
INSERT INTO study_sets (
  user_id,
  name,
  description,
  is_public
) VALUES (
  $1, $2, $3, $4
)
RETURNING *;

-- name: GetStudySet :one
SELECT * FROM study_sets
WHERE id = $1;

-- name: GetStudySetWithWords :many
SELECT 
  sqlc.embed(study_sets),
  sqlc.embed(words)
FROM study_sets
LEFT JOIN study_set_words ON study_sets.id = study_set_words.study_set_id
LEFT JOIN words ON study_set_words.word_id = words.id
WHERE study_sets.id = $1;

-- name: ListUserStudySets :many
SELECT * FROM study_sets
WHERE user_id = $1
ORDER BY updated_at DESC
LIMIT $2 OFFSET $3;

-- name: ListPublicStudySets :many
SELECT * FROM study_sets
WHERE is_public = TRUE
ORDER BY updated_at DESC
LIMIT $1 OFFSET $2;

-- name: UpdateStudySet :one
UPDATE study_sets
SET
  name = $2,
  description = $3,
  is_public = $4,
  updated_at = NOW()
WHERE id = $1 AND user_id = $5
RETURNING *;

-- name: DeleteStudySet :exec
DELETE FROM study_sets
WHERE id = $1 AND user_id = $2;

-- name: AddWordToStudySet :exec
INSERT INTO study_set_words (study_set_id, word_id)
VALUES ($1, $2)
ON CONFLICT (study_set_id, word_id) DO NOTHING;

-- name: RemoveWordFromStudySet :exec
DELETE FROM study_set_words
WHERE study_set_id = $1 AND word_id = $2;

-- name: GetStudySetWords :many
SELECT sqlc.embed(words)
FROM words
JOIN study_set_words ON words.id = study_set_words.word_id
WHERE study_set_words.study_set_id = $1
ORDER BY study_set_words.created_at;

-- name: CountWordsInStudySet :one
SELECT COUNT(*) FROM study_set_words
WHERE study_set_id = $1;
