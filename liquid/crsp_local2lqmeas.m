function RSLT = crsp_local2lqmeas(configfile)

    global LOG;
    global CONFG;

    % Read the CONFG, initialize paths, and set up the LOG
    RSLT = initialize(configfile, [mfilename '.log']);
    
    LOG.info('');
    LOG.info('----------------------------------------------------------');
    LOG.info(sprintf('Running %s', mfilename));
    LOG.info(sprintf('  configfile:    %s', configfile));
    LOG.info('----------------------------------------------------------');

    cfPfx = 'LIQ.CRSP.lqmeas.';
    
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
    RSLT.startdate = CONFG.getPropInt('LIQ.CRSP.startdate');
    RSLT.stopdate = CONFG.getPropInt('LIQ.CRSP.stopdate');
    
    % Pull the data into the input cache
    cachename_in = CONFG.getProp('LIQ.CRSP.local.cachename');
    RSLT.cachefile_in = [pwd filesep RSLT.cacheDir filesep cachename_in];
    LOG.warn(sprintf('Input cache: %s', RSLT.cachefile_in));
    
    testspec = crsp_testcache_local();
    [CACHE_IN, valid] = cache_valid(RSLT.cachefile_in, testspec);
    if (valid)
        LOG.info('Input cache is valid');
    else
        errmsg = 'INPUT CACHE FAILED INTEGRITY CHECKS - TERMINATING';
        LOG.err(errmsg);
        error('OFRresearch:LIQ:CorruptCacheCRSP', [errmsg '\n']);
    end
    
    %% Build SIC-based samples
    
    LOG.info('');
    LOG.info('Identifying the CRSP samples based on 1-digit SIC');

    % Semicolon-delimited string of SIC codes to consider
    RSLT.SIClist = CONFG.getProp([cfPfx 'SIClist']);
    SIClist = strsplit(RSLT.SIClist,';');
    RSLT.SICcount = length(SIClist);
    
    % Create the TxN matrix of two-digit SIC codes, and round non-fin'ls
    sic = floor(CACHE_IN.data.vals.SICCD/100);
    sic(sic<60) = floor(sic(sic<60)/10)*10;
    sic(sic>69) = floor(sic(sic>69)/10)*10; 
    % Reduce it to a 1xN vector based on the modal values in each column
    sic = mode(sic);

    % sicmap starts as a simple vector of column indexes, [1 2 3 ... N]
    sicmap = 1:1:length(CACHE_IN.data.ids.PERMNO); 
         
    LOG.info(sprintf('There are %d SIC codes requested', RSLT.SICcount));
    CACHE.data.SAM_SIC=NaN(RSLT.SICcount, 1);
    CACHE.data.SAM_DATES=cell(RSLT.SICcount, 1);
    CACHE.data.SAM_ID=cell(RSLT.SICcount, 1);
    CACHE.data.SAM_VOL=cell(RSLT.SICcount, 1);
    CACHE.data.SAM_RET=cell(RSLT.SICcount, 1);
    CACHE.data.SAM_BID=cell(RSLT.SICcount, 1);
    CACHE.data.SAM_ASK=cell(RSLT.SICcount, 1);
    CACHE.data.SAM_SHR=cell(RSLT.SICcount, 1);
    CACHE.data.SAM_PRC=cell(RSLT.SICcount, 1);
    t = find(CACHE_IN.data.dates.vec>=RSLT.startdate, 1, 'first');
    T = find(CACHE_IN.data.dates.vec>=RSLT.stopdate, 1, 'last');
    for idx = 1:RSLT.SICcount
        i = str2double(SIClist{idx});
        CACHE.data.SAM_SIC(idx) = i;
        LOG.trace([' -- SIC ' SIClist{idx}]);
        % Pick the subset of sicmap indexes matching sic==i
        sicmap_i = sicmap(sic==i); 
        % Subset a vector, ids_i, with only PERMNOs that match sic==i
        % NOTE!! sicmap indexes by SIC code (0-9), but cell arrays are 1-10
        CACHE.data.SAM_ID{idx} = CACHE_IN.data.ids.PERMNO(sicmap_i);
        CACHE.data.SAM_DATES{idx} = CACHE_IN.data.dates.vec(t:T);
        % Similarly subset the columns of the vals matrixes
        CACHE.data.SAM_VOL{idx} = CACHE_IN.data.vals.VOL(t:T,sicmap_i);
        CACHE.data.SAM_RET{idx} = CACHE_IN.data.vals.RET(t:T,sicmap_i);
        CACHE.data.SAM_BID{idx} = CACHE_IN.data.vals.BID(t:T,sicmap_i);
        CACHE.data.SAM_ASK{idx} = CACHE_IN.data.vals.ASK(t:T,sicmap_i);
        CACHE.data.SAM_SHR{idx} = CACHE_IN.data.vals.SHROUT(t:T,sicmap_i);
        CACHE.data.SAM_PRC{idx} = CACHE_IN.data.vals.PRC(t:T,sicmap_i);
        % CRSP shows stale prices at the close with a minus sign; fix it:
        CACHE.data.SAM_PRC{idx} = abs(CACHE.data.SAM_PRC{idx});
    end
    clear i sicmap_i;

    %% Calculate liquidity measures
    
    LOG.info('');
    LOG.info('..........................................................');
    LOG.info('Calculating liquidity measures for CRSP');
    LOG.info('..........................................................');
    
    tictime = tic;
    
    RSLT.metrics = CONFG.getProp([cfPfx 'metrics']);
    RSLT.parallel_cores = CONFG.getPropInt([cfPfx 'CRSP_parallel_cores']);
    metrics_list = strsplit(RSLT.metrics,';');
    
    RSLT.job_count = length(metrics_list)*RSLT.SICcount;
    LOG.info(sprintf('Proposed job count is: %d workers', RSLT.job_count));

    RSLT.parcores = min(RSLT.job_count, RSLT.parallel_cores);
    LOG.info(sprintf('Actual worker count is: %d workers', RSLT.parcores));

    % Because we cannot nest the parfor loop (if we use it), we need to 
    % unpack the program of SICs x metrics into a one-dimensional list, so
    % we can loop at only one level. The four columns of the ensemble are: 
    %    1.  One-digit SIC code, as a string ('0', '1', ..., '9')
    %    2.  Metric to calculate, as a string token (e.g., 'TURN', etc.)
    %    3.  Calculated metric value(s), as a struct
    %    4.  Time required for the calculations, as a float
    RSLT.liqmeas.ensemble = cell(RSLT.job_count, 5);
    for i = 1:RSLT.SICcount
        for m = 1:length(metrics_list)
            row = (i-1)*length(metrics_list) + m;
            RSLT.liqmeas.ensemble{row, 1} = SIClist{i};
            RSLT.liqmeas.ensemble{row, 2} = metrics_list{m};
            RSLT.liqmeas.ensemble{row, 5} = num2str(i);
        end
    end
    
    % Build some arrays to hold the liquidity measures as they're 
    % calculated -- one row per possible SIC code: 0-9
    CACHE.liqmeas.KLAM = cell(RSLT.SICcount, 1);
    CACHE.liqmeas.ROLL = cell(RSLT.SICcount, 1);
    CACHE.liqmeas.LVOL = cell(RSLT.SICcount, 1);
    CACHE.liqmeas.MINVx = cell(RSLT.SICcount, 1);
    CACHE.liqmeas.MINV1 = cell(RSLT.SICcount, 1);
    CACHE.liqmeas.MINV2 = cell(RSLT.SICcount, 1);
    CACHE.liqmeas.MART = cell(RSLT.SICcount, 1);
    CACHE.liqmeas.TURN = cell(RSLT.SICcount, 1);
    CACHE.liqmeas.BIDASK = cell(RSLT.SICcount, 1);
    
    paramMap = containers.Map('KeyType','char','ValueType','any');
    LOG.info('');
    LOG.info('Reading liquidity measure parameters');
    LOG.info(' -- for: KLAM');
    paramMap('KLAM') = readparam('KLAM');
    LOG.info(' -- for: ROLL');
    paramMap('ROLL') = readparam('ROLL');
    LOG.info(' -- for: LVOL');
    paramMap('LVOL') = readparam('LVOL');
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
%        matlabpool('open', RSLT.parcores);
        parpool('open', RSLT.parcores);
        
        % Make local, thread-safe copies for parfor
        ensemble_i = cell(RSLT.job_count, 1);
        ensemble_m = cell(RSLT.job_count, 1);
        ensemble_c = cell(RSLT.job_count, 1);
        ensemble_t = cell(RSLT.job_count, 1);
        ensemble_n = cell(RSLT.job_count, 1);
        for row = 1:RSLT.job_count
            ensemble_i{row,1} = RSLT.liqmeas.ensemble{row,1};
            ensemble_m{row,1} = RSLT.liqmeas.ensemble{row,2};
            ensemble_c{row,1} = RSLT.liqmeas.ensemble{row,3};
            ensemble_t{row,1} = RSLT.liqmeas.ensemble{row,4};
            ensemble_n{row,1} = RSLT.liqmeas.ensemble{row,5};
        end
        
        % Perform all of the liquidity calculations
        LOG.info('');
        LOG.info(sprintf('Launching %d parallel jobs over %d workers', ...
            RSLT.job_count, RSLT.parcores));
        parfor (row = 1:RSLT.job_count, RSLT.parcores)
            idxx = str2double(ensemble_n{row});
            met = ensemble_m{row};
            ticmet = tic;
            ensemble_c{row,1} = calc_liq(CACHE, paramMap, idxx, met);
            ensemble_t{row} = toc(ticmet);
            fprintf('Done: met=%s SIC=%s time=%7.4f\n', ...
                ensemble_m{row}, ensemble_i{row}, ensemble_t{row});
        end
        
        % Send an after-action report to the LOG, and tidy up
        LOG.info('');
        LOG.info('Reassembling parallelized calculations');
        LOG.info('------------------------------------------------------');
        for row = 1:RSLT.job_count
LOG.debug(['  -- Row:  ' num2str(row)]);
            LOG.info(sprintf('  Metric %s for SIC=%s took %7.4f secs', ...
                ensemble_m{row}, ensemble_i{row}, ensemble_t{row}));
            cmd = sprintf('CACHE.liqmeas.%s{%d} = ensemble_c{%d};', ...
                ensemble_m{row}, str2double(ensemble_n{row}), row);
            LOG.debug(['  -- Copying:  ' cmd]);
            eval(cmd);
            RSLT.liqmeas.ensemble{row,3} = ensemble_c{row};
            RSLT.liqmeas.ensemble{row,4} = ensemble_t{row};
        end
        clear idxx ensemble_i ensemble_m ensemble_c ensemble_t cmd pcores;

        LOG.warn('');
        LOG.warn(sprintf('Closing parallel pool with %d workers', ...
            RSLT.parcores));
%        matlabpool('close');
%        delete(gcp);
        delete(gcp('nocreate'));
        
    else 
        for row = 1:RSLT.job_count
            idxx = str2double(RSLT.liqmeas.ensemble{row, 1});
            met = RSLT.liqmeas.ensemble{row, 2};
            ticmet = tic;
            RSLT.liqmeas.ensemble{row, 3} = ...
                calc_liq(CACHE, paramMap, idxx, met);
            RSLT.liqmeas.ensemble{row, 4} = toc(ticmet);
            LOG.info(sprintf('  Metric %s for SIC=%d took %7.4f secs', ...
                met, idxx, RSLT.liqmeas.ensemble{row, 4}));
            cmd = sprintf(['CACHE.liqmeas.%s{%d} = ' ... 
                'RSLT.liqmeas.ensemble{%d, 3};'], met, idxx+1, row);
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
    CACHE.manifest.code.crsp_local2lqmeas = ...
        read_textfile_to_var('crsp_local2lqmeas.m');
    CACHE.manifest.code.crsp_testcache_local = ...
        read_textfile_to_var('crsp_testcache_local.m');
    CACHE.manifest.code.crsp_testcache_lqmeas = ...
        read_textfile_to_var('crsp_testcache_lqmeas.m');
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
    testspec = crsp_testcache_lqmeas();
    [~, valid] = cache_valid(RSLT.cachefile, testspec);
    if (valid)
        LOG.info('======================================================');
        LOG.info('Valid cache file');
        LOG.info([mfilename ' terminating successfully']);
        LOG.info('======================================================');
    else
        errmsg = 'CACHE FAILED INTEGRITY CHECKS - TERMINATING';
        LOG.err(errmsg);
        error('OFRresearch:LIQ:CorruptCacheCRSP', [errmsg '\n']);
    end
    
    LOG.close(); 
    clear LOG;
end 

function OUT = calc_liq(CACHE, paramMap, i, metric)
    %SAM_DATES = CACHE.data.SAM_DATES{i+1};
    SAM_VOL = CACHE.data.SAM_VOL{i};
    SAM_RET = CACHE.data.SAM_RET{i};
    SAM_BID = CACHE.data.SAM_BID{i};
    SAM_ASK = CACHE.data.SAM_ASK{i};
    SAM_SHR = CACHE.data.SAM_SHR{i};
    SAM_PRC = CACHE.data.SAM_PRC{i};
    switch metric
        case 'ROLL'   % Roll's implied bid-ask spread (Roll 1984)
            param = paramMap('ROLL');
            [OUT.roll, OUT.roll_avg, OUT.roll_med] = roll_implied_bidask(...
                SAM_PRC, ...
                param.estsize, param.min_estobs, param.poscov_rule);
        case 'LVOL' % Simple log volatility
            param = paramMap('LVOL');
            [OUT.lvol, OUT.lvol_avg, OUT.lvol_med] = log_volatility(...
                SAM_RET, ...
                param.estsize, param.min_estobs);
        case 'KLAM'   % Kyle's lambda (Kyle 1985)
            param = paramMap('KLAM');
            [OUT.klam, OUT.klam_avg, OUT.klam_med] = kyles_lambda(...
                SAM_RET, SAM_PRC, SAM_VOL, ...
                param.estsize, param.min_estobs);
        case 'MINV1'  % Microstructure invariant (Kyle & Obizhaeva 2013)
            param = paramMap('MINV1');
            [OUT.koln, OUT.koln_avg, OUT.koln_med] = microstruct_invar_2013(... 
                param, SAM_RET, SAM_PRC, SAM_VOL);
        case 'MINV2'  % Microstructure invariant (Kyle & Obizhaeva 2013)
            param = paramMap('MINV2');
            [OUT.kosq, OUT.kosq_avg, OUT.kosq_med] = microstruct_invar_2013(...
                param, SAM_RET, SAM_PRC, SAM_VOL);
        case 'AMIH'   % Amihud's absolute return to volume ratio (Amihud 2002)
            %param = paramMap('AMIH');
            [OUT.amih, OUT.amih_avg, OUT.amih_med] = absret_vol(...
                SAM_RET, SAM_VOL);
        case 'MART'   % Index of Martin 
            %param = paramMap('MART');
            [OUT.mart, OUT.mart_avg, OUT.mart_med] = martin_index(...
                SAM_PRC, SAM_VOL);
        case 'TURN'   % Turnover ratio
            %param = paramMap('TURN');
            [OUT.turn, OUT.turn_avg, OUT.turn_med] = turnover_ratio(...
                SAM_SHR, SAM_VOL);
        case 'BIDASK' % Simple bid-ask spread
            %param = paramMap('BIDASK');
            [OUT.bask, OUT.bask_avg, OUT.bask_med] = bidask(...
                SAM_BID, SAM_ASK);
        otherwise
            OUT.error = ['ERROR! UNRECOGNIZED METRIC: ' metric];
    end
end

