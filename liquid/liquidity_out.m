function liquidity_out(results)
%LIQUIDITY_OUT
% Routine to output macroeconomic results for subsequent charting
%   Creates matrices for each chart by combining vectors 
%   of each element from the results structure data
% Parameters
%   results - Structure containing all of the information to be output
%               Includes the output location as:
%                 results.buildDir
%                 results.output_file
%                 results.output_xls
%               Also includes the actual output data:
%                 results.amihud.sample_max_CRSP
%                 results.amihud.CRSP0_kdates
%                 results.amihud.CRSP0_klambdas
%                   ...
%                 results.amihud.CRSPn_klambdas
%                 results.kyleobiz.CRSP0_avgCost
%                   ...
%                 results.kyleobiz.CRSPn_avgCost
%                 results.kyleobiz.CRSP0_medCost
%                   ...
%                 results.kyleobiz.CRSPn_medCost
%
%                 results.amihud.sample_max_VIX
%                 results.amihud.VIX1_kdates
%                 results.amihud.VIX1_klambdas
%                   ...
%                 results.amihud.VIXn_klambdas
%                 results.kyleobiz.VIX1_avgCost
%                   ...
%                 results.kyleobiz.VIXn_avgCost
%                 results.kyleobiz.VIX1_medCost
%                   ...
%                 results.kyleobiz.VIXn_medCost

    global LOG;

    LOG.info('');
    LOG.info('..........................................................');
    LOG.info(sprintf('Running liquidity_out'));
    LOG.info('..........................................................');

    outpath = [pwd filesep results.buildDir];
    outfile = [outpath filesep results.output_file];
    xlsfile = [outpath filesep results.output_xls];
    
    %% Matlab output
    LOG.info('');
    LOG.info(['Building output - Matlab *.mat file: ' outfile]);
    save(outfile, '-struct', 'results');

    %% Excel output
    LOG.info('');
    LOG.info(['Building output - Excel *.xls file:  ' xlsfile]);
    warning('off', 'MATLAB:xlswrite:AddSheet');
    
    LOG.info('');
    LOG.info('  CRSP output - Amihud measures');
    sheet = 'CRSP_Amihud';
    LOG.info(sprintf('   -- Dates for %s', sheet));
    xlswrite(xlsfile, {'Date', 'Lambda by SIC category'}, sheet, 'A1');
    xlswrite(xlsfile, results.amihud.CRSP0_kdates, sheet, 'A3');
    for i = 0:results.amihud.sample_max_CRSP-1
        LOG.info(sprintf('   -- for 1-digit SIC = %d', i));
        colhead = [char(64+i+2) '2'];
        coldata = [char(64+i+2) '3'];
        LOG.trace(sprintf('      for Amihud: %s, %s', colhead, coldata));
        idata = eval(['results.amihud.CRSP' num2str(i) '_klambdas;']);
        xlswrite(xlsfile, i, sheet, colhead);
        xlswrite(xlsfile, idata, sheet, coldata);
    end

    LOG.info('');
    LOG.info('  CRSP output - KyleObiz measures');
    sheet = 'CRSP_KyleObiz';
    LOG.info(sprintf('   -- Dates for %s', sheet));
    sechead = [char(64+3+results.kyleobiz.sample_max_CRSP) '1'];
    xlswrite(xlsfile, {'Date', 'Average by SIC category'}, sheet, 'A1');
    xlswrite(xlsfile, {'Median by SIC category'}, sheet, sechead);
    xlswrite(xlsfile, results.CRSP0_DATES, sheet, 'A3');
    for i = 0:results.kyleobiz.sample_max_CRSP-1
        LOG.info(sprintf('   -- for 1-digit SIC = %d', i));
        colhead = [char(64+i+2) '2'];
        coldata = [char(64+i+2) '3'];
        LOG.trace(sprintf('      for KyleObiz: %s, %s', colhead, coldata));
        idata = eval(['results.kyleobiz.CRSP' num2str(i) '_avgCost;']);
        xlswrite(xlsfile, i, sheet, colhead);
        xlswrite(xlsfile, idata, sheet, coldata);
        colhead = [char(64+i+3+results.kyleobiz.sample_max_CRSP) '2'];
        coldata = [char(64+i+3+results.kyleobiz.sample_max_CRSP) '3'];
        LOG.trace(sprintf('      for KyleObiz: %s, %s', colhead, coldata));
        idata = eval(['results.kyleobiz.CRSP' num2str(i) '_medCost;']);
        xlswrite(xlsfile, i, sheet, colhead);
        xlswrite(xlsfile, idata, sheet, coldata);
    end

    LOG.info('');
    LOG.info('  VIX output - Amihud measures');
    sheet = 'VIX_Amihud';
    LOG.info(sprintf('   -- Dates for %s', sheet));
    xlswrite(xlsfile, {'Date', 'Lambda by VIX maturity'}, sheet, 'A1');
    xlswrite(xlsfile, results.amihud.VIX1_kdates, sheet, 'A3');
    for i = 1:results.kyleobiz.sample_max_VIX
        LOG.info(sprintf('   -- for VIX maturity = %d mos', i));
        colhead = [char(64+i+1) '2'];
        coldata = [char(64+i+1) '3'];
        LOG.trace(sprintf('      for Amihud: %s, %s', colhead, coldata));
        idata = eval(['results.amihud.VIX' num2str(i) '_klambdas;']);
        xlswrite(xlsfile, i, sheet, colhead);
        xlswrite(xlsfile, idata, sheet, coldata);
    end

    LOG.info('');
    LOG.info('  VIX output - KyleObiz measures');
    sheet = 'VIX_KyleObiz';
    LOG.info(sprintf('   -- Dates for %s', sheet));
    sechead = [char(64+3+results.kyleobiz.sample_max_VIX) '1'];
    xlswrite(xlsfile, {'Date', 'Average by VIX maturity'}, sheet, 'A1');
    xlswrite(xlsfile, {'Median by VIX maturity'}, sheet, sechead);
    xlswrite(xlsfile, results.kyleobiz.VIX_dates, sheet, 'A3');
    for i = 1:results.kyleobiz.sample_max_VIX
        LOG.info(sprintf('   -- for VIX maturity = %d mos', i));
        colhead = [char(64+i+1) '2'];
        coldata = [char(64+i+1) '3'];
        LOG.trace(sprintf('      for KyleObiz: %s, %s', colhead, coldata));
        idata = eval(['results.kyleobiz.VIX' num2str(i) '_avgCost;']);
        xlswrite(xlsfile, i, sheet, colhead);
        xlswrite(xlsfile, idata, sheet, coldata);
        colhead = [char(64+i+2+results.kyleobiz.sample_max_VIX) '2'];
        coldata = [char(64+i+2+results.kyleobiz.sample_max_VIX) '3'];
        LOG.trace(sprintf('      for KyleObiz: %s, %s', colhead, coldata));
        idata = eval(['results.kyleobiz.VIX' num2str(i) '_medCost;']);
        xlswrite(xlsfile, i, sheet, colhead);
        xlswrite(xlsfile, idata, sheet, coldata);
    end

    LOG.info('');
    LOG.info('  WTI output - Amihud measures');
    sheet = 'WTI_Amihud';
    LOG.info(sprintf('   -- Dates for %s', sheet));
    xlswrite(xlsfile, {'Date', 'Lambda by WTI maturity'}, sheet, 'A1');
    xlswrite(xlsfile, results.amihud.WTI1_kdates, sheet, 'A3');
    for i = 1:results.kyleobiz.sample_max_WTI
        LOG.info(sprintf('   -- for WTI maturity = %d mos', i));
        colhead = [char(64+i+1) '2'];
        coldata = [char(64+i+1) '3'];
        LOG.trace(sprintf('      for Amihud: %s, %s', colhead, coldata));
        idata = eval(['results.amihud.WTI' num2str(i) '_klambdas;']);
        xlswrite(xlsfile, i, sheet, colhead);
        xlswrite(xlsfile, idata, sheet, coldata);
    end

    LOG.info('');
    LOG.info('  WTI output - KyleObiz measures');
    sheet = 'WTI_KyleObiz';
    LOG.info(sprintf('   -- Dates for %s', sheet));
    sechead = [char(64+3+results.kyleobiz.sample_max_WTI) '1'];
    xlswrite(xlsfile, {'Date', 'Average by WTI maturity'}, sheet, 'A1');
    xlswrite(xlsfile, {'Median by WTI maturity'}, sheet, sechead);
    xlswrite(xlsfile, results.kyleobiz.WTI_dates, sheet, 'A3');
    for i = 1:results.kyleobiz.sample_max_WTI
        LOG.info(sprintf('   -- for WTI maturity = %d mos', i));
        colhead = [char(64+i+1) '2'];
        coldata = [char(64+i+1) '3'];
        LOG.trace(sprintf('      for KyleObiz: %s, %s', colhead, coldata));
        idata = eval(['results.kyleobiz.WTI' num2str(i) '_avgCost;']);
        xlswrite(xlsfile, i, sheet, colhead);
        xlswrite(xlsfile, idata, sheet, coldata);
        colhead = [char(64+i+2+results.kyleobiz.sample_max_WTI) '2'];
        coldata = [char(64+i+2+results.kyleobiz.sample_max_WTI) '3'];
        LOG.trace(sprintf('      for KyleObiz: %s, %s', colhead, coldata));
        idata = eval(['results.kyleobiz.WTI' num2str(i) '_medCost;']);
        xlswrite(xlsfile, i, sheet, colhead);
        xlswrite(xlsfile, idata, sheet, coldata);
    end
    
end
