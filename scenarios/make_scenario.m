function S = make_scenario(name, P)
% 12 h day (08:00-20:00) on a 1-minute grid.
t = (0:P.Ts:12*3600)';  h = t/3600;
rng(1);
wander = 10*filter(0.02, [1 -0.98], randn(size(t)));       % slow weather variation (~1 C)
To   = 34 + 5*sin(2*pi*(h-1)/24) + wander;                 % daily outdoor cycle, peak 15:00
N    = round(interp1([0 1 2 4 5 7 9 12],[0 6 18 8 15 22 5 0], h, 'previous'));   % people entering/leaving
Tset = 24*ones(size(t));
switch name
    case 'summer_day'
    case 'setpoint_step'
        N = 10*ones(size(t));  Tset(h>=3) = 22;  Tset(h>=7) = 26;
    case 'crowd_entry'
        N = 4*ones(size(t));   N(h>=3 & h<6) = 25;
    case 'heat_wave'
        To = To + 8*min(max((h-2)/2,0),1);                 % +8 C ramp between 2 h and 4 h
    otherwise
        error('Unknown scenario: %s', name);
end
S = struct('t',t,'To',To,'N',N,'Tset',Tset,'T_end',t(end));
S.To_ts = timeseries(To,t);  S.N_ts = timeseries(N,t);  S.Tset_ts = timeseries(Tset,t);
end