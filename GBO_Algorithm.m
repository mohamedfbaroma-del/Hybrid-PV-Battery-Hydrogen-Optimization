% =========================================================================
% Gradient-Based Optimizer (GBO) - Standard MATLAB Implementation
% Optimized for Power Systems and Engineering Optimization Problems
% -------------------------------------------------------------------------
% Author: Dr. Mohamed Baroma
% Description: This script implements the Gradient-Based Optimizer (GBO), 
%              leveraging gradient-based search rules and local escaping 
%              operators to achieve high-performance global optimization.
% =========================================================================

function [Best_Cost, Best_Pos, Convergence_curve] = GBO(N, Max_iter, lb, ub, dim, fobj)
    
    % Initialize tracking variables
    Top_st = 1:N; % Population tracking index
    Convergence_curve = zeros(1, Max_iter);
    
    % Initialize population positions within search boundaries
    X = initialization(N, dim, ub, lb); 
    Fitness = zeros(1, N);
    
    % Evaluate initial fitness for all search agents
    for i = 1:N
        Fitness(i) = fobj(X(i, :));
    end
    
    % Identify the global best and worst solutions
    [best_cost, best_idx] = min(Fitness);
    Best_Pos = X(best_idx, :);
    Best_Cost = best_cost;
    
    [~, worst_idx] = max(Fitness);
    Worst_Pos = X(worst_idx, :);
    
    % Main optimization loop
    for it = 1:Max_iter
        
        % -----------------------------------------------------------------
        % Adaptive Parameter Calculations (beta and alpha)
        % -----------------------------------------------------------------
        beta = 0.2 + (1.2 - 0.2) * (1 - (it / Max_iter)^3)^2;
        alpha = abs(beta * sin(3 * pi / 2 + sin(beta * 3 * pi / 2)));
        
        for i = 1:N
            
            % Select four distinct random search agents for gradient approximation
            r1 = randi([1, N]); while r1 == i, r1 = randi([1, N]); end
            r2 = randi([1, N]); while r2 == i || r2 == r1, r2 = randi([1, N]); end
            r3 = randi([1, N]); while r3 == i || r3 == r1 || r2 == r3, r3 = randi([1, N]); end
            r4 = randi([1, N]); while r4 == i || r4 == r1 || r4 == r2 || r4 == r3, r4 = randi([1, N]); end
            
            X1 = X(r1, :); 
            X2 = X(r2, :); 
            X3 = X(r3, :); 
            X4 = X(r4, :);
            
            % -------------------------------------------------------------
            % Gradient Search Rule (GSR) - Exploration & Exploitation Phase
            % -------------------------------------------------------------
            DM = rand * alpha * (Best_Pos - X(r1, :)); % Direction Matrix
            GSR = randn * (0.5 * (X(r1, :) + X(r2, :) + X(r3, :) + X(r4, :)) - X(i, :)) + DM;
            
            % Update candidate position
            Xnew = X(i, :) + GSR;
            
            % -------------------------------------------------------------
            % Local Escaping Operator (LEO) - Local Optima Avoidance
            % -------------------------------------------------------------
            if rand < 0.5
                f1 = -1 + 2 * rand(); 
                f2 = -1 + 2 * rand();
                L1 = rand < 0.5; 
                u1 = L1 * 2 * rand() + (1 - L1); 
                u2 = L1 * rand() + (1 - L1);
                u3 = L1 * rand() + (1 - L1);
                
                Xk = unifrnd(lb, ub, 1, dim); % Random position vector within bounds
                Xnew = Xnew + f1 * (u1 * Best_Pos - u2 * Xk) + f2 * 0.5 * (u3 * (X2 - X1) + u2 * (X(r1, :) - X(r2, :))) / 2;
            end
            
            % -------------------------------------------------------------
            % Boundary Constraints Handling and Greedy Selection
            % -------------------------------------------------------------
            Xnew = max(Xnew, lb);
            Xnew = min(Xnew, ub);
            
            New_Cost = fobj(Xnew);
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
        
        % Store the best cost of the current iteration
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