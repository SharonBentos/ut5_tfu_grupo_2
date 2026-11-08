-- Base propia del servicio de estadísticas (UT5).
-- Copia de películas y calificaciones de la UT4 con los mismos IDs,
-- más la tabla donde se guardan las estadísticas calculadas por película.

CREATE TABLE IF NOT EXISTS movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL UNIQUE,
    year INTEGER CHECK (year >= 1888),
    director TEXT,
    genre TEXT
);

-- Copia local de las calificaciones (se alimenta con eventos ReseñaCreada).
-- El id es el de la reseña en el servicio de reviews.
CREATE TABLE IF NOT EXISTS ratings (
    id INTEGER PRIMARY KEY,
    movie_id INTEGER NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
    reviewer_id INTEGER NOT NULL,
    score REAL NOT NULL CHECK (score >= 0 AND score <= 10),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (movie_id, reviewer_id)
);

CREATE INDEX IF NOT EXISTS idx_ratings_movie_id ON ratings(movie_id);

CREATE TABLE IF NOT EXISTS movie_stats (
    movie_id INTEGER PRIMARY KEY REFERENCES movies(id) ON DELETE CASCADE,
    rating_count INTEGER NOT NULL DEFAULT 0,
    avg_rating REAL,
    min_rating REAL,
    max_rating REAL,
    median_rating REAL,
    stddev_rating REAL,
    score_distribution JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO movies (id, title, year, director, genre) VALUES (1, 'Sueños de libertad', 1994, 'Frank Darabont', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (2, 'El Padrino', 1972, 'Francis Ford Coppola', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (3, 'El Caballero Oscuro', 2008, 'Christopher Nolan', 'Acción') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (4, 'Doce hombres sin piedad', 1957, 'Sidney Lumet', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (5, 'La lista de Schindler', 1993, 'Steven Spielberg', 'Biografía') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (6, 'El Señor de los Anillos: El retorno del Rey', 2003, 'Peter Jackson', 'Aventura') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (7, 'Tiempos violentos', 1994, 'Quentin Tarantino', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (8, 'Forrest Gump', 1994, 'Robert Zemeckis', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (9, 'El club de la pelea', 1999, 'David Fincher', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (10, 'El origen', 2010, 'Christopher Nolan', 'Ciencia ficción') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (11, 'Matrix', 1999, 'Lana Wachowski, Lilly Wachowski', 'Ciencia ficción') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (12, 'Buenos muchachos', 1990, 'Martin Scorsese', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (13, 'Interestelar', 2014, 'Christopher Nolan', 'Ciencia ficción') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (14, 'El viaje de Chihiro', 2001, 'Hayao Miyazaki', 'Animación') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (15, 'Parásitos', 2019, 'Bong Joon-ho', 'Suspenso') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (16, 'El silencio de los corderos', 1991, 'Jonathan Demme', 'Suspenso') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (17, 'Rescatando al soldado Ryan', 1998, 'Steven Spielberg', 'Bélico') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (18, 'Ciudad de Dios', 2002, 'Fernando Meirelles', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (19, 'Whiplash: Música y obsesión', 2014, 'Damien Chazelle', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (20, 'Amigos intocables', 2011, 'Olivier Nakache & Éric Toledano', 'Comedia') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (21, 'El Padrino: Parte II', 1974, 'Francis Ford Coppola', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (22, 'Milagros inesperados', 1999, 'Frank Darabont', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (23, 'Gladiador', 2000, 'Ridley Scott', 'Acción') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (24, 'Los infiltrados', 2006, 'Martin Scorsese', 'Crimen') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (25, 'El truco final', 2006, 'Christopher Nolan', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (26, 'Titanic', 1997, 'James Cameron', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (27, 'Avatar', 2009, 'James Cameron', 'Ciencia ficción') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (28, 'Jurassic Park', 1993, 'Steven Spielberg', 'Aventura') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (29, 'Toy Story', 1995, 'John Lasseter', 'Animación') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (30, 'Coco', 2017, 'Lee Unkrich', 'Animación') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (31, 'Avengers: Endgame', 2019, 'Anthony Russo & Joe Russo', 'Acción') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (32, 'El Rey León', 1994, 'Roger Allers & Rob Minkoff', 'Animación') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (33, 'Star Wars: Una nueva esperanza', 1977, 'George Lucas', 'Ciencia ficción') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (34, 'Casablanca', 1942, 'Michael Curtiz', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (35, 'Psicosis', 1960, 'Alfred Hitchcock', 'Suspenso') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (36, 'El resplandor', 1980, 'Stanley Kubrick', 'Terror') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (37, 'Volver al futuro', 1985, 'Robert Zemeckis', 'Ciencia ficción') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (38, 'La La Land', 2016, 'Damien Chazelle', 'Musical') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (39, 'Joker', 2019, 'Todd Phillips', 'Drama') ON CONFLICT (id) DO NOTHING;
INSERT INTO movies (id, title, year, director, genre) VALUES (40, 'Dune: Parte uno', 2021, 'Denis Villeneuve', 'Ciencia ficción') ON CONFLICT (id) DO NOTHING;

INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (1, 34, 5, 7.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (2, 36, 1, 8.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (3, 20, 6, 6.5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (4, 15, 2, 5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (5, 6, 1, 9.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (6, 31, 3, 5.5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (7, 18, 3, 5.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (8, 3, 3, 6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (9, 19, 3, 7.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (10, 32, 4, 7.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (11, 29, 1, 6.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (12, 31, 4, 5.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (13, 21, 3, 6.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (14, 13, 4, 5.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (15, 26, 2, 6.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (16, 5, 3, 7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (17, 16, 3, 7.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (18, 35, 5, 6.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (19, 16, 1, 7.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (20, 2, 4, 5.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (21, 21, 2, 5.8) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (22, 36, 3, 9.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (23, 6, 5, 7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (24, 40, 6, 5.5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (25, 35, 6, 8.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (26, 38, 5, 6.6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (27, 17, 2, 7.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (28, 28, 1, 7.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (29, 24, 3, 9.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (30, 30, 2, 10) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (31, 24, 1, 9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (32, 34, 2, 9.6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (33, 25, 2, 8.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (34, 13, 1, 8.8) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (35, 9, 2, 9.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (36, 37, 2, 5.6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (37, 11, 1, 7.1) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (38, 20, 2, 9.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (39, 31, 2, 8.6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (40, 11, 2, 8) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (41, 22, 1, 9.6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (42, 34, 1, 6.2) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (43, 17, 5, 7.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (44, 27, 2, 8.6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (45, 18, 1, 9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (46, 35, 1, 8.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (47, 15, 4, 8) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (48, 6, 2, 5.5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (49, 1, 1, 6.1) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (50, 38, 1, 8.5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (51, 20, 1, 5.8) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (52, 8, 5, 9.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (53, 38, 2, 5.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (54, 29, 4, 9.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (55, 22, 2, 7.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (56, 1, 2, 9.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (57, 40, 2, 5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (58, 14, 1, 7.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (59, 28, 3, 6.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (60, 9, 4, 7.8) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (61, 26, 3, 7.2) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (62, 40, 3, 9.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (63, 16, 4, 7.8) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (64, 27, 1, 9.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (65, 27, 4, 6.5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (66, 33, 1, 9.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (67, 23, 3, 5.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (68, 14, 2, 9.6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (69, 8, 3, 9.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (70, 40, 1, 6.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (71, 5, 1, 6.1) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (72, 14, 5, 6.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (73, 4, 2, 6.5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (74, 22, 3, 5.5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (75, 8, 2, 7.5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (76, 24, 2, 7.2) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (77, 39, 4, 5.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (78, 26, 4, 7.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (79, 13, 2, 6.2) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (80, 32, 1, 8.2) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (81, 6, 4, 9.8) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (82, 15, 3, 8.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (83, 5, 2, 5.8) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (84, 15, 1, 9.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (85, 29, 3, 7.6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (86, 34, 6, 5.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (87, 39, 1, 5.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (88, 17, 1, 8.2) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (89, 2, 1, 6.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (90, 39, 3, 7.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (91, 40, 4, 8.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (92, 32, 3, 5.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (93, 1, 6, 9.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (94, 23, 2, 9.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (95, 11, 4, 7.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (96, 23, 1, 8.6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (97, 37, 5, 9.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (98, 28, 4, 7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (99, 30, 1, 6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (100, 14, 4, 5.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (101, 33, 2, 9.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (102, 8, 1, 5.5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (103, 9, 1, 5.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (104, 26, 1, 8.7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (105, 3, 2, 6.5) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (106, 21, 5, 10) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (107, 3, 1, 9.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (108, 7, 1, 9.1) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (109, 12, 1, 7) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (110, 36, 2, 6.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (111, 18, 2, 9.6) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (112, 31, 1, 8.2) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (113, 27, 5, 8.2) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (114, 30, 3, 5.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (115, 2, 3, 9.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (116, 9, 5, 6.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (117, 32, 2, 5.9) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (118, 1, 4, 6.4) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (119, 19, 1, 6.1) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (120, 1, 3, 6.8) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (121, 37, 1, 6.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (122, 25, 1, 6.3) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (123, 21, 1, 8.2) ON CONFLICT (id) DO NOTHING;
INSERT INTO ratings (id, movie_id, reviewer_id, score) VALUES (124, 34, 3, 8.3) ON CONFLICT (id) DO NOTHING;
