function results = do_trace(results)

    global LOG;
    global CONFG;
    global CACHE;

    LOG.info('');
    LOG.info('..........................................................');
    LOG.info(sprintf('Running do_trace'));
    LOG.info('..........................................................');

    cfPfx = 'LIQ.TRACE.';
    results.TRACE.cfg.DoTRACEpar = ...
        CONFG.getPropBoolean([cfPfx 'DoTRACEpar']);
    
    % Load some basic config info
    results.TRACE.startdate = CONFG.getPropInt([cfPfx 'startdate']);
    results.TRACE.stopdate = CONFG.getPropInt([cfPfx 'stopdate']);
    
    results.TRACE.RNGseed = CONFG.getPropInt([cfPfx 'RNGseed']);
    rng(results.TRACE.RNGseed);
% % %     % Batched fetching should typically be switched on, to avoid 
% % %     % memory bottlenecks
% % %     results.CRSP.FetchInBatches = CONFG.getProp([cfPfx 'FetchInBatches']);
% % %     setdbprefs('FetchInBatches', results.FetchInBatches);
    
    %% Creating/reading a local cache of TRACE data
    
    tic0 = tic;

    results.cachename = CONFG.getProp([cfPfx 'cachename']);
    results.cachepath = [pwd filesep results.cacheDir];
    results.TRACE.cachefile = ...
        [results.cachepath filesep results.cachename];
    LOG.info([' -- ' results.TRACE.cachefile]);
    if (~exist(results.cachepath, 'dir'))
        LOG.warn('  -- CACHE directory missing, creating:');
        LOG.warn(['     ' results.cachepath]);
        mkdir(results.cachepath);
    end
    CACHE = cache_create(results.TRACE.cachefile, ...
        results.startdate, results.stopdate);
    
    cachetime = toc(tic0);
    fprintf(' -- %7.4f secs\n', cachetime);
    LOG.info('');
    LOG.info(sprintf('Cache setup took %7.4f secs', cachetime));
    clear cachetime
    
    %% Pulling the TRACE data
    LOG.info('');
    LOG.info('Pulling the TRACE data');

    results.TRACE.cfg.DBinst = CONFG.getProp([cfPfx 'DBinst']);
    results.TRACE.cfg.DBdrv = CONFG.getProp([cfPfx 'DBdrv']);
    results.TRACE.cfg.DBurl = CONFG.getProp([cfPfx 'DBurl']);
    results.TRACE.cfg.DBuser = CONFG.getProp([cfPfx 'DBuser']);
    results.TRACE.cfg.DBpass = CONFG.getProp([cfPfx 'DBpass']);
    results.TRACE.cfg.FetchBatchSize = ...
        CONFG.getPropInt([cfPfx 'FetchBatchSize']);

    results.TRACE.cfg.minPrice = CONFG.getPropDouble([cfPfx 'minPrice']);
    results.TRACE.cfg.maxPrice = CONFG.getPropDouble([cfPfx 'maxPrice']);

    D0 = sprintf('%d', results.startdate);
    D0 = datestr(datenum(D0, 'yyyymmdd'), 'yyyy-mm-dd');
    D1 = sprintf('%d', results.stopdate);
    D1 = datestr(datenum(D1, 'yyyymmdd'), 'yyyy-mm-dd');

    % Substitution strings for replacing date variables in the SQL
    SelVarD0 = CONFG.getProp([cfPfx 'SelVarD0']);
    SelVarD1 = CONFG.getProp([cfPfx 'SelVarD1']);

    % Build SQL statements by substituting in D0 and D1 for the variables
    SelDates = CONFG.getProp([cfPfx 'SelDates']);
    SelDates = strrep(SelDates, SelVarD0, D0);
    SelDates = strrep(SelDates, SelVarD1, D1);
    results.TRACE.sql.SQLdates = SelDates;
    
    SelTypes = CONFG.getProp([cfPfx 'SelTypes']);
    SelTypes = strrep(SelTypes, SelVarD0, D0);
    SelTypes = strrep(SelTypes, SelVarD1, D1);
    results.TRACE.sql.SQLtypes = SelTypes;
    
    SelVals = CONFG.getProp([cfPfx 'SelVals']);
    SelVals = strrep(SelVals, SelVarD0, D0);
    SelVals = strrep(SelVals, SelVarD1, D1);
    results.TRACE.sql.SQLvals = SelVals;
    
    % Pull the data into the cache
    CACHE = cacheTRACE(CACHE, results.TRACE.cachefile, ...
        results.TRACE.cfg, results.TRACE.sql);

    %% Calculating price impacts
    LOG.info('');
    LOG.info('Calculating price impacts for TRACE');
    LOG.info('..........................................................');
    
    param = readparam();
    CACHE = impactTRACE(CACHE, results.TRACE.cachefile, param);

    %% Hidden Markov model 
    
    LOG.info('');
    LOG.info('Estimating the hidden Markov model');
    LOG.info('..........................................................');

    HMCparams = readparam_hmc(cfPfx);
    LOG.info('Estimating Markov chain for each SIC index portfolio:');
    for i=0:9
        LOG.info(sprintf(' -- HMC for SIC index %d', i));
        eval(['Yi = CACHE.TRACE.pi.kyleobiz' num2str(i) '_avgCost;']);
        HMCi = univariateHMC(HMCparams, Yi);
        eval(['results.TRACE.HMC' num2str(i) ' = HMCi']);
        clear Yi;
    end
    
    %% Output the results
    
    LOG.info('');
    LOG.info('CRSP output');
    LOG.info('..........................................................');
    
    LOG.info('');
    LOG.info('MAT output');
    results_matname = CONFG.getProp([cfPfx 'results_matname']);
    results.TRACE.results_matname = ...
        strrep(results_matname, 'yyyymmdd', results.invocationTime);
    results.TRACE.results_matfile = ...
        [results.cachepath filesep results.TRACE.results_matname];
    results_TRACE = results.TRACE;
    save(results.TRACE.results_matfile, '-struct', 'results_TRACE');
    clear results_TRACE results_matname;
    
    LOG.info('');
    LOG.info('XLS output');
    results_xlsname = CONFG.getProp([cfPfx 'results_xlsname']);
    results.TRACE.results_xlsname = ...
        strrep(results_xlsname, 'yyyymmdd', results.invocationTime);
    xlspath = [results.buildDir filesep results.TRACE.results_xlsname];
    results.TRACE.xlspath = xlspath;
    datesvec = CACHE.TRACE.dates.vec;
    datecountA = size(CACHE.TRACE.pi.amihud0_kdates, 1);
    datecountK = size(CACHE.TRACE.pi.sic0_DATES, 1);
    titles{1} = CONFG.getProp([cfPfx 'xls.title1']);
% % %     for i = 1:CACHE.TRACE.pi.kyleobiz.sample_max
    for i = 1:10
        colhead{i} = num2str(i-1);
    end
    
    LOG.info('');
    LOG.info('  TRACE output - Amihud measures');
    sheet = 'TRACE_Amihud';
    LOG.info(sprintf('   -- Dates for %s', sheet));
    xlswrite(xlspath, {'Date', 'Lambda by TRACE bucket'}, sheet, 'A1');
    xlswrite(xlspath, CACHE.TRACE.dates.vec, sheet, 'A3');
    for i = 0:results.TRACE.amihud.sample_max-1
        LOG.info(sprintf('   -- for TRACE bucket SIC = %d', i));
        colhead = [char(64+i+2) '2'];
        coldata = [char(64+i+2) '3'];
        LOG.trace(sprintf('      for Amihud: %s, %s', colhead, coldata));
        idata = eval(['results.TRACE.amihud' num2str(i) '_klambdas;']);
        xlswrite(xlspath, i, sheet, colhead);
        xlswrite(xlspath, idata, sheet, coldata);
    end

    LOG.info('');
    LOG.info('  TRACE output - KyleObiz measures');
    sheet = 'TRACE_KyleObiz';
    LOG.info(sprintf('   -- Dates for %s', sheet));
    sechead = [char(64+3+results.TRACE.kyleobiz.sample_max) '1'];
    xlswrite(xlspath, {'Date', 'Average by TRACE bucket'}, sheet, 'A1');
    xlswrite(xlspath, {'Median by TRACE bucket'}, sheet, sechead);
    xlswrite(xlspath, CACHE.TRACE.dates.vec, sheet, 'A3');
    for i = 0:results.TRACE.kyleobiz.sample_max-1
        LOG.info(sprintf('   -- for TRACE bucket SIC = %d', i));
        colhead = [char(64+i+2) '2'];
        coldata = [char(64+i+2) '3'];
        LOG.trace(sprintf('      for KyleObiz: %s, %s', colhead, coldata));
        idata = eval(['results.TRACE.kyleobiz' num2str(i) '_avgCost;']);
        xlswrite(xlspath, i, sheet, colhead);
        xlswrite(xlspath, idata, sheet, coldata);
        colhead = [char(64+i+2+results.TRACE.kyleobiz.sample_max) '2'];
        coldata = [char(64+i+2+results.TRACE.kyleobiz.sample_max) '3'];
        LOG.trace(sprintf('      for KyleObiz: %s, %s', colhead, coldata));
        idata = eval(['results.TRACE.kyleobiz' num2str(i) '_medCost;']);
        xlswrite(xlspath, i, sheet, colhead);
        xlswrite(xlspath, idata, sheet, coldata);
    end
    
%     make_timeseries_SVG(reg1(:,17:25),reg2(:,17:25),reg3(:,17:25),dates, names(17:25), 'G:\OFR\Research and Analysis\Projects\liquidity\trunk\build\RibsTRACE.svg')
end

function reslt = calc_kyleobiz_seq(reslt, RET, PRC, VOL)
    global LOG;
    param = readparam();
    for i = 1:size(RET, 2)
        LOG.info(sprintf(' -- for series = %d', i));
        SAM_RET = RET(:,i);
        SAM_PRC = PRC(:,i);
        SAM_VOL = VOL(:,i);
        [avgCost, medCost] = ...
            kyle_obizhaeva_lambda(param, SAM_RET, SAM_PRC, SAM_VOL);
        % Capturing the results
        eval(['reslt.kyleobiz' num2str(i) '_avgCost = avgCost;']);
        eval(['reslt.kyleobiz' num2str(i) '_medCost = medCost;']);
    end
end

function reslt = calc_kyleobiz_par(reslt, RET, PRC, VOL)

    global LOG;
    global GRID;
    
    JOB = createJob(GRID);
    param = readparam();
    for i = 1:size(RET, 2)
        LOG.info(sprintf(' -- for series = %d', i));
        SAM_RET = RET(:,i);
        SAM_PRC = PRC(:,i);
        SAM_VOL = VOL(:,i);
        task(i) = createTask(JOB, ...
            @kyle_obizhaeva_lambda, 2, {param SAM_RET SAM_PRC SAM_VOL});
    end

    % This should be quick, so we submit and then wait for the JOB
    submit(JOB);
    waitForState(JOB);
    % JOB returns a cell array with one row per task, and
    % two output columns for each row (i.e., for each task):
    %   The first column is the average cost; 
    %   the second column is the median cost.
    costs = fetchOutputs(JOB); %getAllOutputArguments(JOB);
    for i = 1:size(RET, 2)
        costs_i = costs(i);
        LOG.info(sprintf(' -- for series = %d', i));
        eval(sprintf('reslt.kyleobiz%d_avgCost = %d;', i, costs_i{1}));
        eval(sprintf('reslt.kyleobiz%d_medCost = %d;', i, costs_i{2}));
    end
    destroy(JOB);
end

