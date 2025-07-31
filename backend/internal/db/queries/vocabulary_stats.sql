-- Vocabulary Statistics Queries

-- name: CreateOrUpdateVocabularyStats :one
INSERT INTO vocabulary_stats (
  user_id,
  word_id,
  total_attempts,
  correct_attempts,
  total_response_time_ms,
  mastery_level,
  last_attempt_at
) VALUES (
  $1, $2, $3, $4, $5, $6, $7
)
ON CONFLICT (user_id, word_id)
DO UPDATE SET
  total_attempts = vocabulary_stats.total_attempts + EXCLUDED.total_attempts,
  correct_attempts = vocabulary_stats.correct_attempts + EXCLUDED.correct_attempts,
  total_response_time_ms = vocabulary_stats.total_response_time_ms + EXCLUDED.total_response_time_ms,
  mastery_level = EXCLUDED.mastery_level,
  last_attempt_at = EXCLUDED.last_attempt_at,
  updated_at = NOW()
RETURNING *;

-- name: GetVocabularyStats :one
SELECT * FROM vocabulary_stats
WHERE user_id = $1 AND word_id = $2;

-- name: ListUserVocabularyStats :many
SELECT sqlc.embed(vocabulary_stats), sqlc.embed(words)
FROM vocabulary_stats
JOIN words ON vocabulary_stats.word_id = words.id
WHERE vocabulary_stats.user_id = $1
ORDER BY vocabulary_stats.last_attempt_at DESC
LIMIT $2 OFFSET $3;

-- name: GetWordsNeedingReview :many
SELECT sqlc.embed(words), sqlc.embed(vocabulary_stats)
FROM words
LEFT JOIN vocabulary_stats ON words.id = vocabulary_stats.word_id AND vocabulary_stats.user_id = $1
WHERE vocabulary_stats.mastery_level < $2 OR vocabulary_stats.mastery_level IS NULL
ORDER BY vocabulary_stats.last_attempt_at ASC NULLS FIRST
LIMIT $3;

-- name: GetUserMasteryDistribution :many
SELECT 
  mastery_level,
  COUNT(*) as word_count
FROM vocabulary_stats
WHERE user_id = $1
GROUP BY mastery_level
ORDER BY mastery_level;

-- name: GetUserLearningProgress :one
SELECT 
  COUNT(*) as total_words_studied,
  SUM(CASE WHEN mastery_level >= 8 THEN 1 ELSE 0 END) as mastered_words,
  AVG(mastery_level) as average_mastery,
  SUM(total_attempts) as total_attempts,
  SUM(correct_attempts) as total_correct,
  SUM(total_response_time_ms) as total_study_time_ms
FROM vocabulary_stats
WHERE user_id = $1;

-- name: UpdateWordMastery :one
UPDATE vocabulary_stats
SET
  mastery_level = $3,
  updated_at = NOW()
WHERE user_id = $1 AND word_id = $2
RETURNING *;

-- name: DeleteVocabularyStats :exec
DELETE FROM vocabulary_stats
WHERE user_id = $1 AND word_id = $2;
