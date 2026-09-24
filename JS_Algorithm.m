% =========================================================================
% Jellyfish Search Optimizer (JS) - Standard MATLAB Implementation
% Optimized for Power Systems and Engineering Optimization Problems
% -------------------------------------------------------------------------
% Author: Dr. Mohamed Baroma
% Description: This script implements the Jellyfish Search (JS) algorithm, 
%              mimicking the behaviors of jellyfish in the ocean (ocean currents, 
%              passive/active motions, and time control mechanism) to solve 
%              complex global optimization problems.
% =========================================================================

function [Best_Cost, Best_Pos, Convergence_curve] = JS(N, Max_iter, lb, ub, dim, fobj)
    
    % Initialize population positions within boundary constraints
    X = initialization(N, dim, ub, lb);
    Fitness = zeros(1, N);
    Convergence_curve = zeros(1, Max_iter);
    
    % Evaluate initial fitness for all search agents (jellyfish)
    for i = 1:N
        Fitness(i) = fobj(X(i, :));
    end
    
    % Identify the global best solution (Best Jellyfish)
    [Best_Cost, Best_idx] = min(Fitness);
    Best_Pos = X(Best_idx, :);
    
    % Main optimization loop
    for it = 1:Max_iter
        
        % -----------------------------------------------------------------
        % Time Control Mechanism (ct)
        % Controls the transition between ocean current and internal motions
        % -----------------------------------------------------------------
        ct = abs((1 - it * (1 / Max_iter)) * (2 * rand - 1));
        
        for i = 1:N
            
            % -------------------------------------------------------------
            % Phase 1: Ocean Current (Exploration phase when ct >= 0.5)
            % -------------------------------------------------------------
            if ct >= 0.5
                trend = Best_Pos - 3 * rand() * mean(X, 1);
                Xnew = X(i, :) + rand() * trend;
                
            % -------------------------------------------------------------
            % Phase 2: Jellyfish Inside Swarm Motion (Exploitation phase)
            % Divided into Passive Motion and Active Motion based on rand < (1 - ct)
            % -------------------------------------------------------------
            else
                if rand < (1 - ct) % Active Motion (Type B)
                    % Select a random jellyfish different from current index 'i'
                    j = i; 
                    while j == i
                        j = randi(N); 
                    end
                    
                    Step = X(i, :) - X(j, :);
                    if Fitness(j) < Fitness(i)
                        Step = X(j, :) - X(i, :);
                    end
                    Xnew = X(i, :) + rand() * Step;
                    
                else % Passive Motion (Type A)
                    Xnew = X(i, :) + 0.1 * (ub - lb) .* rand(1, dim);
                end
            end
            
            % -------------------------------------------------------------
            % Boundary Constraints Handling and Greedy Selection
            % -------------------------------------------------------------
            Xnew = max(Xnew, lb);
            Xnew = min(Xnew, ub);
            New_Cost = fobj(Xnew);
            
            % Update position if the new solution yields better fitness
            if New_Cost < Fitness(i)
                X(i, :) = Xnew;
                Fitness(i) = New_Cost;
                
                % Update global best solution if applicable
                if New_Cost < Best_Cost
                    Best_Cost = New_Cost;
                    Best_Pos = Xnew;
                end
            end
        end
        
        % Store the best cost of the current iteration in the convergence curve
        Convergence_curve(it) = Best_Cost;
    end
end

% =========================================================================
% Helper Functions Section
% =========================================================================

function Positions = initialization(SearchAgents_no, dim, ub, lb)
    % INITIALIZATION Generates initial population within search boundaries.
    Boundary_no = size(ub, 2);
    if Boundary_no == 1
        Positions = rand(SearchAgents_no, dim) .* (ub - lb) + lb;
    else
        for i = 1:dim
            Positions(:, i) = rand(SearchAgents_no, 1) .* (ub(i) - lb(i)) + lb(i);
        end
    end
end