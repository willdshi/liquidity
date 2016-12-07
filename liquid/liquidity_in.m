function results = liquidity_in()

    global LOG;
    global CONFG;
    global CACHE;

    LOG.info('');
    LOG.info('..........................................................');
    LOG.info(sprintf('Running liquidity_in'));
    LOG.info('..........................................................');

    results.inputDir = CONFG.getProp('input_directory');
    results.buildDir = CONFG.getProp('output_directory');
    results.cacheDir = CONFG.getProp('cache_directory');

    % Load some basic config info
    cfPfx = 'LIQ.';
    results.startdate = CONFG.getPropInt([cfPfx 'startdate']);
    results.stopdate = CONFG.getPropInt([cfPfx 'stopdate']);
    results.eventdate = CONFG.getPropInt([cfPfx 'eventdate']);
    D0 = sprintf('%d', results.startdate);
    D0 = datestr(datenum(D0, 'yyyymmdd'), 'yyyy-mm-dd');
    D1 = sprintf('%d', results.stopdate);
    D1 = datestr(datenum(D1, 'yyyymmdd'), 'yyyy-mm-dd');
    results.output_file = CONFG.getProp([cfPfx 'output_file']);
    results.output_xls = CONFG.getProp([cfPfx 'output_xls']);
    
    % Batched fetching should typically be switched on, to avoid 
    % memory bottlenecks
    results.FetchInBatches = CONFG.getProp([cfPfx 'FetchInBatches']);
    setdbprefs('FetchInBatches', results.FetchInBatches);

    
    %% Setting up the Matlab cache file, if necessary
    LOG.info('');
    LOG.info('Setting up local data cache');
    results.cachename = CONFG.getProp([cfPfx 'cachename']);
    results.cachepath = [pwd filesep results.cacheDir];
    results.cachefile = [results.cachepath filesep results.cachename];
    LOG.info([' -- ' results.cachefile]);
    if (~exist(results.cachepath, 'dir'))
        LOG.warn('  -- CACHE directory missing, creating:');
        LOG.warn(['     ' results.cachepath]);
        mkdir(results.cachepath);
    end
    CACHE = cache_create(results.cachefile, ...
        results.startdate, results.stopdate);
    
    %% Pulling the VIX data
    LOG.info('');
    LOG.info('Pulling the VIX data');

    cfPfx = 'LIQ.VIX.';
    results.VIXcfg.DBinst = CONFG.getProp([cfPfx 'DBinst']);
    results.VIXcfg.DBdrv = CONFG.getProp([cfPfx 'DBdrv']);
    results.VIXcfg.DBurl = CONFG.getProp([cfPfx 'DBurl']);
    results.VIXcfg.DBuser = CONFG.getProp([cfPfx 'DBuser']);
    results.VIXcfg.DBpass = CONFG.getProp([cfPfx 'DBpass']);

    % Substitution strings for replacing date variables in the SQL
    SelVarD0 = CONFG.getProp([cfPfx 'SelVarD0']);
    SelVarD1 = CONFG.getProp([cfPfx 'SelVarD1']);

    % Build SQL statements by substituting in D0 and D1 for the variables
    SelDates = CONFG.getProp([cfPfx 'SelDates']);
    SelDates = strrep(SelDates, SelVarD0, D0);
    SelDates = strrep(SelDates, SelVarD1, D1);
    results.VIXsql.SQLdates = SelDates;
    
    SelTypes = CONFG.getProp([cfPfx 'SelTypes']);
    SelTypes = strrep(SelTypes, SelVarD0, D0);
    SelTypes = strrep(SelTypes, SelVarD1, D1);
    results.VIXsql.SQLtypes = SelTypes;
    
    SelVals = CONFG.getProp([cfPfx 'SelVals']);
    SelVals = strrep(SelVals, SelVarD0, D0);
    SelVals = strrep(SelVals, SelVarD1, D1);
    results.VIXsql.SQLvals = SelVals;
    
    % Pull the data into the cache
    CACHE = cacheVIX(CACHE, results.cachefile, ...
        results.VIXcfg, results.VIXsql);
    

    %% Pulling the WTI data
    LOG.info('');
    LOG.info('Pulling the WTI data');

    cfPfx = 'LIQ.WTI.';
    results.WTIcfg.DBinst = CONFG.getProp([cfPfx 'DBinst']);
    results.WTIcfg.DBdrv = CONFG.getProp([cfPfx 'DBdrv']);
    results.WTIcfg.DBurl = CONFG.getProp([cfPfx 'DBurl']);
    results.WTIcfg.DBuser = CONFG.getProp([cfPfx 'DBuser']);
    results.WTIcfg.DBpass = CONFG.getProp([cfPfx 'DBpass']);

    % Substitution strings for replacing date variables in the SQL
    SelVarD0 = CONFG.getProp([cfPfx 'SelVarD0']);
    SelVarD1 = CONFG.getProp([cfPfx 'SelVarD1']);

    % Build SQL statements by substituting in D0 and D1 for the variables
    SelDates = CONFG.getProp([cfPfx 'SelDates']);
    SelDates = strrep(SelDates, SelVarD0, D0);
    SelDates = strrep(SelDates, SelVarD1, D1);
    results.WTIsql.SQLdates = SelDates;
    
    SelTypes = CONFG.getProp([cfPfx 'SelTypes']);
    SelTypes = strrep(SelTypes, SelVarD0, D0);
    SelTypes = strrep(SelTypes, SelVarD1, D1);
    results.WTIsql.SQLtypes = SelTypes;
    
    SelVals = CONFG.getProp([cfPfx 'SelVals']);
    SelVals = strrep(SelVals, SelVarD0, D0);
    SelVals = strrep(SelVals, SelVarD1, D1);
    results.WTIsql.SQLvals = SelVals;
    
    % Pull the data into the cache
    CACHE = cacheWTI(CACHE, results.cachefile, ...
        results.WTIcfg, results.WTIsql);
    

    %% Pulling the CRSP data
    LOG.info('');
    LOG.info('Pulling the CRSP data');

    cfPfx = 'LIQ.CRSP.';
    results.CRSPcfg.DBinst = CONFG.getProp([cfPfx 'DBinst']);
    results.CRSPcfg.DBdrv = CONFG.getProp([cfPfx 'DBdrv']);
    results.CRSPcfg.DBurl = CONFG.getProp([cfPfx 'DBurl']);
    results.CRSPcfg.DBuser = CONFG.getProp([cfPfx 'DBuser']);
    results.CRSPcfg.DBpass = CONFG.getProp([cfPfx 'DBpass']);
    results.CRSPcfg.FetchBatchSize = ...
        CONFG.getPropInt([cfPfx 'FetchBatchSize']);

    % Substitution strings for replacing date variables in the SQL
    SelVarD0 = CONFG.getProp([cfPfx 'SelVarD0']);
    SelVarD1 = CONFG.getProp([cfPfx 'SelVarD1']);

    % Build SQL statements by substituting in D0 and D1 for the variables
    SelDates = CONFG.getProp([cfPfx 'SelDates']);
    SelDates = strrep(SelDates, SelVarD0, D0);
    SelDates = strrep(SelDates, SelVarD1, D1);
    results.CRSPsql.SQLdates = SelDates;
    
    SelTypes = CONFG.getProp([cfPfx 'SelTypes']);
    SelTypes = strrep(SelTypes, SelVarD0, D0);
    SelTypes = strrep(SelTypes, SelVarD1, D1);
    results.CRSPsql.SQLtypes = SelTypes;
    
    SelVals = CONFG.getProp([cfPfx 'SelVals']);
    SelVals = strrep(SelVals, SelVarD0, D0);
    SelVals = strrep(SelVals, SelVarD1, D1);
    results.CRSPsql.SQLvals = SelVals;
    
    % Pull the data into the cache
    CACHE = cacheCRSP(CACHE, results.cachefile, ...
        results.CRSPcfg, results.CRSPsql);
    

    %% Recession and event dates
%     
%     % The NBER recession dates are monthly (from the St. Louis Fed)
%     confPfx = 'LIQUIDITY.NBER.recession.';
%     LOG.info('');
%     LOG.info(['Begin: ' confPfx]);
%     NBERspec.startdate = results.startdate;
%     NBERspec.stopdate = results.stopdate;
%     NBERspec.sourcefile = [pwd filesep results.inputDir filesep ...
%         CONFG.getProp([confPfx 'filename'])];
%     NBERspec.impute = CONFG.getPropBoolean([confPfx 'impute']);
%     NBERspec.dateformat = CONFG.getProp([confPfx 'dateformat']);
%     NBERspec.datecol = CONFG.getPropInt([confPfx 'datecol']);
%     NBERspec.obscol = CONFG.getPropInt([confPfx 'obscol']);
%     NBERspec.approxnobs = CONFG.getPropInt([confPfx 'approxnobs']);
%     LOG.info(['Parsing: ' NBERspec.sourcefile]);
%     LOG.info([' -- Start date: ' num2str(NBERspec.startdate)]);
%     LOG.info([' -- End date:   ' num2str(NBERspec.stopdate)]);
%     [NBERrecess NBERrecess_datint ~] = readCSVtimeseries(NBERspec);
%     LOG.info(' Parse succeeded');
%     clear NBERspec;
%     
%     % Save the results
%     results.NBERrecess = NBERrecess;
%     results.NBERrecess_datint = NBERrecess_datint;

end

