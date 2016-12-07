function RSLT = trace_csv2local(configfile)
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
%     LIQ.TRACE.local.cachedir

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

    % Pull the data into the cache
    LOG.info('');
    LOG.info(['Caching data in ' mfilename '.m']);
    LOG.info(sprintf(' -- cachefile: %s', RSLT.cachefile));

    LOG.info('');
    LOG.info('Identifying the TRACE samples Investment Grade');
    
    RSLT.CSVdir = CONFG.getProp('LIQ.TRACE.local.cachedir');
    RSLT.CSVfile = CONFG.getProp('LIQ.TRACE.local.csvfile');

    % Read Text Files from Repository
    RSLT.CSVcfg.ALL_file = [RSLT.CSVdir filesep RSLT.CSVfile];
    RSLT.CSVcfg.BONDID_file = [RSLT.CSVdir filesep 'bondid_non.csv'];
    RSLT.CSVcfg.DATES_file = [RSLT.CSVdir filesep 'dates_non.csv'];
    RSLT.CSVcfg.PRC_file = [RSLT.CSVdir 'prc_non.csv'];
    RSLT.CSVcfg.VOL_file = [RSLT.CSVdir 'vol_non.csv'];
    RSLT.CSVcfg.CRS_file = [RSLT.CSVdir 'crs_non.csv'];
    RSLT.CSVcfg.CRM_file = [RSLT.CSVdir 'crm_non.csv'];
    RSLT.CSVcfg.CRF_file = [RSLT.CSVdir 'crf_non.csv'];
    RSLT.CSVcfg.DATES_file;
    % Create the CACHE
    CACHE.data = makeCache(RSLT.CSVcfg);
    
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
        read_textfile_to_var('trace_csv2local.m');
    manifest.code.trace_testcache_local = ...
        read_textfile_to_var('trace_testcache_local.m');
    manifest.code.LOG = read_textfile_to_var(RSLT.logfile);
end

function SUBCACHE = makeCache(cfg)

    global LOG;

    tictime = tic;

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
    datavals{1}(1,:) = [];
    ctids = length(datavals{1});
    LOG.info(sprintf('  Number of values retrieved: %d', ctids));
    SUBCACHE.ids.BONDID = cell(1, ctids);
    SUBCACHE.ids.colMapBONDID = ...
        containers.Map('KeyType','char','ValueType','int32');
    for i=1:ctids
        idi = datavals{1}{i+1};
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
%     SUBCACHE.vals.VLD = nan(ctdat, ctids);
%     SUBCACHE.vals.CRS = int8(nan(ctdat, ctids));
%     SUBCACHE.vals.CGS = int8(nan(ctdat, ctids));
%     SUBCACHE.vals.CDS = int16(nan(ctdat, ctids));
%     SUBCACHE.vals.CRM = int8(nan(ctdat, ctids));
%     SUBCACHE.vals.CGM = int8(nan(ctdat, ctids));
%     SUBCACHE.vals.CDM = int16(nan(ctdat, ctids));
%     SUBCACHE.vals.CRF = int8(nan(ctdat, ctids));
%     SUBCACHE.vals.CGF = int8(nan(ctdat, ctids));
%     SUBCACHE.vals.CDF = int16(nan(ctdat, ctids));
    SUBCACHE.vals.CGc = int8(nan(ctdat, ctids));
    
    % Read the IDs row in the CSV file into a single cell of a cell array
    fid = fopen(cfg.ALL_file);
    headrow = textscan(fid, '%s', 1, 'Delimiter','\n');
    headrow = textscan(headrow{1}{1},'%s','Delimiter',',');
    headrow = headrow{1};
    [kCUS,kDAT,kPRC,kVOL,kCRS,kCGS,kCDS,kCRM,kCGM,kCDM,kCRF,kCGF,kCDF] =...
        findCols(headrow);
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
    SUBCACHE.vals.CRmapM = ...
        containers.Map('KeyType','char','ValueType','int8');
    SUBCACHE.vals.CRmapM('') = 0;
    SUBCACHE.vals.CRmapM('NR') = 0;
    SUBCACHE.vals.CRmapM('not rated') = 0;
    SUBCACHE.vals.CRmapM('NR') = 0;
    for i = 1:size(SUBCACHE.vals.CRsetM,1)
        SUBCACHE.vals.CRmapM(SUBCACHE.vals.CRsetM{i}) = i;
    end
    % Set up S&P map
    SUBCACHE.vals.CRsetS = {'AAA';'AA+';'AA';'AA-';'A+';'A';'A-';
        'BBB+';'BBB';'BBB-';'BB+';'BB';'BB-';'B+';'B';'B-';
        'CCC+';'CCC';'CCC-';'CC';'C';'D';};
    SUBCACHE.vals.CRmapS = ...
        containers.Map('KeyType','char','ValueType','int8');
    SUBCACHE.vals.CRmapS('') = 0;
    SUBCACHE.vals.CRmapS('NR') = 0;
    SUBCACHE.vals.CRmapS('not rated') = 0;
    SUBCACHE.vals.CRmapS('NR') = 0;
    for i = 1:size(SUBCACHE.vals.CRsetS,1)
        SUBCACHE.vals.CRmapS(SUBCACHE.vals.CRsetS{i}) = i;
    end
    % Set up Fitch map
    SUBCACHE.vals.CRsetF = {'AAA';'AA+';'AA';'AA-';'A+';'A';'A-';
        'BBB+';'BBB';'BBB-';'BB+';'BB';'BB-';'B+';'B';'B-';
        'CCC';'DDD';'DD';'D';};
    SUBCACHE.vals.CRmapF = ...
        containers.Map('KeyType','char','ValueType','int8');
    SUBCACHE.vals.CRmapF('') = 0;
    SUBCACHE.vals.CRmapF('NR') = 0;
    SUBCACHE.vals.CRmapF('not rated') = 0;
    SUBCACHE.vals.CRmapF('NR') = 0;
    for i = 1:size(SUBCACHE.vals.CRsetF,1)
        SUBCACHE.vals.CRmapF(SUBCACHE.vals.CRsetF{i}) = i;
    end

    fmt = '%s %d %s %f %d %s %s %d8 %d %s %s %d8 %d %s %s %d8 %d %d8 %s %s';

    % Read the first row to see the sequence
    nextrow = textscan(fid, '%s', 1, 'Delimiter','\n');
    nextrow = textscan(nextrow{1}{1}, fmt, 'Delimiter', ',');
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
    lagCRF = SUBCACHE.vals.CRmapF(nextrow{kCRF}{1}); 
    lagCDF = nextrow{kCDF};
    lagCGc = pecking_order(lagCGM, lagCGS, lagCGF);
    lagVLD = lagPRC * lagVOL;
    
    % Now step through and write out values when the ID or date changes
    while ~feof(fid)
        nextrow = textscan(fid, '%s', 1, 'Delimiter','\n');
        nextrow = textscan(nextrow{1}{1}, fmt, 'Delimiter', ',');
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
%             SUBCACHE.vals.VLD(irow, jcol) = lagVLD;
%             SUBCACHE.vals.CRS(irow, jcol) = SUBCACHE.vals.CRmapS(lagCRS{1});
%             SUBCACHE.vals.CGS(irow, jcol) = lagCGS;
%             SUBCACHE.vals.CDS(irow, jcol) = lagCDS;
%             SUBCACHE.vals.CRM(irow, jcol) = SUBCACHE.vals.CRmapM(lagCRM{1});
%             SUBCACHE.vals.CGM(irow, jcol) = lagCGM;
%             SUBCACHE.vals.CDM(irow, jcol) = lagCDM;
%             SUBCACHE.vals.CRF(irow, jcol) = SUBCACHE.vals.CRmapS(lagCRF{1});
%             SUBCACHE.vals.CGF(irow, jcol) = lagCGF;
%             SUBCACHE.vals.CDF(irow, jcol) = lagCDF;
            SUBCACHE.vals.CGc(irow, jcol) = lagCGc;
            SUBCACHE.vals.CGc(irow, jcol) = ...
                pecking_order(lagCGM, lagCGS, lagCGF);
            lagVOL = VOL;
            lagVLD = PRC*VOL;
        end
        lagCUS = CUS; 
        lagDAT = DAT; 
        lagPRC = PRC; 
        lagCRS = SUBCACHE.vals.CRmapS(nextrow{kCRS}{1}); 
        lagCGS = nextrow{kCGS}; 
        lagCDS = nextrow{kCDS}; 
        lagCRM = SUBCACHE.vals.CRmapM(nextrow{kCRM}{1}); 
        lagCGM = nextrow{kCGM}; 
        lagCDM = nextrow{kCDM}; 
        lagCRF = SUBCACHE.vals.CRmapF(nextrow{kCRF}{1}); 
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

% function rv = datstr2int32(datstr)
% % Converts a string of form 'yyyy-mm-dd' to an int of form yyyymmdd
%     yyyy = str2double(datstr(1:4));
%     mm = str2double(datstr(6:7));
%     dd = str2double(datstr(9:10));
%     rv = yyyy*10000+mm*100+dd;
% end

function [kCUS,kDAT,kPRC,kVOL,kCRS,kCGS,kCDS,kCRM,kCGM,kCDM,kCRF,kCGF,kCDF] = ...
    findCols(headrow)

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
            case 'rating_grade' 
            case 'portfolio' 
            otherwise
                errmsg = sprintf('Field not found %s ==> %s', ...
                    headrow{i}, columnname);
                LOG.err(errmsg);
                error('OFRresearch:LIQ:TRACEfindCols', [errmsg '\n']);        
        end
    end
end