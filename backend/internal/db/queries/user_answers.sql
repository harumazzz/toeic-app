-- name: CreateUserAnswer :one
INSERT INTO user_answers (
    attempt_id,
    question_id,
    selected_answer,
    is_correct,
    answer_time
) VALUES (
    $1, $2, $3, $4, $5
) RETURNING *;

-- name: GetUserAnswer :one
SELECT * FROM user_answers
WHERE user_answer_id = $1 LIMIT 1;

-- name: GetUserAnswerByAttemptAndQuestion :one
SELECT * FROM user_answers
WHERE attempt_id = $1 AND question_id = $2 LIMIT 1;

-- name: ListUserAnswersByAttempt :many
SELECT * FROM user_answers
WHERE attempt_id = $1
ORDER BY answer_time;

-- name: ListUserAnswersByAttemptWithQuestions :many
SELECT 
    ua.*,
    q.title as question_title,
    q.true_answer,
    q.explanation,
    q.possible_answers
FROM user_answers ua
JOIN questions q ON ua.question_id = q.question_id
WHERE ua.attempt_id = $1
ORDER BY ua.answer_time;

-- name: UpdateUserAnswer :one
UPDATE user_answers
SET 
    selected_answer = $2,
    is_correct = $3,
    answer_time = NOW()
WHERE user_answer_id = $1
RETURNING *;

-- name: UpdateUserAnswerByAttemptAndQuestion :one
UPDATE user_answers
SET 
    selected_answer = $3,
    is_correct = $4,
    answer_time = NOW()
WHERE attempt_id = $1 AND question_id = $2
RETURNING *;

-- name: DeleteUserAnswer :exec
DELETE FROM user_answers
WHERE user_answer_id = $1;

-- name: DeleteUserAnswersByAttempt :exec
DELETE FROM user_answers
WHERE attempt_id = $1;

-- name: CountUserAnswersByAttempt :one
SELECT COUNT(*) FROM user_answers
WHERE attempt_id = $1;

-- name: CountCorrectAnswersByAttempt :one
SELECT COUNT(*) FROM user_answers
WHERE attempt_id = $1 AND is_correct = true;

-- name: GetAttemptScore :one
SELECT 
    COUNT(*) as total_questions,
    COUNT(CASE WHEN is_correct = true THEN 1 END) as correct_answers,
    ROUND(
        (COUNT(CASE WHEN is_correct = true THEN 1 END)::numeric / COUNT(*)::numeric) * 990, 2
    ) as calculated_score
FROM user_answers
WHERE attempt_id = $1;

-- name: GetQuestionAnalytics :many
SELECT 
    q.question_id,
    q.title,
    COUNT(ua.user_answer_id) as total_attempts,
    COUNT(CASE WHEN ua.is_correct = true THEN 1 END) as correct_attempts,
    ROUND(
        (COUNT(CASE WHEN ua.is_correct = true THEN 1 END)::numeric / COUNT(ua.user_answer_id)::numeric) * 100, 2
    ) as success_rate
FROM questions q
LEFT JOIN user_answers ua ON q.question_id = ua.question_id
WHERE q.content_id IN (
    SELECT c.content_id FROM contents c
    JOIN parts p ON c.part_id = p.part_id
    WHERE p.exam_id = $1
)
GROUP BY q.question_id, q.title
ORDER BY success_rate ASC;

-- name: GetUserAnswerHistory :many
SELECT 
    ua.*,
    q.title as question_title,
    q.true_answer,
    ea.exam_id,
    e.title as exam_title
FROM user_answers ua
JOIN exam_attempts ea ON ua.attempt_id = ea.attempt_id
JOIN questions q ON ua.question_id = q.question_id
JOIN contents c ON q.content_id = c.content_id
JOIN parts p ON c.part_id = p.part_id
JOIN exams e ON p.exam_id = e.exam_id
WHERE ea.user_id = $1
ORDER BY ua.answer_time DESC
LIMIT $2 OFFSET $3;
