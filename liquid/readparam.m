function P = readparam(metric)

    global LOG;
    global CONFG;

    LOG.trace(sprintf('Running readparam'));

    % A "starter" parameter ensures a non-null return value:
    P.metric = metric;
    
    switch metric
        
      case 'KLAM'
    	cfPfx = 'LIQ.param.KLAM.';
        P.estsize = CONFG.getPropDouble([cfPfx 'estsize']);
        P.min_estobs = CONFG.getPropInt([cfPfx 'min_estobs']);
        P.min_regress_obs = CONFG.getPropDouble([cfPfx 'min_regress_obs']);
        P.am_sample_max = CONFG.getPropInt([cfPfx 'sample_max']);

      case 'ROLL'
    	cfPfx = 'LIQ.param.ROLL.';
        P.estsize = CONFG.getPropDouble([cfPfx 'estsize']);
        P.min_estobs = CONFG.getPropInt([cfPfx 'min_estobs']);
        P.poscov_rule = CONFG.getPropInt([cfPfx 'poscov_rule']);
        
      case 'LVOL'
    	cfPfx = 'LIQ.param.LVOL.';
        P.estsize = CONFG.getPropDouble([cfPfx 'estsize']);
        P.min_estobs = CONFG.getPropInt([cfPfx 'min_estobs']);
        
      case 'MINVx'
    	cfPfx = 'LIQ.param.MINVx.';
        P.sigma_estimlag = CONFG.getPropDouble([cfPfx 'sigma_estimlag']);
        P.p = CONFG.getPropDouble([cfPfx 'benchmarkStockPrice']);
        P.V = CONFG.getPropDouble([cfPfx 'dailyVol']);
        P.V_estimlag = CONFG.getPropInt([cfPfx 'dailyVolEstlag']);
        P.sigma = CONFG.getPropDouble([cfPfx 'sigma']);
        P.X = CONFG.getPropDouble([cfPfx 'tradeSize']);
        P.lambda_bar = CONFG.getPropDouble([cfPfx 'lambda_bar']);
        P.kappa_bar = CONFG.getPropDouble([cfPfx 'kappa_bar']);
        P.ko_sample_max = CONFG.getPropInt([cfPfx 'sample_max']);
        P.sigma_estimlag = CONFG.getPropDouble([cfPfx 'sigma_estimlag']);

      case 'MINV1'
    	cfPfx = 'LIQ.param.MINV1.';
        P.sample_max = CONFG.getPropInt([cfPfx 'sample_max']);
        P.Pstar = CONFG.getPropDouble([cfPfx 'Pstar']);
        P.Vstar = CONFG.getPropDouble([cfPfx 'Vstar']);
        P.Sstar = CONFG.getPropDouble([cfPfx 'Sstar']);
        P.sig_estim_lag = int16(CONFG.getPropInt([cfPfx 'sig_estim_lag']));
        P.sig_estim_minobs = int16(CONFG.getPropInt([cfPfx 'sig_estim_minobs']));
        P.vol_estim_lag = int16(CONFG.getPropInt([cfPfx 'vol_estim_lag']));
        P.vol_estim_minobs = int16(CONFG.getPropInt([cfPfx 'vol_estim_minobs']));
        P.vol_adj = CONFG.getPropDouble([cfPfx 'vol_adj']);
        P.X = CONFG.getPropDouble([cfPfx 'X']);
        P.X_method = CONFG.getProp([cfPfx 'X_method']);
        P.alpha0 = CONFG.getPropDouble([cfPfx 'alpha0']);
        P.alphaI = CONFG.getPropDouble([cfPfx 'alphaI']);
        P.alphaX = CONFG.getPropDouble([cfPfx 'alphaX']);
        P.K0 = CONFG.getPropDouble([cfPfx 'K0']);
        P.KI = CONFG.getPropDouble([cfPfx 'KI']);
        P.cost_clip = CONFG.getPropDouble([cfPfx 'cost_clip']);

      case 'MINV2'
    	cfPfx = 'LIQ.param.MINV2.';
        P.sample_max = CONFG.getPropInt([cfPfx 'sample_max']);
        P.Pstar = CONFG.getPropDouble([cfPfx 'Pstar']);
        P.Vstar = CONFG.getPropDouble([cfPfx 'Vstar']);
        P.Sstar = CONFG.getPropDouble([cfPfx 'Sstar']);
        P.sig_estim_lag = int16(CONFG.getPropInt([cfPfx 'sig_estim_lag']));
        P.sig_estim_minobs = int16(CONFG.getPropInt([cfPfx 'sig_estim_minobs']));
        P.vol_estim_lag = int16(CONFG.getPropInt([cfPfx 'vol_estim_lag']));
        P.vol_estim_minobs = int16(CONFG.getPropInt([cfPfx 'vol_estim_minobs']));
        P.vol_adj = CONFG.getPropDouble([cfPfx 'vol_adj']);
        P.X = CONFG.getPropDouble([cfPfx 'X']);
        P.X_method = CONFG.getProp([cfPfx 'X_method']);
        P.alpha0 = CONFG.getPropDouble([cfPfx 'alpha0']);
        P.alphaI = CONFG.getPropDouble([cfPfx 'alphaI']);
        P.alphaX = CONFG.getPropDouble([cfPfx 'alphaX']);
        P.K0 = CONFG.getPropDouble([cfPfx 'K0']);
        P.KI = CONFG.getPropDouble([cfPfx 'KI']);
        P.cost_clip = CONFG.getPropDouble([cfPfx 'cost_clip']);

      case 'MART'
    	cfPfx = 'LIQ.param.MART.';

      case 'TURN'
    	cfPfx = 'LIQ.param.TURN.';
            
      otherwise
        P = NaN;     
          
    end
    LOG.trace(sprintf('Params are read'));
    
end

