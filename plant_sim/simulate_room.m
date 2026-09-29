function R = simulate_room(S, ctrl_mode, K_fixed, opts)
% MATLAB twin of simulink/hvac_nnpid.slx (same physics, sensors, controller code).
% ctrl_mode: 0 = fixed PID, 1 = NN gain-scheduled PID.
if nargin < 4, opts = struct(); end
P     = hvac_params();
dt    = getopt(opts,'dt',1);
noise = getopt(opts,'noise',true);
Ti0   = getopt(opts,'Ti0',P.Ti0);   Tw0 = getopt(opts,'Tw0',P.Tw0);
if isfield(opts,'seed'), rng(opts.seed); end

t    = (0:dt:S.T_end)';  n = numel(t);
To   = interp1(S.t, S.To,   t, 'linear',   'extrap');
N    = interp1(S.t, S.N,    t, 'previous', 'extrap');
Tset = interp1(S.t, S.Tset, t, 'previous', 'extrap');

Ti = zeros(n,1); Tw = Ti; Q = Ti; U = Ti; Kh = zeros(n,3);
Ti(1) = Ti0;  Tw(1) = Tw0;
Tim = Ti0;  Tom = To(1);              % sensor-lag states
xa  = 0;                              % actuator-lag state
I = 0; Tm_prev = 0; u = 0; K = K_fixed(:); st = zeros(4,1);

for k = 1:n
    if mod(t(k), P.Ts) == 0           % ---- sensors + controller (every Ts) ----
        Tm    = P.q_res*round((Tim + noise*P.sig_Ti*randn)/P.q_res);
        Tom_m = P.q_res*round((Tom + noise*P.sig_To*randn)/P.q_res);
        if t(k) == 0, Tm_prev = Tm; end
        if ctrl_mode == 1
            [K, st] = gain_scheduler(Tom_m, N(k), Tset(k), st);
        else
            K = K_fixed(:);
        end
        [u, I] = pid_step(Tset(k), Tm, K, I, Tm_prev, Tom_m);
        Tm_prev = Tm;
    end
    [Qc, Qh, ~] = hvac_capacity(To(k));
    Q(k) = min(max(xa, -Qc), Qh);  U(k) = u;  Kh(k,:) = K';
    if k == n, break; end
    G   = 1/P.Rwin + P.c_vent*N(k);   % outdoor conductance rises with occupancy
    dTi = ((Tw(k)-Ti(k))/P.Rw + (To(k)-Ti(k))*G + Q(k) + P.q_person*N(k) + P.q_eq*(N(k)>0))/P.Ca;
    dTw = ((Ti(k)-Tw(k))/P.Rw + (To(k)-Tw(k))/P.Ro)/P.Cw;
    Ti(k+1) = Ti(k) + dt*dTi;   Tw(k+1) = Tw(k) + dt*dTw;
    xa  = xa  + dt/P.tau_act*(u - xa);
    Tim = Tim + dt/P.tau_s*(Ti(k) - Tim);
    Tom = Tom + dt/P.tau_s*(To(k) - Tom);
end
[~,~,COP] = hvac_capacity(To);
R = struct('t',t,'Ti',Ti,'Tw',Tw,'To',To,'N',N,'Tset',Tset,'Q',Q,'U',U,'K',Kh,'COP',COP);
end

function v = getopt(o,f,d)
if isfield(o,f), v = o.(f); else, v = d; end
end