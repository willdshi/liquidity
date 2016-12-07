function [dateSet, IDSet, prcMatrix, retMatrix, volMatrix] = fetchdata(spec)
%FETCHDATA  Program to read and cache CRSP securities price data
%
% Parameters
%  spec - structure containing process parameters:
%            spec.csvpath -    location of the input CSV CRSP file
%            spec.csvfile -    name of the input CSV CRSP file
%            spec.cachepath -  location of the MAT cache file 
%            spec.cachefile -  name of the MAT cache file 
%            spec.identifier - security identifier in CRSP CSV file
%            spec.startdate -  date to begin extracting data (int32, YYYYMMDD)
%            spec.stopdate -   date to end extracting data (int32, YYYYMMDD)

    global LOG;
    
    % Path to the input CSV file
    csvpath = strtrim(spec.csvpath);
    lpath = length(csvpath);
    if (lpath>=1 && ~strcmp(csvpath(lpath:lpath), filesep())) 
        csvpath = [csvpath filesep()];
    end
    csvfile = strtrim(spec.csvfile);
    csvfullpath = [csvpath csvfile];
    LOG.info(' ');
    LOG.info(['CSV file:  ', csvfullpath]);
    % Path to the temporary MAT cache
    cachepath = strtrim(spec.cachepath);
    LOG.info(' ');
    LOG.info(['Cache directory:  ', cachepath]);
    lpath = length(cachepath);
    if (lpath>=1 && ~strcmp(cachepath(lpath:lpath), filesep())) 
        cachepath = [cachepath filesep()];
    end
    cachefile = strtrim(spec.cachefile);
    cachefullpath = [cachepath cachefile];

    % Other input identifiers
    reshapespec.cachepath = cachepath;
    reshapespec.sourcefile = csvfullpath;
    reshapespec.idname = spec.identifier;
    reshapespec.datename = spec.datename;
    reshapespec.startYYYYMMDD = spec.startdate;
    reshapespec.endYYYYMMDD = spec.stopdate;

    LOG.info(['Cache file:  ', cachefullpath]);
    if (exist(cachepath, 'dir') && exist(cachefullpath, 'file'))
        % Recover prior CACHE
        CACHE = load(cachefullpath);
    else
        % Create a new CACHE
        CACHE.process_cache = cachefullpath;
        save(cachefullpath, '-struct', 'CACHE');
    end
    
    if ~structureFieldExists(CACHE, 'prcMatrix')
        LOG.info('Reading price data');
        reshapespec.varname = 'PRC';
        [prcDateSet, prcIDSet, prcIDSet2, prcMatrix] = reshapeCRSPcsv(reshapespec);
    else
        LOG.info('Extracting price data from cache');
        prcDateSet = CACHE.dateSet;
        prcIDSet = CACHE.IDSet;
        prcMatrix  = CACHE.prcMatrix;
    end
    
    if ~structureFieldExists(CACHE, 'volMatrix')
        LOG.info('Reading volume data');
        reshapespec.varname = 'VOL';
        [volDateSet, volIDSet, ~, volMatrix] = reshapeCRSPcsv(reshapespec);
    else
        LOG.info('Extracting volume data from cache');
        volDateSet = CACHE.dateSet;
        volIDSet = CACHE.IDSet;
        volMatrix  = CACHE.volMatrix;
    end
    
    if ~structureFieldExists(CACHE, 'retMatrix')
        LOG.info('Reading returns data');
        reshapespec.varname = 'RET';
        [retDateSet, retIDSet, ~, retMatrix] = reshapeCRSPcsv(reshapespec);
    else
        LOG.info('Extracting returns data from cache');
        retDateSet = CACHE.dateSet;
        retIDSet = CACHE.IDSet;
        retMatrix  = CACHE.retMatrix;
    end
    
    % The dates and IDs should be identical.  Test it:
    for i=1:max(size(prcDateSet,1), size(volDateSet, 1))
        if (prcDateSet(1,i) ~= volDateSet(1,i))
            LOG.err(['Date mismatch at ' int2str(i) ':']);
            LOG.err(['  prcDateSet(1,i): ' int2str(prcDateSet(1,i))]);
            LOG.err(['  volDateSet(1,i): ' int2str(volDateSet(1,i))]);
        end
    end
    for i=1:max(size(prcDateSet,1), size(retDateSet, 1))
        if (prcDateSet(1,i) ~= retDateSet(1,i))
            LOG.err(['Date mismatch at ' int2str(i) ':']);
            LOG.err(['  prcDateSet(1,i): ' int2str(prcDateSet(1,i))]);
            LOG.err(['  retDateSet(1,i): ' int2str(retDateSet(1,i))]);
        end
    end
    for i=1:max(size(prcIDSet,1), size(volIDSet, 1))
        if (~strcmp(prcIDSet(1,i),volIDSet(1,i)))
            LOG.err(['Date mismatch at ' int2str(i) ':']);
            LOG.err(['  prcIDSet(1,i): ' int2str(prcIDSet(1,i))]);
            LOG.err(['  volIDSet(1,i): ' int2str(volIDSet(1,i))]);
        end
    end
    for i=1:max(size(prcIDSet,1), size(retIDSet, 1))
        if (~strcmp(prcIDSet(1,i),retIDSet(1,i)))
            LOG.err(['Date mismatch at ' int2str(i) ':']);
            LOG.err(['  prcIDSet(1,i): ' int2str(prcIDSet(1,i))]);
            LOG.err(['  retIDSet(1,i): ' int2str(retIDSet(1,i))]);
        end
    end
    
    dateSet = prcDateSet;
    IDSet = prcIDSet;
    
    LOG.warn('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - ');
    LOG.warn([' Caching:  ' cachefullpath]);
    LOG.warn(['  - Time:  ' datestr(now)]);
    CACHE.prcMatrix = prcMatrix;
    CACHE.volMatrix = volMatrix;
    CACHE.retMatrix = retMatrix;
    CACHE.dateSet = prcDateSet;
    CACHE.IDSet = prcIDSet;
    CACHE.IDSet2 = prcIDSet2;
    save(cachefullpath, '-struct', 'CACHE');
    LOG.warn('##########################################################');
    LOG.warn('');
    
end
