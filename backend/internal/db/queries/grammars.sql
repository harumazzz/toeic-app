-- name: CreateGrammar :one
INSERT INTO grammars (
    level,
    title,
    tag,
    grammar_key,
    related,
    contents
) VALUES (
    $1, $2, $3, $4, $5, $6
) RETURNING *;

-- name: GetGrammar :one
SELECT * FROM grammars
WHERE id = $1 LIMIT 1;

-- name: BatchGetGrammars :many
SELECT * FROM grammars
WHERE id = ANY($1::int[])
ORDER BY id;

-- name: ListGrammars :many
SELECT * FROM grammars
ORDER BY id
LIMIT $1
OFFSET $2;

-- name: UpdateGrammar :one
UPDATE grammars
SET
    level = $2,
    title = $3,
    tag = $4,
    grammar_key = $5,
    related = $6,
    contents = $7
WHERE id = $1
RETURNING *;

-- name: DeleteGrammar :exec
DELETE FROM grammars
WHERE id = $1;

-- name: SearchGrammars :many
SELECT * FROM grammars
WHERE
    title ILIKE '%' || $1 || '%' OR
    grammar_key ILIKE '%' || $1 || '%' OR
    EXISTS (SELECT 1 FROM unnest(tag) AS t WHERE t ILIKE '%' || $1 || '%') OR
    contents::text ILIKE '%' || $1 || '%'
ORDER BY 
    CASE 
        WHEN LOWER(title) = LOWER($1) THEN 1
        WHEN title ILIKE $1 || '%' THEN 2
        WHEN title ILIKE '%' || $1 || '%' THEN 3
        WHEN grammar_key ILIKE $1 || '%' THEN 4
        WHEN grammar_key ILIKE '%' || $1 || '%' THEN 5
        ELSE 6
    END,
    level, id
LIMIT $2
OFFSET $3;

-- name: GetRandomGrammar :one
SELECT * FROM grammars
ORDER BY RANDOM()
LIMIT 1;

-- name: ListGrammarsByLevel :many
SELECT * FROM grammars
WHERE level = $1
ORDER BY id
LIMIT $2
OFFSET $3;

-- name: ListGrammarsByTag :many
SELECT * FROM grammars
WHERE $1 = ANY(tag)
ORDER BY level, id
LIMIT $2
OFFSET $3;
