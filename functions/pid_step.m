function [u, I_new] = pid_step(Tset, Tm, K, I, Tm_prev, To_m)
%#codegen
% Discrete PID. u<0 = cooling, u>0 = heating (W). Stateless: caller keeps I, Tm_prev.
P = hvac_params();
[Qc, Qh, ~] = hvac_capacity(To_m);          % controller uses MEASURED outdoor temp
e   = Tset - Tm;
D   = -K(3) * (Tm - Tm_prev) / P.Ts;        % derivative on measurement
u_unsat = K(1)*e + I + D;
u = min(max(u_unsat, -Qc), Qh);             % actuator limits
if (u == u_unsat) || (sign(e) ~= sign(u_unsat))   % anti-windup: conditional integration
    I_new = I + K(2)*e*P.Ts;
else
    I_new = I;
end
end