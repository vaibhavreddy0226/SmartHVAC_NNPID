function M = compute_metrics(R, t0, t1)
% Metrics over window [t0, t1] seconds.
idx = R.t >= t0 & R.t <= t1;
t = R.t(idx) - t0;  Ti = R.Ti(idx);  Q = R.Q(idx);  COP = R.COP(idx);
e = R.Tset(idx) - Ti;  e0 = e(1);
M.rise_min = NaN;  M.overshoot_C = NaN;
if abs(e0) > 1                                       % only defined for a large initial error
    prog = 1 - abs(e)/abs(e0);
    i10 = find(prog >= 0.1, 1);  i90 = find(prog >= 0.9, 1);
    if ~isempty(i10) && ~isempty(i90), M.rise_min = (t(i90) - t(i10))/60; end
    M.overshoot_C = max(0, max(-sign(e0)*e));
end
out = find(abs(e) > 0.3, 1, 'last');                 % 0.3 C settling band
if isempty(out), M.settle_min = 0; elseif out == numel(t), M.settle_min = NaN; else, M.settle_min = t(out+1)/60; end
M.sse_C          = mean(abs(e(t > 0.8*t(end))));    % steady-state error (last 20%)
M.max_dev_C      = max(abs(e));
M.IAE_Ch         = trapz(t, abs(e))/3600;
M.ITAE_Ch2       = trapz(t, t.*abs(e))/3600^2;
M.comfort_viol_pct = 100*mean(abs(e) > 0.5);
M.thermal_kWh    = trapz(t, abs(Q))/3.6e6;           % control effort
M.electric_kWh   = trapz(t, abs(Q)./COP)/3.6e6;      % energy with COP
M.Q_TV_kW        = sum(abs(diff(Q)))/1000;           % actuator activity
end