clear; clc; rng(42);
root = hvac_root();  P = hvac_params();
n_pts = 200;
lo = [22  0 22];   hi = [40 20 26];                % ranges of [To  N  Tset]
U = zeros(n_pts,3);
for j = 1:3, U(:,j) = (randperm(n_pts)' - rand(n_pts,1))/n_pts; end   % Latin hypercube
X = lo + U.*(hi - lo);   X(:,2) = round(X(:,2));

lb = log10(P.K_min(:))';  ub = log10(P.K_max(:))';  x0 = log10(P.K_fixed(:))';
ps = optimoptions('patternsearch','Display','off','MaxFunctionEvaluations',120);
Y = zeros(n_pts,3);  J = zeros(n_pts,1);
tic
for i = 1:n_pts                                    % (use parfor if you have Parallel Toolbox)
    [Y(i,:), J(i)] = patternsearch(@(x) gain_cost(x, X(i,:), P), x0, [],[],[],[], lb, ub, [], ps);
    if mod(i,10) == 0, fprintf('%3d/%d done (%.0f s)\n', i, n_pts, toc); end
end
save(fullfile(root,'data','training_data.mat'), 'X', 'Y', 'J');   % Y = log10([Kp Ki Kd])
fprintf('Saved data/training_data.mat\n');