function results = do_vix(results)

    global LOG;
    global CONFG;
    global CACHE;

    LOG.info('');
    LOG.info('..........................................................');
    LOG.info(sprintf('Running do_vix'));
    LOG.info('..........................................................');

    cfPfx = 'LIQ.VIX.';
    results.VIX.cfg.DoVIXpar = CONFG.getPropBoolean([cfPfx 'DoVIXpar']);
    
    % Load some basic config info
    results.VIX.startdate = CONFG.getPropInt([cfPfx 'startdate']);
    results.VIX.stopdate = CONFG.getPropInt([cfPfx 'stopdate']);
% % %     % Batched fetching should typically be switched on, to avoid 
% % %     % memory bottlenecks
% % %     results.CRSP.FetchInBatches = CONFG.getProp([cfPfx 'FetchInBatches']);
% % %     setdbprefs('FetchInBatches', results.FetchInBatches);
    
    %% Creating/reading a local cache of VIX data
    
    tic0 = tic;

    results.cachename = CONFG.getProp([cfPfx 'cachename']);
    results.cachepath = [pwd filesep results.cacheDir];
    results.VIX.cachefile = ...
        [results.cachepath filesep results.cachename];
    LOG.info([' -- ' results.VIX.cachefile]);
    if (~exist(results.cachepath, 'dir'))
        LOG.warn('  -- CACHE directory missing, creating:');
        LOG.warn(['     ' results.cachepath]);
        mkdir(results.cachepath);
    end
    CACHE = cache_create(results.VIX.cachefile, ...
        results.VIX.startdate, results.VIX.stopdate);
    
    cachetime = toc(tic0);
    fprintf(' -- %7.4f secs\n', cachetime);
    LOG.info('');
    LOG.info(sprintf('Cache setup took %7.4f secs', cachetime));
    clear cachetime
    
    %% Pulling the VIX data
    LOG.info('');
    LOG.info('Pulling the VIX data');

    results.VIX.cfg.DBinst = CONFG.getProp([cfPfx 'DBinst']);
    results.VIX.cfg.DBdrv = CONFG.getProp([cfPfx 'DBdrv']);
    results.VIX.cfg.DBurl = CONFG.getProp([cfPfx 'DBurl']);
    results.VIX.cfg.DBuser = CONFG.getProp([cfPfx 'DBuser']);
    results.VIX.cfg.DBpass = CONFG.getProp([cfPfx 'DBpass']);

    D0 = sprintf('%d', results.VIX.startdate);
    D0 = datestr(datenum(D0, 'yyyymmdd'), 'yyyy-mm-dd');
    D1 = sprintf('%d', results.VIX.stopdate);
    D1 = datestr(datenum(D1, 'yyyymmdd'), 'yyyy-mm-dd');

    % Substitution strings for replacing date variables in the SQL
    SelVarD0 = CONFG.getProp([cfPfx 'SelVarD0']);
    SelVarD1 = CONFG.getProp([cfPfx 'SelVarD1']);

    % Build SQL statements by substituting in D0 and D1 for the variables
    SelDates = CONFG.getProp([cfPfx 'SelDates']);
    SelDates = strrep(SelDates, SelVarD0, D0);
    SelDates = strrep(SelDates, SelVarD1, D1);
    results.VIX.sql.SQLdates = SelDates;
    
    SelTypes = CONFG.getProp([cfPfx 'SelTypes']);
    SelTypes = strrep(SelTypes, SelVarD0, D0);
    SelTypes = strrep(SelTypes, SelVarD1, D1);
    results.VIX.sql.SQLtypes = SelTypes;
    
    SelVals = CONFG.getProp([cfPfx 'SelVals']);
    SelVals = strrep(SelVals, SelVarD0, D0);
    SelVals = strrep(SelVals, SelVarD1, D1);
    results.VIX.sql.SQLvals = SelVals;
    
    % Pull the data into the cache
    CACHE = cacheVIX(CACHE, results.VIX.cachefile, ...
        results.VIX.cfg, results.VIX.sql);

    %% Pulling the samples
    
    LOG.info('');
    LOG.info('Identifying the 9 VIX contracts based on term to maturity');
    VIX_PRC = CACHE.VIX.vals.PRC;
    VIX_RET = CACHE.VIX.vals.RET;
    VIX_VOL = CACHE.VIX.vals.VOL;
    
    param = readparam();
    
    %% AMIHUD

    LOG.info('');
    LOG.info('Computing Kyle''s lambda via the Amihud method');

%     results.VIX.amihud.min_regress_obs = param.min_regress_obs;
%     results.VIX.amihud.sample_max = param.am_sample_max;

    LOG.info('');
    LOG.info('The VIX sample of volatitity futures data');
    tic_klam = tic;
    results.VIX.amihud.sample_max = ...
        min(param.am_sample_max, size(VIX_RET, 2));
    for i = 1:results.VIX.amihud.sample_max
        LOG.info(sprintf(' -- for VIX maturity = %d mos', i));
        SAM_DATES = CACHE.VIX.dates.vec;
        SAM_RET = VIX_RET(:,i);
        SAM_PRC = VIX_PRC(:,i);
        SAM_VOL = VIX_VOL(:,i);
        [klambdas, kdates] = ...
            kyles_lambda(SAM_RET, SAM_PRC, SAM_VOL, SAM_DATES, param);
        % Capturing the results
        eval(['results.VIX.amihud' num2str(i) '_kdates = kdates;']);
        eval(['results.VIX.amihud' num2str(i) '_klambdas = klambdas;']);
    end
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_klam)));
    clear tic_klam klambdas kdates SAM_RET SAM_PRC SAM_VOL SAM_DATES;

    %% KYLEOBIZ

    LOG.info('');
    LOG.info('Computing price impact via the Kyle and Obizhaeva method');

    tic_kno = tic;
    sample_max = min(param.ko_sample_max, size(CACHE.VIX.vals.RET, 2));
    VIXPRC = CACHE.VIX.vals.PRC(:,1:sample_max);
    VIXRET = CACHE.VIX.vals.RET(:,1:sample_max);
    VIXVOL = CACHE.VIX.vals.VOL(:,1:sample_max);
    LOG.info('');
    if (results.VIX.cfg.DoVIXpar)
        LOG.info('The VIX futures data (parallel computations)');
        results = parallel_config(results); % In case a config is needed
        results.VIX = calc_kyleobiz_par(results.VIX,VIXRET,VIXPRC,VIXVOL);
    else
        LOG.info('The VIX futures data (sequential computations)');
        results.VIX = calc_kyleobiz_seq(results.VIX,VIXRET,VIXPRC,VIXVOL);
    end
    results.VIX.kyleobiz.sample_max = sample_max;
    results.VIX.kyleobiz.dates = CACHE.VIX.dates.vec;
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_kno)));
    clear VIXRET VIXPRC VIXVOL;
    
%     LOG.info('');
%     LOG.info('The VIX sample of volatitity futures data');
%     tic_kno = tic;
%     results.VIX.kyleobiz.sample_max = ...
%         min(param.ko_sample_max, size(VIX_RET, 2));
%     results.VIX.kyleobiz.VIX_dates = CACHE.VIX.dates.vec;
%     for i = 1:results.VIX.kyleobiz.sample_max
%         LOG.info(sprintf(' -- for VIX maturity = %d mos', i));
%         SAM_DATES = CACHE.VIX.dates.vec;
%         SAM_RET = VIX_RET(:,i);
%         SAM_PRC = VIX_PRC(:,i);
%         SAM_VOL = VIX_VOL(:,i);
%         [avgCost, medCost] = ...
%             kyle_obizhaeva_lambda(param, SAM_RET, SAM_PRC, SAM_VOL);
%         % Capturing the results
%         eval(['results.VIX.kyleobiz' num2str(i) '_avgCost = avgCost;']);
%         eval(['results.VIX.kyleobiz' num2str(i) '_medCost = medCost;']);
%     end
%     LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_kno)));
%     clear i tic_kno avgCost medCost SAM_RET SAM_PRC SAM_VOL;
    
    %% Hidden Markov model 
    
    LOG.info('');
    LOG.info('Estimating the hidden Markov model');

    HMCparams = readparam_hmc(cfPfx);

    
    %% Output the results
    
    results.VIX.cachename = CONFG.getProp([cfPfx 'cachename']);
    results.VIX.cachefile = ...
        [results.cachepath filesep results.VIX.cachename];
    results_VIX = results.VIX;
    save(results.VIX.cachefile, '-struct', 'results_VIX');
    clear results_VIX;
    
    results.VIX.xlsfile = CONFG.getProp([cfPfx 'xlsfile']);
    xlspath = [results.buildDir filesep results.VIX.xlsfile];
    results.VIX.xlspath = xlspath;
    
    LOG.info('');
    LOG.info('  VIX output - Amihud measures');
    sheet = 'VIX_Amihud';
    LOG.info(sprintf('   -- Dates for %s', sheet));
    xlswrite(xlspath, {'Date', 'Lambda by VIX maturity'}, sheet, 'A1');
    xlswrite(xlspath, results.VIX.amihud1_kdates, sheet, 'A3');
    for i = 1:results.VIX.amihud.sample_max
        LOG.info(sprintf('   -- for VIX maturity = %d mos', i));
        colhead = [char(64+i+1) '2'];
        coldata = [char(64+i+1) '3'];
        LOG.trace(sprintf('      for Amihud: %s, %s', colhead, coldata));
        idata = eval(['results.VIX.amihud' num2str(i) '_klambdas;']);
        xlswrite(xlspath, i, sheet, colhead);
        xlswrite(xlspath, idata, sheet, coldata);
    end

    LOG.info('');
    LOG.info('  VIX output - KyleObiz measures');
    sheet = 'VIX_KyleObiz';
    LOG.info(sprintf('   -- Dates for %s', sheet));
    sechead = [char(64+3+results.VIX.kyleobiz.sample_max) '1'];
    xlswrite(xlspath, {'Date', 'Average by VIX maturity'}, sheet, 'A1');
    xlswrite(xlspath, {'Median by VIX maturity'}, sheet, sechead);
    xlswrite(xlspath, CACHE.VIX.dates.vec, sheet, 'A3');
    for i = 1:results.VIX.kyleobiz.sample_max
        LOG.info(sprintf('   -- for VIX maturity = %d mos', i));
        colhead = [char(64+i+1) '2'];
        coldata = [char(64+i+1) '3'];
        LOG.trace(sprintf('      for KyleObiz: %s, %s', colhead, coldata));
        idata = eval(['results.VIX.kyleobiz' num2str(i) '_avgCost;']);
        xlswrite(xlspath, i, sheet, colhead);
        xlswrite(xlspath, idata, sheet, coldata);
        colhead = [char(64+i+2+results.VIX.kyleobiz.sample_max) '2'];
        coldata = [char(64+i+2+results.VIX.kyleobiz.sample_max) '3'];
        LOG.trace(sprintf('      for KyleObiz: %s, %s', colhead, coldata));
        idata = eval(['results.VIX.kyleobiz' num2str(i) '_medCost;']);
        xlswrite(xlspath, i, sheet, colhead);
        xlswrite(xlspath, idata, sheet, coldata);
    end
    
%     make_timeseries_SVG(reg1(:,17:25),reg2(:,17:25),reg3(:,17:25),dates, names(17:25), 'G:\OFR\Research and Analysis\Projects\liquidity\trunk\build\RibsVIX.svg')
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

