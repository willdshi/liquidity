function RSLT = crsp_dbsql2local(configfile)
%  Required configuration parameters, to be defined in configfile:
%     output_directory              (string)
%     cache_directory               (string)
%     input_directory_win           (string)
%     input_directory_lin           (string)
%     search_path                   (string)
%     LIQ.CRSP.startdate            (int)
%     LIQ.CRSP.stopdate             (int)
%     LIQ.CRSP.local.cachename      (string)
%     LIQ.CRSP.local.cachetimetest  (boolean)
%     LIQ.CRSP.local.forcecache     (boolean)
%     LIQ.CRSP.local.DBinst         (string)
%     LIQ.CRSP.local.DBdrv          (string)
%     LIQ.CRSP.local.DBurl          (string)
%     LIQ.CRSP.local.DBuser         (string)
%     LIQ.CRSP.local.DBpass         (string)
%     LIQ.CRSP.local.FetchBatchSize (int)
%     LIQ.CRSP.local.SelVarD0       (string)
%     LIQ.CRSP.local.SelVarD1       (string)
%     LIQ.CRSP.local.SelDates       (string)
%     LIQ.CRSP.local.SelTypes       (string)
%     LIQ.CRSP.local.SelVals        (string)
%     LIQ.CRSP.local.RSLTname       (string)

    global LOG;
    global CONFG;

    % Read the CONFG, initialize paths, and set up the LOG
    RSLT = initialize(configfile, [mfilename '.log']);
    
    LOG.info('');
    LOG.info('----------------------------------------------------------');
    LOG.info(sprintf('Running %s', mfilename));
    LOG.info(sprintf('  configfile:    %s', configfile));
    LOG.info('----------------------------------------------------------');

    cfPfx = 'LIQ.CRSP.local.';
    
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
    RSLT.startdate = CONFG.getPropInt('LIQ.CRSP.startdate');
    RSLT.stopdate = CONFG.getPropInt('LIQ.CRSP.stopdate');
    
    % Pulling the data
    LOG.info('');
    LOG.info('Pulling the CRSP data');

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
    testspec = crsp_testcache_local();
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

function manifest = build_manifest(RSLT, configfile)
    manifest.startdate = RSLT.startdate;
    manifest.stopdate = RSLT.stopdate;
    manifest.code.CONFG = read_textfile_to_var(configfile);
    manifest.code.crsp_dbsql2local = ...
        read_textfile_to_var('crsp_dbsql2local.m');
    manifest.code.crsp_testcache_local = ...
        read_textfile_to_var('crsp_testcache_local.m');
    manifest.code.LOG = read_textfile_to_var(RSLT.logfile);
end

function SUBCACHE = makeCache(cfg, sqlcfg)

    global LOG;

    tictime = tic;
    
    % Opening a connection to the DB
    LOG.info('');
    LOG.info('Database connection for CRSP cache:');
    LOG.info(sprintf(' -- DBinst:      %s', cfg.DBinst));
    LOG.info(sprintf(' -- DBuser:      %s', cfg.DBuser));
    LOG.info(sprintf(' -- DBpass:      %s', cfg.DBpass));
    LOG.info(sprintf(' -- DBdrv:       %s', cfg.DBdrv));
    LOG.info(sprintf(' -- DBurl:       %s', cfg.DBurl)); 
    LOG.info(sprintf(' -- DBbatchsize: %d', cfg.FetchBatchSize)); 

    conn = database( ...
        cfg.DBinst, cfg.DBuser, cfg.DBpass, cfg.DBdrv, cfg.DBurl);
    
    % This should be a query for all the various IDs; something like this: 
    %  SELECT DISTINCT date FROM [OHMJ].[dbo].[CRSP_LM]
    LOG.info('');
    LOG.info('Database query for CRSP dates:');
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
    
    % This should be a query for all the various IDs; something like this: 
    %  SELECT DISTINCT permno, MIN(cusip) AS cusip, <etc.> FROM [CRSP_LM]
    LOG.info('');
    LOG.info('Database query for CRSP ids:');
    LOG.info(['  ' sqlcfg.SQLtypes]);
    datavals = fetch(conn, sqlcfg.SQLtypes);
    ctids = length(datavals);
    LOG.info(sprintf('  Number of values retrieved: %d', ctids));
    SUBCACHE.ids.PERMNO = cell(1, ctids);
    SUBCACHE.ids.colMapPERMNO = ...
        containers.Map('KeyType','int32','ValueType','int32');
    for i=1:ctids
        idi = datavals{i};
        SUBCACHE.ids.PERMNO{i} = idi;
        SUBCACHE.ids.colMapPERMNO(idi) = i;
    end
    
    % This should be a query for all the various IDs; something like this: 
    %  SELECT date,permno,prc,vol,ret,siccd,shrout FROM [CRSP_LM] <etc.>
    LOG.info('');
    LOG.info('Database query for CRSP values:');
    LOG.info(['  ' sqlcfg.SQLvals]);
    datacurs = exec(conn, sqlcfg.SQLvals);
    % Since CRSP pulls may be too big, we have to fetch in batches
    set(datacurs, 'RowLimit', cfg.FetchBatchSize);
    
    [kDAT,kIDX,kPRC,kVOL,kRET,kBID,kASK,kSIC,kNAI,kSHR] = ...
        findCols(datacurs);
    LOG.info('  Selection columns: ');
    LOG.info(sprintf('   - date:       %d', kDAT));
    LOG.info(sprintf('   - permno:     %d', kIDX));
    LOG.info(sprintf('   - price:      %d', kPRC));
    LOG.info(sprintf('   - volume:     %d', kVOL));
    LOG.info(sprintf('   - return:     %d', kRET));
    LOG.info(sprintf('   - bid:        %d', kBID));
    LOG.info(sprintf('   - ask:        %d', kASK));
    LOG.info(sprintf('   - SIC code:   %d', kSIC));
    LOG.info(sprintf('   - NAICS code: %d', kNAI));
    LOG.info(sprintf('   - shares:     %d', kSHR));
    LOG.info('');
    
    SUBCACHE.vals.PRC = NaN(ctdat, ctids);
    SUBCACHE.vals.VOL = NaN(ctdat, ctids);
    SUBCACHE.vals.RET = NaN(ctdat, ctids);
    SUBCACHE.vals.BID = NaN(ctdat, ctids);
    SUBCACHE.vals.ASK = NaN(ctdat, ctids);
    SUBCACHE.vals.SICCD = NaN(ctdat, ctids);
    SUBCACHE.vals.NAICS = NaN(ctdat, ctids);
    SUBCACHE.vals.SHROUT = NaN(ctdat, ctids);
    batch_counter = 0;
    row_counter = 0;
    datacurs = fetch(datacurs, cfg.FetchBatchSize);
    while ~strcmp(datacurs.Data, 'No Data')
        batch_counter = batch_counter+1;
        LOG.debug(sprintf(' -- Retrieving batch: %d', batch_counter));
        datavals = datacurs.Data;
        ctvals = size(datavals,1);
        LOG.debug(sprintf('    Starting PERMNO/date/rows: %s/%d/%d', ...
            datavals{1,kIDX}, datstr2int32(datavals{1,kDAT}), ctvals));
        % Some of the values come back as strings, some as numbers...
        for i=1:ctvals
            idx = datavals{i,kIDX};
            outcol = SUBCACHE.ids.colMapPERMNO(idx);
            dat = datstr2int32(datavals{i,kDAT});
            outrow = SUBCACHE.dates.rowMapDATE(dat);
            SUBCACHE.vals.PRC(outrow, outcol) = ...
                cell2mat(datavals(i,kPRC));
            SUBCACHE.vals.RET(outrow, outcol) = ...
                str2double(cell2mat(datavals(i,kRET)));
            SUBCACHE.vals.VOL(outrow, outcol) = ...
                cell2mat(datavals(i,kVOL));
            SUBCACHE.vals.BID(outrow, outcol) = ...
                cell2mat(datavals(i,kBID));
            SUBCACHE.vals.ASK(outrow, outcol) = ...
                cell2mat(datavals(i,kASK));
            SUBCACHE.vals.SICCD(outrow, outcol) = ...
                str2double(cell2mat(datavals(i,kSIC)));
            SUBCACHE.vals.NAICS(outrow, outcol) = ...
                str2double(cell2mat(datavals(i,kNAI)));
            SUBCACHE.vals.SHROUT(outrow, outcol) = ...
                cell2mat(datavals(i,kSHR));
            row_counter = row_counter+1;
        end
        LOG.debug(sprintf('    Cumulative rows/time: %d/%7.2f sec', ...
            row_counter, toc(tictime)));
        datacurs = fetch(datacurs, cfg.FetchBatchSize);
    end
    LOG.info('');
    LOG.info(sprintf('Time elapsed, SQL pull: %7.2f sec', toc(tictime)));
end

function [kDAT,kIDX,kPRC,kVOL,kRET,kBID,kASK,kSIC,kNAI,kSHR] = ...
    findCols(curs)
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
    kRET = -1;
    kBID = -1;
    kASK = -1;
    kSIC = -1;
    kNAI = -1;
    kSHR = -1;
    for i=1:propsize
        % Note the conversion to char -- SQL returns java.lang.String
        columnname = lower(char(properties.ColumnName{i}));
        switch columnname
            case 'date' 
                kDAT = i;
            case 'permno'
                kIDX = i;
            case 'prc'
                kPRC = i;
            case 'vol'
                kVOL = i;
            case 'ret'
                kRET = i;
            case 'bid'
                kBID = i;
            case 'ask'
                kASK = i;
            case 'siccd'
                kSIC = i;
            case 'naics'
                kNAI = i;
            case 'shrout'
                kSHR = i;
            otherwise
                errmsg = sprintf('Field not found %s ==> %s', ...
                    properties.ColumnName{i}, columnname);
                LOG.err(errmsg);
                error('OFRresearch:LIQ:CRSPfindCols', [errmsg '\n']);        
        end
    end
end

function rv = datstr2int32(datstr)
% Converts a string of form 'yyyy-mm-dd' to an int of form yyyymmdd
    yyyy = str2double(datstr(1:4));
    mm = str2double(datstr(6:7));
    dd = str2double(datstr(9:10));
    rv = yyyy*10000+mm*100+dd;
end



