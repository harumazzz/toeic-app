CREATE TABLE words (
    id SERIAL NOT NULL PRIMARY KEY, 
    word VARCHAR(255) NOT NULL UNIQUE,
    pronounce VARCHAR(255) NOT NULL,
    level INT NOT NULL,
    descript_level VARCHAR(255) NOT NULL,
    short_mean VARCHAR(255) NOT NULL,
    means JSONB,
    snym JSONB,
    freq REAL NOT NULL,
    conjugation JSONB
);