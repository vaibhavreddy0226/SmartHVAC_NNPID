clear; clc;
P = hvac_params();
lb = log10(P.K_min(:))';  ub = log10(P.K_max(:))';  x0 = log10(P.K_fixed(:))';
cond = [34 10 24];                                    % nominal: 34 C outdoor, 10 people, 24 C setpoint
ps = optimoptions('patternsearch','Display','iter','MaxFunctionEvaluations',300);
[xb, Jb] = patternsearch(@(x) gain_cost(x, cond, P), x0, [],[],[],[], lb, ub, [], ps);
fprintf('\nBest cost %.4f. Paste into config/hvac_params.m:\n', Jb);
fprintf('P.K_fixed  = [%.1f; %.3f; %.1f];\n', 10.^xb);