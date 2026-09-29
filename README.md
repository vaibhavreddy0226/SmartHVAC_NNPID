# SmartHVAC NNPID

- This project is a smart HVAC system to control temperature and the Kp, Ki, Kd constants are been controlled by the neural networks.  
- The system is simulated under four conditions `summer day`, `setpoint step`, `crowd entry`, `heat wave`.
---
## Running   
### Method 1
In this method the sequence of running is 
```
startup.m  
s00_tune_baseline.m        <- run this, then edit config/hvac_params.m yourself  
main_run_all.m             
```
After running the `s00_tune_baseline.m` you will get something like this `P.K_fixed  = [1500.0; 0.906; 4991.0];` replace the line you got here inside the `hvac_params.m` at the end with the line there .  

### Method 2
Here you need not to run `s00_tune_baseline.m` you can use the value i run and pasted in `hvac_params.m`.  
sequence for running  
```
startup.m
main_run_all.m             
```

