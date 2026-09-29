function J = gain_cost(logK, cond, P)
% Cost of running fixed gains 10.^logK at operating condition cond = [To N Tset].
K = 10.^logK(:);
T_end = 2*3600;  t = (0:P.Ts:T_end)';
S.t = t; S.T_end = T_end;
S.To   = cond(1)*ones(size(t));
S.N    = cond(2)*ones(size(t));  S.N(t >= 3600) = cond(2) + 5;   % 5 people walk in at 1 h
S.Tset = cond(3)*ones(size(t));
o.dt = 5; o.noise = true; o.seed = 0;                            % noisy sensors, repeatable
o.Ti0 = cond(3) + 3;                                             % start 3 C too warm
o.Tw0 = o.Ti0 + (cond(1) - o.Ti0)*P.Rw/(P.Rw + P.Ro);
R = simulate_room(S, 0, K, o);
if ~all(isfinite(R.Ti)), J = 1e3; return; end
e   = R.Tset - R.Ti;
J_e = mean((R.t/T_end).*abs(e));                 % normalized ITAE
J_u = mean((R.Q/P.Qc_rated).^2);                 % control effort
J_o = max(0, max(e));                            % overcooling (undershoot)
J   = min(J_e + 0.5*J_u + 2*J_o, 1e3);
end