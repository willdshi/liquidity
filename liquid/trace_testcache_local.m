function testspec = trace_testcache_local()

    testspec.EXIST = cell(2,1);
    % Basic existence checks:
    testspec.EXIST{1} =  'CACHE.data.ids';
    testspec.EXIST{2} =  'CACHE.data.dates';
    testspec.EXIST{3} =  'CACHE.data.vals';
    testspec.EXIST{4} =  'CACHE.data.ids.BONDID';
    testspec.EXIST{5} =  'CACHE.data.vals.PRC';
    testspec.EXIST{6} =  'CACHE.data.vals.VOL';
%     testspec.EXIST{7} =  'CACHE.data.vals.VLD';
%     testspec.EXIST{8} =  'CACHE.data.vals.CRS';
%     testspec.EXIST{9} =  'CACHE.data.vals.CGS';
%     testspec.EXIST{10} =  'CACHE.data.vals.CDS';
%     testspec.EXIST{11} =  'CACHE.data.vals.CRM';
%     testspec.EXIST{12} =  'CACHE.data.vals.CGM';
%     testspec.EXIST{13} =  'CACHE.data.vals.CDM';
%     testspec.EXIST{14} =  'CACHE.data.vals.CRF';
%     testspec.EXIST{15} =  'CACHE.data.vals.CGF';
%     testspec.EXIST{16} =  'CACHE.data.vals.CDF';
    testspec.EXIST{7} =  'CACHE.data.vals.CGc';
    testspec.EXIST{8} =  'CACHE.data.dates.vec';
    
    testspec.BOOL = cell(2,1);
    % Ensuring all the arrays have the same number of observations (dates):
    testspec.BOOL{1} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.PRC, 1)';
    testspec.BOOL{2} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.VOL, 1)';
    testspec.BOOL{3} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.VLD, 1)';
%     testspec.BOOL{4} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.CRS, 1)';
%     testspec.BOOL{5} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.CGS, 1)';
%     testspec.BOOL{6} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.CDS, 1)';
%     testspec.BOOL{7} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.CRM, 1)';
%     testspec.BOOL{8} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.CGM, 1)';
%     testspec.BOOL{9} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.CDM, 1)';
%     testspec.BOOL{10} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.CRF, 1)';
%     testspec.BOOL{11} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.CGF, 1)';
%     testspec.BOOL{12} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.CDF, 1)';
    testspec.BOOL{4} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.CGc, 1)';
    % Ensuring all the arrays have the same number of columns (ids):
    testspec.BOOL{5} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.PRC, 2)';
    testspec.BOOL{6} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.VOL, 2)';
%     testspec.BOOL{16} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.VLD, 2)';
%     testspec.BOOL{17} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.CRS, 2)';
%     testspec.BOOL{18} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.CGS, 2)';
%     testspec.BOOL{19} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.CDS, 2)';
%     testspec.BOOL{20} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.CRM, 2)';
%     testspec.BOOL{21} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.CGM, 2)';
%     testspec.BOOL{22} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.CDM, 2)';
%     testspec.BOOL{23} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.CRF, 2)';
%     testspec.BOOL{24} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.CGF, 2)';
%     testspec.BOOL{25} = 'size(CACHE.data.ids.BONDID,2)==size(CACHE.data.vals.CDF, 2)';
end
