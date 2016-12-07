function RSLT = trace_local2lqmeas(configfile)
%  Required configuration parameters, to be defined in configfile:
%     output_directory               (string)
%     cache_directory                (string)
%     input_directory_win            (string)
%     input_directory_lin            (string)
%     search_path                    (string)
%     LIQ.TRACE.startdate            (int)
%     LIQ.TRACE.stopdate             (int)
%     LIQ.TRACE.local.cachename      (string)
%     LIQ.TRACE.local.cachetimetest  (boolean)
%     LIQ.TRACE.local.forcecache     (boolean)
%     LIQ.TRACE.local.RSLTname       (string)
%     LIQ.TRACE.local.minPrice       (double)
%     LIQ.TRACE.local.maxPrice       (double)
%     LIQ.TRACE..cachedir

    global LOG;
    global CONFG;

    % Read the CONFG, initialize paths, and set up the LOG
    RSLT = initialize(configfile, [mfilename '.log']);
    
    LOG.info('');
    LOG.info('----------------------------------------------------------');
    LOG.info(sprintf('Running %s', mfilename));
    LOG.info(sprintf('  configfile:    %s', configfile));
    LOG.info('----------------------------------------------------------');

    cfPfx = 'LIQ.TRACE.lqmeas.';
    
    %% Check whether we really need to go through with a rebuild ...
    
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
    RSLT.startdate = CONFG.getPropInt('LIQ.TRACE.startdate');
    RSLT.stopdate = CONFG.getPropInt('LIQ.TRACE.stopdate');
    
    % Pull the data into the input cache
    cachename_in = CONFG.getProp('LIQ.TRACE.local.cachename');
    RSLT.cachefile_in = [pwd filesep RSLT.cacheDir filesep cachename_in];
    LOG.warn(sprintf('Input cache: %s', RSLT.cachefile_in));
    
    testspec = trace_testcache_local();
    [CACHE_IN, valid] = cache_valid(RSLT.cachefile_in, testspec);
    if (valid)
        LOG.info('Input cache is valid');
    else
        errmsg = 'INPUT CACHE FAILED INTEGRITY CHECKS - TERMINATING';
        LOG.err(errmsg);
        error('OFRresearch:LIQ:CorruptCacheTRACE', [errmsg '\n']);
    end
    
     %% If we make it this far, we're going to (re-)build the cache
%     
%     % Load some basic config info
%     RSLT.startdate = CONFG.getPropInt('LIQ.TRACE.startdate');
%     RSLT.stopdate = CONFG.getPropInt('LIQ.TRACE.stopdate');
%     
%     % Pulling the data
%     LOG.info('');
%     LOG.info('Pulling the TRACE data');
% 
%     % Pull the data into the cache
%     LOG.info('');
%     LOG.info(['Caching data in ' mfilename '.m']);
%     LOG.info(sprintf(' -- cachefile: %s', RSLT.cachefile));
% 
%     LOG.info('');
%     LOG.info('Identifying the TRACE samples Investment Grade');
%     
%     RSLT.CSVdir = CONFG.getProp('LIQ.TRACE.local.cachedir');
%     RSLT.CSVfile = CONFG.getProp('LIQ.TRACE.local.csvfile');
%     RSLT.CSVfile = CONFG.getProp('LIQ.TRACE.local.csvfile');
%     RSLT.CSVfile = CONFG.getProp('LIQ.TRACE.local.csvfile');
% 
%     % Read Text Files from Repository
%     RSLT.CSVcfg.ALL_file = [RSLT.CSVdir filesep RSLT.CSVfile];
%     RSLT.CSVcfg.BONDID_file = [RSLT.CSVdir filesep 'bondid_non.csv'];
%     RSLT.CSVcfg.DATES_file = [RSLT.CSVdir filesep 'dates_non.csv'];
%     RSLT.CSVcfg.PRC_file = [RSLT.CSVdir 'prc_non.csv'];
%     RSLT.CSVcfg.VOL_file = [RSLT.CSVdir 'vol_non.csv'];
%     RSLT.CSVcfg.CRS_file = [RSLT.CSVdir 'crs_non.csv'];
%     RSLT.CSVcfg.CRM_file = [RSLT.CSVdir 'crm_non.csv'];
%     RSLT.CSVcfg.CRF_file = [RSLT.CSVdir 'crf_non.csv'];
%     RSLT.CSVcfg.DATES_file;
%     % Create the CACHE
%     CACHE.data = makeCache(RSLT.CSVcfg);
%     
%     % Assembling a manifest and save the CACHE
%     LOG.warn('');
%     LOG.warn('----------------------------------------------------------');
%     LOG.warn(sprintf('Caching log file to: %s', RSLT.cachefile));
%     LOG.warn('----------------------------------------------------------');
%     CACHE.manifest = build_manifest(RSLT, configfile);
%     save(RSLT.cachefile, '-struct', 'CACHE', '-v7.3');
    
    
    %% Build investment-grade-based samples
    
    T = length(CACHE_IN.data.dates.vec);
    Nraw = length(CACHE_IN.data.ids.BONDID);
    bondport_dates = CACHE_IN.data.dates.vec;

    LOG.info('');
    LOG.info(sprintf('Pooling bonds based on Investment Grade'));

    % Credit grade numerical values (matrices CGx):
    % Investment Grade - Prime                       = 11
    % Investment Grade - High Grade                  = 12
    % Investment Grade - Upper Medium Grade          = 13
    % Investment Grade - Lower Medium Grade          = 14
    % High Yield - Non Investment Grade Speculative  = 21
    % High Yield - Highly Speculative                = 22
    % High Yield - Substantial Risks                 = 23
    % High Yield - Extremely Speculative             = 24
    % High Yield - Default Imminent                  = 25
    % High Yield - In Default                        = 26
    % Unknown/Unrated                                = 30
%     data_gradecode = [11,12,13,14,21,22,23,24,25,26,30];

    % Create a Tx4 matrix, for four rating grade partitions:
    %   Investment Grade - Prime   = 11
    %   Investment Grade - Other   = 12-14
    %   High Yield - All grades    = 21-26
    %   Unknown/Unrated            = 30

    % Hard-coding the grades:
    RSLT.gradelist = {'IG-Prime', 'IG-Other', 'Junk', 'Unrated'};
    RSLT.gradecount = length(RSLT.gradelist);

    RSLT.minPrice = CONFG.getPropInt('LIQ.TRACE.local.minPrice');
    RSLT.maxPrice = CONFG.getPropInt('LIQ.TRACE.local.maxPrice');
    
    % Aggregate bonds cross-sectionally into ratings-grade portfolios
%     clust_grademap = 1:1:length(gradepool);
    bondport_PRC = nan(T, RSLT.gradecount);
    bondport_VOL = nan(T, RSLT.gradecount);
    % We will keep track of how many distinct bonds fall into each 
    % bucket here, in RSLT.clust_grades_bondct (noting that each bond could
    % be reclassified each day):
    bondport_cnt = nan(T, RSLT.gradecount);
%     bondport_CGc = nan(size(data_CGc,1), length(RSLT.clust_grades));
%     datapool_BONDID = nan(1, length(RSLT.clust_grades));
    for t = 1:T
        today_PRC = CACHE_IN.data.vals.PRC(t,:);
        today_VOL = CACHE_IN.data.vals.VOL(t,:);
        today_CGc = CACHE_IN.data.vals.CGc(t,:);
        today_PRC(today_PRC>RSLT.maxPrice) = NaN;
        today_PRC(today_PRC<RSLT.minPrice) = NaN;
        for idx = 1:RSLT.gradecount
            switch idx
                case 1
                    %   Investment Grade - Prime   = 11
                    PRC_grade_idx = today_PRC(today_CGc==11); 
                    VOL_grade_idx = today_VOL(today_CGc==11); 
                case 2
                    %   Investment Grade - Other   = 12-14
                    rangetest = boolean((today_CGc>11) .* (today_CGc<20));
                    PRC_grade_idx = today_PRC(rangetest); 
                    VOL_grade_idx = today_VOL(rangetest); 
                case 3
                    %   High Yield - All grades    = 21-26
                    rangetest = boolean((today_CGc>20) .* (today_CGc<30));
                    PRC_grade_idx = today_PRC(rangetest); 
                    VOL_grade_idx = today_VOL(rangetest); 
                case 4
                    %   Unknown/Unrated            = 30
                    PRC_grade_idx = today_PRC(today_CGc>29); 
                    VOL_grade_idx = today_VOL(today_CGc>29); 
            end
            bondport_cnt(t,idx) = length(PRC_grade_idx);
            bondport_VOL(t,idx) = nansum(VOL_grade_idx);
            bondport_PRC(t,idx) = nansum(PRC_grade_idx .* ...
                 VOL_grade_idx ./ bondport_VOL(t,idx));
        end
    end
    
    % Remove any holiday trading dates
    for t=T:-1:1
        if (isholiday(bondport_dates(t)))
            bondport_dates(t) = [];
            bondport_cnt(t,:) = [];
            bondport_VOL(t,:) = [];
            bondport_PRC(t,:) = [];
        end
    end
    
    clear CACHE_IN;
    
    LOG.info(sprintf('%d ratings grades requested', RSLT.gradecount));
    CACHE.data.SAM_DATES=cell(1, RSLT.gradecount);
%     CACHE.data.SAM_ID=cell(1, RSLT.gradecount);
    CACHE.data.SAM_VOL=cell(1, RSLT.gradecount);
    CACHE.data.SAM_RET=cell(1,RSLT.gradecount);
    CACHE.data.SAM_PRC=cell(1,RSLT.gradecount);
    t = find(bondport_dates>=RSLT.startdate, 1, 'first');
    T = find(bondport_dates>=RSLT.stopdate, 1, 'last');
    for idx = 1:RSLT.gradecount
%         i = str2double(gradelist{idx});
%         LOG.trace([' -- Grade ' gradelist{idx}]);
        % Pick the subset of grademap indexes matching grade==i
%         grademap_i = grademap(grade==i); 
        
        % Subset a vector, ids_i, with only PERMNOs that match grade==i
%         CACHE.data.SAM_ID{idx} = datapool_BONDID(sicmap_i);
        CACHE.data.SAM_DATES{idx} = bondport_dates(t:T);
%         % Similarly subset the columns of the vals matrixes
        CACHE.data.SAM_VOL{idx} = bondport_VOL(t:T,idx);
        CACHE.data.SAM_PRC{idx} = bondport_PRC(t:T,idx);
        
        % Calculate returns as daily log price relatives
        ctdat = size(CACHE.data.SAM_PRC{idx},1);
        ctids = size(CACHE.data.SAM_PRC{idx},2);
        CACHE.data.SAM_RET{idx} = NaN(ctdat, ctids);
        % Lagged prices (PRC0) and prices (PRC1)
        PRC0 = CACHE.data.SAM_PRC{idx}(1:ctdat-1);
        PRC1 = CACHE.data.SAM_PRC{idx}(2:ctdat);
        % Element-by-element calculation for the whole matrix
        CACHE.data.SAM_RET{idx}(2:ctdat) = log(PRC1./PRC0);
    end
    clear i idx grademap_i iii jjj PRC0 PRC1 ctdat ctids;

    %% Calculate liquidity measures
    
    LOG.info('');
    LOG.info('..........................................................');
    LOG.info('Calculating liquidity measures for TRACE');
    LOG.info('..........................................................');
    
    tictime = tic;
    
    RSLT.metrics = CONFG.getProp([cfPfx 'metrics']);
    RSLT.parallel_cores = CONFG.getPropInt([cfPfx 'parallel_cores_req']);
    metrics_list = strsplit(RSLT.metrics,';');
    
    RSLT.job_count = length(metrics_list)*RSLT.gradecount;
    LOG.info(sprintf('Proposed job count is: %d workers', RSLT.job_count));

    RSLT.parcores = min(RSLT.job_count, RSLT.parallel_cores);
    LOG.info(sprintf('Actual worker count is: %d workers', RSLT.parcores));

    % Because we cannot nest the parfor loop (if we use it), we need to 
    % unpack the program of grades x metrics into a one-dimensional list, so
    % we can loop at only one level. The four columns of the ensemble are: 
    %    1.  One-digit Investment Grade code, as a string ('0', '1', ..., '9')
    %    2.  Metric to calculate, as a string token (e.g., 'TURN', etc.)
    %    3.  Calculated metric value(s), as a struct
    %    4.  Time required for the calculations, as a float
    RSLT.liqmeas.ensemble = cell(RSLT.job_count, 4);
    for i = 1:RSLT.gradecount
        for m = 1:length(metrics_list)
            row = (i-1)*length(metrics_list) + m;
            RSLT.liqmeas.ensemble{row, 1} = i;
            RSLT.liqmeas.ensemble{row, 2} = metrics_list{m};
        end
    end
    
    % Build some arrays to hold the liquidity measures as they're 
    % calculated -- one row per ratings-grade bucket
    CACHE.liqmeas.KLAM = cell(RSLT.gradecount, 1);
    CACHE.liqmeas.ROLL = cell(RSLT.gradecount, 1);
    CACHE.liqmeas.LVOL = cell(RSLT.gradecount, 1);
    CACHE.liqmeas.MINVx = cell(RSLT.gradecount, 1);
    CACHE.liqmeas.MINV1 = cell(RSLT.gradecount, 1);
    CACHE.liqmeas.MINV2 = cell(RSLT.gradecount, 1);
    CACHE.liqmeas.MART = cell(RSLT.gradecount, 1);
    
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
        parpool(RSLT.parcores);

        % Make local, thread-safe copies so that parfor can slice
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
%             idxx = ensemble_i{row};
            met = ensemble_m{row};
            ticmet = tic;
            ensemble_c{row,1} = calc_liq(CACHE, paramMap, ensemble_i{row}, met);
            ensemble_t{row} = toc(ticmet);
            fprintf('Done: met=%s rating group=%d time=%7.4f\n', ...
                ensemble_m{row}, ensemble_i{row}, ensemble_t{row});
        end
%         ticmet = tic;
%         parfor (row = 1:RSLT.job_count, RSLT.parcores)
%             %ticmet = tic;
%             %idxx = str2double(ensemble_i{row,1});
%             %met = ensemble_m{row};
%             %ensemble_c{row,1} = calc_liq(CACHE_SUB, paramMap, idxx, met);
%             ensemble_c{row,1} = calc_liq(ensemble_DAT{row}, ...
%                 ensemble_VOL{row}, ensemble_RET{row}, ensemble_PRC{row}, ...
%                 ensemble_p{row}, str2double(ensemble_i{row}), ensemble_m{row});
%             ensemble_t{row} = toc(ticmet);
%             fprintf('Row=\t%d\t time=\t%7.4f\t met=\t%s\t SIC=\t%s\n', ...
%                 row, ensemble_t{row}, ensemble_m{row}, ensemble_i{row});
%         end
        
        % Send an after-action report to the LOG, and tidy up
        LOG.info('');
        LOG.info('Reassembling parallelized calculations');
        LOG.info('------------------------------------------------------');
        for row = 1:RSLT.job_count
            LOG.info(sprintf('  Metric %s for Grade=%s took %7.4f secs', ...
                ensemble_m{row}, ensemble_i{row}, ensemble_t{row}));
            cmd = sprintf('CACHE.liqmeas.%s{%d} = ensemble_c{%d};', ...
                ensemble_m{row}, ensemble_i{row}, row);
            LOG.debug(['  -- Copying:  ' cmd]);
            eval(cmd);
            RSLT.liqmeas.ensemble{row,3} = ensemble_c{row};
            RSLT.liqmeas.ensemble{row,4} = ensemble_t{row};
        end

        LOG.warn('');
        LOG.warn(sprintf('Closing parallel pool with %d workers', ...
            RSLT.parcores));
%         parpool('close');
        delete(gcp('nocreate'));
        
    else 
        for row = 1:RSLT.job_count
%             SAM_DATES = CACHE.data.SAM_DATES{idxx+1};
%             SAM_VOL = CACHE.data.SAM_VOL{idxx+1};
%             SAM_RET = CACHE.data.SAM_RET{idxx+1};
%             SAM_PRC = CACHE.data.SAM_PRC{idxx+1};
%             met = RSLT.liqmeas.ensemble{row, 2};
%             param = paramMap(met);
            ticmet = tic;
            RSLT.liqmeas.ensemble{row, 3} = calc_liq(ensemble_DAT{row}, ...
                ensemble_VOL{row}, ensemble_RET{row}, ensemble_PRC{row}, ...
                ensemble_n{row}, str2double(ensemble_i{row}), ensemble_m{row});
            RSLT.liqmeas.ensemble{row, 4} = toc(ticmet);
            idxx = str2double(ensemble_i{row});
            LOG.info(sprintf('  Metric %s for Grade=%d took %7.4f secs', ...
                ensemble_m{row}, idxx, RSLT.liqmeas.ensemble{row, 4}));
            cmd = sprintf(['CACHE.liqmeas.%s{%d} = ' ... 
                'RSLT.liqmeas.ensemble{%d, 3};'], ensemble_m{row}, idxx+1, row);
            LOG.debug(['  -- Copying:  ' cmd]);
            eval(cmd);
        end
    end
    clear idxx ensemble_i ensemble_m ensemble_c ensemble_t cmd pcores;
    clear ensemble_p ensemble_DAT ensemble_VOL ensemble_RET ensemble_PRC;

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
    CACHE.manifest.code.trace_local2lqmeas = ...
        read_textfile_to_var('trace_local2lqmeas.m');
    CACHE.manifest.code.trace_testcache_local = ...
        read_textfile_to_var('trace_testcache_local.m');
    CACHE.manifest.code.trace_testcache_lqmeas = ...
        read_textfile_to_var('trace_testcache_lqmeas.m');
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
    testspec = trace_testcache_lqmeas();
    [~, valid] = cache_valid(RSLT.cachefile, testspec);
    if (valid)
        LOG.info('======================================================');
        LOG.info('Valid cache file');
        LOG.info([mfilename ' terminating successfully']);
        LOG.info('======================================================');
    else
        errmsg = 'CACHE FAILED INTEGRITY CHECKS - TERMINATING';
        LOG.err(errmsg);
        error('OFRresearch:LIQ:CorruptCacheTRACE', [errmsg '\n']);
    end
    
    LOG.close(); 
    clear LOG;
end 

function OUT = calc_liq(CACHE, paramMap, i, metric)
    %SAM_DATES = CACHE.data.SAM_DATES{i+1};
    SAM_VOL = CACHE.data.SAM_VOL{i};
    SAM_RET = CACHE.data.SAM_RET{i};
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
        otherwise
            OUT.error = ['ERROR! UNRECOGNIZED METRIC: ' metric];
    end
end

% function manifest = build_manifest(RSLT, configfile)
%     manifest.startdate = RSLT.startdate;
%     manifest.stopdate = RSLT.stopdate;
%     manifest.code.CONFG = read_textfile_to_var(configfile);
%     manifest.code.trace_dbsql2local = ...
%         read_textfile_to_var('trace_csv2local.m');
%     manifest.code.trace_testcache_local = ...
%         read_textfile_to_var('trace_testcache_local.m');
%     manifest.code.LOG = read_textfile_to_var(RSLT.logfile);
% end

function SUBCACHE = makeCache(cfg)

    global LOG;

    tictime = tic;

%     data_BONDID = csvread(BONDID_NON);
%     data_DATES = csvread(DATES_NON);
%     data_PRC = csvread(PRC_NON,1,1);
%     data_VOL = csvread(VOL_NON,1,1);
%     data_CRS= importdata(CRS_NON,',');
%     data_CRM = importdata(CRM_NON,',');
%     data_CRF = importdata(CRF_NON,',');
    
    % Read in all the dates
    LOG.info('');
    LOG.info('CSV query for TRACE dates:');
    datavals = csvread(cfg.DATES_file, 1, 0);
    ctdat = length(datavals);
    LOG.info(sprintf('  Number of values retrieved: %d', ctdat));
    SUBCACHE.dates.vec = -1*ones(ctdat, 1);
    SUBCACHE.dates.rowMapDATE = ...
        containers.Map('KeyType','int32','ValueType','int32');
    for i=1:ctdat
        datint = int32(datavals(i));
        SUBCACHE.dates.vec(i) = datint;
        SUBCACHE.dates.rowMapDATE(datint) = i;
    end
    clear i datavals datint;
    
    % Read in all the various IDs
    LOG.info('');
    LOG.info('CSV query for TRACE ids:');
    fid=fopen(cfg.BONDID_file); 
    datavals = textscan(fid, '%s\n'); 
    fclose(fid);
    ctids = length(datavals{1})-1;
    LOG.info(sprintf('  Number of values retrieved: %d', ctids));
    SUBCACHE.ids.BONDID = cell(1, ctids);
    SUBCACHE.ids.colMapBONDID = ...
        containers.Map('KeyType','char','ValueType','int32');
    for i=2:ctids+1
        idi = datavals{1}{i};
        LOG.trace(sprintf('   - BONDID:      %s, col=%d', idi, i));
        SUBCACHE.ids.BONDID{i} = idi;
        SUBCACHE.ids.colMapBONDID(idi) = i;
    end
    clear i datavals idi;
    
    % Read in the PRC data
    LOG.info('');
    LOG.info('CSV query for TRACE PRC values:');
    
    % Set up the target arrays
    SUBCACHE.vals.PRC = nan(ctdat, ctids);
    SUBCACHE.vals.VOL = nan(ctdat, ctids);
    SUBCACHE.vals.VLD = nan(ctdat, ctids);
    SUBCACHE.vals.CRS = int8(nan(ctdat, ctids));
    SUBCACHE.vals.CGS = int8(nan(ctdat, ctids));
    SUBCACHE.vals.CDS = int16(nan(ctdat, ctids));
    SUBCACHE.vals.CRM = int8(nan(ctdat, ctids));
    SUBCACHE.vals.CGM = int8(nan(ctdat, ctids));
    SUBCACHE.vals.CDM = int16(nan(ctdat, ctids));
    SUBCACHE.vals.CRF = int8(nan(ctdat, ctids));
    SUBCACHE.vals.CGF = int8(nan(ctdat, ctids));
    SUBCACHE.vals.CDF = int16(nan(ctdat, ctids));
    SUBCACHE.vals.CGc = int8(nan(ctdat, ctids));
    
    % Read the IDs row in the CSV file into a single cell of a cell array
    fid = fopen(cfg.ALL_file);
    headrow = textscan(fid, '%s', 1, 'Delimiter','\n');
    headrow = textscan(headrow{1}{1},'%s','Delimiter',',');
    headrow = headrow{1};
    [kCUS,kDAT,kPRC,kVOL,kCRS,kCGS,kCDS,kCRM,kCGM,kCDM,kCRF,kCGF,kCDF] = findCols(headrow);
    LOG.info('  Selection columns: ');
    LOG.info(sprintf('   - cusip_id:        %d', kCUS)); 
    LOG.info(sprintf('   - trd_exctn_dt:    %d', kDAT)); 
    LOG.info(sprintf('   - rptd_pr:         %d', kPRC)); 
    LOG.info(sprintf('   - entrd_vol_qt:    %d', kVOL)); 
    LOG.info(sprintf('   - sp_rating:       %d', kCRS)); 
    LOG.info(sprintf('   - sp_gradenum:     %d', kCGS)); 
    LOG.info(sprintf('   - sp_datediff:     %d', kCDS)); 
    LOG.info(sprintf('   - moody_rating:    %d', kCRM)); 
    LOG.info(sprintf('   - moody_gradenum:  %d', kCGM)); 
    LOG.info(sprintf('   - moody_datediff:  %d', kCDM)); 
    LOG.info(sprintf('   - fitch_rating:    %d', kCRF)); 
    LOG.info(sprintf('   - fitch_gradenum:  %d', kCGF)); 
    LOG.info(sprintf('   - fitch_datediff:  %d', kCDF));
    LOG.info('');

    % Set up Moody's map
    SUBCACHE.vals.CRsetM = {'Aaa';'Aa1';'Aa2';'Aa3';'A1';'A2';'A3';
        'Baa1';'Baa2';'Baa3';'Ba1';'Ba2';'Ba3';'B1';'B2';'B3';
        'Caa1';'Caa2';'Caa3';'Ca';'C'};
    SUBCACHE.vals.CRmapM = containers.Map('KeyType','char','ValueType','int8');
    SUBCACHE.vals.CRmapM('') = 0;
    SUBCACHE.vals.CRmapM('NR') = 0;
    SUBCACHE.vals.CRmapM('not rated') = 0;
    for i = 1:size(SUBCACHE.vals.CRsetM,1)
        SUBCACHE.vals.CRmapM(SUBCACHE.vals.CRsetM{i}) = i;
    end
    % Set up S&P map
    SUBCACHE.vals.CRsetS = {'AAA';'AA+';'AA';'AA-';'A+';'A';'A-';
        'BBB+';'BBB';'BBB-';'BB+';'BB';'BB-';'B+';'B';'B-';
        'CCC+';'CCC';'CCC-';'CC';'C';'D';};
    SUBCACHE.vals.CRmapS = containers.Map('KeyType','char','ValueType','int8');
    SUBCACHE.vals.CRmapS('') = 0;
    SUBCACHE.vals.CRmapS('NR') = 0;
    SUBCACHE.vals.CRmapS('not rated') = 0;
    for i = 1:size(SUBCACHE.vals.CRsetS,1)
        SUBCACHE.vals.CRmapS(SUBCACHE.vals.CRsetS{i}) = i;
    end
    % Set up Fitch map
    SUBCACHE.vals.CRsetF = {'AAA';'AA+';'AA';'AA-';'A+';'A';'A-';
        'BBB+';'BBB';'BBB-';'BB+';'BB';'BB-';'B+';'B';'B-';
        'CCC';'DDD';'DD';'D';};
    SUBCACHE.vals.CRmapF = containers.Map('KeyType','char','ValueType','int8');
    SUBCACHE.vals.CRmapF('') = 0;
    SUBCACHE.vals.CRmapF('NR') = 0;
    SUBCACHE.vals.CRmapF('not rated') = 0;
    for i = 1:size(SUBCACHE.vals.CRsetF,1)
        SUBCACHE.vals.CRmapF(SUBCACHE.vals.CRsetF{i}) = i;
    end

%     nextrow = read_nextrow(fid);
    fmt = '%s %d %s %f %d %s %s %d8 %d %s %s %d8 %d %s %s %d8 %d %d8';
    nextrow = textscan(fid, '%s', 1, 'Delimiter','\n');
    nextrow = textscan(nextrow{1}{1}, fmt, 'Delimiter', ',');
%     nextrow = nextrow{1};
    lagCUS = nextrow{kCUS}; 
    lagDAT = nextrow{kDAT}; 
    lagPRC = nextrow{kPRC}; 
    lagVOL = nextrow{kVOL}; 
    lagCGM(nextrow{kCGM}>0) = nextrow{kCGM}; 
    lagCRM = nextrow{kCRM}; 
    lagCDM = nextrow{kCDM}; 
    lagCGS(nextrow{kCGS}>0) = nextrow{kCGS}; 
    lagCRS = nextrow{kCRS}; 
    lagCDS = nextrow{kCDS}; 
    lagCGF(nextrow{kCGF}>0) = nextrow{kCGF}; 
    lagCRF = nextrow{kCRF}; 
    lagCDF = nextrow{kCDF};
    lagCGc = pecking_order(lagCGM, lagCGS, lagCGF);
%     lagCGc(nextrow{kCGc}>0) = nextrow{kCGc}; 
    lagVLD = lagPRC * lagVOL;
    while ~feof(fid)
        nextrow = textscan(fid, '%s', 1, 'Delimiter','\n');
        nextrow = textscan(nextrow{1}{1}, fmt, 'Delimiter', ',');
%         nextrow = nextrow{1};
%         nextrow = read_nextrow(fid);
        CUS = nextrow{kCUS}; 
        DAT = nextrow{kDAT}; 
        PRC = nextrow{kPRC}; 
        VOL = nextrow{kVOL}; 
        if (strcmp(CUS,lagCUS) && DAT==lagDAT)
            % Accumulate volume and dollar volume over the day:
            lagVOL = lagVOL + VOL;
            lagVLD = lagVLD + PRC*VOL;
        else
            % New bond/day; record the closing price and total volume
            irow = SUBCACHE.dates.rowMapDATE(lagDAT);
            jcol = SUBCACHE.ids.colMapBONDID(lagCUS{1});
            SUBCACHE.vals.PRC(irow, jcol) = lagPRC;
            SUBCACHE.vals.VOL(irow, jcol) = lagVOL;
            SUBCACHE.vals.VLD(irow, jcol) = lagVLD;
            SUBCACHE.vals.CRS(irow, jcol) = SUBCACHE.vals.CRmapS(lagCRS{1});
            SUBCACHE.vals.CGS(irow, jcol) = lagCGS;
            SUBCACHE.vals.CDS(irow, jcol) = lagCDS;
            SUBCACHE.vals.CRM(irow, jcol) = SUBCACHE.vals.CRmapM(lagCRM{1});
            SUBCACHE.vals.CGM(irow, jcol) = lagCGM;
            SUBCACHE.vals.CDM(irow, jcol) = lagCDM;
            SUBCACHE.vals.CRF(irow, jcol) = SUBCACHE.vals.CRmapS(lagCRF{1});
            SUBCACHE.vals.CGF(irow, jcol) = lagCGF;
            SUBCACHE.vals.CDF(irow, jcol) = lagCDF;
            SUBCACHE.vals.CGc(irow, jcol) = lagCGc;
            SUBCACHE.vals.CGc(irow, jcol) = ...
                pecking_order(lagCGM, lagCGS, lagCGF);
        end
        lagCUS = CUS; 
        lagDAT = DAT; 
        lagPRC = PRC; 
        lagCRS = nextrow{kCRS}; 
        lagCGS = nextrow{kCGS}; 
        lagCDS = nextrow{kCDS}; 
        lagCRM = nextrow{kCRM}; 
        lagCGM = nextrow{kCGM}; 
        lagCDM = nextrow{kCDM}; 
        lagCRF = nextrow{kCRF}; 
        lagCGF = nextrow{kCGF}; 
        lagCDF = nextrow{kCDF};
    end

    for b = 1:size(SUBCACHE.vals.CGc,2)
        if (SUBCACHE.vals.CGc(1,b)<=0)
            SUBCACHE.vals.CGc(1,b) = 30;
        end
        for t = 2:size(SUBCACHE.vals.CGc,1)
            if (SUBCACHE.vals.CGc(t,b)<=0)
                SUBCACHE.vals.CGc(t,b) = SUBCACHE.vals.CGc(t-1,b);
            end
        end
    end
%     PRC_ids(1,:) = [];
%     datavals = csvread(cfg.PRC_file, 1, 0);
%     PRC_dates = int32(datavals(:,1));
%     faa = datavals(:,2:end);
% 
%     SUBCACHE.vals.PRC = NaN(ctdat, ctids);
%     SUBCACHE.vals.VOL = NaN(ctdat, ctids);
%     SUBCACHE.vals.SICCD = NaN(ctdat, ctids);
%     batch_counter = 0;
%     row_counter = 0;
%     datacurs = fetch(datacurs, cfg.FetchBatchSize);
%     while ~strcmp(datacurs.Data, 'No Data')
%         batch_counter = batch_counter+1;
%         LOG.debug(sprintf(' -- Retrieving batch: %d', batch_counter));
%         datavals = datacurs.Data;
%         ctvals = size(datavals,1);
%         LOG.debug(sprintf('    Starting BONDID/date/rows: %s/%d/%d', ...
%             datavals{1,kIDX}, datstr2int32(datavals{1,kDAT}), ctvals));
%         for i=1:ctvals
%             idx = datavals{i,kIDX};
%             outcol = SUBCACHE.ids.colMapBONDID(idx);
%             dat = datstr2int32(datavals{i,kDAT});
%             outrow = SUBCACHE.dates.rowMapDATE(dat);
%             PRC = cell2mat(datavals(i,kPRC));
%             SUBCACHE.vals.PRC(outrow, outcol) = PRC;
%             SUBCACHE.vals.VOL(outrow, outcol) = cell2mat(datavals(i,kVOL));
%             SUBCACHE.vals.SICCD(outrow, outcol) = ...
%                 str2double(cell2mat(datavals(i,kSIC)));
%         end
%         LOG.debug(sprintf('    Cumulative rows/time: %d/%7.2f sec', ...
%             row_counter, toc(tictime)));
%         datacurs = fetch(datacurs, cfg.FetchBatchSize);
%     end
    
    fclose(fid);
    
    LOG.info('');
    LOG.info(sprintf('Time for TRACE CSV exec: %7.2f sec',toc(tictime)));

end

function CGcomposite = pecking_order(CGM, CGS, CGF)
    % Ratings grade pecking order:
    if (CGM<30) 
        CGcomposite = CGM;
    elseif (CGS<30)
        CGcomposite = CGS;
    elseif (CGF<30)
        CGcomposite = CGF;
    else 
        CGcomposite = CGM;
    end
end

function nrw = read_nextrow(fid)
    nrw = textscan(fid, '%s', 1, 'Delimiter','\n');
    nrw = textscan(nrw{1}{1},'%s,%d,%s,%f,%d,%s,%s,%d8,%d,%s,%s,%d8,%d,%s,%s,%d8,%d,%d8');
    nrw = nrw{1};
end

% function [ids, dats, ratings, igrs] = convert_ratings(csv_filename, ratingtype)
%     CRmap = containers.Map('KeyType','char','ValueType','int8');
%     CRmap('') = 0;
%     CRmap('UNRATED') = 0;
%     switch ratingtype
%         case 'M'
%             CRmoody = {'Aaa';'Aa1';'Aa2';'Aa3';'A1';'A2';'A3';
%                 'Baa1';'Baa2';'Baa3';'Ba1';'Ba2';'Ba3';'B1';'B2';'B3';
%                 'Caa1';'Caa2';'Caa3';'Ca';'C'};
%             IG_thresh = 7;
%             for i = 1:size(CRmoody,1)
%                 CRmap(CRmoody{i}) = i;
%             end
%         case 'S'
%             CRsandp = {'AAA';'AA+';'AA';'AA-';'A+';'A';'A-';
%                 'BBB+';'BBB';'BBB-';'BB+';'BB';'BB-';'B+';'B';'B-';
%                 'CCC+';'CCC';'CCC-';'CC';'C';'D';};
%             IG_thresh = 7;
%             for i = 1:size(CRsandp,1)
%                 CRmap(CRsandp{i}) = i;
%             end
%         case 'F'
%             CRfitch = {'AAA';'AA+';'AA';'AA-';'A+';'A';'A-';
%                 'BBB+';'BBB';'BBB-';'BB+';'BB';'BB-';'B+';'B';'B-';
%                 'CCC';'DDD';'DD';'D';};
%             IG_thresh = 7;
%             for i = 1:size(CRfitch,1)
%                 CRmap(CRfitch{i}) = i;
%             end
%     end
%     
%     % Read each row in the CSV file into a single cell of a cell array
%     fID = fopen(csv_filename);
%     rawrows = textscan(fID,'%s','Delimiter','\n');
%     fclose(fID);
%     % Parse each cell/row into distinct columns
%     ids = textscan(rawrows{1}{1},'%s','Delimiter',',');
% 
%     % Build numeric arrays for dates, ratings, and inv. grade flags
%     ct_ids = size(ids{1},1)-1;
%     ct_dats = size(rawrows{1},1)-1;
%     ratings = zeros(ct_dats, ct_ids);
%     igrs = (-1)*ones(ct_dats, ct_ids);
%     dats = zeros(ct_dats,1);
%     for d = 1:ct_dats
%         daily_ratings = textscan([rawrows{1}{d+1} ','],'%s','Delimiter',',');
%         dats(d) = int32(str2double(daily_ratings{1}{1}));
%         for i = 1:ct_ids;
%             rating_string = daily_ratings{1}{1+i};
%             ratings(d,i) = CRmap(rating_string);
%             if (ratings(d,i) > IG_thresh)
%                 igrs(d,i) = 0;
%             elseif (ratings(d,i) > 0)
%                 igrs(d,i) = 1;
%             end
%         end
%         ids{1}(1,:) = [];
%     end
%     
% end
% 
% function rv = datstr2int32(datstr)
% % Converts a string of form 'yyyy-mm-dd' to an int of form yyyymmdd
%     yyyy = str2double(datstr(1:4));
%     mm = str2double(datstr(6:7));
%     dd = str2double(datstr(9:10));
%     rv = yyyy*10000+mm*100+dd;
% end

function [kCUS,kDAT,kPRC,kVOL,kCRS,kCGS,kCDS,kCRM,kCGM,kCDM,kCRF,kCGF,kCDF] = findCols(headrow)

    global LOG;
    
    propsize = size(headrow, 1);
    kCUS = -1; 
    kDAT = -1; 
    kPRC = -1; 
    kVOL = -1; 
    kCRS = -1; 
    kCGS = -1; 
    kCDS = -1; 
    kCRM = -1; 
    kCGM = -1; 
    kCDM = -1; 
    kCRF = -1; 
    kCGF = -1; 
    kCDF = -1;
    for i=1:propsize
        columnname = lower(char(headrow{i}));
        switch columnname
            case 'cusip_id' 
                kCUS = i; 
            case 'trd_exctn_dt' 
                kDAT = i; 
            case 'rptd_pr' 
                kPRC = i; 
            case 'entrd_vol_qt' 
                kVOL = i; 
            case 'sp_rating' 
                kCRS = i; 
            case 'sp_gradenum' 
                kCGS = i; 
            case 'sp_datediff' 
                kCDS = i; 
            case 'moody_rating' 
                kCRM = i; 
            case 'moody_gradenum' 
                kCGM = i; 
            case 'moody_datediff' 
                kCDM = i; 
            case 'fitch_rating' 
                kCRF = i; 
            case 'fitch_gradenum' 
                kCGF = i; 
            case 'fitch_datediff' 
                kCDF = i;
            case 'trd_exctn_tm' 
            case 'rating_gradenum' 
            case 'sp_grade' 
            case 'moody_grade' 
            case 'fitch_grade' 
            otherwise
                errmsg = sprintf('Field not found %s ==> %s', ...
                    headrow{i}, columnname);
                LOG.err(errmsg);
                error('OFRresearch:LIQ:TRACEfindCols', [errmsg '\n']);        
        end
    end
end
