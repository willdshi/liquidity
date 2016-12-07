function HMCparams = readparam_hmc(useDefaultValues)

    global LOG;
    global CONFG;

    if (useDefaultValues)
        HMCparams.logInputData = true;
        HMCparams.K = 3;
        HMCparams.sample = 100;
        HMCparams.burnin = 100;
        HMCparams.priorChange = 50;
        HMCparams.numStandardDevForStart = 4;
        HMCparams.modelType = 1;
        HMCparams.priorSlopeVarRescale = 100;
        HMCparams.priorSigma2Shape = 1;
        HMCparams.priorSigma2Scale = 1;
        HMCparams.priorDelta = 0.1;
    else 
        cfPfx = ['LIQ.HMC' '.'];
        LOG.info('');
        LOG.info(sprintf('Running readparam_hmc for %s:', cfPfx));
        HMCparams.logInputData = ...
            CONFG.getPropBoolean([cfPfx 'HMC_logInputData']);
        HMCparams.K = ...
            CONFG.getPropDouble([cfPfx 'HMC_K']);
        HMCparams.sample = ...
            CONFG.getPropDouble([cfPfx 'HMC_sample']);
        HMCparams.burnin = ...
            CONFG.getPropDouble([cfPfx 'HMC_burnin']);
        HMCparams.priorChange = ...
            CONFG.getPropDouble([cfPfx 'HMC_priorChange']);
        HMCparams.numStandardDevForStart = ...
            CONFG.getPropDouble([cfPfx 'HMC_numStandardDevForStart']);      
        HMCparams.modelType = ...
            CONFG.getPropInt([cfPfx 'HMC_modelType']);      
        HMCparams.priorSlopeVarRescale = ...
            CONFG.getPropDouble([cfPfx 'HMC_priorSlopeVarRescale']);
        HMCparams.priorSigma2Shape = ...
            CONFG.getPropDouble([cfPfx 'HMC_priorSigma2Shape']);
        HMCparams.priorSigma2Scale = ...
            CONFG.getPropDouble([cfPfx 'HMC_priorSigma2Scale']);
        HMCparams.priorDelta = ...
            CONFG.getPropDouble([cfPfx 'HMC_priorDelta']);
        LOG.info('');
%     HMCparams.printFigures = ...
%         CONFG.getPropBoolean([cfPfx 'HMC_printFigures']);
%     HMCparams.debugMCMC = CONFG.getPropBoolean([cfPfx 'HMC_debugMCMC']);
%     HMCparams.genData = CONFG.getPropBoolean([cfPfx 'HMC_genData']);
%     HMCparams.randomStart = ...
%         CONFG.getPropBoolean([cfPfx 'HMC_randomStart']);
%     HMCparams.syntheticData = ...
%         CONFG.getPropBoolean([cfPfx 'HMC_syntheticData']);
%     HMCparams.thinPrintScreen = ...
%         CONFG.getPropInt([cfPfx 'HMC_thinPrintScreen']);
%
%     datadir = [CONFG.getProp('cache_directory') filesep ...
%         CONFG.getProp([cfPfx 'HMCfile_subdir']) filesep];
%     HMCparams.predUnivariateData = ...
%         [datadir CONFG.getProp([cfPfx 'HMCfile_predUnivariateData'])];
%     HMCparams.hiddenMC = ...
%         [datadir CONFG.getProp([cfPfx 'HMCfile_hiddenMC'])];
%     HMCparams.modelParameters = ...
%         [datadir CONFG.getProp([cfPfx 'HMCfile_modelParameters'])];
%     HMCparams.trueParams = ...
%         [datadir CONFG.getProp([cfPfx 'HMCfile_trueParams'])];
%     HMCparams.dataInput = ...
%         [datadir CONFG.getProp([cfPfx 'HMCfile_dataInput'])];
%
%     HMCparams.N = CONFG.getPropInt([cfPfx 'HMC_N']);
    end
    
end



