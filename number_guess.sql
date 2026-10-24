CREATE DATABASE number_guess;
\connect number_guess

CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(22) UNIQUE NOT NULL,
  games_played INTEGER NOT NULL DEFAULT 0,
  best_game INTEGER
);

GRANT CONNECT ON DATABASE number_guess TO freecodecamp;
GRANT SELECT, INSERT, UPDATE ON TABLE users TO freecodecamp;
GRANT USAGE, SELECT ON SEQUENCE users_user_id_seq TO freecodecamp;
