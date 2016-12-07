function RSLT = vixwti_dbsql2local(configfile, VIXorWTI)
%  Required configuration parameters, to be defined in configfile:
%     output_directory               (string)
%     cache_directory                (string)
%     input_directory_win            (string)
%     input_directory_lin            (string)
%     search_path                    (string)
%     LIQ.{VIXorWTI}.startdate            (int)
%     LIQ.{VIXorWTI}.stopdate             (int)
%     LIQ.{VIXorWTI}.local.cachename      (string)
%     LIQ.{VIXorWTI}.local.cachetimetest  (boolean)
%     LIQ.{VIXorWTI}.local.forcecache     (boolean)
%     LIQ.{VIXorWTI}.local.DBinst         (string)
%     LIQ.{VIXorWTI}.local.DBdrv          (string)
%     LIQ.{VIXorWTI}.local.DBurl          (string)
%     LIQ.{VIXorWTI}.local.DBuser         (string)
%     LIQ.{VIXorWTI}.local.DBpass         (string)
%     LIQ.{VIXorWTI}.local.FetchBatchSize (int)
%     LIQ.{VIXorWTI}.local.SelVarD0       (string)
%     LIQ.{VIXorWTI}.local.SelVarD1       (string)
%     LIQ.{VIXorWTI}.local.SelDates       (string)
%     LIQ.{VIXorWTI}.local.SelTypes       (string)
%     LIQ.{VIXorWTI}.local.SelVals        (string)
%     LIQ.{VIXorWTI}.local.RSLTname       (string)
%     LIQ.{VIXorWTI}.local.minPrice       (double)
%     LIQ.{VIXorWTI}.local.maxPrice       (double)

    global LOG;
    global CONFG;

    % Read the CONFG, initialize paths, and set up the LOG
    RSLT = initialize(configfile, [mfilename '-' VIXorWTI '.log']);
    
    LOG.info('');
    LOG.info('----------------------------------------------------------');
    LOG.info(sprintf('Running %s for %s', mfilename, VIXorWTI));
    LOG.info(sprintf('  configfile:    %s', configfile));
    LOG.info('----------------------------------------------------------');

    cfPfx = ['LIQ.' VIXorWTI '.local.'];
    
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
    RSLT.startdate = CONFG.getPropInt(['LIQ.' VIXorWTI '.startdate']);
    RSLT.stopdate = CONFG.getPropInt(['LIQ.' VIXorWTI '.stopdate']);
    
    % Pulling the data
    LOG.info('');
    LOG.info(['Pulling the ' VIXorWTI ' data']);

    % Assemble the SQL connection info
    RSLT.dbcfg.DBinst = CONFG.getProp([cfPfx 'DBinst']);
    RSLT.dbcfg.DBdrv = CONFG.getProp([cfPfx 'DBdrv']);
    RSLT.dbcfg.DBurl = CONFG.getProp([cfPfx 'DBurl']);
    RSLT.dbcfg.DBuser = CONFG.getProp([cfPfx 'DBuser']);
    RSLT.dbcfg.DBpass = CONFG.getProp([cfPfx 'DBpass']);
    RSLT.dbcfg.FetchBatchSize = CONFG.getPropInt([cfPfx 'FetchBatchSize']);

    % Assemble the SQL query strings ...
    % First, some manipulations of the date strings
    D0 = sprintf('%d', RSLT.startdate);
    D0 = datestr(datenum(D0, 'yyyymmdd'), 'yyyy-mm-dd');
    D1 = sprintf('%d', RSLT.stopdate);
    D1 = datestr(datenum(D1, 'yyyymmdd'), 'yyyy-mm-dd');

    % Substitution strings for replacing date variables in the SQL
    SelVarD0 = CONFG.getProp([cfPfx 'SelVarD0']);
    SelVarD1 = CONFG.getProp([cfPfx 'SelVarD1']);

    % Build SQL statements by substituting in D0 and D1 for the variables
    SelDates = CONFG.getProp([cfPfx 'SelDates']);
    SelDates = strrep(SelDates, SelVarD0, D0);
    SelDates = strrep(SelDates, SelVarD1, D1);
    RSLT.sqlcfg.SQLdates = SelDates;
    
    SelTypes = CONFG.getProp([cfPfx 'SelTypes']);
    SelTypes = strrep(SelTypes, SelVarD0, D0);
    SelTypes = strrep(SelTypes, SelVarD1, D1);
    RSLT.sqlcfg.SQLtypes = SelTypes;
    
    SelVals = CONFG.getProp([cfPfx 'SelVals']);
    SelVals = strrep(SelVals, SelVarD0, D0);
    SelVals = strrep(SelVals, SelVarD1, D1);
    RSLT.sqlcfg.SQLvals = SelVals;
    
    % Pull the data into the cache
    LOG.info('');
    LOG.info(['Caching data in ' mfilename '.m']);
    LOG.info(sprintf(' -- cachefile: %s', RSLT.cachefile));

    % Create the CACHE
    CACHE.data = makeCache(RSLT.dbcfg, RSLT.sqlcfg);
    
    % Assembling a manifest and save the CACHE
    LOG.warn('');
    LOG.warn('----------------------------------------------------------');
    LOG.warn(sprintf('Caching log file to: %s', RSLT.cachefile));
    LOG.warn('----------------------------------------------------------');
    CACHE.manifest = build_manifest(RSLT, configfile);
    save(RSLT.cachefile, '-struct', 'CACHE', '-v7.3');
    
    %% Finishing up
    
    % Save the accumulated results (RSLT) to a file
    RSLT.RSLTname = CONFG.getProp([cfPfx 'RSLTname']);
    RSLT.RSLTfile = [RSLT.buildDir filesep RSLT.RSLTname];
    LOG.warn('');
    LOG.warn('----------------------------------------------------------');
    LOG.warn(sprintf('Caching log file to: %s', RSLT.RSLTfile));
    LOG.warn('----------------------------------------------------------');
    RSLT.manifest = build_manifest(RSLT, configfile);
    save(RSLT.RSLTfile, '-struct', 'RSLT', '-v7.3');

    % Test the saved CACHE
    testspec = vixwti_testcache_local();
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
    clear all;
end 

function manifest = build_manifest(RSLT, configfile)
    manifest.startdate = RSLT.startdate;
    manifest.stopdate = RSLT.stopdate;
    manifest.code.CONFG = read_textfile_to_var(configfile);
    manifest.code.trace_dbsql2local = ...
        read_textfile_to_var('trace_dbsql2local.m');
    manifest.code.trace_testcache_local = ...
        read_textfile_to_var('trace_testcache_local.m');
    manifest.code.LOG = read_textfile_to_var(RSLT.logfile);
end

function SUBCACHE = makeCache(cfg, sqlcfg)

    global LOG;

    tictime = tic;
    
    % Opening a connection to the DB
    LOG.info('');
    LOG.info('Database connection for VIX/WTI cache:');
    LOG.info(sprintf(' -- DBinst:      %s', cfg.DBinst));
    LOG.info(sprintf(' -- DBuser:      %s', cfg.DBuser));
    LOG.info(sprintf(' -- DBpass:      %s', cfg.DBpass));
    LOG.info(sprintf(' -- DBdrv:       %s', cfg.DBdrv));
    LOG.info(sprintf(' -- DBurl:       %s', cfg.DBurl)); 

    conn = database( ...
        cfg.DBinst, cfg.DBuser, cfg.DBpass, cfg.DBdrv, cfg.DBurl);
    
    % This should be a query for all the various IDs; something like this: 
    %  SELECT DISTINCT [Date] FROM [OHMJ].[dbo].[Bloomberg_VIX_WTI]
    LOG.info('');
    LOG.info('Database query for VIX/WTI dates:');
    LOG.info(['  ' sqlcfg.SQLdates]);
    datavals = fetch(conn, sqlcfg.SQLdates);
    ctdat = length(datavals);
    LOG.info(sprintf('  Number of values retrieved: %d', ctdat));
    SUBCACHE.dates.vec = -1*ones(ctdat, 1);
    SUBCACHE.dates.rowMapDATE = ...
        containers.Map('KeyType','int32','ValueType','int32');
    for i=1:ctdat
        datint = datstr2int32(datavals{i});
        SUBCACHE.dates.vec(i) = datint;
        SUBCACHE.dates.rowMapDATE(datint) = i;
    end
    clear i datavals datint;
    
    % This should be a query for all the various IDs; something like this: 
    %  SELECT DISTINCT Contract_Index FROM [OHMJ].[dbo].[Bloomberg_VIX_WTI]
    LOG.info('');
    LOG.info('Database query for VIX/WTI ids:');
    LOG.info(['  ' sqlcfg.SQLtypes]);
    datavals = fetch(conn, sqlcfg.SQLtypes);
    ctids = length(datavals);
    LOG.info(sprintf('  Number of values retrieved: %d', ctids));
    SUBCACHE.ids.VIXWTI = cell(1, ctids);
    SUBCACHE.ids.colMapVIXWTI = ...
        containers.Map('KeyType','int32','ValueType','int32');
    for i=1:ctids
        idi = datavals{i};
        LOG.trace(sprintf('   - ID: %d, placed in col=%d', idi, i));
        SUBCACHE.ids.VIXWTI{i} = idi;
        SUBCACHE.ids.colMapVIXWTI(idi) = i;
    end
    clear i datavals idi;
    
    % This should be a query for all the various IDs; something like this: 
    %  SELECT DISTINCT Contract_Index FROM [OHMJ].[dbo].[Bloomberg_VIX_WTI]
    LOG.info('');
    LOG.info('Database query for VIX/WTI values:');
    LOG.info(['  ' sqlcfg.SQLvals]);
    datacurs = exec(conn, sqlcfg.SQLvals);
    % If VIX/WTI pulls don't get large, no need to fetch in batches
    set(datacurs, 'RowLimit', 0);
    
    [kDAT, kIDX, kPRC, kVOL] = findVIXWTIcols(datacurs);
    LOG.info('  Selection columns: ');
    LOG.info(sprintf('   - date:               %d', kDAT));
    LOG.info(sprintf('   - contract_index_num: %d', kIDX));
    LOG.info(sprintf('   - price:              %d', kPRC));
    LOG.info(sprintf('   - volume:             %d', kVOL));
    LOG.info('');
    LOG.info(sprintf('Time for VIX/WTI SQL exec: %7.2f sec',toc(tictime)));
    
    % We are assuming here that FetchBatchSize=0
    datacurs = fetch(datacurs, 0);
    datavals = datacurs.Data;
    ctvals = length(datavals);
    LOG.info(sprintf('  Number of values retrieved: %d', ctvals));
    SUBCACHE.vals.PRC = NaN(ctdat, ctids);
    SUBCACHE.vals.VOL = NaN(ctdat, ctids);
    SUBCACHE.vals.RET = NaN(ctdat, ctids);
    for i = 1:ctvals
        % Identify the target row and column from the source info
        thisdate = datstr2int32(datavals{i,kDAT});
        target_row = SUBCACHE.dates.rowMapDATE(thisdate);
        thisID = datavals{i,kIDX};
        target_col = SUBCACHE.ids.colMapVIXWTI(thisID);
        % Copy the data from the SQL resultset to the output arrays
        PRC = cell2mat(datavals(i,kPRC));
        SUBCACHE.vals.PRC(target_row, target_col) = PRC;
        if (target_row>1)
            RET = log(PRC)-log(lagPRC);
        else
            RET = NaN;
        end
        SUBCACHE.vals.RET(target_row, target_col) = RET;
        SUBCACHE.vals.VOL(target_row, target_col) = ...
            cell2mat(datavals(i,kVOL));
        lagPRC = PRC;
    end
    
    LOG.info('');
    LOG.info(sprintf('Time elapsed, total: %7.2f sec', toc(tictime)));
end

function rv = datstr2int32(datstr)
% Converts a string of form 'yyyy-mm-dd' to an int of form yyyymmdd
    yyyy = str2double(datstr(1:4));
    mm = str2double(datstr(6:7));
    dd = str2double(datstr(9:10));
    rv = yyyy*10000+mm*100+dd;
end

