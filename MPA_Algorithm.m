% =========================================================================
% Marine Predators Algorithm (MPA) - Standard MATLAB Implementation
% Optimized for Power Systems Optimization Problems
% -------------------------------------------------------------------------
% Author: Dr. Mohamed Baroma
% Description: This script implements the Marine Predators Algorithm (MPA) 
%              for solving complex optimization problems in power systems 
%              (e.g., optimal power flow, economic dispatch, parameter estimation).
% =========================================================================

function [Top_Predator_fit, Top_Predator_pos, Convergence_curve] = MPA(SearchAgents_no, Max_iter, lb, ub, dim, fobj)
    
    % Initialize global tracking variables
    Top_Predator_pos = zeros(1, dim);
    Top_Predator_fit = inf;             % Initialize with infinity for minimization problems
    Convergence_curve = zeros(1, Max_iter);
    stepsize = zeros(SearchAgents_no, dim);
    fitness = inf(SearchAgents_no, 1);
    
    % Initialize population (Prey matrix) within boundary constraints
    Prey = initialization(SearchAgents_no, dim, ub, lb);
    
    % Define boundary matrices for spatial constraint handling
    Xmin = repmat(ones(1, dim) .* lb, SearchAgents_no, 1);
    Xmax = repmat(ones(1, dim) .* ub, SearchAgents_no, 1);
    
    iter = 0;
    
    % Main optimization loop
    while iter < Max_iter
        
        for i = 1:size(Prey, 1)
            
            % Enforce boundary constraints (Clipping method)
            Flag4ub = Prey(i, :) > ub;
            Flag4lb = Prey(i, :) < lb;
            Prey(i, :) = (Prey(i, :) .* (~(Flag4ub + Flag4lb))) + ub .* Flag4ub + lb .* Flag4lb;
            
            % Evaluate objective function (Fitness calculation)
            fitness(i, 1) = fobj(Prey(i, :));
            
            % Update the best solution found so far (Top Predator)
            if fitness(i, 1) < Top_Predator_fit
                Top_Predator_fit = fitness(i, 1);
                Top_Predator_pos = Prey(i, :);
            end
        end
        
        % -----------------------------------------------------------------
        % Adaptive Parameter Calculation
        % -----------------------------------------------------------------
        % Adaptive Constant Factor (CF) controlling movement step size
        CF = (1 - iter / Max_iter)^(2 * iter / Max_iter);
        
        % -----------------------------------------------------------------
        % Optimization Phases of MPA
        % -----------------------------------------------------------------
        
        % Phase 1: High velocity ratio (Exploration phase - Iteration < Max_iter/3)
        if iter < Max_iter / 3
            for i = 1:size(Prey, 1)
                RB = randn(1, dim);
                stepsize(i, :) = RB .* (Top_Predator_pos - RB .* Prey(i, :));
                Prey(i, :) = Prey(i, :) + P_R(iter, Max_iter) * RB .* stepsize(i, :);
            end
            
        % Phase 2: Unit velocity ratio (Transition from Exploration to Exploitation)
        elseif iter < 2 * Max_iter / 3
            for i = 1:size(Prey, 1)
                if i > size(Prey, 1) / 2
                    % Prey updates position based on Brownian motion
                    RB = randn(1, dim);
                    stepsize(i, :) = RB .* (RB .* Top_Predator_pos - Prey(i, :));
                    Prey(i, :) = Top_Predator_pos + P_R(iter, Max_iter) * CF * stepsize(i, :);
                else
                    % Predator updates position based on Levy flight
                    stepsize(i, :) = (Top_Predator_pos - Prey(i, :));
                    Prey(i, :) = Prey(i, :) + P_R(iter, Max_iter) * CF * stepsize(i, :);
                end
            end
            
        % Phase 3: Low velocity ratio (Exploitation phase - Iteration > 2*Max_iter/3)
        else
            for i = 1:size(Prey, 1)
                RB = randn(1, dim);
                stepsize(i, :) = (RB .* Top_Predator_pos - RB .* Prey(i, :));
                Prey(i, :) = Top_Predator_pos + P_R(iter, Max_iter) * CF * stepsize(i, :);
            end
        end
        
        % -----------------------------------------------------------------
        % Fish Aggregating Devices (FADs) Effect (Local optima avoidance)
        % -----------------------------------------------------------------
        Prey = FADs(Prey, 0.2, Xmin, Xmax); % FADs probability rate = 0.2
        
        % Increment iteration counter and store convergence history
        iter = iter + 1;
        Convergence_curve(iter) = Top_Predator_fit;
        
        % Display progress status every 50 iterations
        if mod(iter, 50) == 0
            disp(['MPA Iteration: ', num2str(iter), ' | Best Fitness Cost: ', num2str(Top_Predator_fit)]);
        end
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
            ub_i = ub(i);
            lb_i = lb(i);
            Positions(:, i) = rand(SearchAgents_no, 1) .* (ub_i - lb_i) + lb_i;
        end
    end
end

function R = P_R(~, ~)
    % P_R Returns constant scaling factor for random movement steps.
    R = 0.5; 
end

function Prey = FADs(Prey, FADs_Rate, Xmin, Xmax)
    % FADS Simulates Fish Aggregating Devices effect to escape local optima.
    [n, d] = size(Prey);
    U = rand(n, d) < FADs_Rate;
    Prey = Prey + 0.2 * (Xmin + rand(n, d) .* (Xmax - Xmin)) .* U;
end