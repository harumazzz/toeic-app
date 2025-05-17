CREATE TABLE grammars (
    id SERIAL NOT NULL PRIMARY KEY,
    level INTEGER NOT NULL,
    title TEXT NOT NULL,
    tag TEXT[] NOT NULL,
    grammar_key TEXT NOT NULL,
    related INTEGER[] NOT NULL,
    contents JSONB NOT NULL
);
