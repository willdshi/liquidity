function [CACHE, okay] = cache_valid(cachefile, testspec)

    global LOG;
    
    LOG.info('');
    LOG.info(sprintf('Testing cache validity: %s', cachefile));
    
    % Load the CACHE; it will be referenced in the testspec, via
    % statements of the form, for example:
    %   'size(CACHE.dates.vec,1)==size(CACHE.vals.PRC, 1)'
    CACHE = load(cachefile);
    
    % Assume it's a-okay unless and until a test below fails
    okay = true();
    
    % Basic existence checks:
    LOG.info(sprintf('Checking for existence of fields (%d)', ...
        length(testspec.EXIST)));
    for i = 1:length(testspec.EXIST)
        tse = testspec.EXIST{i};
        LOG.trace(sprintf(' -- Existence assertion %d: %s', i, tse));
        splitpoint = regexp(tse, '\.[a-zA-Z][a-zA-Z0-9_]*$');
        STRUCT = eval([tse(1:splitpoint-1) ';']);
        VAR = tse(splitpoint+1:end);
        if (~testStructFieldExists(STRUCT, VAR))
            errmsg = [' !!! Existence check failed: ' tse];
            LOG.err(errmsg);
            okay = false();
        end
    end
    clear tse i;
    
    % Boolean checks:
    LOG.info(sprintf('Checking Boolean assertions (%d)', ...
        length(testspec.BOOL)));
    for i = 1:length(testspec.BOOL)
        assert_true = testspec.BOOL{i};
        LOG.trace(sprintf(' -- Assertion %d: %s', i, assert_true));
        if (~eval(assert_true))
            errmsg = [' !!! Boolean check failed: ' assert_true];
            LOG.err(errmsg);
            okay = false();
        end
    end
    
end

