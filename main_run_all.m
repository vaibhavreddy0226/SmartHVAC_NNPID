% Run s00 first by hand and paste K_fixed into config/hvac_params.m, then:
startup;
s01_generate_training_data;
s02_train_nn;
s03_build_model;
s04_verify_link;      % stops with an error if Simulink and scripts disagree
s05_run_comparison;