function P = hvac_params()
% Single source of truth for MATLAB scripts AND Simulink.
% ---- Thermal plant (~50 m2 office room) ----
P.Ca       = 1.2e6;   % J/K   air + furniture capacitance
P.Cw       = 8e6;     % J/K   wall capacitance
P.Rw       = 0.004;   % K/W   air <-> wall
P.Ro       = 0.008;   % K/W   wall <-> outdoor
P.Rwin     = 0.03;    % K/W   window/infiltration (fixed part)
P.c_vent   = 6;       % W/K per person, fresh-air ventilation (occupancy dependent)
P.q_person = 75;      % W per person, sensible heat
P.q_eq     = 300;     % W lights/equipment when occupied
% ---- HVAC ----
P.Qc_rated = 8000;    % W cooling capacity at 35 C outdoor
P.Qh_max   = 5000;    % W heating capacity
P.k_derate = 0.012;   % 1/K capacity loss per K above 35 C
P.COP0     = 3.0;  P.k_cop = 0.05;   % COP at 35 C and its drop per K
P.tau_act  = 90;      % s actuator lag
% ---- Sensors ----
P.tau_s    = 45;      % s sensor lag
P.sig_Ti   = 0.1;  P.sig_To = 0.3;   % C, noise std (indoor, outdoor)
P.q_res    = 0.1;     % C, quantization
P.Ts       = 60;      % s, sensor + controller sample time
% ---- Initial conditions ----
P.Ti0 = 28;  P.Tw0 = 30;
% ---- Baseline fixed PID (overwrite with s00 result) ----
P.K_fixed  = [1500; 2; 5000];        % [Kp W/K; Ki W/(K s); Kd W s/K]
% ---- Scheduler ----
P.alpha_To = 0.1;                    % low-pass factor on measured outdoor temp
P.max_dK   = 0.05;                   % max relative gain change per sample
P.K_min    = [200; 0.2;  500];
P.K_max    = [6000; 12; 20000];
P.K_fixed  = [1500.0; 0.906; 4991.0];
end