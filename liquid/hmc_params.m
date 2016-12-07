function params = hmc_params()
    params.logInputData = false; 
    params.K = 3;
    params.sample = 100;
    params.burnin = 100;
    params.priorChange = 50;
    params.numStandardDevForStart = 4; 
    params.modelType = 1; 
    params.priorSlopeVarRescale = 100;
    params.priorSigma2Shape = 1;
    params.priorSigma2Scale = 1;
    params.priorDelta = 0.1;
end