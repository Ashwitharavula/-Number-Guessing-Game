#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess --no-psqlrc --tuples-only --no-align --quiet --set=ON_ERROR_STOP=1"

echo "Enter your username:"
read -r USERNAME

if [[ -z "$USERNAME" || ${#USERNAME} -gt 22 ]]; then
  echo "Username must be between 1 and 22 characters." >&2
  exit 1
fi

if ! INSERTED_USER=$(
  $PSQL --set=username="$USERNAME" 2>&1 <<'SQL'
INSERT INTO users (username) VALUES (:'username')
ON CONFLICT (username) DO NOTHING
RETURNING user_id;
SQL
); then
  echo "Could not access the number_guess database: $INSERTED_USER" >&2
  exit 1
fi

if [[ -n "$INSERTED_USER" ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  if ! USER_STATS=$(
    $PSQL --set=username="$USERNAME" 2>&1 <<'SQL'
SELECT games_played || '|' || COALESCE(best_game::TEXT, '')
FROM users
WHERE username = :'username';
SQL
  ); then
    echo "Could not retrieve your game statistics: $USER_STATS" >&2
    exit 1
  fi

  IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$USER_STATS"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"
while true; do
  if ! read -r GUESS; then
    echo "No guess was provided." >&2
    exit 1
  fi

  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

  if [[ ! "$GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  else
    GUESS_NUMBER=$GUESS
    while [[ ${#GUESS_NUMBER} -gt 1 && "$GUESS_NUMBER" == 0* ]]; do
      GUESS_NUMBER=${GUESS_NUMBER#0}
    done

    if (( ${#GUESS_NUMBER} < ${#SECRET_NUMBER} )) ||
      { (( ${#GUESS_NUMBER} == ${#SECRET_NUMBER} )) && [[ "$GUESS_NUMBER" < "$SECRET_NUMBER" ]]; }; then
      echo "It's higher than that, guess again:"
    elif [[ "$GUESS_NUMBER" == "$SECRET_NUMBER" ]]; then
      break
    else
      echo "It's lower than that, guess again:"
    fi
  fi
done

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

if ! UPDATE_RESULT=$(
  $PSQL --set=username="$USERNAME" --set=guesses="$NUMBER_OF_GUESSES" 2>&1 <<'SQL'
UPDATE users
SET games_played = games_played + 1,
    best_game = LEAST(COALESCE(best_game, :'guesses'::INTEGER), :'guesses'::INTEGER)
WHERE username = :'username';
SQL
); then
  echo "Could not save your game statistics: $UPDATE_RESULT" >&2
  exit 1
fi
