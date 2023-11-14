# Number pairing puzzle

This code builds a videogame  in Godot 3.5.

It is based on a mathematical puzzle, as result of a  research collaboration with Erika Roldán and Peter Kagey.

# Rules

The rules of this puzzle are simple.

The player selects a number from a drop-down menu un the top left corner. This number corresponds to the level of difficulty of the game: from 1 to a maximum number (specified in the code as MAX_LEVEL).

Once selected, the level will determine the amount of numbers that the player needs to place in the board.

The objective is to use the minimum number of tiles in the board to pair all of the numbers to each other. In other words: We need to make all of the numbers neighbors to each other in the grid, at least once, and not necesarilly at the same time.

As help, the player is provided with a list of the numbers that have been placed in the board so far, each one those with the list of the numbers that it has been paired to.

**NOTE:  A start screen and reset option are still missing in the current version (0.9) of the game, and to start a new game, the playe must reopen the game**
