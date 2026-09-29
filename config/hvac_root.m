function r = hvac_root()
% Returns the project root folder (parent of /config).
r = fileparts(fileparts(mfilename('fullpath')));
end