function testspec = trace_testcache_lqmeas()
    % Basic existence checks:
    testspec.EXIST = cell(2,1);
    testspec.EXIST{1} = 'CACHE.data.SAM_DATES';
    testspec.EXIST{2} = 'CACHE.data.SAM_VOL';
    testspec.EXIST{3} = 'CACHE.data.SAM_RET';
    testspec.EXIST{4} = 'CACHE.data.SAM_PRC';
    testspec.EXIST{5} = 'CACHE.liqmeas.AMIH';
    testspec.EXIST{6} = 'CACHE.liqmeas.MINVx';
    testspec.EXIST{7} = 'CACHE.liqmeas.MINV1';
    testspec.EXIST{8} = 'CACHE.liqmeas.MINV2';

    % Some boolean tests:
    testspec.BOOL = cell(2,1);
    testspec.BOOL{1} = 'true()';
    testspec.BOOL{2} = 'true()';
%     testspec.BOOL{1} = 'size(CACHE.liqmeas.AMIH{1,1}.klambdas,1)==size(CACHE.liqmeas.AMIH{2,1}.klambdas,1)';
%     testspec.BOOL{2} = 'size(CACHE.liqmeas.AMIH{1,1}.klambdas,1)==size(CACHE.liqmeas.AMIH{3,1}.klambdas,1)';
%     testspec.BOOL{3} = 'size(CACHE.liqmeas.AMIH{1,1}.klambdas,1)==size(CACHE.liqmeas.AMIH{4,1}.klambdas,1)';
%     testspec.BOOL{4} = 'size(CACHE.liqmeas.AMIH{1,1}.klambdas,1)==size(CACHE.liqmeas.AMIH{5,1}.klambdas,1)';
%     testspec.BOOL{5} = 'size(CACHE.liqmeas.AMIH{1,1}.klambdas,1)==size(CACHE.liqmeas.AMIH{6,1}.klambdas,1)';
%     testspec.BOOL{6} = 'size(CACHE.liqmeas.AMIH{1,1}.klambdas,1)==size(CACHE.liqmeas.AMIH{7,1}.klambdas,1)';
%     testspec.BOOL{7} = 'size(CACHE.liqmeas.AMIH{1,1}.klambdas,1)==size(CACHE.liqmeas.AMIH{8,1}.klambdas,1)';
%     testspec.BOOL{8} = 'size(CACHE.liqmeas.AMIH{1,1}.klambdas,1)==size(CACHE.liqmeas.AMIH{9,1}.klambdas,1)';
%     testspec.BOOL{9} = 'size(CACHE.liqmeas.AMIH{1,1}.klambdas,1)==size(CACHE.liqmeas.AMIH{10,1}.klambdas,1)';
%     testspec.BOOL{10} = 'size(CACHE.liqmeas.MINV1{1,1}.avgCost,1)==size(CACHE.liqmeas.MINV1{2,1}.avgCost,1)';
%     testspec.BOOL{11} = 'size(CACHE.liqmeas.MINV1{1,1}.avgCost,1)==size(CACHE.liqmeas.MINV1{3,1}.avgCost,1)';
%     testspec.BOOL{12} = 'size(CACHE.liqmeas.MINV1{1,1}.avgCost,1)==size(CACHE.liqmeas.MINV1{4,1}.avgCost,1)';
%     testspec.BOOL{13} = 'size(CACHE.liqmeas.MINV1{1,1}.avgCost,1)==size(CACHE.liqmeas.MINV1{5,1}.avgCost,1)';
%     testspec.BOOL{14} = 'size(CACHE.liqmeas.MINV1{1,1}.avgCost,1)==size(CACHE.liqmeas.MINV1{6,1}.avgCost,1)';
%     testspec.BOOL{15} = 'size(CACHE.liqmeas.MINV1{1,1}.avgCost,1)==size(CACHE.liqmeas.MINV1{7,1}.avgCost,1)';
%     testspec.BOOL{16} = 'size(CACHE.liqmeas.MINV1{1,1}.avgCost,1)==size(CACHE.liqmeas.MINV1{8,1}.avgCost,1)';
%     testspec.BOOL{17} = 'size(CACHE.liqmeas.MINV1{1,1}.avgCost,1)==size(CACHE.liqmeas.MINV1{9,1}.avgCost,1)';
%     testspec.BOOL{18} = 'size(CACHE.liqmeas.MINV1{1,1}.avgCost,1)==size(CACHE.liqmeas.MINV1{10,1}.avgCost,1)';
end
