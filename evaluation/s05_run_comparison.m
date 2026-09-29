clear; clc; close all;
root = hvac_root();  P = hvac_params();  mdl = 'hvac_nnpid';
init_workspace;  load_system(mdl);

% name, window start (s), window end (s)
cases = {'summer_day',0,12*3600; 'setpoint_step',3*3600,7*3600; ...
         'crowd_entry',3*3600,6*3600; 'heat_wave',2*3600,6*3600};
rows = [];
for c = 1:size(cases,1)
    name = cases{c,1};  t0 = cases{c,2};  t1 = cases{c,3};
    S  = make_scenario(name, P);
    Rf = run_simulink_case(mdl, S, 0);             % fixed PID
    Rn = run_simulink_case(mdl, S, 1);             % NN gain-scheduled PID
    R = {Rf, Rn};  lab = {"Fixed PID","NN-PID"};
    for k = 1:2
        M = compute_metrics(R{k}, t0, t1);
        M.scenario = string(name);  M.controller = lab{k};
        rows = [rows; M];                          %#ok<AGROW>
    end
    fig = figure('Position',[100 100 900 850]);
    h = Rf.t/3600;
    subplot(4,1,1); plot(h,Rf.Ti,h,Rn.Ti,h,Rf.Tset,'k--'); grid on; ylabel('T_{in} (°C)');
    legend('Fixed PID','NN-PID','Setpoint'); title(name,'Interpreter','none');
    subplot(4,1,2); plot(h,Rf.Q/1000,h,Rn.Q/1000); grid on; ylabel('Q_{HVAC} (kW)');
    subplot(4,1,3); plot(h,Rf.K(:,1),h,Rn.K(:,1)); grid on; ylabel('K_p (W/K)');
    subplot(4,1,4); yyaxis left; plot(h,Rf.To); ylabel('T_{out} (°C)');
    yyaxis right; stairs(h,Rf.N); ylabel('People'); xlabel('Time (h)'); grid on;
    exportgraphics(fig, fullfile(root,'results',[name '.png']), 'Resolution',150);
end
T = movevars(struct2table(rows), {'scenario','controller'}, 'Before', 1);
disp(T);
writetable(T, fullfile(root,'results','metrics_table.csv'));