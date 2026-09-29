function [K, st_new] = gain_scheduler(To_m, N_m, Tset, st)
%#codegen
% st = [To_filtered; Kp; Ki; Kd]; st(2)==0 means first call.
P = hvac_params();
if st(2) == 0
    To_f = To_m;
else
    To_f = st(1) + P.alpha_To*(To_m - st(1));          % low-pass filter on noisy sensor
end
y     = nn_gain_fcn([To_f; N_m; Tset]);                % log10 gains from trained NN
K_raw = min(max(10.^y(:), P.K_min), P.K_max);
if st(2) == 0
    K = K_raw;
else
    K_prev = st(2:4);
    K = min(max(K_raw, K_prev*(1 - P.max_dK)), K_prev*(1 + P.max_dK));   % rate limit
end
st_new = [To_f; K];
end