function RSLT = vixwti_local2lqmeas(configfile, VIXorWTI)

    global LOG;
    global CONFG;

    % Read the CONFG, initialize paths, and set up the LOG
    RSLT = initialize(configfile, [mfilename '.log']);
    
    LOG.info('');
    LOG.info('----------------------------------------------------------');
    LOG.info(sprintf('Running %s', mfilename));
    LOG.info(sprintf('  configfile:    %s', configfile));
    LOG.info('----------------------------------------------------------');

    cfPfx = ['LIQ.' VIXorWTI '.lqmeas.'];
    
    %% Check whether we really need to go through with a rebuild ...
    
    LOG.warn('');
    LOG.warn('Checking output cache');
    
    % Build the full path to the output cache file
    RSLT.benchmarkfile = [mfilename('fullpath') '.m'];
    RSLT.cachename = CONFG.getProp([cfPfx 'cachename']);
    RSLT.cache_timetest = CONFG.getPropBoolean([cfPfx 'cachetimetest']);
    RSLT.forcecache = CONFG.getPropBoolean([cfPfx 'forcecache']);
   
    % Test whether we need or want to rebuild the cache
    RSLT.cachepath = [pwd filesep RSLT.cacheDir];
	[RSLT.cachefile, RSLT.cachefile_xst, RSLT.cachefile_rebuild] = ...
        cache_uptodate(RSLT.cachepath, RSLT.cachename, ...
        RSLT.cache_timetest, RSLT.benchmarkfile, RSLT.forcecache);

    LOG.warn('');
    if (~RSLT.cachefile_rebuild)
        LOG.warn('======================================================');
        LOG.warn(['Terminating without building from: ' mfilename ':']);
        LOG.warn('======================================================');
        LOG.close(); 
        clear LOG;
        return;      % NOTE: ALTERNATE RETURN !!!
    end
    
    %% If we make it this far, we're going to (re-)build the cache
    
    % Load some basic config info
    RSLT.startdate = CONFG.getPropInt(['LIQ.' VIXorWTI '.startdate']);
    RSLT.stopdate = CONFG.getPropInt(['LIQ.' VIXorWTI '.stopdate']);
    
    % Pull the data into the input cache
    cachename_in = CONFG.getProp(['LIQ.' VIXorWTI '.local.cachename']);
    RSLT.cachefile_in = [pwd filesep RSLT.cacheDir filesep cachename_in];
    LOG.warn(sprintf('Input cache: %s', RSLT.cachefile_in));
    
    testspec = vixwti_testcache_local();
    [CACHE_IN, valid] = cache_valid(RSLT.cachefile_in, testspec);
    if (valid)
        LOG.info('Input cache is valid');
    else
        errmsg = 'INPUT CACHE FAILED INTEGRITY CHECKS - TERMINATING';
        LOG.err(errmsg);
        error('OFRresearch:LIQ:CorruptCacheVIXWTI', [errmsg '\n']);
    end
    
    %% Extracting chosen samples
    
    LOG.info('');
    LOG.info(['Extracting the ' VIXorWTI ' samples']);

    RSLT.sample_max = size(CACHE_IN.data.vals.RET, 2);
    LOG.info(sprintf('There are %d maturities', RSLT.sample_max));
    CACHE.data.SAM_DATES=cell(RSLT.sample_max, 1);
    CACHE.data.SAM_ID=cell(10, 1);
    CACHE.data.SAM_VOL=cell(RSLT.sample_max, 1);
    CACHE.data.SAM_RET=cell(RSLT.sample_max, 1);
    CACHE.data.SAM_PRC=cell(RSLT.sample_max, 1);
    t = find(CACHE_IN.data.dates.vec>=RSLT.startdate, 1, 'first');
    T = find(CACHE_IN.data.dates.vec>=RSLT.stopdate, 1, 'last');
    for idx = 1:RSLT.sample_max
        CACHE.data.SAM_ID{idx} = sprintf('%s_%d', VIXorWTI, idx);
        CACHE.data.SAM_DATES{idx} = CACHE_IN.data.dates.vec(t:T);
        CACHE.data.SAM_VOL{idx} = CACHE_IN.data.vals.VOL(t:T,idx);
        CACHE.data.SAM_RET{idx} = CACHE_IN.data.vals.RET(t:T,idx);
        CACHE.data.SAM_PRC{idx} = CACHE_IN.data.vals.PRC(t:T,idx);
    end
    clear idx;

    %% Calculate liquidity measures
    
    LOG.info('');
    LOG.info('..........................................................');
    LOG.info(['Calculating liquidity measures for ' VIXorWTI]);
    LOG.info('..........................................................');
    
    tictime = tic;
    
    RSLT.metrics = CONFG.getProp([cfPfx 'metrics']);
    RSLT.parallel_cores = CONFG.getPropInt([cfPfx 'parallel_cores']);
    metrics_list = strsplit(RSLT.metrics,';');
    
    RSLT.job_count = length(metrics_list)*RSLT.sample_max;
    LOG.info(sprintf('Proposed job count is: %d jobs', RSLT.job_count));

    RSLT.parcores = min(RSLT.job_count, RSLT.parallel_cores);
    LOG.info(sprintf('Actual worker count is: %d workers', RSLT.parcores));

    % Because we cannot nest the parfor loop (if we use it), we need to 
    % unpack the program of maturities x metrics into a list, so
    % we can loop at only one level. The four columns of the ensemble are: 
    %    1.  Futures contract maturity, as a string ('0', '1', ..., '9')
    %    2.  Metric to calculate, as a string token (e.g., 'MINV1', etc.)
    %    3.  Calculated metric value(s), as a struct
    %    4.  Time required for the calculations, as a float
    RSLT.liqmeas.ensemble = cell(RSLT.job_count, 4);
    for i = 1:RSLT.sample_max
        for m = 1:length(metrics_list)
            row = (i-1)*length(metrics_list) + m;
            RSLT.liqmeas.ensemble{row, 1} = num2str(i);
            RSLT.liqmeas.ensemble{row, 2} = metrics_list{m};
        end
    end
    
    % Build some arrays to hold the liquidity measures as they're 
    % calculated -- one row per possible maturity
    CACHE.liqmeas.KLAM = cell(RSLT.sample_max, 1);
    CACHE.liqmeas.MINVx = cell(RSLT.sample_max, 1);
    CACHE.liqmeas.MINV1 = cell(RSLT.sample_max, 1);
    CACHE.liqmeas.MINV2 = cell(RSLT.sample_max, 1);
    
    paramMap = containers.Map('KeyType','char','ValueType','any');
    LOG.info('');
    LOG.info('Reading liquidity measure parameters');
    LOG.info(' -- for: KLAM');
    paramMap('KLAM') = readparam('KLAM');
    LOG.info(' -- for: MINVx');
    paramMap('MINVx') = readparam('MINVx');
    LOG.info(' -- for: MINV1');
    paramMap('MINV1') = readparam('MINV1');
    LOG.info(' -- for: MINV2');
    paramMap('MINV2') = readparam('MINV2');
    
    if (RSLT.parallel_cores > 0)
        LOG.warn('');
        LOG.warn(sprintf('Opening parallel pool with %d workers', ...
            RSLT.parcores));
        matlabpool('open', RSLT.parcores);
        
        % Make local, thread-safe copies for parfor
        ensemble_i = cell(RSLT.job_count, 1);
        ensemble_m = cell(RSLT.job_count, 1);
        ensemble_c = cell(RSLT.job_count, 1);
        ensemble_t = cell(RSLT.job_count, 1);
        for row = 1:RSLT.job_count
            ensemble_i{row,1} = RSLT.liqmeas.ensemble{row,1};
            ensemble_m{row,1} = RSLT.liqmeas.ensemble{row,2};
            ensemble_c{row,1} = RSLT.liqmeas.ensemble{row,3};
            ensemble_t{row,1} = RSLT.liqmeas.ensemble{row,4};
        end
        
        % Perform all of the liquidity calculations
        LOG.info('');
        LOG.info(sprintf('Launching %d parallel jobs over %d workers', ...
            RSLT.job_count, RSLT.parcores));
        parfor (row = 1:RSLT.job_count, RSLT.parcores)
            idxx = str2double(ensemble_i{row});
            met = ensemble_m{row};
            ticmet = tic;
            ensemble_c{row,1} = calc_liq(CACHE, paramMap, idxx, met);
            ensemble_t{row} = toc(ticmet);
            fprintf('Done: met=%s maturity=%s time=%7.4f\n', ...
                ensemble_m{row}, ensemble_i{row}, ensemble_t{row});
        end
        
        % Send an after-action report to the LOG, and tidy up
        LOG.info('');
        LOG.info('Reassembling parallelized calculations');
        LOG.info('------------------------------------------------------');
        for row = 1:RSLT.job_count
            LOG.info(sprintf(' Metric %s, maturity=%s took %7.4f secs', ...
                ensemble_m{row}, ensemble_i{row}, ensemble_t{row}));
            cmd = sprintf('CACHE.liqmeas.%s{%d} = ensemble_c{%d};', ...
                ensemble_m{row}, str2double(ensemble_i{row}), row);
            LOG.debug(['  -- Copying:  ' cmd]);
            eval(cmd);
            RSLT.liqmeas.ensemble{row,3} = ensemble_c{row};
            RSLT.liqmeas.ensemble{row,4} = ensemble_t{row};
        end
        clear idxx ensemble_i ensemble_m ensemble_c ensemble_t cmd pcores;

        LOG.warn('');
        LOG.warn(sprintf('Closing parallel pool with %d workers', ...
            RSLT.parcores));
        matlabpool('close');
        delete(gcp);
        
    else 
        for row = 1:RSLT.job_count
            idxx = str2double(RSLT.liqmeas.ensemble{row, 1});
            met = RSLT.liqmeas.ensemble{row, 2};
            ticmet = tic;
            RSLT.liqmeas.ensemble{row, 3} = ...
                calc_liq(CACHE, paramMap, idxx, met);
            RSLT.liqmeas.ensemble{row, 4} = toc(ticmet);
            LOG.info(sprintf(' Metric %s, maturity=%s took %7.4f secs', ...
                met, idxx, RSLT.liqmeas.ensemble{row, 4}));
            cmd = sprintf(['CACHE.liqmeas.%s{%d} = ' ... 
                'RSLT.liqmeas.ensemble{%d, 3};'], met, idxx, row);
            LOG.debug(['  -- Copying:  ' cmd]);
            eval(cmd);
        end
    end

    LOG.info('');
    LOG.info('..........................................................');
    time_elapsed = toc(tictime);
    LOG.info(sprintf('Liquidity metrics took %7.4f secs (%7.4f min)', ...
        time_elapsed, time_elapsed/60));
    LOG.info('..........................................................');

    %% Saving the CACHE to disk

    LOG.info('');

    % Pull the data into the input cache
    cachename = CONFG.getProp([cfPfx 'cachename']);
    RSLT.cachefile = [pwd filesep RSLT.cacheDir filesep cachename];
    LOG.info(['Caching output in ' mfilename '.m']);
    LOG.info(sprintf(' -- cachefile: %s', RSLT.cachefile));

    % Assembling a manifest
    CACHE.manifest.startdate = RSLT.startdate;
    CACHE.manifest.stopdate = RSLT.stopdate;
    CACHE.manifest.code.CONFG = read_textfile_to_var(configfile);
    CACHE.manifest.code.vixwti_local2lqmeas = ...
        read_textfile_to_var('vixwti_local2lqmeas.m');
    CACHE.manifest.code.vixwti_testcache_local = ...
        read_textfile_to_var('vixwti_testcache_local.m');
    CACHE.manifest.code.vixwti_testcache_lqmeas = ...
        read_textfile_to_var('vixwti_testcache_lqmeas.m');
    CACHE.manifest.code.readparam = read_textfile_to_var('readparam.m');
    LOG.warn(sprintf('Caching log file to: %s', RSLT.cachefile));
    CACHE.manifest.code.LOG = read_textfile_to_var(RSLT.logfile);

    % Save the CACHE
    LOG.warn('');
    LOG.warn('----------------------------------------------------------');
    LOG.warn(sprintf('Saving cache to file: %s', RSLT.cachefile));
    LOG.warn('----------------------------------------------------------');
    save(RSLT.cachefile, '-struct', 'CACHE', '-v7.3');
    
    %% Finishing up
    
    % Save the accumulated results (RSLT) to a file
    RSLT.RSLTname = CONFG.getProp([cfPfx 'RSLTname']);
    RSLT.RSLTfile = [RSLT.buildDir filesep RSLT.RSLTname];
    LOG.warn('');
    LOG.warn(sprintf('Saving results to file: %s', RSLT.RSLTfile));
    save(RSLT.RSLTfile, '-struct', 'RSLT', '-v7.3');

    % Test the saved CACHE
    testspec = vixwti_testcache_lqmeas();
    [~, valid] = cache_valid(RSLT.cachefile, testspec);
    if (valid)
        LOG.info('======================================================');
        LOG.info('Valid cache file');
        LOG.info([mfilename ' (' VIXorWTI ') terminating successfully']);
        LOG.info('======================================================');
    else
        errmsg = 'CACHE FAILED INTEGRITY CHECKS - TERMINATING';
        LOG.err(errmsg);
        error('OFRresearch:LIQ:CorruptCacheVIXWTI', [errmsg '\n']);
    end
    
    LOG.close(); 
    clear LOG;
end 

function OUT = calc_liq(CACHE, paramMap, i, metric)
    SAM_DATES = CACHE.data.SAM_DATES{i};
    SAM_VOL = CACHE.data.SAM_VOL{i};
    SAM_RET = CACHE.data.SAM_RET{i};
    SAM_PRC = CACHE.data.SAM_PRC{i};
    switch metric
        case 'KLAM'   % Kyle's lambda (Kyle 1985)
            param = paramMap('KLAM');
            [OUT.klambdas, OUT.kdates] = kyles_lambda(...
                SAM_RET, SAM_PRC, SAM_VOL, SAM_DATES, param);
        case 'MINVx'   % Microstructure invariant (Kyle & Obizhaeva 2011)
            param = paramMap('MINVx');
            [OUT.avgCost, OUT.medCost] = microstruct_invar_2011( ...
                param, SAM_RET, SAM_PRC, SAM_VOL);
        case 'MINV1'   % Microstructure invariant (Kyle & Obizhaeva 2013)
            param = paramMap('MINV1');
            [OUT.cost, OUT.avgCost, OUT.medCost] = ...
                microstruct_invar_2013(param, SAM_RET, SAM_PRC, SAM_VOL);
        case 'MINV2'   % Microstructure invariant (Kyle & Obizhaeva 2013)
            param = paramMap('MINV2');
            [OUT.cost, OUT.avgCost, OUT.medCost] = ... 
                microstruct_invar_2013(param, SAM_RET, SAM_PRC, SAM_VOL);
%         case 'MART'   % Index of Martin 
%             %param = readparam('MART');
%             [OUT.MLI_avg, OUT.MLI_med] = martin_index(...
%                 SAM_PRC, SAM_VOL.*SAM_PRC);
%         case 'TURN'   % Turnover ratio
%             %param = readparam('TURN');
%             [OUT.TR, OUT.TR_avg, OUT.TR_med] = turnover_ratio(...
%                 SAM_SHR, SAM_VOL);
%         case 'BIDASK'   % Turnover ratio
%             %param = readparam('BIDASK');
%             [OUT.BidAsk, OUT.BidAsk_avg, OUT.BidAsk_med] = bidask(...
%                 SAM_BID, SAM_ASK);
        otherwise
            OUT.error = ['ERROR! UNRECOGNIZED METRIC: ' metric];
    end
end

