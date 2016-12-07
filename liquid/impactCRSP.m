function CACHE = impactCRSP(CACHE, cachefile, cfg)
%impactCRSP calculates price impacts for the CRSP data and caches results
% Parameters
%   cfg -   Structure containing estimation parameters for the 
%           Amihud and Kyle-Obizhaeva measures
%
% Returns
%   CACHE -  structure containing the data

    global LOG;
    
    LOG.info('');
    LOG.info('Calculating price impacts in impactCRSP');
    LOG.info(sprintf(' -- cachefile: %s', cachefile));

    if (testStructFieldExists(CACHE, 'CRSP') && ...
          testStructFieldExists(CACHE.CRSP, 'pi'))
        LOG.info('CACHE found, including CRSP.pi field');
        if (~testCRSPCacheIntegrity(CACHE))
            errmsg = 'CACHE.CRSP.pi failed checks - rebuilding';
            LOG.err(errmsg);
            CACHE.CRSP = rmfield(CACHE.CRSP, 'pi');
            CACHE = makePriceImpactCache(CACHE, cfg);
            save(cachefile, '-struct', 'CACHE', '-v7.3');
        end
    else
        LOG.info('CACHE not found, building it from scratch');
        CACHE = makePriceImpactCache(CACHE, cfg);
        save(cachefile, '-struct', 'CACHE', '-v7.3');
    end
    
    if (~testCRSPCacheIntegrity(CACHE))
        errmsg = 'CACHE.CRSP.pi FAILED INTEGRITY CHECKS - TERMINATING';
        LOG.err(errmsg);
        error('OFRAnnualReport:LIQ:CorruptCacheCRSP', [errmsg '\n']);
    end
    LOG.info('CACHE.CRSP complete');
    
end 

function CACHE = makePriceImpactCache(CACHE, param)

    global LOG;

    tictime = tic;
    
    LOG.info('');
    LOG.info('Identifying the 10 CRSP samples based on 1-digit SIC');

    % Create the TxN matrix of one-digit SIC codes
    sic = floor(CACHE.CRSP.vals.SICCD/1000);
    % Reduce it to a 1xN vector based on the modal values in each column
    sic = mode(sic);

    % sicmap starts as a simple vector of column indexes, [1 2 3 ... N]
    sicmap = 1:1:length(CACHE.CRSP.ids.PERMNO); 
         
    LOG.info(' -- applying the CRSP samples to VOL, RET, PRC, etc.');
    for i = 0:9
        % Pick the subset of sicmap indexes matching sic==i
        sicmap_i = sicmap(sic==i); 
        % Subset a vector, ids_i, with only PERMNOs that match sic==i
        ids_i = CACHE.CRSP.ids.PERMNO(sicmap_i);
        % Similarly subset the columns of the vals matrixes
        SAM_VOL = CACHE.CRSP.vals.VOL(:,sicmap_i);
        SAM_PRC = CACHE.CRSP.vals.PRC(:,sicmap_i);
        % CRSP shows stale prices at the close with a minus sign; fix it:
        SAM_RET = abs(CACHE.CRSP.vals.PRC(:,sicmap_i));
        SAM_DATES = CACHE.CRSP.dates.vec;
        eval(['CACHE.CRSP.pi.sic' num2str(i) '_PERMNO = ids_i;']);
        eval(['CACHE.CRSP.pi.sic' num2str(i) '_DATES = SAM_DATES;']);
        eval(['CACHE.CRSP.pi.sic' num2str(i) '_RET = SAM_RET;']);
        eval(['CACHE.CRSP.pi.sic' num2str(i) '_PRC = SAM_PRC;']);
        eval(['CACHE.CRSP.pi.sic' num2str(i) '_VOL = SAM_VOL;']);
    end
    clear i ids_i sicmap_i SAM_RET SAM_PRC SAM_VOL SAM_DATES;

    LOG.info('');
    LOG.info(sprintf('Time for CRSP SIC filtering exec: %7.2f sec', ...
        toc(tictime)));
    
    param = readparam();
    
    %% AMIHUD

    LOG.info('');
    LOG.info('Computing Kyle''s lambda via the Amihud method');

%     CACHE.CRSP.pi.amihud.min_regress_obs = param.min_regress_obs;
%     CACHE.CRSP.pi.amihud.sample_max = param.am_sample_max;

    LOG.info('');
    LOG.info('The CRSP sample of daily stock data');
    tic_klam = tic;
% % %     CACHE.CRSP.pi.amihud.sample_max = ...
% % %         min(param.am_sample_max, size(CACHE.CRSP.vals.RET, 2));
    for i = 0:9
        eval(['SAM_DATES = CACHE.CRSP.pi.sic' num2str(i) '_DATES;']);
        eval(['SAM_RET = CACHE.CRSP.pi.sic' num2str(i) '_RET;']);
        eval(['SAM_PRC = CACHE.CRSP.pi.sic' num2str(i) '_PRC;']);
        eval(['SAM_VOL = CACHE.CRSP.pi.sic' num2str(i) '_VOL;']);
        LOG.info(sprintf(' -- for 1-digit SIC = %d, %d firms', ...
            i, size(SAM_RET,2)));
        [klambdas, kdates] = ...
            kyles_lambda(SAM_RET, SAM_PRC, SAM_VOL, SAM_DATES, param);
        % Capturing the results
        eval(['CACHE.CRSP.pi.amihud' num2str(i) '_kdates = kdates;']);
        eval(['CACHE.CRSP.pi.amihud' num2str(i) '_klambdas = klambdas;']);
    end
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_klam)));
    clear tic_klam klambdas kdates SAM_RET SAM_PRC SAM_VOL SAM_DATES;

    %% KYLEOBIZ

    LOG.info('');
    LOG.info('Computing price impact via the Kyle and Obizhaeva method');

%     tic_kno = tic;
%     sample_max = min(param.ko_sample_max, size(CACHE.CRSP.vals.RET, 2));
%     CRSPPRC = CACHE.CRSP.vals.PRC(:,1:sample_max);
%     CRSPRET = CACHE.CRSP.vals.RET(:,1:sample_max);
%     CRSPVOL = CACHE.CRSP.vals.VOL(:,1:sample_max);
%     LOG.info('');
%     if (CACHE.CRSP.pi.cfg.DoCRSPpar)
%         LOG.info('The CRSP bond data (parallel computations)');
%         results = parallel_config(results); % In case a config is needed
%         CACHE.CRSP.pi = ...
%             calc_kyleobiz_par(CACHE.CRSP.pi, CRSPRET, CRSPPRC, CRSPVOL);
%     else
%         LOG.info('The CRSP bond data (sequential computations)');
%         CACHE.CRSP.pi = ...
%             calc_kyleobiz_seq(CACHE.CRSP.pi, CRSPRET, CRSPPRC, CRSPVOL);
%     end
%     CACHE.CRSP.pi.kyleobiz.sample_max = sample_max;
%     CACHE.CRSP.pi.kyleobiz.dates = CACHE.CRSP.dates.vec;
%     LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_kno)));
%     clear CRSPRET CRSPPRC CRSPVOL;
    
    tic_kno = tic;
% % %     CACHE.CRSP.pi.kyleobiz.sample_max = ...
% % %         min(param.ko_sample_max, size(CACHE.CRSP.vals.RET, 2));
    for i = 0:9
        eval(['SAM_DATES = CACHE.CRSP.pi.sic' num2str(i) '_DATES;']);
        eval(['SAM_RET = CACHE.CRSP.pi.sic' num2str(i) '_RET;']);
        eval(['SAM_PRC = CACHE.CRSP.pi.sic' num2str(i) '_PRC;']);
        eval(['SAM_VOL = CACHE.CRSP.pi.sic' num2str(i) '_VOL;']);
        LOG.info(sprintf(' -- for 1-digit SIC = %d, %d firms', ...
            i, size(SAM_RET,2)));
        [avgCost, medCost] = ...
            kyle_obizhaeva_lambda(param, SAM_RET, SAM_PRC, SAM_VOL);
        % Capturing the results
        eval(['CACHE.CRSP.pi.kyleobiz' num2str(i) '_avgCost = avgCost;']);
        eval(['CACHE.CRSP.pi.kyleobiz' num2str(i) '_medCost = medCost;']);
    end
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_kno)));
    clear i tic_kno avgCost medCost SAM_RET SAM_PRC SAM_VOL;

%     LOG.info('');
%     LOG.info('The CRSP sample of volatitity futures data');
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


function aokay = testCRSPCacheIntegrity(cach)
    % Assume it's a-okay unless and until a test below fails
    aokay = true();
    % Basic existence checks:
    CACX = cach.CRSP.pi;
    for i = 0:9
        pfx = ['sic' num2str(i)];
        aokay = min(aokay, testStructFieldExists(CACX, [pfx '_PERMNO']));
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



