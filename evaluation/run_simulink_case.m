function R = run_simulink_case(mdl, S, mode)
% Runs hvac_nnpid.slx for scenario S. mode: 0 = fixed PID, 1 = NN-PID.
load_system(mdl);
assignin('base','ctrl_mode',mode);
assignin('base','To_ts',S.To_ts);   assignin('base','N_ts',S.N_ts);
assignin('base','Tset_ts',S.Tset_ts); assignin('base','T_end',S.T_end);
out = sim(mdl);
t = (0:1:S.T_end)';
R.t = t;
R.Ti   = resamp(out.log_Ti,   t, 'linear');
R.Q    = resamp(out.log_Q,    t, 'linear');
R.To   = resamp(out.log_To,   t, 'linear');
R.N    = resamp(out.log_N,    t, 'previous');
R.Tset = resamp(out.log_Tset, t, 'previous');
R.K    = resamp(out.log_K,    t, 'previous');      % N x 3
[~,~,R.COP] = hvac_capacity(R.To);
end

function y = resamp(ts, t, method)
tm = ts.Time;  d = squeeze(ts.Data);
if isvector(d), d = d(:); elseif size(d,1) ~= numel(tm), d = d'; end
[tm, iu] = unique(tm, 'last');                      % variable-step logs contain duplicate times
y = interp1(tm, d(iu,:), t, method, 'extrap');
end