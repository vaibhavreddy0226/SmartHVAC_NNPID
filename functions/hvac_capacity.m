function [Qc_max, Qh_max, COP] = hvac_capacity(To)
%#codegen
P = hvac_params();
Qc_max = P.Qc_rated * max(0.4, 1 - P.k_derate*(To - 35));   % cooling limit falls when hot
Qh_max = P.Qh_max;
COP    = max(1.5, P.COP0 - P.k_cop*(To - 35));
end