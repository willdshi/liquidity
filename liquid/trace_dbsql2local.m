function RSLT = trace_dbsql2local(configfile)
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
%     LIQ.TRACE.local.DBinst         (string)
%     LIQ.TRACE.local.DBdrv          (string)
%     LIQ.TRACE.local.DBurl          (string)
%     LIQ.TRACE.local.DBuser         (string)
%     LIQ.TRACE.local.DBpass         (string)
%     LIQ.TRACE.local.FetchBatchSize (int)
%     LIQ.TRACE.local.SelVarD0       (string)
%     LIQ.TRACE.local.SelVarD1       (string)
%     LIQ.TRACE.local.SelDates       (string)
%     LIQ.TRACE.local.SelTypes       (string)
%     LIQ.TRACE.local.SelVals        (string)
%     LIQ.TRACE.local.RSLTname       (string)
%     LIQ.TRACE.local.minPrice       (double)
%     LIQ.TRACE.local.maxPrice       (double)

    global LOG;
    global CONFG;

    % Read the CONFG, initialize paths, and set up the LOG
    RSLT = initialize(configfile, [mfilename '.log']);
    
    LOG.info('');
    LOG.info('----------------------------------------------------------');
    LOG.info(sprintf('Running %s', mfilename));
    LOG.info(sprintf('  configfile:    %s', configfile));
    LOG.info('----------------------------------------------------------');

    cfPfx = 'LIQ.TRACE.local.';
    
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
    
    % Pulling the data
    LOG.info('');
    LOG.info('Pulling the TRACE data');

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
    testspec = trace_testcache_local();
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
    LOG.info('Database connection for TRACE cache:');
    LOG.info(sprintf(' -- DBinst:      %s', cfg.DBinst));
    LOG.info(sprintf(' -- DBuser:      %s', cfg.DBuser));
    LOG.info(sprintf(' -- DBpass:      %s', cfg.DBpass));
    LOG.info(sprintf(' -- DBdrv:       %s', cfg.DBdrv));
    LOG.info(sprintf(' -- DBurl:       %s', cfg.DBurl)); 
    LOG.info(sprintf(' -- DBbatchsize: %d', cfg.FetchBatchSize)); 

    conn = database( ...
        cfg.DBinst, cfg.DBuser, cfg.DBpass, cfg.DBdrv, cfg.DBurl);
    
    % This should be a query for all the various IDs; something like this: 
    % SELECT DISTINCT trd_exctn_dt AS DATE FROM [OHMJ].[dbo].[TRACE_FINAL]
    LOG.info('');
    LOG.info('Database query for TRACE dates:');
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
    % SELECT DISTINCT bond_sym_id AS BONDID FROM [OHMJ].[dbo].[TRACE_FINAL]
    LOG.info('');
    LOG.info('Database query for TRACE ids:');
    LOG.info(['  ' sqlcfg.SQLtypes]);
    datavals = fetch(conn, sqlcfg.SQLtypes);
    ctids = length(datavals);
    LOG.info(sprintf('  Number of values retrieved: %d', ctids));
    SUBCACHE.ids.BONDID = cell(1, ctids);
    SUBCACHE.ids.colMapBONDID = ...
        containers.Map('KeyType','char','ValueType','int32');
    for i=1:ctids
        idi = datavals{i};
        LOG.trace(sprintf('   - BONDID:      %s, col=%d', idi, i));
        SUBCACHE.ids.BONDID{i} = idi;
        SUBCACHE.ids.colMapBONDID(idi) = i;
    end
    clear i datavals idi;
    
    % This should be a query for all the various IDs; something like this: 
    % SELECT date,bondid,prc,vol,siccd FROM [OHMJ].[dbo].[TRACE_FINAL]
    LOG.info('');
    LOG.info('Database query for TRACE values:');
    LOG.info(['  ' sqlcfg.SQLvals]);
    datacurs = exec(conn, sqlcfg.SQLvals);
    % Since TRACE pulls may be too big, we have to fetch in batches
    set(datacurs, 'RowLimit', cfg.FetchBatchSize);
    
    [kDAT, kIDX, kPRC, kVOL, kSIC] = findCols(datacurs);
    LOG.info('  Selection columns: ');
    LOG.info(sprintf('   - date:      %d', kDAT));
    LOG.info(sprintf('   - bondid:    %d', kIDX));
    LOG.info(sprintf('   - price:     %d', kPRC));
    LOG.info(sprintf('   - volume:    %d', kVOL));
    LOG.info(sprintf('   - SIC code:  %d', kSIC));
    LOG.info('');
    LOG.info(sprintf('Time for TRACE SQL exec: %7.2f sec',toc(tictime)));
    
    SUBCACHE.vals.PRC = NaN(ctdat, ctids);
    SUBCACHE.vals.VOL = NaN(ctdat, ctids);
    SUBCACHE.vals.SICCD = NaN(ctdat, ctids);
    batch_counter = 0;
    row_counter = 0;
    datacurs = fetch(datacurs, cfg.FetchBatchSize);
    while ~strcmp(datacurs.Data, 'No Data')
        batch_counter = batch_counter+1;
        LOG.debug(sprintf(' -- Retrieving batch: %d', batch_counter));
        datavals = datacurs.Data;
        ctvals = size(datavals,1);
        LOG.debug(sprintf('    Starting BONDID/date/rows: %s/%d/%d', ...
            datavals{1,kIDX}, datstr2int32(datavals{1,kDAT}), ctvals));
        for i=1:ctvals
            idx = datavals{i,kIDX};
            outcol = SUBCACHE.ids.colMapBONDID(idx);
            dat = datstr2int32(datavals{i,kDAT});
            outrow = SUBCACHE.dates.rowMapDATE(dat);
            PRC = cell2mat(datavals(i,kPRC));
            SUBCACHE.vals.PRC(outrow, outcol) = PRC;
            SUBCACHE.vals.VOL(outrow, outcol) = cell2mat(datavals(i,kVOL));
            SUBCACHE.vals.SICCD(outrow, outcol) = ...
                str2double(cell2mat(datavals(i,kSIC)));
        end
        LOG.debug(sprintf('    Cumulative rows/time: %d/%7.2f sec', ...
            row_counter, toc(tictime)));
        datacurs = fetch(datacurs, cfg.FetchBatchSize);
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

function [kDAT,kIDX,kPRC,kVOL,kSIC] = findCols(curs)
% Parses a SQL resultset to discover the position of fields 
    rset = resultset(curs);
    metadata = rsmd(rset);
    properties = get(metadata);
    properties.ColumnName;
    propsize = size(properties.ColumnName, 2);
    kDAT = -1;
    kIDX = -1;
    kPRC = -1;
    kVOL = -1;
    kSIC = -1;
    for i=1:propsize
        % Note the conversion to char -- SQL returns java.lang.String
        columnname = lower(char(properties.ColumnName{i}));
        switch columnname
            case 'date' 
                kDAT = i;
            case 'bondid'
                kIDX = i;
            case 'prc'
                kPRC = i;
            case 'vol'
                kVOL = i;
            case 'siccd'
                kSIC = i;
            otherwise
                errmsg = sprintf('Field not found %s ==> %s', ...
                    properties.ColumnName{i}, columnname);
                LOG.err(errmsg);
                error('OFRresearch:LIQ:TRACEfindCols', [errmsg '\n']);        
        end
    end
end


