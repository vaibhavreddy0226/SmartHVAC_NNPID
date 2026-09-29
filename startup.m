% Run once per MATLAB session (from the project root folder).
root = fileparts(mfilename('fullpath'));
for d = {'data','nn','results'}
    if ~isfolder(fullfile(root,d{1})), mkdir(fullfile(root,d{1})); end
end
addpath(genpath(root));
disp('SmartHVAC_NNPID: paths set.');