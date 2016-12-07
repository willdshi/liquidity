function testspec = vixwti_testcache_local()

    testspec.EXIST = cell(2,1);
    % Basic existence checks:
    testspec.EXIST{1} =  'CACHE.data.ids';
    testspec.EXIST{2} =  'CACHE.data.dates';
    testspec.EXIST{3} =  'CACHE.data.vals';
    testspec.EXIST{4} =  'CACHE.data.vals.PRC';
    testspec.EXIST{5} =  'CACHE.data.vals.VOL';
    testspec.EXIST{6} =  'CACHE.data.vals.RET';
    
    testspec.BOOL = cell(2,1);
    % Ensuring all the arrays have the same number of observations (dates):
    testspec.BOOL{1} = ...
        'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.PRC, 1)';
    testspec.BOOL{2} = ...
        'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.VOL, 1)';
    testspec.BOOL{3} = ...
        'size(CACHE.data.dates.vec,1)==size(CACHE.data.vals.RET, 1)';
    % Ensuring all the arrays have the same number of columns (ids):
    testspec.BOOL{4} = ...
        'size(CACHE.data.ids.VIXWTI,2)==size(CACHE.data.vals.PRC, 2)';
    testspec.BOOL{5} = ...
        'size(CACHE.data.ids.VIXWTI,2)==size(CACHE.data.vals.VOL, 2)';
    testspec.BOOL{6} = ...
        'size(CACHE.data.ids.VIXWTI,2)==size(CACHE.data.vals.RET, 2)';
end
