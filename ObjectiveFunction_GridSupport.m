% =========================================================================
% Objective Function for Grid Support with Renewable Energy and Storage
% Optimized for Power Systems Optimal Sizing & Operation
% -------------------------------------------------------------------------
% Author: Dr. Mohamed Baroma
% Description: This function evaluates the multi-objective fitness for 
%              integrating PV, Battery Storage, and Hydrogen Systems into 
%              power distribution networks using MATPOWER (runpf).
% =========================================================================

function Total_Fitness = ObjectiveFunction_GridSupport(x, mpc_base)
    % Decision Variables:
    % x(1): PV Capacity (MW)
    % x(2): Battery Capacity (MWh)
    % x(3): Hydrogen System Capacity (MW)
    
    %% 1. Parameters Setup
    mpc = mpc_base; 
    define_constants; 
    
    Grid_Price = 0.15;      % Grid electricity purchase price ($/kWh)
    Emission_Factor = 0.7;  % CO2 emission factor (kg CO2/kWh) [Reference: IEA Global Energy & CO2 Status Report]
    CRF = 0.09;             % Capital Recovery Factor for economic analysis
    
    % Capital costs for generation and storage technologies [Reference: IRENA Renewable Power Generation Costs Report]
    Cost_PV = 850000;         % PV installation cost ($/MW)
    Cost_Batt = 350000;       % Battery storage system cost ($/MWh)
    Cost_H2_System = 1200000; % Hydrogen system installation cost ($/MW)
    
    %% 2. Environmental and Load Profiles (Vectorized for efficiency)
    t = 1:24;
    % Daily scaled load profile (MW)
    P_Load_Profile = [183.6, 183.6, 183.6, 183.6, 183.6, 183.6, 183.6, 183.6, ... 
                      882.0, 1836.0, 1836.0, 1836.0, 1836.0, 1836.0, 1836.0, ... 
                      1065.6, 1065.6, 349.2, 349.2, 349.2, 349.2, 183.6, 183.6, 183.6] / 1000; 
    
    Solar_Profile = max(0, sin((t - 6) * pi / 12));
    P_PV_Gen = x(1) * Solar_Profile;
    
    Total_Grid_Energy = 0; 
    Total_Losses = 0; 
    Total_Voltage_Violation = 0;
    
    SOC = 0.5 * x(2);   % Initial State of Charge for Battery (MWh)
    LOH = 0.5 * x(3);   % Initial Level of Hydrogen Storage (MW/MWh equivalent)
    
    % Designated buses for distributed grid support injection
    Injection_Buses = [10, 12, 24, 30]; 
    
    %% 3. Dynamic Energy Management Loop (24-Hour Horizon)
    opt = mpoption('verbose', 0, 'out.all', 0, 'pf.enforce_q_lims', 1);
    
    for h = 1:24
        P_Net = P_PV_Gen(h) - P_Load_Profile(h);
        P_Storage_Action = 0; 
        
        % Surplus power management (Charging storage systems)
        if P_Net > 0 
            Charge_Batt = min(P_Net, x(2) - SOC);
            SOC = SOC + Charge_Batt;
            Remaining_Surplus = P_Net - Charge_Batt;
            
            Charge_H2 = min(Remaining_Surplus, x(3) - LOH);
            LOH = LOH + Charge_H2;
            
            P_Storage_Action = -(Charge_Batt + Charge_H2); 
            
        % Deficit power management (Discharging storage systems)
        else 
            Deficit = abs(P_Net);
            Discharge_Batt = min(Deficit, SOC - 0.2 * x(2));
            SOC = SOC - Discharge_Batt;
            Remaining_Deficit = Deficit - Discharge_Batt;
            
            Discharge_H2 = min(Remaining_Deficit, LOH - 0.1 * x(3));
            LOH = LOH - Discharge_H2;
            
            P_Storage_Action = (Discharge_Batt + Discharge_H2);
        end
        
        P_Total_Injection = P_PV_Gen(h) + P_Storage_Action;
        
        % Distribute injected power across designated grid support buses
        for i = 1:length(Injection_Buses)
            bus_idx = Injection_Buses(i);
            gen_idx = find(mpc.gen(:, GEN_BUS) == bus_idx);
            if ~isempty(gen_idx)
                mpc.gen(gen_idx, PG) = P_Total_Injection / length(Injection_Buses);
            end
        end
        
        base_load = sum(mpc.bus(:, PD));
        mpc.bus(:, PD) = (P_Load_Profile(h) / base_load) * mpc.bus(:, PD);
        
        % Run AC Power Flow using MATPOWER
        results = runpf(mpc, opt);
        
        if results.success
            Total_Losses = Total_Losses + sum(get_losses(results));
            
            % Voltage deviation penalty function calculation (Limits: [0.95, 1.05] p.u.)
            v = results.bus(:, VM);
            Total_Voltage_Violation = Total_Voltage_Violation + sum(max(0, v - 1.05).^2 + max(0, 0.95 - v).^2);
            Total_Grid_Energy = Total_Grid_Energy + results.gen(1, PG); 
        else
            % Heavy penalty assigned for power flow non-convergence cases
            Total_Grid_Energy = Total_Grid_Energy + 10e3; 
        end
    end
    
    %% 4. Multi-Objective Function Evaluation (Normalized)
    Annual_Investment_Cost = (x(1) * Cost_PV + x(2) * Cost_Batt + x(3) * Cost_H2_System) * CRF;
    Annual_Grid_Cost = Total_Grid_Energy * 365 * Grid_Price;
    Total_Annual_Cost = Annual_Investment_Cost + Annual_Grid_Cost;
    
    % Objective weighting factors vector [Cost, Emissions, Losses, Voltage Deviation]
    W = [0.4, 0.2, 0.2, 0.2]; 
    
    % Final weighted normalized fitness evaluation
    Total_Fitness = W(1) * (Total_Annual_Cost / 1e6) + ... 
                    W(2) * ((Total_Grid_Energy * 365 * Emission_Factor) / 1e6) + ... 
                    W(3) * (Total_Losses / 10) + ... 
                    W(4) * (Total_Voltage_Violation * 100);
end