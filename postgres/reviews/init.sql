CREATE TABLE IF NOT EXISTS movies (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL UNIQUE,
    year INTEGER CHECK (year >= 1888),
    director TEXT,
    genre TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS reviewers (
    id SERIAL PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    display_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ratings (
    id SERIAL PRIMARY KEY,
    movie_id INTEGER NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
    reviewer_id INTEGER NOT NULL REFERENCES reviewers(id) ON DELETE CASCADE,
    score REAL NOT NULL CHECK (score >= 0 AND score <= 10),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (movie_id, reviewer_id)
);

CREATE TABLE IF NOT EXISTS outbox (
    id BIGSERIAL PRIMARY KEY,
    event_type TEXT NOT NULL,
    aggregate_id BIGINT NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    published_at TIMESTAMPTZ,
    attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT
);

CREATE INDEX IF NOT EXISTS idx_ratings_movie_id ON ratings(movie_id);
CREATE INDEX IF NOT EXISTS idx_ratings_reviewer_id ON ratings(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_outbox_pending
    ON outbox (created_at, id)
    WHERE published_at IS NULL;

INSERT INTO movies (id, title, year, director, genre) VALUES
(1, 'Sueños de libertad', 1994, 'Frank Darabont', 'Drama'),
(2, 'El Padrino', 1972, 'Francis Ford Coppola', 'Crimen'),
(3, 'El Caballero Oscuro', 2008, 'Christopher Nolan', 'Acción')
ON CONFLICT (id) DO NOTHING;

INSERT INTO reviewers (id, username, display_name) VALUES
(1, 'alice', 'Alice Johnson'),
(2, 'bob', 'Bob Smith'),
(3, 'carol', 'Carol Williams')
ON CONFLICT (id) DO NOTHING;