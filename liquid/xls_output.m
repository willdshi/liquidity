function xls_output(xlspath, sheet, titles, colhead, dates, data)
% XLS_OUTPUT dumps times series data to MS-Excel in a standard format
%
%   Inputs:
%     xlspath = file location
%     sheet   = worksheet name
%     titles  = descriptive titles for the top rows
%     colhead = descriptive column headers for the individual series
%     dates   = Tx1 vector of dates
%     data    = TxN vector of observation data

    xlswrite(xlspath, titles(2), sheet, 'A1');
    xlswrite(xlspath, titles{1}, sheet, 'A2');
    xlswrite(xlspath, dates, sheet, 'A3');
    for j = 1:size(data,2)
        xlswrite(xlspath, colhead{j}, sheet, [char(64+j+1) '2']);
        xlswrite(xlspath, data(:,j), sheet, [char(64+j+1) '3']);
    end
end


