#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only -c"

#Generate the random number
RANDOM_NUMBER=$((1 + $RANDOM % 1000))
FLAG=true

# Get user
echo "Enter your username:"
read USERNAME

# If user doesn't exist
USER_AVAILABLE=$($PSQL "SELECT username FROM users WHERE username = '$USERNAME'")
if [[ -z $USER_AVAILABLE ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  USER='new'
else
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username = '$USERNAME'")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username = '$USERNAME'")
  echo "Welcome back, $USERNAME! You have played $(echo $GAMES_PLAYED | sed -r 's/^ *| *$//g') games, and your best game took $(echo $BEST_GAME | sed -r 's/^ *| *$//g') guesses."
  USER='old'
fi

# Begin game
echo "Guess the secret number between 1 and 1000:"
COUNTER=1
while [[ $FLAG = true ]]
do
  read ANSWER
  if [[ ! $ANSWER =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  elif [[ $ANSWER -gt $RANDOM_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
    COUNTER=$((COUNTER+1))
  elif [[ $ANSWER -lt $RANDOM_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
    COUNTER=$((COUNTER+1))
  else
    # Get correct number
    FLAG=false
    echo "You guessed it in $COUNTER tries. The secret number was $RANDOM_NUMBER. Nice job!"
  fi
done

# Updating database
if [ "$USER" = "new" ]
then
  INSERT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 1, $COUNTER)") 
else
  if [[ $COUNTER < $BEST_GAME ]]
  then
    BEST_GAME=$COUNTER
  fi
  UPDATE_GAMES=$($PSQL "UPDATE users SET games_played = $GAMES_PLAYED+1 WHERE username = '$USERNAME'")
  UPDATE_BEST=$($PSQL "UPDATE users SET best_game = $COUNTER WHERE username = '$USERNAME'")
fi
