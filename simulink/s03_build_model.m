clear; clc; bdclose all;
root = hvac_root();  mdl = 'hvac_nnpid';
assert(~isempty(which('nn_gain_fcn')), 'Run s02_train_nn first (nn_gain_fcn.m missing).');
init_workspace;

new_system(mdl);  open_system(mdl);
set_param(mdl,'Solver','ode45','StopTime','T_end','MaxStep','10','RelTol','1e-4', ...
          'ReturnWorkspaceOutputs','on','PreLoadFcn','init_workspace;');

blk = @(n) [mdl '/' n];
mk  = @(type,name,x,y,varargin) add_block(type, blk(name), 'Position',[x y x+110 y+60], varargin{:});
ln  = @(a,b) add_line(mdl, a, b, 'autorouting','smart');
FCN = 'simulink/User-Defined Functions/Fcn';
MFB = 'simulink/User-Defined Functions/MATLAB Function';

%% A) Scenario inputs (From Workspace -> variables made by init_workspace / run_simulink_case)
mk('simulink/Sources/From Workspace','To_true', 30,  30,'VariableName','To_ts',  'Interpolate','on', 'OutputAfterFinalValue','Holding final value');
mk('simulink/Sources/From Workspace','N_true',  30, 150,'VariableName','N_ts',   'Interpolate','off','OutputAfterFinalValue','Holding final value');
mk('simulink/Sources/From Workspace','Tset_in', 30, 700,'VariableName','Tset_ts','Interpolate','on', 'OutputAfterFinalValue','Holding final value');

%% B) Thermal plant (two-node RC model)
mk(FCN,'Q_int',  200, 150,'Expr','q_person*u + q_eq*(u>0)');                 % occupant + equipment heat (W)
mk(FCN,'G_out',  200, 230,'Expr','1/Rwin + c_vent*u');                       % outdoor conductance (W/K)
mk('simulink/Signal Routing/Mux','Mux_air', 360,100,'Inputs','6');           % [Ti Tw To G Qhvac Qint]
mk(FCN,'dTi',    500, 100,'Expr','((u(2)-u(1))/Rw + (u(3)-u(1))*u(4) + u(5) + u(6))/Ca');
mk('simulink/Continuous/Integrator','Int_Ti', 640,100,'InitialCondition','Ti0');
mk('simulink/Signal Routing/Mux','Mux_wall',360,330,'Inputs','3');           % [Tw Ti To]
mk(FCN,'dTw',    500, 330,'Expr','((u(2)-u(1))/Rw + (u(3)-u(1))/Ro)/Cw');
mk('simulink/Continuous/Integrator','Int_Tw', 640,330,'InitialCondition','Tw0');

%% C) Sensors: lag -> noise -> sample (ZOH) -> quantize
sens = {'Ti','Ti0','sig_Ti',450,11; 'To','To_ts.Data(1)','sig_To',560,22};
for i = 1:2
    tg = sens{i,1};  y = sens{i,4};
    mk('simulink/Math Operations/Sum',       ['Lag_e_' tg], 800, y, 'Inputs','+-');
    mk('simulink/Math Operations/Gain',      ['Lag_g_' tg], 920, y, 'Gain','1/tau_s');
    mk('simulink/Continuous/Integrator',     ['Lag_i_' tg],1040, y, 'InitialCondition',sens{i,2});
    mk('simulink/Sources/Random Number',     ['Noise_' tg],1040, y+70,'Mean','0','Variance',[sens{i,3} '^2'],'SampleTime','Ts','Seed',num2str(sens{i,5}));
    mk('simulink/Math Operations/Sum',       ['Add_'   tg],1160, y, 'Inputs','++');
    mk('simulink/Discrete/Zero-Order Hold',  ['ZOH_'   tg],1280, y, 'SampleTime','Ts');
    mk('simulink/Discontinuities/Quantizer', ['Quant_' tg],1400, y, 'QuantizationInterval','q_res');
end

%% D) Controller
mk('simulink/Discrete/Zero-Order Hold','ZOH_Tset',200,700,'SampleTime','Ts');
mk('simulink/Discrete/Zero-Order Hold','ZOH_N',   200,620,'SampleTime','Ts');
mk(MFB,'Scheduler',  1550, 600);                                             % NN gain scheduler
mk('simulink/Sources/Constant','K_fixed_c',1550,740,'Value','K_fixed','VectorParams1D','off');
mk('simulink/Sources/Constant','Mode_c',   1550,820,'Value','ctrl_mode');
mk('simulink/Signal Routing/Switch','K_switch',1720,700,'Criteria','u2 >= Threshold','Threshold','0.5');
mk(MFB,'PID',        1880, 700);

%% E) Actuator
mk('simulink/Continuous/Transfer Fcn','Act_lag',2040,700,'Numerator','[1]','Denominator','[tau_act 1]');
mk(MFB,'Cap_lim',    1880, 860);                                             % capacity limits vs TRUE outdoor temp
mk('simulink/Discontinuities/Saturation Dynamic','Sat_dyn',2200,760);

%% F) Logging (To Workspace, MaxDataPoints must be inf)
logs = {'log_Ti','Int_Ti/1'; 'log_Tm','Quant_Ti/1'; 'log_Q','Sat_dyn/1'; 'log_K','K_switch/1'; ...
        'log_To','To_true/1'; 'log_N','N_true/1'; 'log_Tset','Tset_in/1'};
for i = 1:size(logs,1)
    mk('simulink/Sinks/To Workspace', logs{i,1}, 2400, 30+80*i, 'VariableName',logs{i,1}, ...
       'SaveFormat','Timeseries','MaxDataPoints','inf');
    ln(logs{i,2}, [logs{i,1} '/1']);
end

%% G) MATLAB Function block code
set_code(blk('Scheduler'), strjoin({ ...
 'function K = sched_block(To_m, N_m, Tset)', ...
 'persistent st', ...
 'if isempty(st)', '    st = zeros(4,1);', 'end', ...
 '[K, st] = gain_scheduler(To_m, N_m, Tset, st);', 'end'}, newline));
set_code(blk('PID'), strjoin({ ...
 'function u = pid_block(Tset, Tm, K, To_m)', ...
 'persistent I Tm_prev', ...
 'if isempty(I)', '    I = 0;', '    Tm_prev = Tm;', 'end', ...
 '[u, I] = pid_step(Tset, Tm, K, I, Tm_prev, To_m);', ...
 'Tm_prev = Tm;', 'end'}, newline));
set_code(blk('Cap_lim'), strjoin({ ...
 'function [lo, hi] = cap_block(To)', ...
 '[Qc, Qh, ~] = hvac_capacity(To);', 'lo = -Qc;', 'hi = Qh;', 'end'}, newline));

%% H) Connections
% -- plant --
ln('To_true/1','Mux_air/3');  ln('To_true/1','Mux_wall/3');
ln('N_true/1','Q_int/1');    ln('N_true/1','G_out/1');
ln('G_out/1','Mux_air/4');    ln('Q_int/1','Mux_air/6');
ln('Int_Ti/1','Mux_air/1');   ln('Int_Ti/1','Mux_wall/2');
ln('Int_Tw/1','Mux_air/2');   ln('Int_Tw/1','Mux_wall/1');
ln('Mux_air/1','dTi/1');      ln('dTi/1','Int_Ti/1');
ln('Mux_wall/1','dTw/1');     ln('dTw/1','Int_Tw/1');
ln('Sat_dyn/1','Mux_air/5');
% -- sensors --
ln('Int_Ti/1','Lag_e_Ti/1');  ln('To_true/1','Lag_e_To/1');
for tg = {'Ti','To'}
    t_ = tg{1};
    ln(['Lag_e_' t_ '/1'],['Lag_g_' t_ '/1']);   ln(['Lag_g_' t_ '/1'],['Lag_i_' t_ '/1']);
    ln(['Lag_i_' t_ '/1'],['Lag_e_' t_ '/2']);   ln(['Lag_i_' t_ '/1'],['Add_' t_ '/1']);
    ln(['Noise_' t_ '/1'],['Add_' t_ '/2']);     ln(['Add_' t_ '/1'],['ZOH_' t_ '/1']);
    ln(['ZOH_' t_ '/1'],['Quant_' t_ '/1']);
end
% -- controller --
ln('Tset_in/1','ZOH_Tset/1');  ln('N_true/1','ZOH_N/1');
ln('Quant_To/1','Scheduler/1'); ln('ZOH_N/1','Scheduler/2'); ln('ZOH_Tset/1','Scheduler/3');
ln('Scheduler/1','K_switch/1'); ln('Mode_c/1','K_switch/2'); ln('K_fixed_c/1','K_switch/3');
ln('ZOH_Tset/1','PID/1'); ln('Quant_Ti/1','PID/2'); ln('K_switch/1','PID/3'); ln('Quant_To/1','PID/4');
% -- actuator --
ln('PID/1','Act_lag/1');  ln('Act_lag/1','Sat_dyn/2');
ln('To_true/1','Cap_lim/1');
ln('Cap_lim/2','Sat_dyn/1');   % upper limit (heating)
ln('Cap_lim/1','Sat_dyn/3');   % lower limit (cooling)

try, Simulink.BlockDiagram.arrangeSystem(mdl); end     %#ok<TRYNC> tidy layout
set_param(mdl,'SimulationCommand','update');            % compile check: errors show here
save_system(mdl, fullfile(root,'simulink',[mdl '.slx']));
disp('Built and saved simulink/hvac_nnpid.slx');

function set_code(path, code)
rt = sfroot;
ch = rt.find('-isa','Stateflow.EMChart','Path',path);
ch.Script = code;
end