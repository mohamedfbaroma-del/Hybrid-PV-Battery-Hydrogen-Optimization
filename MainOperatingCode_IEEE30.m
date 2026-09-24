% =========================================================================
% Main Integrated Script for IEEE 30-Bus Optimal Sizing & Stability Analysis
% Optimized for Advanced Power Systems Research
% -------------------------------------------------------------------------
% Author: Dr. Mohamed Baroma
% Description: This script executes metaheuristic algorithms (JS, ESMA, MPA, GBO)
%              over 30 runs, optimizes hybrid renewable-storage integration on 
%              the IEEE 30-bus test system, and performs 24-hour stability analysis.
% =========================================================================

clc; clear; close all;

%% 1. Simulation Setup & Configuration
Run_Times = 30;           % Number of independent trial runs
Algorithms = {'JS', 'ESMA', 'MPA', 'GBO'}; 
Num_Algo = length(Algorithms);
Max_Iter = 100;           % Maximum iterations per run
SearchAgents = 30;        % Population size
Injection_Buses = [24, 26, 29, 30]; % Designated distributed generation buses

% Preallocate memory for tracking results
Results_BestCost = zeros(Run_Times, Num_Algo);
Convergence_Curves = zeros(Max_Iter, Num_Algo);
Best_X_All = zeros(Num_Algo, 3); % Optimal sizing storage/generation matrix [PV, Batt, H2]

disp('--- Initiating Metaheuristic Optimization for IEEE 30-Bus Hybrid System ---');

%% 2. Main Optimization Loop
for algo_idx = 1:Num_Algo
    Algo_Name = Algorithms{algo_idx};
    fprintf('Executing optimization for algorithm: %s across 30 runs... \n', Algo_Name);
    
    current_curve_sum = zeros(1, Max_Iter);
    Global_Best_Score = inf;
    
    for run = 1:Run_Times
        % Decision variables boundaries: x(1): PV (MW), x(2): Batt (MWh), x(3): H2 (MW)
        lb = [0, 0, 0];       
        ub = [5000, 5000, 1000]; 
        dim = 3;              
        
        % Assign objective function handle for IEEE 30 distributed network
        fobj = @CostFunction_IEEE30_Distributed; 
        
        % Execute selected metaheuristic optimization algorithm
        if strcmp(Algo_Name, 'JS'),      [Score, Pos, Curve] = JS(SearchAgents, Max_Iter, lb, ub, dim, fobj);
        elseif strcmp(Algo_Name, 'ESMA'), [Score, Pos, Curve] = ESMA(SearchAgents, Max_Iter, lb, ub, dim, fobj);
        elseif strcmp(Algo_Name, 'MPA'),  [Score, Pos, Curve] = MPA(SearchAgents, Max_Iter, lb, ub, dim, fobj);
        else,                             [Score, Pos, Curve] = GBO(SearchAgents, Max_Iter, lb, ub, dim, fobj); 
        end
        
        Results_BestCost(run, algo_idx) = Score;
        current_curve_sum = current_curve_sum + Curve;
        
        % Track and store the global best solution across runs
        if Score < Global_Best_Score
            Global_Best_Score = Score;
            Best_X_All(algo_idx, :) = Pos;
        end
    end
    % Compute average convergence behavior
    Convergence_Curves(:, algo_idx) = current_curve_sum / Run_Times;
end

%% 3. Post-Optimization Voltage & Stability Analysis (24-Hour Horizon)
fprintf('\nExecuting 24-hour post-optimization stability & voltage profile assessment...\n');

V30_Profiles = zeros(24, Num_Algo + 1); % +1 accounts for the Base Case
V_Drop_Peak = zeros(Num_Algo, length(Injection_Buses));
TVD_Stability = zeros(1, Num_Algo);

% Define 24-hour operational profiles
t = 1:24;
Load_Profile = 180 * ones(1, 24); 
Load_Profile(8:16) = 1750; 
Load_Profile(17:20) = 1750 * 0.4;
P_Solar_Unit = max(0, sin((t - 6) * pi / 12));

mpc_base = loadcase('case30');
opt = mpoption('verbose', 0, 'out.all', 0);

% A - Base Case Power Flow Evaluation (Without Integration)
for i = 1:24
    mpc_temp = mpc_base;
    mpc_temp.bus(:, 3) = mpc_temp.bus(:, 3) * (Load_Profile(i) / sum(mpc_temp.bus(:, 3)));
    res_b = runpf(mpc_temp, opt);
    V30_Profiles(i, 1) = res_b.bus(30, 8); % Voltage magnitude at Bus 30
end

% B - Optimized Integration Evaluation for Each Algorithm
for k = 1:Num_Algo
    X = Best_X_All(k, :);
    SOC = 0.5 * X(2); 
    LOH = 0.5 * X(3);
    
    for i = 1:24
        % Net power calculation and energy storage dispatch
        P_Net = (X(1) * P_Solar_Unit(i)) - Load_Profile(i);
        if P_Net > 0
            To_Storage = min(P_Net, X(2) - SOC); 
            SOC = SOC + To_Storage;
            P_Hybrid_Out = 0;
        else
            Deficit = abs(P_Net);
            From_Storage = min(Deficit, SOC - 0.2 * X(2)); 
            SOC = SOC - From_Storage;
            P_Hybrid_Out = -(Deficit - From_Storage); % Net power deficit covered by hybrid system
        end
        
        % MATPOWER hourly power flow execution
        mpc_hour = mpc_base;
        mpc_hour.bus(:, 3) = mpc_hour.bus(:, 3) * (Load_Profile(i) / sum(mpc_hour.bus(:, 3)));
        for b = 1:length(Injection_Buses)
            mpc_hour.bus(Injection_Buses(b), 3) = mpc_hour.bus(Injection_Buses(b), 3) - (P_Hybrid_Out / (4 * 1000));
        end
        res_hour = runpf(mpc_hour, opt);
        V30_Profiles(i, k + 1) = res_hour.bus(30, 8);
        
        % Compute Total Voltage Deviation (TVD) and peak voltage drop at Hour 12 (Peak Load)
        if i == 12
            V_Drop_Peak(k, :) = 1.0 - res_hour.bus(Injection_Buses, 8);
            TVD_Stability(k) = sum(abs(res_hour.bus(:, 8) - 1.0));
        end
    end
end

%% 4. Advanced Results Visualization & Export (Figures 1 - 8)
% Figure 1: Robustness Analysis (Boxplot of Objective Values)
figure('Name', 'Robustness Boxplot', 'Position', [100, 100, 700, 500]); 
boxplot(Results_BestCost, Algorithms);
title('Fig 1: Algorithm Robustness Analysis (Network Cost & Losses)'); 
ylabel('Objective Fitness Value'); 
grid on;

% Figure 2: Convergence Performance Curves
figure('Name', 'Convergence Performance', 'Position', [150, 150, 700, 500]); 
hold on;
for i = 1:Num_Algo
    plot(Convergence_Curves(:, i), 'LineWidth', 2); 
end
legend(Algorithms, 'Location', 'northeast'); 
title('Fig 2: Convergence Speed Comparison on IEEE 30-Bus System'); 
xlabel('Iteration Number'); ylabel('Best Fitness Cost');
grid on;

% Figure 6: Voltage Drop at Injection Nodes during Peak Load Hour
figure('Name', 'Voltage Drop Analysis', 'Position', [200, 200, 700, 500]); 
bar(V_Drop_Peak');
set(gca, 'XTickLabel', {'Bus 24', 'Bus 26', 'Bus 29', 'Bus 30'});
legend(Algorithms, 'Location', 'northeast'); 
title('Fig 6: Voltage Drop at Injection Nodes (Peak Load Hour)'); 
ylabel('Voltage Deviation (p.u.)');
grid on;

% Figure 7: Grid Stability Index - Total Voltage Deviation (TVD)
figure('Name', 'System Stability Index', 'Position', [250, 250, 700, 500]); 
b7 = bar(TVD_Stability);
b7.FaceColor = 'flat'; 
set(gca, 'XTickLabel', Algorithms);
title('Fig 7: Grid Stability - Total Voltage Deviation (Lower is Better)'); 
ylabel('TVD Index');
grid on;

% Figure 8: 24-Hour Voltage Profile at Weakest Bus (Bus 30)
figure('Name', '24-Hour Voltage Profile', 'Position', [300, 300, 700, 500]); 
plot(1:24, V30_Profiles(:, 1), 'k--', 'LineWidth', 2.5); 
hold on;
for k = 1:Num_Algo
    plot(1:24, V30_Profiles(:, k + 1), 'LineWidth', 2); 
end
legend(['Base Case', Algorithms], 'Location', 'southeast');
title('Fig 8: 24h Voltage Profile at Bus 30 (Weakest Node Assessment)'); 
xlabel('Time of Day (Hour)'); 
ylabel('Voltage Magnitude (p.u.)'); 
grid on;

% Save publication-quality figure
print(gcf, 'Final_Stability_Analysis.png', '-dpng', '-r300');
disp('--- Optimization and Stability Analysis Successfully Completed and Exported. ---');