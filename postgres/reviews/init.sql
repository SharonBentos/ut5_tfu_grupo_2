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

INSERT INTO movies (id, title, year, director, genre) VALUES (1, 'SueÃ±os de libertad', 1994, 'Frank Darabont', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (2, 'El Padrino', 1972, 'Francis Ford Coppola', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (3, 'El Caballero Oscuro', 2008, 'Christopher Nolan', 'AcciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (4, 'Doce hombres sin piedad', 1957, 'Sidney Lumet', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (5, 'La lista de Schindler', 1993, 'Steven Spielberg', 'BiografÃ­a') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (6, 'El SeÃ±or de los Anillos: El retorno del Rey', 2003, 'Peter Jackson', 'Aventura') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (7, 'Tiempos violentos', 1994, 'Quentin Tarantino', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (8, 'Forrest Gump', 1994, 'Robert Zemeckis', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (9, 'El club de la pelea', 1999, 'David Fincher', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (10, 'El origen', 2010, 'Christopher Nolan', 'Ciencia ficciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (11, 'Matrix', 1999, 'Lana Wachowski, Lilly Wachowski', 'Ciencia ficciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (12, 'Buenos muchachos', 1990, 'Martin Scorsese', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (13, 'Interestelar', 2014, 'Christopher Nolan', 'Ciencia ficciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (14, 'El viaje de Chihiro', 2001, 'Hayao Miyazaki', 'AnimaciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (15, 'ParÃ¡sitos', 2019, 'Bong Joon-ho', 'Suspenso') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (16, 'El silencio de los corderos', 1991, 'Jonathan Demme', 'Suspenso') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (17, 'Rescatando al soldado Ryan', 1998, 'Steven Spielberg', 'BÃ©lico') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (18, 'Ciudad de Dios', 2002, 'Fernando Meirelles', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (19, 'Whiplash: MÃºsica y obsesiÃ³n', 2014, 'Damien Chazelle', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (20, 'Amigos intocables', 2011, 'Olivier Nakache & Ã‰ric Toledano', 'Comedia') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (21, 'El Padrino: Parte II', 1974, 'Francis Ford Coppola', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (22, 'Milagros inesperados', 1999, 'Frank Darabont', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (23, 'Gladiador', 2000, 'Ridley Scott', 'AcciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (24, 'Los infiltrados', 2006, 'Martin Scorsese', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (25, 'El truco final', 2006, 'Christopher Nolan', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (26, 'Titanic', 1997, 'James Cameron', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (27, 'Avatar', 2009, 'James Cameron', 'Ciencia ficciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (28, 'Jurassic Park', 1993, 'Steven Spielberg', 'Aventura') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (29, 'Toy Story', 1995, 'John Lasseter', 'AnimaciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (30, 'Coco', 2017, 'Lee Unkrich', 'AnimaciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (31, 'Avengers: Endgame', 2019, 'Anthony Russo & Joe Russo', 'AcciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (32, 'El Rey LeÃ³n', 1994, 'Roger Allers & Rob Minkoff', 'AnimaciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (33, 'Star Wars: Una nueva esperanza', 1977, 'George Lucas', 'Ciencia ficciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (34, 'Casablanca', 1942, 'Michael Curtiz', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (35, 'Psicosis', 1960, 'Alfred Hitchcock', 'Suspenso') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (36, 'El resplandor', 1980, 'Stanley Kubrick', 'Terror') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (37, 'Volver al futuro', 1985, 'Robert Zemeckis', 'Ciencia ficciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (38, 'La La Land', 2016, 'Damien Chazelle', 'Musical') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (39, 'Joker', 2019, 'Todd Phillips', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (40, 'Dune: Parte uno', 2021, 'Denis Villeneuve', 'Ciencia ficciÃ³n') ON CONFLICT (id) DO NOTHING;
INSERT INTO reviewers (id, username, display_name) VALUES (1, 'alice', 'Alice Johnson') ON CONFLICT (id) DO NOTHING;
INSERT INTO reviewers (id, username, display_name) VALUES (2, 'bob', 'Bob Smith') ON CONFLICT (id) DO NOTHING;
INSERT INTO reviewers (id, username, display_name) VALUES (3, 'carol', 'Carol Williams') ON CONFLICT (id) DO NOTHING;
INSERT INTO reviewers (id, username, display_name) VALUES (4, 'dave', 'Dave Brown') ON CONFLICT (id) DO NOTHING;
INSERT INTO reviewers (id, username, display_name) VALUES (5, 'eve', 'Eve Davis') ON CONFLICT (id) DO NOTHING;
INSERT INTO reviewers (id, username, display_name) VALUES (6, 'frank', 'Frank Miller') ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (34, 5, 7.3, 'Visualmente impactante') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (36, 1, 8.4, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (20, 6, 6.5, 'Un clÃ¡sico') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (15, 2, 5, 'Para ver de nuevo') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (6, 1, 9.4, 'Inolvidable') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (31, 3, 5.5, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (18, 3, 5.3, 'Un clÃ¡sico') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (3, 3, 6, 'Gran actuaciÃ³n') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (19, 3, 7.3, 'Para ver de nuevo') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (32, 4, 7.9, 'Emotiva') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (29, 1, 6.3, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (31, 4, 5.3, 'Inolvidable') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (21, 3, 6.4, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (13, 4, 5.3, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (26, 2, 6.7, 'Recomendada') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (5, 3, 7, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (16, 3, 7.9, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (35, 5, 6.7, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (16, 1, 7.3, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (2, 4, 5.3, 'Emotiva') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (21, 2, 5.8, 'Intensa') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (36, 3, 9.9, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (6, 5, 7, 'Un clÃ¡sico') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (40, 6, 5.5, 'Conmovedora') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (35, 6, 8.3, 'Emotiva') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (38, 5, 6.6, 'Intensa') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (17, 2, 7.7, 'Obra maestra') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (28, 1, 7.9, 'Para ver de nuevo') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (24, 3, 9.3, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (30, 2, 10, 'Un clÃ¡sico') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (24, 1, 9, 'Buena pero larga') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (34, 2, 9.6, 'Conmovedora') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (25, 2, 8.7, 'Divertida') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (13, 1, 8.8, 'Excelente') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (9, 2, 9.4, 'Recomendada') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (37, 2, 5.6, 'Gran actuaciÃ³n') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (11, 1, 7.1, 'Visualmente impactante') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (20, 2, 9.9, 'Intensa') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (31, 2, 8.6, 'Buena pero larga') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (11, 2, 8, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (22, 1, 9.6, 'Visualmente impactante') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (34, 1, 6.2, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (17, 5, 7.7, 'Emotiva') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (27, 2, 8.6, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (18, 1, 9, 'Para ver de nuevo') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (35, 1, 8.4, 'Divertida') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (15, 4, 8, 'Visualmente impactante') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (6, 2, 5.5, 'Un clÃ¡sico') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (1, 1, 6.1, 'Recomendada') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (38, 1, 8.5, 'Un clÃ¡sico') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (20, 1, 5.8, 'Inolvidable') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (8, 5, 9.4, 'Inolvidable') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (38, 2, 5.3, 'Intensa') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (29, 4, 9.3, 'Obra maestra') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (22, 2, 7.4, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (1, 2, 9.7, 'Obra maestra') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (40, 2, 5, 'Inolvidable') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (14, 1, 7.3, 'Recomendada') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (28, 3, 6.7, 'Divertida') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (9, 4, 7.8, 'Visualmente impactante') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (26, 3, 7.2, 'Divertida') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (40, 3, 9.3, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (16, 4, 7.8, 'Para ver de nuevo') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (27, 1, 9.9, 'Un clÃ¡sico') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (27, 4, 6.5, 'Excelente') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (33, 1, 9.4, 'Inolvidable') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (23, 3, 5.7, 'Obra maestra') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (14, 2, 9.6, 'Conmovedora') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (8, 3, 9.7, 'Visualmente impactante') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (40, 1, 6.9, 'Gran actuaciÃ³n') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (5, 1, 6.1, 'Gran actuaciÃ³n') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (14, 5, 6.3, 'Conmovedora') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (4, 2, 6.5, 'Un clÃ¡sico') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (22, 3, 5.5, 'Buena pero larga') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (8, 2, 7.5, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (24, 2, 7.2, 'Gran actuaciÃ³n') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (39, 4, 5.4, 'Obra maestra') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (26, 4, 7.4, 'Conmovedora') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (13, 2, 6.2, 'Visualmente impactante') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (32, 1, 8.2, 'Visualmente impactante') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (6, 4, 9.8, 'Intensa') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (15, 3, 8.9, 'Intensa') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (5, 2, 5.8, 'Intensa') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (15, 1, 9.9, 'Buena pero larga') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (29, 3, 7.6, 'Recomendada') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (34, 6, 5.7, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (39, 1, 5.3, 'Un clÃ¡sico') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (17, 1, 8.2, 'Inolvidable') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (2, 1, 6.7, 'Recomendada') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (39, 3, 7.7, 'Para ver de nuevo') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (40, 4, 8.4, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (32, 3, 5.3, 'Emotiva') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (1, 6, 9.4, 'Para ver de nuevo') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (23, 2, 9.7, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (11, 4, 7.4, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (23, 1, 8.6, 'Obra maestra') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (37, 5, 9.7, 'Excelente') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (28, 4, 7, 'Conmovedora') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (30, 1, 6, 'Recomendada') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (14, 4, 5.3, 'Visualmente impactante') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (33, 2, 9.9, 'Intensa') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (8, 1, 5.5, 'Divertida') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (9, 1, 5.4, 'Recomendada') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (26, 1, 8.7, 'Emotiva') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (3, 2, 6.5, 'Excelente') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (21, 5, 10, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (3, 1, 9.9, 'Divertida') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (7, 1, 9.1, 'Visualmente impactante') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (12, 1, 7, 'Conmovedora') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (36, 2, 6.3, 'Divertida') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (18, 2, 9.6, 'Intensa') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (31, 1, 8.2, 'Obra maestra') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (27, 5, 8.2, 'Gran actuaciÃ³n') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (30, 3, 5.3, 'Para ver de nuevo') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (2, 3, 9.4, 'Muy buena') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (9, 5, 6.4, 'Gran actuaciÃ³n') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (32, 2, 5.9, 'Conmovedora') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (1, 4, 6.4, 'Para ver de nuevo') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (19, 1, 6.1, 'Excelente') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (1, 3, 6.8, 'Buena pero larga') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (37, 1, 6.3, 'Visualmente impactante') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (25, 1, 6.3, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (21, 1, 8.2, 'Emotiva') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
INSERT INTO ratings (movie_id, reviewer_id, score, comment) VALUES (34, 3, 8.3, 'Me encantÃ³') ON CONFLICT (movie_id, reviewer_id) DO NOTHING;
SELECT setval(pg_get_serial_sequence('ratings', 'id'), (SELECT MAX(id) FROM ratings));
