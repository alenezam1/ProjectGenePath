function untitled

clear; clc;

% Start timing the execution
tic;

% Load the map)
map = im2bw(imread('random_map.bmp'));

% Define start and finish points
% Start point and finish point coordinates
startPoint = [1, 1];
finishPoint = [500, 500];

% GA Configuration[HARDCODED]
% Parameters for the Genetic Algorithm
populationSize = 200;
numberOfGenerations = 1000; 
numberOfPointsInSolution = 10; 
crossoverProbability = 0.7;
mutationProbability = 0.3;
elitismRatio = 0.1;

% Prompt user
% Get user input for GA methods
selectionMethod = input('Enter selection method (0: RWS, 1: Tournament, 2: Rank-based): ');
crossoverMethod = input('Enter crossover method (0: Uniform, 1: k-Point): ');
mutationMethod = input('Enter mutation method (0: Swap, 1: Polynomial): ');

% Initialize population
fprintf('Initializing population...\n');
initStart = tic;
population = initializePopulation(populationSize, numberOfPointsInSolution, startPoint, finishPoint);
initTime = toc(initStart);
fprintf('Population initialized in %.2f seconds.\n', initTime);

% Run the GA
fprintf('Running Genetic Algorithm');
gaStart = tic;
geneticAlgorithm(map, population, numberOfGenerations, startPoint, finishPoint, ...
    selectionMethod, crossoverMethod, mutationMethod, ...
    crossoverProbability, mutationProbability, elitismRatio);
gaTime = toc(gaStart);
fprintf('Genetic Algorithm completed in %.2f seconds.\n', gaTime);

% Stop timing the execution
totalTime = toc;
fprintf('Total execution time: %.2f seconds\n', totalTime);
end

function population = initializePopulation(populationSize, numberOfPoints, startPoint, finishPoint)
% Initialize population with random paths
% Each individual in the population represents a path with random intermediate points
population = zeros(populationSize, numberOfPoints * 2);
for i = 1:populationSize
    xCoords = randi([startPoint(1), finishPoint(1)], 1, numberOfPoints);
    yCoords = randi([startPoint(2), finishPoint(2)], 1, numberOfPoints);
    population(i, :) = reshape([xCoords; yCoords], 1, []);
end
end

function geneticAlgorithm(map, population, numberOfGenerations, startPoint, finishPoint, ...
    selectionMethod, crossoverMethod, mutationMethod, ...
    crossoverProbability, mutationProbability, elitismRatio)
% Execute the Genetic Algorithm
populationSize = size(population, 1);
numberOfPoints = size(population, 2) / 2;
eliteCount = round(elitismRatio * populationSize);

% Track the best fitness and path across generations
globalBestFitness = -inf;
globalBestPath = [];

for generation = 1:numberOfGenerations
    % Calculate fitness for each individual
    fitness = zeros(populationSize, 1);
    for i = 1:populationSize
        fitness(i) = evaluateFitness(population(i, :), map, startPoint, finishPoint);
    end

    % Sort population by fitness
    [fitness, indices] = sort(fitness, 'descend');
    population = population(indices, :);

    % Update global best fitness and path
    if fitness(1) > globalBestFitness
        globalBestFitness = fitness(1);
        globalBestPath = population(1, :);
    end

    % Select elite for the next generation
    newPopulation = population(1:eliteCount, :);

    % Generate offspring until the new population reaches the required size
    while size(newPopulation, 1) < populationSize
        % Select parents using the chosen selection method
        parents = selectParents(selectionMethod, population, fitness, 2);

        % Apply crossover to produce offspring
        if rand < crossoverProbability
            offspring = applyCrossover(crossoverMethod, parents);
        else
            offspring = parents;
        end

        % Apply mutation 
        if rand < mutationProbability
            offspring = applyMutation(mutationMethod, offspring);
        end

        % Add offspring to the new population
        newPopulation = [newPopulation; offspring];
    end

    % Replace the old population with the new one
    population = newPopulation(1:populationSize, :);

    % Display progress for the current generation
    fprintf('Generation %d: Best Fitness = %.2f\n', generation, globalBestFitness);
end

% Plot the best path
plotPath(map, globalBestPath, startPoint, finishPoint);

% Display final results
fprintf('Final Best Fitness: %.2f\n', globalBestFitness);
end

function fitness = evaluateFitness(path, map, startPoint, finishPoint)
% Evaluate the fitness of a given path
pathPoints = [startPoint; reshape(path, [], 2); finishPoint];
pathLength = sum(sqrt(sum(diff(pathPoints).^2, 2)));

% Check for collisions and compute a penalty
collisionPenalty = 0;
for i = 1:size(pathPoints, 1) - 1
    linePoints = interpolateLine(pathPoints(i, :), pathPoints(i + 1, :));
    collisionPenalty = collisionPenalty + sum(~map(sub2ind(size(map), linePoints(:, 2), linePoints(:, 1))));
end

% Combine path length and collision penalty to calculate fitness
fitness = -pathLength - collisionPenalty * 1000;
end

function linePoints = interpolateLine(point1, point2)
% Generate points along a line between two points
% used to check for collisions along the path
numPoints = max(abs(point2 - point1)) + 1;
x = round(linspace(point1(1), point2(1), numPoints));
y = round(linspace(point1(2), point2(2), numPoints));
linePoints = [x', y'];
end


function offspring = applyCrossover(crossoverMethod, parents)
% Apply the specified crossover method to generate offspring
parent1 = parents(1, :);
parent2 = parents(2, :);
switch crossoverMethod
    case 0 % Uniform Crossover
        mask = rand(size(parent1)) > 0.5;
offspring = [mask .* parent1 + ~mask .* parent2;
             ~mask .* parent1 + mask .* parent2];
    case 1 % k-Point Crossover
        k = 2; % Number of crossover points
        points = sort(randperm(length(parent1), k));
offspring = parents;
        for i = 1:length(points)
            if mod(i, 2) == 1
                offspring(1, points(i):end) = parent2(points(i):end);
                offspring(2, points(i):end) = parent1(points(i):end);
            end
        end
end
end

function parents = selectParents(selectionMethod, population, fitness, numParents)
% Select parents based on the specified selection method
switch selectionMethod
    case 0 % Roulette Wheel Selection
        probabilities = fitness / sum(fitness);
        indices = randsample(1:size(population, 1), numParents, true, probabilities);
    case 1 % Tournament Selection
        tournamentSize = 5;
        indices = zeros(1, numParents);
        for i = 1:numParents
            candidates = randi(size(population, 1), tournamentSize, 1);
            [~, bestIndex] = max(fitness(candidates));
            indices(i) = candidates(bestIndex);
        end
    case 2 % Rank-based Selection
        ranks = 1:size(population, 1);
        probabilities = ranks / sum(ranks);
        indices = randsample(1:size(population, 1), numParents, true, probabilities);
end
parents = population(indices, :);
end

function offspring = applyMutation(mutationMethod, offspring)
% Apply the specified mutation method 
for i = 1:size(offspring, 1)
    switch mutationMethod
        case 0 % Swap Mutation
            indices = randperm(size(offspring, 2), 2);
            offspring(i, indices) = offspring(i, fliplr(indices));
        case 1 % Polynomial Mutation
            mutationRate = 0.1;
            for j = 1:size(offspring, 2)
                if rand < mutationRate
                    offspring(i, j) = offspring(i, j) + randn * 0.1;
                end
            end
    end
end
end

function plotPath(map, path, startPoint, finishPoint)
% Visualize the best path on the map
pathPoints = [startPoint; reshape(path, [], 2); finishPoint];
imshow(map);
hold on;

% Draw  boundary
rectangle('position', [1, 1, size(map, 1)-1, size(map, 2)-1], 'edgecolor', 'k');

% Plot the path
plot(pathPoints(:, 1), pathPoints(:, 2), 'r', 'LineWidth', 2);

% Mark points along the path, start, and finish
plot(pathPoints(:, 1), pathPoints(:, 2), 'bo', 'MarkerSize', 5, 'MarkerFaceColor', 'b');
plot(startPoint(1), startPoint(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
plot(finishPoint(1), finishPoint(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');

title('Optimal Path');
hold off;
end