function CACHE = impactTRACE(CACHE, cachefile, cfg)
%impactTRACE calculates price impacts for the TRACE data and caches results
% Parameters
%   cfg -   Structure containing estimation parameters for the 
%           Amihud and Kyle-Obizhaeva measures
%
% Returns
%   CACHE -  structure containing the data

    global LOG;
    
    LOG.info('');
    LOG.info('Calculating price impacts in impactTRACE');
    LOG.info(sprintf(' -- cachefile: %s', cachefile));

    if (testStructFieldExists(CACHE, 'TRACE') && ...
          testStructFieldExists(CACHE.TRACE, 'pi'))
        LOG.info('CACHE found, including TRACE.pi field');
        if (~testTRACECacheIntegrity(CACHE))
            errmsg = 'CACHE.TRACE.pi failed checks - rebuilding';
            LOG.err(errmsg);
            CACHE.TRACE = rmfield(CACHE.TRACE, 'pi');
            CACHE = makePriceImpactCache(CACHE, cfg);
            save(cachefile, '-struct', 'CACHE', '-v7.3');
        end
    else
        LOG.info('CACHE not found, building it from scratch');
        CACHE = makePriceImpactCache(CACHE, cfg);
        save(cachefile, '-struct', 'CACHE', '-v7.3');
    end
    
    if (~testTRACECacheIntegrity(CACHE))
        errmsg = 'CACHE.TRACE.pi FAILED INTEGRITY CHECKS - TERMINATING';
        LOG.err(errmsg);
        error('OFRAnnualReport:LIQ:CorruptCacheTRACE', [errmsg '\n']);
    end
    LOG.info('CACHE.TRACE complete');
    
end 

function CACHE = makePriceImpactCache(CACHE, param)

    global LOG;

    tictime = tic;
    
    LOG.info('');
    LOG.info('Identifying the 10 TRACE samples based on 1-digit SIC');

    % Create the TxN matrix of one-digit SIC codes
    sic = floor(CACHE.TRACE.vals.SICCD/1000);
    % Reduce it to a 1xN vector based on the modal values in each column
    sic = mode(sic);

    % sicmap starts as a simple vector of column indexes, [1 2 3 ... N]
    sicmap = 1:1:length(CACHE.TRACE.ids.BONDID); 
         
    LOG.info(' -- applying the TRACE samples to VOL, RET, PRC, etc.');
    for i = 0:9
        % Pick the subset of sicmap indexes matching sic==i
        sicmap_i = sicmap(sic==i); 
        % Subset a vector, ids_i, with only BONDIDs that match sic==i
        ids_i = CACHE.TRACE.ids.BONDID(sicmap_i);
        % Similarly subset the columns of the vals matrixes
        SAM_VOL = CACHE.TRACE.vals.VOL(:,sicmap_i);
        SAM_PRC = CACHE.TRACE.vals.PRC(:,sicmap_i);
        SAM_RET = CACHE.TRACE.vals.RET(:,sicmap_i);
        SAM_DATES = CACHE.TRACE.dates.vec;
        eval(['CACHE.TRACE.pi.sic' num2str(i) '_BONDID = ids_i;']);
        eval(['CACHE.TRACE.pi.sic' num2str(i) '_DATES = SAM_DATES;']);
        eval(['CACHE.TRACE.pi.sic' num2str(i) '_RET = SAM_RET;']);
        eval(['CACHE.TRACE.pi.sic' num2str(i) '_PRC = SAM_PRC;']);
        eval(['CACHE.TRACE.pi.sic' num2str(i) '_VOL = SAM_VOL;']);
    end
    clear i ids_i sicmap_i SAM_RET SAM_PRC SAM_VOL SAM_DATES;

%     % Pad *brief* episodes of no trading with return values of zero
%     price_lookback = 5;
%     for i=0:9
%         eval(['SAM_RET = CACHE.TRACE.pi.sic' num2str(i) '_RET;']);
%         eval(['SAM_PRC = CACHE.TRACE.pi.sic' num2str(i) '_PRC;']);
%         T = size(SAM_RET,1);
%         for j=1,size(SAM_RET,2)
%             for t=1+price_lookback:T
%                 if (isnan(SAM_RET(t,j)))
%                     SAM_PRC_LKBK = SAM_PRC(t-price_lookback:t-1,j);
%                     tt_lastPRC = find(~isnan(SAM_PRC_LKBK), 1, 'last');
%                     if (~isempty(SAM_PRC_LKBK(tt_lastPRC)))
%                         SAM_RET(t,j) = 0.0;
%                     end
%                 end
%             end
%         end
%     end
    
%     TRACE_PRC = CACHE.TRACE.vals.PRC;
%     TRACE_RET = CACHE.TRACE.vals.RET;
%     TRACE_VOL = CACHE.TRACE.vals.VOL;
    
    LOG.info('');
    LOG.info(sprintf('Time for TRACE SIC filtering exec: %7.2f sec', ...
        toc(tictime)));
    
%     param = readparam();
    
    %% AMIHUD

    LOG.info('');
    LOG.info('Computing Kyle''s lambda via the Amihud method');

%     CACHE.TRACE.pi.amihud.min_regress_obs = param.min_regress_obs;
%     CACHE.TRACE.pi.amihud.sample_max = param.am_sample_max;

    LOG.info('');
    LOG.info('The TRACE sample of corporate bond data');
    tic_klam = tic;
    CACHE.TRACE.pi.amihud.sample_max = ...
        min(param.am_sample_max, size(CACHE.TRACE.vals.RET, 2));
    for i = 0:CACHE.TRACE.pi.amihud.sample_max-1
        eval(['SAM_DATES = CACHE.TRACE.pi.sic' num2str(i) '_DATES;']);
        eval(['SAM_RET = CACHE.TRACE.pi.sic' num2str(i) '_RET;']);
        eval(['SAM_PRC = CACHE.TRACE.pi.sic' num2str(i) '_PRC;']);
        eval(['SAM_VOL = CACHE.TRACE.pi.sic' num2str(i) '_VOL;']);
        LOG.info(sprintf(' -- for 1-digit SIC = %d, %d firms', ...
            i, size(SAM_RET,2)));
        [klambdas, kdates] = ...
            kyles_lambda(SAM_RET, SAM_PRC, SAM_VOL, SAM_DATES, param);
        % Capturing the results
        eval(['CACHE.TRACE.pi.amihud' num2str(i) '_kdates = kdates;']);
        eval(['CACHE.TRACE.pi.amihud' num2str(i) '_klambdas = klambdas;']);
    end
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_klam)));
    clear tic_klam klambdas kdates SAM_RET SAM_PRC SAM_VOL SAM_DATES;

    %% KYLEOBIZ

    LOG.info('');
    LOG.info('Computing price impact via the Kyle and Obizhaeva method');

%     tic_kno = tic;
%     sample_max = min(param.ko_sample_max, size(CACHE.TRACE.vals.RET, 2));
%     TRACEPRC = CACHE.TRACE.vals.PRC(:,1:sample_max);
%     TRACERET = CACHE.TRACE.vals.RET(:,1:sample_max);
%     TRACEVOL = CACHE.TRACE.vals.VOL(:,1:sample_max);
%     LOG.info('');
%     if (CACHE.TRACE.pi.cfg.DoTRACEpar)
%         LOG.info('The TRACE bond data (parallel computations)');
%         results = parallel_config(results); % In case a config is needed
%         CACHE.TRACE.pi = ...
%             calc_kyleobiz_par(CACHE.TRACE.pi, TRACERET, TRACEPRC, TRACEVOL);
%     else
%         LOG.info('The TRACE bond data (sequential computations)');
%         CACHE.TRACE.pi = ...
%             calc_kyleobiz_seq(CACHE.TRACE.pi, TRACERET, TRACEPRC, TRACEVOL);
%     end
%     CACHE.TRACE.pi.kyleobiz.sample_max = sample_max;
%     CACHE.TRACE.pi.kyleobiz.dates = CACHE.TRACE.dates.vec;
%     LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_kno)));
%     clear TRACERET TRACEPRC TRACEVOL;
    
    tic_kno = tic;
    CACHE.TRACE.pi.kyleobiz.sample_max = ...
        min(param.ko_sample_max, size(CACHE.TRACE.vals.RET, 2));
    for i = 0:CACHE.TRACE.pi.kyleobiz.sample_max-1
        eval(['SAM_DATES = CACHE.TRACE.pi.sic' num2str(i) '_DATES;']);
        eval(['SAM_RET = CACHE.TRACE.pi.sic' num2str(i) '_RET;']);
        eval(['SAM_PRC = CACHE.TRACE.pi.sic' num2str(i) '_PRC;']);
        eval(['SAM_VOL = CACHE.TRACE.pi.sic' num2str(i) '_VOL;']);
        LOG.info(sprintf(' -- for 1-digit SIC = %d, %d firms', ...
            i, size(SAM_RET,2)));
        [avgCost, medCost] = ...
            kyle_obizhaeva_lambda(param, SAM_RET, SAM_PRC, SAM_VOL);
        % Capturing the results
        eval(['CACHE.TRACE.pi.kyleobiz' num2str(i) '_avgCost = avgCost;']);
        eval(['CACHE.TRACE.pi.kyleobiz' num2str(i) '_medCost = medCost;']);
    end
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_kno)));
    clear i tic_kno avgCost medCost SAM_RET SAM_PRC SAM_VOL;

%     LOG.info('');
%     LOG.info('The TRACE sample of volatitity futures data');
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
    
    LOG.info('');
    LOG.info(sprintf('Time elapsed, price impact, total: %7.2f sec', ...
        toc(tictime)));
end


function aokay = testTRACECacheIntegrity(cach)
    % Assume it's a-okay unless and until a test below fails
    aokay = true();
    % Basic existence checks:
    CACX = cach.TRACE.pi;
    for i = 0:9
        pfx = ['sic' num2str(i)];
        aokay = min(aokay, testStructFieldExists(CACX, [pfx '_BONDID']));
        aokay = min(aokay, testStructFieldExists(CACX, [pfx '_DATES']));
        aokay = min(aokay, testStructFieldExists(CACX, [pfx '_RET']));
        aokay = min(aokay, testStructFieldExists(CACX, [pfx '_PRC']));
        aokay = min(aokay, testStructFieldExists(CACX, [pfx '_VOL']));
        pfx = ['amihud' num2str(i)];
        aokay = min(aokay, testStructFieldExists(CACX, [pfx '_kdates']));
        aokay = min(aokay, testStructFieldExists(CACX, [pfx '_klambdas']));
        pfx = ['kyleobiz' num2str(i)];
        aokay = min(aokay, testStructFieldExists(CACX, [pfx '_avgCost']));
        aokay = min(aokay, testStructFieldExists(CACX, [pfx '_medCost']));
    end
%     % The dates and IDs should have identical size.  Test it:
%     if (size(cach.dates.vec,1) ~= size(cach.vals.PRC, 1))
%         errmsg = sprintf('Date mismatch: dates (%d) vs. vals (%d)', ...
%             size(cach.dates.vec,1), size(cach.vals, 1));
%         LOG.err(errmsg);
%         aokay = false();
%     end
%     if (size(cach.ids.BONDID,2) ~= size(cach.vals.VOL, 2))
%         errmsg = sprintf('ID size mismatch: ids (%d) vs. vals (%d)', ...
%             size(cach.ids.BONDID,2), size(cach.vals, 2));
%         LOG.err(errmsg);
%         aokay = false();
%     end
end



