Hybrid Renewable Energy & Storage Optimization in Power Systems

This repository contains advanced MATLAB scripts and metaheuristic optimization algorithms designed for optimal sizing and stability analysis of hybrid renewable energy systems (Photovoltaic, Battery Storage, and Hydrogen Systems) integrated into electrical power distribution networks (tested on the IEEE 30-bus test system).

Repository Structure

MainOperatingCode_IEEE30.m - The master execution script that runs optimization loops, economic evaluations, 24-hour AC power flows, and generates publication-quality figures.
ObjectiveFunction_GridSupport.m - Evaluates the multi-objective fitness function incorporating investment costs, grid purchase costs, power losses, and voltage deviations.
MPA_Algorithm.m - Marine Predators Algorithm implementation.
JS_Algorithm.m - Jellyfish Search Optimizer implementation.
GBO_Algorithm.m - Gradient-Based Optimizer implementation.
ESMA_Algorithm.m - Enhanced Slime Mould Algorithm implementation (with chaotic initialization and Levy flight).

Key Features and Methodology

  1.  Metaheuristic Optimization: Evaluates and compares multiple state-of-the-art algorithms over 30 independent runs.
  2.  Economic Analysis: Computes Capital Expenditure (CAPEX), Operation & Maintenance (O&M) costs, and annual cumulative total costs using the Capital Recovery Factor (CRF).
  3.  Power System Stability: Performs 24-hour AC power flow via MATPOWER to assess Total Voltage Deviation (TVD) and voltage profiles at critical nodes (e.g.,       Bus 30).
  4.  Professional Visualization: Automatically exports high-resolution (300 DPI) vector figures for research publication.

How to Run

   1. Ensure you have MATLAB installed along with the MATPOWER toolbox.
   2. Open all repository files in your MATLAB workspace.
   3. Run the master script: MainOperatingCode_IEEE30

Author
Hedra Saleeb, Mohamed F. Baroma, Ali M. El-Rifaie, Ahmed A. F. Youssef, Almoataz Y. Abdelaziz, and Rasha Kassem
Research in Electrical Engineering & Power Systems Optimization
