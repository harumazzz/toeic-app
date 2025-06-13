-- name: CreateExamAttempt :one
INSERT INTO exam_attempts (
    user_id,
    exam_id,
    start_time,
    status
) VALUES (
    $1, $2, $3, $4
) RETURNING *;

-- name: GetExamAttempt :one
SELECT * FROM exam_attempts
WHERE attempt_id = $1 LIMIT 1;

-- name: GetExamAttemptByUser :one
SELECT * FROM exam_attempts
WHERE attempt_id = $1 AND user_id = $2 LIMIT 1;

-- name: ListExamAttemptsByUser :many
SELECT * FROM exam_attempts
WHERE user_id = $1
ORDER BY start_time DESC
LIMIT $2 OFFSET $3;

-- name: ListExamAttemptsByExam :many
SELECT * FROM exam_attempts
WHERE exam_id = $1
ORDER BY start_time DESC
LIMIT $2 OFFSET $3;

-- name: GetActiveExamAttempt :one
SELECT * FROM exam_attempts
WHERE user_id = $1 AND exam_id = $2 AND status = 'in_progress'
ORDER BY start_time DESC
LIMIT 1;

-- name: UpdateExamAttemptStatus :one
UPDATE exam_attempts
SET 
    status = $2,
    end_time = CASE 
        WHEN $2 IN ('completed', 'abandoned') THEN NOW() 
        ELSE end_time 
    END,
    updated_at = NOW()
WHERE attempt_id = $1
RETURNING *;

-- name: UpdateExamAttemptScore :one
UPDATE exam_attempts
SET 
    score = $2,
    status = CASE 
        WHEN $2 IS NOT NULL THEN 'completed'::exam_status_enum
        ELSE status 
    END,
    end_time = CASE 
        WHEN $2 IS NOT NULL AND end_time IS NULL THEN NOW() 
        ELSE end_time 
    END,
    updated_at = NOW()
WHERE attempt_id = $1
RETURNING *;

-- name: CompleteExamAttempt :one
UPDATE exam_attempts
SET 
    status = 'completed',
    end_time = NOW(),
    score = $2,
    updated_at = NOW()
WHERE attempt_id = $1
RETURNING *;

-- name: AbandonExamAttempt :one
UPDATE exam_attempts
SET 
    status = 'abandoned',
    end_time = NOW(),
    updated_at = NOW()
WHERE attempt_id = $1
RETURNING *;

-- name: DeleteExamAttempt :exec
DELETE FROM exam_attempts
WHERE attempt_id = $1;

-- name: CountExamAttemptsByUser :one
SELECT COUNT(*) FROM exam_attempts
WHERE user_id = $1;

-- name: CountExamAttemptsByExam :one
SELECT COUNT(*) FROM exam_attempts
WHERE exam_id = $1;

-- name: GetExamAttemptStats :one
SELECT 
    COUNT(*) as total_attempts,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_attempts,
    COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress_attempts,
    COUNT(CASE WHEN status = 'abandoned' THEN 1 END) as abandoned_attempts,
    AVG(score) as average_score,
    MAX(score) as highest_score,
    MIN(score) as lowest_score
FROM exam_attempts
WHERE user_id = $1;

-- name: GetExamLeaderboard :many
SELECT 
    ea.user_id,
    u.username,
    ea.score,
    ea.end_time,
    ROW_NUMBER() OVER (ORDER BY ea.score DESC, ea.end_time ASC) as rank
FROM exam_attempts ea
JOIN users u ON ea.user_id = u.id
WHERE ea.exam_id = $1 AND ea.status = 'completed' AND ea.score IS NOT NULL
ORDER BY ea.score DESC, ea.end_time ASC
LIMIT $2 OFFSET $3;
