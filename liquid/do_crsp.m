function results = do_crsp(results)

    global LOG;
    global CONFG;
    global CACHE;

    LOG.info('');
    LOG.info('..........................................................');
    LOG.info(sprintf('Running do_CRSP'));
    LOG.info('..........................................................');

    cfPfx = 'LIQ.CRSP.';
    results.CRSP.cfg.DoCRSPpar = CONFG.getPropBoolean([cfPfx 'DoCRSPpar']);
    
    % Load some basic config info
    results.CRSP.startdate = CONFG.getPropInt([cfPfx 'startdate']);
    results.CRSP.stopdate = CONFG.getPropInt([cfPfx 'stopdate']);
    
    results.CRSP.RNGseed = CONFG.getPropInt([cfPfx 'RNGseed']);
    rng(results.CRSP.RNGseed);
% % %     % Batched fetching should typically be switched on, to avoid 
% % %     % memory bottlenecks
% % %     results.CRSP.FetchInBatches = CONFG.getProp([cfPfx 'FetchInBatches']);
% % %     setdbprefs('FetchInBatches', results.FetchInBatches);
    
    %% Creating/reading a local cache of CRSP data
    
    tic0 = tic;

    results.cachename = CONFG.getProp([cfPfx 'cachename']);
    results.cachepath = [pwd filesep results.cacheDir];
    results.CRSP.cachefile = ...
        [results.cachepath filesep results.cachename];
    LOG.info([' -- ' results.CRSP.cachefile]);
    if (~exist(results.cachepath, 'dir'))
        LOG.warn('  -- CACHE directory missing, creating:');
        LOG.warn(['     ' results.cachepath]);
        mkdir(results.cachepath);
    end
    CACHE = cache_create(results.CRSP.cachefile, ...
        results.CRSP.startdate, results.CRSP.stopdate);
    
    cachetime = toc(tic0);
    fprintf(' -- %7.4f secs\n', cachetime);
    LOG.info('');
    LOG.info(sprintf('Cache setup took %7.4f secs', cachetime));
    clear cachetime
    
    %% Pulling the CRSP data
    LOG.info('');
    LOG.info('Pulling the CRSP data');

    results.CRSP.cfg.DBinst = CONFG.getProp([cfPfx 'DBinst']);
    results.CRSP.cfg.DBdrv = CONFG.getProp([cfPfx 'DBdrv']);
    results.CRSP.cfg.DBurl = CONFG.getProp([cfPfx 'DBurl']);
    results.CRSP.cfg.DBuser = CONFG.getProp([cfPfx 'DBuser']);
    results.CRSP.cfg.DBpass = CONFG.getProp([cfPfx 'DBpass']);
    results.CRSP.cfg.FetchBatchSize = ...
        CONFG.getPropInt([cfPfx 'FetchBatchSize']);

%     results.CRSP.cfg.minPrice = CONFG.getPropDouble([cfPfx 'minPrice']);
%     results.CRSP.cfg.maxPrice = CONFG.getPropDouble([cfPfx 'maxPrice']);

    D0 = sprintf('%d', results.CRSP.startdate);
    D0 = datestr(datenum(D0, 'yyyymmdd'), 'yyyy-mm-dd');
    D1 = sprintf('%d', results.CRSP.stopdate);
    D1 = datestr(datenum(D1, 'yyyymmdd'), 'yyyy-mm-dd');

    % Substitution strings for replacing date variables in the SQL
    SelVarD0 = CONFG.getProp([cfPfx 'SelVarD0']);
    SelVarD1 = CONFG.getProp([cfPfx 'SelVarD1']);

    % Build SQL statements by substituting in D0 and D1 for the variables
    SelDates = CONFG.getProp([cfPfx 'SelDates']);
    SelDates = strrep(SelDates, SelVarD0, D0);
    SelDates = strrep(SelDates, SelVarD1, D1);
    results.CRSP.sql.SQLdates = SelDates;
    
    SelTypes = CONFG.getProp([cfPfx 'SelTypes']);
    SelTypes = strrep(SelTypes, SelVarD0, D0);
    SelTypes = strrep(SelTypes, SelVarD1, D1);
    results.CRSP.sql.SQLtypes = SelTypes;
    
    SelVals = CONFG.getProp([cfPfx 'SelVals']);
    SelVals = strrep(SelVals, SelVarD0, D0);
    SelVals = strrep(SelVals, SelVarD1, D1);
    results.CRSP.sql.SQLvals = SelVals;
    
    % Pull the data into the cache
    CACHE = cacheCRSP(CACHE, results.CRSP.cachefile, ...
        results.CRSP.cfg, results.CRSP.sql);

    %% Calculating price impacts
    LOG.info('');
    LOG.info('Calculating price impacts for CRSP');
    LOG.info('..........................................................');
    
    param = readparam();
    CACHE = impactCRSP(CACHE, results.CRSP.cachefile, param);
    
    %% Hidden Markov model 
    
    LOG.info('');
    LOG.info('Estimating the hidden Markov model');
    LOG.info('..........................................................');

    HMCparams = readparam_hmc(cfPfx);
    t0 = 1 + CONFG.getPropDouble('LIQ.KYLEOBIZ.sigma_estimlag');
    results.CRSP.SIClist = str2num(CONFG.getProp([cfPfx 'SIClist']));
    results.CRSP.SICcount = length(results.CRSP.SIClist);
    LOG.info('Estimating Markov chain for each SIC index portfolio:');
    for i=1:results.CRSP.SICcount
        LOG.info(sprintf(' -- HMC for SIC index %d', i));
        ii = num2str(results.CRSP.SIClist(i));
        eval(['Yi = CACHE.CRSP.pi.kyleobiz' ii '_avgCost;']);
        Yi = Yi(t0:end);
        eval(['results.CRSP.HMC' ii ' = univariateHMC(HMCparams, Yi)']);
        clear Yi;
    end
    
    %% Output the results to a MAT file
    
    LOG.info('');
    LOG.info('CRSP output to MAT');
    LOG.info('..........................................................');
    
    results_matname = CONFG.getProp([cfPfx 'results_matname']);
    results.CRSP.results_matname = ...
        strrep(results_matname, 'yyyymmdd', results.invocationTime);
    results.CRSP.results_matfile = ...
        [results.buildDir filesep results.CRSP.results_matname];
    results_CRSP = results.CRSP;
    save(results.CRSP.results_matfile, '-struct', 'results_CRSP');
    clear results_CRSP results_matname;

    %% Output the results to an XLS file
    
    LOG.info('');
    LOG.info('CRSP output to XLS');
    LOG.info('..........................................................');
    
    results_xlsname = CONFG.getProp([cfPfx 'results_xlsname']);
    results.CRSP.results_xlsname = ...
        strrep(results_xlsname, 'yyyymmdd', results.invocationTime);
    xlspath = [results.buildDir filesep results.CRSP.results_xlsname];
    results.CRSP.xlspath = xlspath;
    datesvec = CACHE.CRSP.dates.vec;
    datecountA = size(CACHE.CRSP.pi.amihud0_kdates, 1);
    datecountK = size(CACHE.CRSP.pi.sic0_DATES, 1);
    titles{1} = CONFG.getProp([cfPfx 'xls.title1']);
    for i = 1:results.CRSP.SICcount
        colhead{i} = num2str(results.CRSP.SIClist(i));
    end
    
    LOG.info('');
    LOG.info('-- Amihud measures');
    sheet = CONFG.getProp([cfPfx 'ami.sheet']);
    titles{2} = CONFG.getProp([cfPfx 'ami.title2']);
    xlsdata = NaN*ones(datecountA, results.CRSP.SICcount);
    for i = 1:results.CRSP.SICcount
        ii = num2str(results.CRSP.SIClist(i));
        LOG.debug(sprintf('      SIC series %s', ii));
        xlsdata(:,i) = eval(['CACHE.CRSP.pi.amihud' ii '_klambdas(:,1);']);
    end
    xls_output(xlspath, sheet, titles, colhead, datesvec, xlsdata);
    
    LOG.info('');
    LOG.info('-- KyleObiz average cost measures');
    sheet = CONFG.getProp([cfPfx 'koa.sheet']);
    titles{2} = CONFG.getProp([cfPfx 'koa.title2']);
    xlsdata = NaN*ones(datecountK, results.CRSP.SICcount);
    for i = 1:results.CRSP.SICcount
        ii = num2str(results.CRSP.SIClist(i));
        LOG.debug(sprintf('      SIC series %s', ii));
        xlsdata(:,i) = eval(['CACHE.CRSP.pi.kyleobiz' ii '_avgCost;']);
    end
    xls_output(xlspath, sheet, titles, colhead, datesvec, xlsdata);
    
    LOG.info('');
    LOG.info('-- KyleObiz median cost measures');
    sheet = CONFG.getProp([cfPfx 'kom.sheet']);
    titles{2} = CONFG.getProp([cfPfx 'kom.title2']);
    xlsdata = NaN*ones(datecountK, results.CRSP.SICcount);
    for i = 1:results.CRSP.SICcount
        ii = num2str(results.CRSP.SIClist(i));
        LOG.debug(sprintf('      SIC series %s', ii));
        xlsdata(:,i) = eval(['CACHE.CRSP.pi.kyleobiz' ii '_medCost;']);
    end
    xls_output(xlspath, sheet, titles, colhead, datesvec, xlsdata);
    
    LOG.info('');
    LOG.info('-- HMC regime probabilities');
    sheet0 = CONFG.getProp([cfPfx 'hmc.sheet']);
    title2 = CONFG.getProp([cfPfx 'hmc.title2']);
    reg1 = NaN*ones(datecountK, results.CRSP.SICcount);
    reg2 = NaN*ones(datecountK, results.CRSP.SICcount);
    reg3 = NaN*ones(datecountK, results.CRSP.SICcount);
    for i = 1:results.CRSP.SICcount
        ii = num2str(results.CRSP.SIClist(i));
        LOG.debug(sprintf('      SIC series %s', ii));
        reg1(t0:end,i) = ...
            eval(['results.CRSP.HMC' ii '.sfStateGDataAll1(:,1);']);
        reg2(t0:end,i) = ...
            eval(['results.CRSP.HMC' ii '.sfStateGDataAll1(:,2);']);
        reg3(t0:end,i) = ...
            eval(['results.CRSP.HMC' ii '.sfStateGDataAll1(:,3);']);
    end
    for j=1:3
        reg_data = eval(['reg' num2str(j)]);
        titles{2} = strrep(title2, 'zzzz', num2str(j)); 
        sheet = strrep(sheet0, 'zzzz', num2str(j));  % Eg: HMCzzzz-->HMC2
        xls_output(xlspath, sheet, titles, colhead, datesvec, reg_data);
    end
    clear xlspath sheet sheet_zzzz titles title2 colhead xlsdata reg_data;
    
    %% Output the results to a SVG file
    
    LOG.info('');
    LOG.info('CRSP output to SVG');
    LOG.info('..........................................................');
    LOG.info('');
    
    results_svgname = CONFG.getProp([cfPfx 'results_svgname']);
    nampfx = CONFG.getProp([cfPfx 'svg.namepfx']);
    results.CRSP.results_svgname = ...
        strrep(results_svgname, 'yyyymmdd', results.invocationTime);
    svgpath = [results.buildDir filesep results.CRSP.results_svgname];
    svgnames = cell(1, results.CRSP.SICcount);
    for i = 1:results.CRSP.SICcount
        ii = num2str(results.CRSP.SIClist(i));
        LOG.debug(sprintf('      SIC series %s', ii));
        svgnames{i} = [nampfx ii];
    end
    foo = class(datesvec)
    make_timeseries_SVG(reg1, reg2, reg3, datesvec, svgnames, svgpath);
    clear reg1 reg2 reg3 datesvec svgnames svgpath;

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

