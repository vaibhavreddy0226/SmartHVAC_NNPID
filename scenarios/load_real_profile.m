function S = load_real_profile(csvfile, timeVar, tempVar, occVar, t_start, P)
% t_start: datetime where the 12 h window begins. Temperature must be in C; occupancy in people.
T   = readtable(csvfile);
tt  = T.(timeVar);                                   % datetime column
sel = tt >= t_start & tt < t_start + hours(12);
ts  = seconds(tt(sel) - t_start);
t   = (0:P.Ts:12*3600)';
To  = interp1(ts, T.(tempVar)(sel), t, 'linear', 'extrap');
N   = round(interp1(ts, T.(occVar)(sel), t, 'previous', 'extrap'));
Tset = 24*ones(size(t));
S = struct('t',t,'To',To,'N',N,'Tset',Tset,'T_end',t(end));
S.To_ts = timeseries(To,t);  S.N_ts = timeseries(N,t);  S.Tset_ts = timeseries(Tset,t);
end