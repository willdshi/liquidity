function combined_cache = reassemble_cache(cacheinfo)

    global LOG;

    startyear = int32(cacheinfo.startdate/10000);
    stopyear = int32(cacheinfo.stopdate/10000);
    totalyears = stopyear - startyear + 1;
    
    LOG.info('');
    LOG.info(sprintf('In reassemble_cache for %d to %d', startyear, stopyear));

    % Preallocate everything oversize; to be trimmed later
    dates.vec = NaN*ones(totalyears*366,1);
    datescursor = 1;
    % Create the vals matrices if they don't exist
    valscursor = 1;
    cacheinfo.year = startyear;
    CACHE = retrieve_cache(cacheinfo);
    vnames = fieldnames(CACHE.vals);
    for j=1:length(vnames)
        eval(['[~, cct]=size(CACHE.vals.' vnames{j} ');'])
        cct = cct*(stopyear-startyear+1);
        eval(['vals.' vnames{j} '=NaN*ones(length(dates.vec),cct);'])
    end
    ids.PERMNO = {1, cct};
    ids.COMNAM = {1, cct};
    ids.CUSIP = {1, cct};
    ids.NCUSIP = {1, cct};
    ids.TICKER = {1, cct};
    clear cct;

    ids.colMapCOMNAM = containers.Map('KeyType','char', 'ValueType','int32');
    ids.colMapCUSIP = containers.Map('KeyType','char', 'ValueType','int32');
    ids.colMapNCUSIP = containers.Map('KeyType','char', 'ValueType','int32');
    ids.colMapPERMNO = containers.Map('KeyType','char', 'ValueType','int32');
    ids.colMapTICKER = containers.Map('KeyType','char', 'ValueType','int32');

    for yr = startyear:stopyear
        ticstart = tic;
   
        cacheinfo.year = yr;
        CACHE = retrieve_cache(cacheinfo);
        countIDs = size(CACHE.ids.PERMNO,2);
        countDates = size(dates.vec,1);
        countCacheDates = size(CACHE.dates.vec,1);
        
        % Expand the collection of dates
        datescursornew = datescursor + length(CACHE.dates.vec);
        dates.vec(datescursor:datescursornew-1, 1) = CACHE.dates.vec;
        datescursor = datescursornew;

        % Paste the new values from the cache into the extant vals matrices
        for i=1:length(CACHE.ids.PERMNO)
            thisPERMNO = CACHE.ids.PERMNO(1,i);
            colthis = find(strcmp(ids.PERMNO, thisPERMNO)); 
            if (isempty(colthis))
                % Add the newfound entry to the various id sets
                ids.PERMNO = [ids.PERMNO thisPERMNO];
                ids.COMNAM = [ids.COMNAM CACHE.ids.COMNAM(1,i)];
                ids.CUSIP = [ids.CUSIP CACHE.ids.CUSIP(1,i)];
                ids.NCUSIP = [ids.NCUSIP CACHE.ids.NCUSIP(1,i)];
                ids.TICKER = [ids.TICKER CACHE.ids.TICKER(1,i)];
                colthis = find(strcmp(ids.PERMNO, thisPERMNO)); 
                ids.colMapCOMNAM(ids.COMNAM(1,colthis)) = colthis;
                ids.colMapCUSIP(ids.CUSIP(1,colthis)) = colthis;
                ids.colMapNCUSIP(ids.NCUSIP(1,colthis)) = colthis;
                ids.colMapPERMNO(ids.PERMNO(1,colthis)) = colthis;
                ids.colMapTICKER(ids.TICKER(1,colthis)) = colthis;

            end
            for j=1:length(vnames)
                eval(['vals.' vnames{j} '(countDates+1:end,colthis)=' ...
                    'CACHE.vals.' vnames{j} '(:,i);']);
            end    
        end
        
        tocelapse = toc(ticstart);
        disp(sprintf('Year complete %d, it took %d.\n', yr, tocelapse));
        
    end
    
    combined_cache.ids = ids;
    combined_cache.dates = dates;
    combined_cache.vals = vals;
    
end
