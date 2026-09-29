clear; clc; rng(1);
root = hvac_root();
D = load(fullfile(root,'data','training_data.mat'));
x = D.X';  y = D.Y';                               % 3 x n each
fprintf('Spread of optimal log10 gains (std): Kp %.2f  Ki %.2f  Kd %.2f\n', std(D.Y));
% If these are all < ~0.05, the plant barely needs scheduling: widen the ranges in s01.

net = fitnet(10, 'trainbr');
net.divideFcn = 'dividerand';
net.divideParam.trainRatio = 0.85;  net.divideParam.valRatio = 0;  net.divideParam.testRatio = 0.15;
net.trainParam.epochs = 300;  net.trainParam.showWindow = false;
[net, tr] = train(net, x, y);

yh = net(x(:, tr.testInd));
fprintf('Test RMSE (log10 gains): Kp %.3f  Ki %.3f  Kd %.3f\n', sqrt(mean((yh - y(:,tr.testInd)).^2, 2)));

save(fullfile(root,'nn','gain_net.mat'), 'net', 'tr');
genFunction(net, fullfile(root,'nn','nn_gain_fcn'), 'MatrixOnly', 'yes');   % standalone function for Simulink
rehash;
xt = [30; 10; 24];
assert(max(abs(nn_gain_fcn(xt) - net(xt))) < 1e-9, 'Exported NN differs from trained NN');
disp('Gains at 25C/0 people/24C:');  disp(10.^net([25;0;24])');
disp('Gains at 38C/20 people/24C:'); disp(10.^net([38;20;24])');