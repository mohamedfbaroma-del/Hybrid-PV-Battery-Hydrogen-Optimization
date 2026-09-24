% =========================================================================
% Enhanced Slime Mould Algorithm (ESMA) - Standard MATLAB Implementation
% Optimized for Power Systems and Complex Engineering Optimization
% -------------------------------------------------------------------------
% Author: Dr. Mohamed Baroma
% Description: This script implements the Enhanced Slime Mould Algorithm (ESMA) 
%              featuring chaotic initialization (Logistic Map), adaptive weights, 
%              and Levy flight mechanics to prevent local optima stagnation.
% =========================================================================

function [Destination_fitness, all_best_pos, Convergence_curve] = ESMA(N, Max_iter, lb, ub, dim, fobj)
    
    % Initialize global tracking variables
    bestPositions = zeros(1, dim);
    Destination_fitness = inf; % Initialize with infinity for minimization problems
    all_best_pos = zeros(1, dim);
    Convergence_curve = zeros(1, Max_iter);
    it = 1; 
    z = 0.03; % Control parameter for random exploration in SMA
    
    % -----------------------------------------------------------------
    % Phase 1: Chaotic Initialization using Logistic Map
    % Enhances population diversity compared to random uniform distribution
    % -----------------------------------------------------------------
    X = zeros(N, dim);
    for i = 1:N
        for j = 1:dim
            if i == 1
                X(i, j) = rand;
            else
                % Logistic map equation for chaos generation
                X(i, j) = 4 * X(i-1, j) * (1 - X(i-1, j)); 
            end
        end
    end
    
    % Scale chaotic values from [0, 1] range to problem boundaries [lb, ub]
    for j = 1:dim
        X(:, j) = X(:, j) * (ub(j) - lb(j)) + lb(j);
    end
    
    Fitness = inf(N, 1);
    weight = ones(N, dim); % Initialize weight matrix for search agents
    
    % -----------------------------------------------------------------
    % Main Optimization Loop
    % -----------------------------------------------------------------
    while it <= Max_iter
        
        % Boundary constraint enforcement and fitness evaluation
        for i = 1:N
            Flag4ub = X(i, :) > ub;
            Flag4lb = X(i, :) < lb;
            X(i, :) = (X(i, :) .* (~(Flag4ub + Flag4lb))) + ub .* Flag4ub + lb .* Flag4lb;
            
            Fitness(i) = fobj(X(i, :));
        end
        
        % Sort population fitness to identify best and worst solutions
        [SmellOrder, SmellIndex] = sort(Fitness);
        bestFitness = SmellOrder(1);
        bestPositions = X(SmellIndex(1), :);
        worstFitness = SmellOrder(N);
        
        % Update global best destination
        if bestFitness < Destination_fitness
            all_best_pos = bestPositions;
            Destination_fitness = bestFitness;
        end
        
        S = bestFitness - worstFitness + eps; % Fitness variance with epsilon to avoid division by zero
        
        % -----------------------------------------------------------------
        % Adaptive Weight Calculation (Simulating slime mould bio-oscillator)
        % -----------------------------------------------------------------
        for i = 1:N
            if i <= N / 2
                weight(SmellIndex(i), :) = 1 + rand(1, dim) * log10((bestFitness - SmellOrder(i)) / S + 1);
            else
                weight(SmellIndex(i), :) = 1 - rand(1, dim) * log10((bestFitness - SmellOrder(i)) / S + 1);
            end
        end
        
        % Adaptive parameters update
        a = atanh(-(it / Max_iter) + 1); 
        b = 1 - (it / Max_iter);
        
        % -----------------------------------------------------------------
        % Position Update Phase
        % -----------------------------------------------------------------
        for i = 1:N
            if rand < z
                % Random exploration within search space boundaries
                X(i, :) = (rand(1, dim) .* (ub - lb) + lb);
            else
                p = tanh(abs(Fitness(i) - Destination_fitness)); 
                vb = unifrnd(-a, a, 1, dim); 
                vc = unifrnd(-b, b, 1, dim);
                
                r = rand();
                A = randi([1, N]); % Select a random search agent index
                
                if r < p 
                    % Update position towards the best found position with weights
                    X(i, :) = all_best_pos + vb .* (weight(i, :) * X(A, :) - X(i, :));
                else
                    % -------------------------------------------------------------
                    % Levy Flight Mechanics for Local Optima Escaping
                    % -------------------------------------------------------------
                    beta_levy = 1.5;
                    sigma = (gamma(1 + beta_levy) * sin(pi * beta_levy / 2) / (gamma((1 + beta_levy) / 2) * beta_levy * 2^((beta_levy - 1) / 2)))^(1 / beta_levy);
                    u = randn(1, dim) * sigma;
                    v = randn(1, dim);
                    step = u ./ abs(v).^(1 / beta_levy);
                    
                    if rand > 0.5
                         X(i, :) = vc .* X(i, :);
                    else
                         X(i, :) = all_best_pos + 0.01 * step .* (X(i, :) - all_best_pos);
                    end
                end
            end
        end
        
        % Store convergence history
        Convergence_curve(it) = Destination_fitness;
        it = it + 1;
    end
end