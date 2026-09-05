# ProjectGenePath
This project implements a flexible Genetic Algorithm (GA) in MATLAB to solve 2D robot path planning problems using a binary obstacle map.

 Features
- Supports **multiple GA operators**:  
  • Selection: Roulette Wheel, Tournament, Rank-based  
  • Crossover: Uniform, k-Point  
  • Mutation: Swap, Polynomial  
- Optimizes path from `startPoint` to `finishPoint` on a 500×500 map.
- Fitness function includes path length and collision penalties.
- Full visualization of final optimal path on the map.

## Technologies
- MATLAB
- Genetic Algorithms
- Map-based obstacle avoidance
- Heuristic optimization

## Inputs
- `random_map.bmp`: a black & white obstacle map image
- GA parameters hardcoded but customizable in the script

##  Output
- Plots optimal collision-free path on map
- Displays generation-by-generation fitness improvements

## How to Run
1. Place `random_map.bmp` in the same folder.
2. Run `untitled.m` in MATLAB.
3. Input your selection, crossover, and mutation method when prompted.
