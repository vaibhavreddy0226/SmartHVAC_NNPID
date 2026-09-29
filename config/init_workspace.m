% Pushes every parameter into the base workspace so Simulink blocks can use them.
P = hvac_params();
fn = fieldnames(P);
for i = 1:numel(fn), assignin('base', fn{i}, P.(fn{i})); end
if ~evalin('base','exist(''ctrl_mode'',''var'')'), assignin('base','ctrl_mode',0); end
if ~evalin('base','exist(''To_ts'',''var'')')
    S0 = make_scenario('summer_day', P);
    assignin('base','To_ts',S0.To_ts);   assignin('base','N_ts',S0.N_ts);
    assignin('base','Tset_ts',S0.Tset_ts); assignin('base','T_end',S0.T_end);
end