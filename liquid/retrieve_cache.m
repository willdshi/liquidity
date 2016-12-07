function CACHE = retrieve_cache(cacheinfo)

    global LOG;

    LOG.info('');
    LOG.info(sprintf('Running retrieve_cache for %d', cacheinfo.year));
    
    year = cacheinfo.year;

    inputDir = cacheinfo.inputDir;
    cacheDir = cacheinfo.cacheDir;

    cachename = cacheinfo.cachename;
    cachename = strrep(cachename, 'yyyy', num2str(year)); 
    cachefile = [pwd filesep cacheDir filesep cachename];
    
    if (exist(cachefile, 'file'))
        CACHE = load(cachefile);
    else
        % Build the CACHE from scratch
        filename = cacheinfo.filename;
        filename = strrep(filename, 'yyyy', num2str(year));
        CRSPspec.sourcefile = [pwd filesep inputDir filesep filename];
        CRSPspec.cachepath = [pwd filesep cacheDir];
        CRSPspec.startdate = cacheinfo.startdate;
        CRSPspec.stopdate = cacheinfo.stopdate;
        CRSPspec.varlist = cacheinfo.varlist;
        [dates, ids, vals] = CRSPreshapeCSV(CRSPspec);
        CACHE.dates = dates;
        CACHE.ids = ids;
        CACHE.vals = vals;
        save(cachefile, '-struct', 'CACHE');
    end

    %% TESTING CACHE INTEGRITY
    
    % Assume it's a-okay unless and until a test below fails
    aokay = true();
    % Basic existence checks:
    varnames = textscan(cacheinfo.varlist, '%s', 'delimiter', ',');
    for j=1:length(varnames{1})
        aokay = min(aokay, testStructureFieldExists(CACHE.vals,varnames{1}{j}));
    end    
    aokay = min(aokay, testStructureFieldExists(CACHE, 'ids'));
    aokay = min(aokay, testStructureFieldExists(CACHE, 'dates'));
    aokay = min(aokay, testStructureFieldExists(CACHE, 'vals'));
    aokay = min(aokay, testStructureFieldExists(CACHE.ids, 'COMNAM'));
    aokay = min(aokay, testStructureFieldExists(CACHE.ids, 'CUSIP'));
    aokay = min(aokay, testStructureFieldExists(CACHE.ids, 'NCUSIP'));
    aokay = min(aokay, testStructureFieldExists(CACHE.ids, 'PERMNO'));
    aokay = min(aokay, testStructureFieldExists(CACHE.ids, 'TICKER'));
    aokay = min(aokay, testStructureFieldExists(CACHE.dates, 'vec'));
    % The dates and IDs should have identical size.  Test it:
    if (size(CACHE.dates.vec,1) ~= size(CACHE.vals.PRC, 1))
        errmsg = sprintf('Date mismatch between dates (%d) and vals (%d)', ...
            size(CACHE.dates.vec,1), size(CACHE.vals, 1));
        LOG.err(errmsg);
        aokay = false();
    end
    if (size(CACHE.ids.PERMNO,2) ~= size(CACHE.vals.VOL, 2))
        errmsg = sprintf('ID size mismatch between ids (%d) and vals (%d)', ...
            size(CACHE.ids.PERMNO,2), size(CACHE.vals, 2));
        LOG.err(errmsg);
        aokay = false();
    end
    if (~aokay)
        errmsg = 'CACHE FAILED INTEGRITY CHECKS - TERMINATING';
        LOG.err(errmsg);
        error('OFRAnnualReport:EQUITYLIQ:CorruptCache', [errmsg '\n']);
    end

end

function aokay = testStructureFieldExists(struc, field)
    aokay = true();
    if (~structureFieldExists(struc, field))
        LOG.err(['Missing field ' field ' in cache']);
        aokay = false();
    end
end