function LiquidityStudy(configfile)
    
    global LOG;
    global CONFG;
    
    %% Read the config file into the CONFIG instance, and open the LOG:
    results.invocationTime = datestr(now, 'yyyymmdd-HHMM');
    initialize(configfile, [mfilename '.log']);
    
    LOG.info('');
    LOG.info('==========================================================');
    LOG.info('Running LiquidityStudy');
    LOG.info('----------------------------------------------------------');
        
    % Define parallelization setup, if needed
    results = parallel_config(results);
    
    %% TRACE bonds
    LOG.info('');
    LOG.info('----------------------------------------------------------');
    LOG.info('TRACE corporate bond data');
    LOG.info('----------------------------------------------------------');
    if (CONFG.getPropBoolean('LIQ.TRACE.DoTRACE'))
        tic0 = tic;
        fprintf('Running do_trace()\n');
        results = do_trace(results);
        LOG.info(sprintf('do_trace() took %7.4f secs', toc(tic0)));
    end
    
    %% CRSP equities
    LOG.info('');
    LOG.info('----------------------------------------------------------');
    LOG.info('CRSP domestic equities data');
    LOG.info('----------------------------------------------------------');
    if (CONFG.getPropBoolean('LIQ.CRSP.DoCRSP'))
        tic0 = tic;
        fprintf('Running crsp_dbsql2localcache()\n');
        %results = do_crsp(results);
        crsp_dbsql2localcache(configfile, testspec_only)
        LOG.info(sprintf('crsp_dbsql2localcache(): %7.4f secs',toc(tic0)));
    end
    
    %% VIX futures
    LOG.info('');
    LOG.info('----------------------------------------------------------');
    LOG.info('VIX volatility futures data');
    LOG.info('----------------------------------------------------------');
    if (CONFG.getPropBoolean('LIQ.VIX.DoVIX'))
        tic0 = tic;
        fprintf('Running do_vix()\n');
        results = do_vix(results);
        LOG.info(sprintf('do_vix() took %7.4f secs', toc(tic0)));
    end
    
    %% VIX futures
    LOG.info('');
    LOG.info('----------------------------------------------------------');
    LOG.info('WTI oil futures data');
    LOG.info('----------------------------------------------------------');
    if (CONFG.getPropBoolean('LIQ.WTI.DoWTI'))
        tic0 = tic;
        fprintf('Running do_wti()\n');
        results = do_wti(results);
        LOG.info(sprintf('do_wti() took %7.4f secs', toc(tic0)));
    end
    
    %% Ta-da
    LOG.info('');
    LOG.info('----------------------------------------------------------');
    LOG.info('Finished LiquidityStudy');
    LOG.info('==========================================================');
    LOG.info('==========================================================');
end


