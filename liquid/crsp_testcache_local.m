function testspec = crsp_testcache_local()

    testspec.EXIST = cell(2,1);
    % Basic existence checks:
    testspec.EXIST{1} =  'CACHE.data.ids';
    testspec.EXIST{2} =  'CACHE.data.dates';
    testspec.EXIST{3} =  'CACHE.data.vals';
    testspec.EXIST{4} =  'CACHE.data.ids.PERMNO';
    testspec.EXIST{5} =  'CACHE.data.vals.PRC';
    testspec.EXIST{6} =  'CACHE.data.vals.RET';
    testspec.EXIST{7} =  'CACHE.data.vals.VOL';
    testspec.EXIST{8} =  'CACHE.data.vals.BID';
    testspec.EXIST{9} =  'CACHE.data.vals.ASK';
    testspec.EXIST{10} = 'CACHE.data.vals.SICCD';
    testspec.EXIST{11} = 'CACHE.data.vals.NAICS';
    testspec.EXIST{12} = 'CACHE.data.vals.SHROUT';
    testspec.EXIST{13} = 'CACHE.data.dates.vec';
    
    testspec.BOOL = cell(2,1);
    % Ensuring all the arrays have the same number of observations (dates):
    testspec.BOOL{1} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.PRC, 1)';
    testspec.BOOL{2} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.RET, 1)';
    testspec.BOOL{3} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.VOL, 1)';
    testspec.BOOL{4} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.BID, 1)';
    testspec.BOOL{5} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.ASK, 1)';
    testspec.BOOL{6} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.SICCD, 1)';
    testspec.BOOL{7} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.NAICS, 1)';
    testspec.BOOL{8} = 'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.SHROUT, 1)';
    % Ensuring all the arrays have the same number of columns (ids):
    testspec.BOOL{9} = 'size(CACHE.data.ids.PERMNO,2)==size(CACHE.data.vals.PRC, 2)';
    testspec.BOOL{10} = 'size(CACHE.data.ids.PERMNO,2)==size(CACHE.data.vals.RET, 2)';
    testspec.BOOL{11} = 'size(CACHE.data.ids.PERMNO,2)==size(CACHE.data.vals.VOL, 2)';
    testspec.BOOL{12} = 'size(CACHE.data.ids.PERMNO,2)==size(CACHE.data.vals.BID, 2)';
    testspec.BOOL{13} = 'size(CACHE.data.ids.PERMNO,2)==size(CACHE.data.vals.ASK, 2)';
    testspec.BOOL{14} = 'size(CACHE.data.ids.PERMNO,2)==size(CACHE.data.vals.SICCD, 2)';
    testspec.BOOL{15} = 'size(CACHE.data.ids.PERMNO,2)==size(CACHE.data.vals.NAICS, 2)';
    testspec.BOOL{16} = 'size(CACHE.data.ids.PERMNO,2)==size(CACHE.data.vals.SHROUT, 2)';
end



