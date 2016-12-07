function results = liquidity_proc(results)

    global LOG;

    LOG.info('');
    LOG.info('..........................................................');
    LOG.info(sprintf('Running liquidity_proc'));
    LOG.info('..........................................................');

    results = do_vix(results);
%     results = do_wti(results);
%     results = do_crsp(results);
%     results = do_trace(results);
    
end

function foo()
    %% Building the samples
    
    global LOG;
    global CACHE;
    global CONFG;

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
        eval(['results.CRSP' num2str(i) '_PERMNO = ids_i;']);
        eval(['results.CRSP' num2str(i) '_DATES = SAM_DATES;']);
        eval(['results.CRSP' num2str(i) '_RET = SAM_RET;']);
        eval(['results.CRSP' num2str(i) '_PRC = SAM_PRC;']);
        eval(['results.CRSP' num2str(i) '_VOL = SAM_VOL;']);
    end
    clear i ids_i sicmap_i SAM_RET SAM_PRC SAM_VOL SAM_DATES;

    LOG.info('');
    LOG.info('Identifying the 9 VIX contracts based on term to maturity');
    VIX_PRC = CACHE.VIX.vals.PRC;
    VIX_RET = CACHE.VIX.vals.RET;
    VIX_VOL = CACHE.VIX.vals.VOL;
    
    LOG.info('');
    LOG.info('Identifying the 7 WTI contracts based on term to maturity');
    WTI_PRC = CACHE.WTI.vals.PRC;
    WTI_RET = CACHE.WTI.vals.RET;
    WTI_VOL = CACHE.WTI.vals.VOL;
    
    
    %% AMIHUD

    LOG.info('');
    LOG.info('Computing Kyle''s lambda via the Amihud method');

    cfPfx = ['LIQ.AMIHUD' '.'];
    param.min_regress_obs = CONFG.getPropDouble([cfPfx 'min_regress_obs']);
    results.amihud.min_regress_obs = param.min_regress_obs;
    results.amihud.sample_max = CONFG.getPropInt([cfPfx 'sample_max']);

    LOG.info('');
    LOG.info('The CRSP sample of daily stock data');
    tic_klam = tic;
    results.amihud.sample_max_CRSP = ...
        min(results.amihud.sample_max,size(results.CRSP0_RET, 2));
    for i = 0:results.amihud.sample_max_CRSP-1
        LOG.info(sprintf(' -- for 1-digit SIC = %d', i));
        eval(['SAM_DATES = results.CRSP' num2str(i) '_DATES;']);
        eval(['SAM_RET = results.CRSP' num2str(i) '_RET;']);
        eval(['SAM_PRC = results.CRSP' num2str(i) '_PRC;']);
        eval(['SAM_VOL = results.CRSP' num2str(i) '_VOL;']);
        LOG.info(sprintf('    Sample size = %d firms', size(SAM_RET,2)));
        [klambdas, kdates] = ...
            kyles_lambda(SAM_RET, SAM_PRC, SAM_VOL, SAM_DATES, param);
        % Capturing the results
        eval(['results.amihud.CRSP' num2str(i) '_kdates = kdates;']);
        eval(['results.amihud.CRSP' num2str(i) '_klambdas = klambdas;']);
    end
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_klam)));
    clear tic_klam klambdas kdates SAM_RET SAM_PRC SAM_VOL SAM_DATES;

    LOG.info('');
    LOG.info('The VIX sample of volatitity futures data');
    tic_klam = tic;
    results.amihud.sample_max_VIX = ...
        min(results.amihud.sample_max, size(VIX_RET, 2));
    for i = 1:results.amihud.sample_max_VIX
        LOG.info(sprintf(' -- for VIX maturity = %d mos', i));
        SAM_DATES = CACHE.VIX.dates.vec;
        SAM_RET = VIX_RET(:,i);
        SAM_PRC = VIX_PRC(:,i);
        SAM_VOL = VIX_VOL(:,i);
        [klambdas, kdates] = ...
            kyles_lambda(SAM_RET, SAM_PRC, SAM_VOL, SAM_DATES, param);
        % Capturing the results
        eval(['results.amihud.VIX' num2str(i) '_kdates = kdates;']);
        eval(['results.amihud.VIX' num2str(i) '_klambdas = klambdas;']);
    end
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_klam)));
    clear tic_klam klambdas kdates SAM_RET SAM_PRC SAM_VOL SAM_DATES;

    LOG.info('');
    LOG.info('The WTI sample of volatitity futures data');
    tic_klam = tic;
    results.amihud.sample_max_WTI = ...
        min(results.amihud.sample_max, size(WTI_RET, 2));
    for i = 1:results.amihud.sample_max_WTI
        LOG.info(sprintf(' -- for WTI maturity = %d mos', i));
        SAM_DATES = CACHE.WTI.dates.vec;
        SAM_RET = WTI_RET(:,i);
        SAM_PRC = WTI_PRC(:,i);
        SAM_VOL = WTI_VOL(:,i);
        [klambdas, kdates] = ...
            kyles_lambda(SAM_RET, SAM_PRC, SAM_VOL, SAM_DATES, param);
        % Capturing the results
        eval(['results.amihud.WTI' num2str(i) '_kdates = kdates;']);
        eval(['results.amihud.WTI' num2str(i) '_klambdas = klambdas;']);
    end
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_klam)));
    clear param tic_klam klambdas kdates SAM_RET SAM_PRC SAM_VOL SAM_DATES;

    %% KYLEOBIZ

    LOG.info('');
    LOG.info('Computing price impact via the Kyle and Obizhaeva method');

    % Load the cached input data, or build the cache if necessary
    cfPfx = 'LIQ.KYLEOBIZ.';
    param.sigma_estimlag = CONFG.getPropDouble([cfPfx 'sigma_estimlag']);
    param.p = CONFG.getPropDouble([cfPfx 'benchmarkStockPrice']);
    param.V = CONFG.getPropDouble([cfPfx 'dailyVol']);
    param.sigma = CONFG.getPropDouble([cfPfx 'sigma']);
    param.X = CONFG.getPropDouble([cfPfx 'tradeSize']);
    param.lambda_bar = CONFG.getPropDouble([cfPfx 'lambda_bar']);
    param.kappa_bar = CONFG.getPropDouble([cfPfx 'kappa_bar']);

    results.kyleobiz.sample_max = CONFG.getPropInt([cfPfx 'sample_max']);

    LOG.info('');
    LOG.info('The CRSP sample of daily stock data');
    tic_kno = tic;
    results.kyleobiz.sample_max_CRSP = ...
        min(results.kyleobiz.sample_max,size(results.CRSP0_RET, 2));
    for i = 0:results.kyleobiz.sample_max_CRSP-1
        LOG.info(sprintf(' -- for 1-digit SIC = %d', i));
        eval(['SAM_DATES = results.CRSP' num2str(i) '_DATES;']);
        eval(['SAM_RET = results.CRSP' num2str(i) '_RET;']);
        eval(['SAM_PRC = results.CRSP' num2str(i) '_PRC;']);
        eval(['SAM_VOL = results.CRSP' num2str(i) '_VOL;']);
        LOG.info(sprintf('    Sample size = %d firms', size(SAM_RET,2)));
        [avgCost, medCost] = ...
            kyle_obizhaeva_lambda(param, SAM_RET, SAM_PRC, SAM_VOL);
        % Capturing the results
        eval(['results.kyleobiz.CRSP' num2str(i) '_avgCost = avgCost;']);
        eval(['results.kyleobiz.CRSP' num2str(i) '_medCost = medCost;']);
    end
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_kno)));
    clear i tic_kno avgCost medCost SAM_RET SAM_PRC SAM_VOL;

    LOG.info('');
    LOG.info('The VIX sample of volatitity futures data');
    tic_kno = tic;
    results.kyleobiz.sample_max_VIX = ...
        min(results.kyleobiz.sample_max, size(VIX_RET, 2));
    results.kyleobiz.VIX_dates = CACHE.VIX.dates.vec;
    for i = 1:results.kyleobiz.sample_max_VIX
        LOG.info(sprintf(' -- for VIX maturity = %d mos', i));
        SAM_DATES = CACHE.VIX.dates.vec;
        SAM_RET = VIX_RET(:,i);
        SAM_PRC = VIX_PRC(:,i);
        SAM_VOL = VIX_VOL(:,i);
        [avgCost, medCost] = ...
            kyle_obizhaeva_lambda(param, SAM_RET, SAM_PRC, SAM_VOL);
        % Capturing the results
        eval(['results.kyleobiz.VIX' num2str(i) '_avgCost = avgCost;']);
        eval(['results.kyleobiz.VIX' num2str(i) '_medCost = medCost;']);
    end
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_kno)));
    clear i tic_kno avgCost medCost SAM_RET SAM_PRC SAM_VOL;

    LOG.info('');
    LOG.info('The WTI sample of volatitity futures data');
    tic_kno = tic;
    results.kyleobiz.sample_max_WTI = ...
        min(results.kyleobiz.sample_max, size(WTI_RET, 2));
    results.kyleobiz.WTI_dates = CACHE.WTI.dates.vec;
    for i = 1:results.kyleobiz.sample_max_WTI
        LOG.info(sprintf(' -- for WTI maturity = %d mos', i));
        SAM_DATES = CACHE.WTI.dates.vec;
        SAM_RET = WTI_RET(:,i);
        SAM_PRC = WTI_PRC(:,i);
        SAM_VOL = WTI_VOL(:,i);
        [avgCost, medCost] = ...
            kyle_obizhaeva_lambda(param, SAM_RET, SAM_PRC, SAM_VOL);
        % Capturing the results
        eval(['results.kyleobiz.WTI' num2str(i) '_avgCost = avgCost;']);
        eval(['results.kyleobiz.WTI' num2str(i) '_medCost = medCost;']);
    end
    LOG.info(sprintf('Calculations took %7.4f secs', toc(tic_kno)));
    clear i param tic_kno avgCost medCost SAM_RET SAM_PRC SAM_VOL;
end
