Here we keep track of the evolution of the Balancing Algorithm in its entirety.

# The Sauce 
We begin with the commit [abece2d](https://github.com/ravimohan1991/Equalizer/commit/abece2d0584d4e0d8903901787747b9895da28ca). The fundamental idea is like so
- Seperate Bots and Humans
- Sort the EQPlayerInfo (Note to self: Prevent sending Bot's arzi. Don't wanna burden BE with redundant queries) of the Human players with some basis parameter
- FillUp teams in certain fashion
- Restore bot-crowd at the end of the routine
