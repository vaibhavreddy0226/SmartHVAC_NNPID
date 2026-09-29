clear; clc;
%% 1) Every file must be on the path
req = {'hvac_params','hvac_root','init_workspace','hvac_capacity','pid_step','gain_scheduler', ...
       'nn_gain_fcn','make_scenario','simulate_room','gain_cost','run_simulink_case','compute_metrics','hvac_nnpid'};
for i = 1:numel(req)
    assert(~isempty(which(req{i})), 'MISSING on path: %s (did you run startup.m and s02/s03?)', req{i});
end
disp('[OK] all files found');

%% 2) Every workspace variable used by Simulink blocks must exist
init_workspace;
vars = {'Ca','Cw','Rw','Ro','Rwin','c_vent','q_person','q_eq','tau_act','tau_s','sig_Ti','sig_To', ...
        'q_res','Ts','Ti0','Tw0','K_fixed','ctrl_mode','To_ts','N_ts','Tset_ts','T_end'};
for i = 1:numel(vars)
    assert(evalin('base',sprintf('exist(''%s'',''var'')',vars{i})) == 1, 'Workspace variable missing: %s', vars{i});
end
disp('[OK] workspace variables present');

%% 3) Simulink model vs MATLAB twin, noise OFF, both controller modes
mdl = 'hvac_nnpid';  P = hvac_params();  S = make_scenario('summer_day', P);
assignin('base','sig_Ti',0);  assignin('base','sig_To',0);
for mode = 0:1
    Rs = run_simulink_case(mdl, S, mode);
    Rm = simulate_room(S, mode, P.K_fixed, struct('noise',false,'dt',1));
    rmseTi = sqrt(mean((Rs.Ti - Rm.Ti).^2));   maxTi = max(abs(Rs.Ti - Rm.Ti));
    rmseQ  = sqrt(mean((Rs.Q  - Rm.Q ).^2));
    dK     = max(abs(Rs.K(:) - Rm.K(:))./max(abs(Rm.K(:)),1e-9));
    fprintf('mode %d: Ti RMSE %.4f C | max %.3f C | Q RMSE %.1f W | max rel K diff %.2e\n', mode, rmseTi, maxTi, rmseQ, dK);
    assert(rmseTi < 0.05 && maxTi < 0.2, 'LINK FAILED for mode %d: Simulink and MATLAB twin disagree', mode);
end
init_workspace;                                    % restore noise settings
disp('[OK] Simulink model and MATLAB scripts are linked and consistent');