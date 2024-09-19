function [roadload_force_N roadload_power_kW roadload_force_lbs roadload_power_hp] = calc_roadload_abc_N(A_N, B_N, C_N, MPH, varargin)
%function [roadload_force_N roadload_power_kW roadload_force_lbs roadload_power_hp] = calc_roadload_abc_N(A_N, B_N, C_N, MPH, varargin)
    
    KW2HP = 1.341;
    N2LBF = 0.224808943;
    KMH2MPH = .621371; %Nist derivation
    MPH2MPS = 1/KMH2MPH*1000.0/3600.0; %Nist derivation
    MPS2MPH = 1/MPH2MPS;

    grade_pct = parse_varargs(varargin,'grade_pct',0);
    mass_kg   = parse_varargs(varargin,'mass_kg',0);

    MPS = MPH/MPS2MPH;
    
    roadload_force_N = A_N + B_N * MPS + C_N * MPS .* MPS + sin(atan(grade_pct/100)) * mass_kg * 9.81;
    roadload_power_kW = roadload_force_N .* MPS / 1000;
    
    roadload_force_lbs = roadload_force_N * N2LBF;
    roadload_power_hp = roadload_power_kW * KW2HP;
end