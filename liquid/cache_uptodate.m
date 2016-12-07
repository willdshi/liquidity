function [cfile, xst, rebuild] = cache_uptodate(cpath, cname, cttest, bmfile, force)
% CACHE_TEST Check whether cache file exists and/or needs rebuilding
% 
% Input args:
%     cdir    Directory name where the cache should be
%     cname   Filename for the cache file
%     cttest  Whether to test the timestamp on the cache file
%     bmknam  The benchmark file for a timestamp comparison
%     force   Whether to force rebuiding of the cache, regardless
%
% Output args:
%     cfile   The calculated path to the cache file
%     exist   Whether the indicated cache file exists already
%     rebuild Whether the cache file should be rebuilt
    
    global LOG;
    
    LOG.info('');
    LOG.info('..........................................................');
    LOG.info('Checking cache');
    LOG.info(sprintf(' -- cpath  = %s', cpath));
    LOG.info(sprintf(' -- cname  = %s', cname));
    LOG.info(sprintf(' -- cttest = %d', cttest));
    LOG.info(sprintf(' -- bmfile = %s', bmfile));
    LOG.info(sprintf(' -- force  = %d', force));

    % Test the path to the output cache file
    LOG.info('');
    if (~exist(cpath, 'dir'))
        LOG.warn(['!!! Cache directory missing, creating: ' cpath]);
        LOG.info('');
        mkdir(cpath);
    end
    cfile = [cpath filesep cname];
    LOG.info(['Cachefile target:  ' cfile]);
    xst = exist(cfile, 'file');
    LOG.info(sprintf('Cachefile exists:  %d', xst));
   
    % Test whether we need or want to rebuild the cache
    rebuild = (~xst || cache_timetest(cfile, bmfile, cttest, force));
    LOG.info('..........................................................');

end

function rebuild = cache_timetest(cachefile, bmarkfile, timetest, force)

    global LOG; 

    % If the cache already exists and is newer than this program, then 
    % there should be no work to do -- the output is already up to date!
    cache_exists = exist(cachefile, 'file');
    rebuild = false;
    if (cache_exists)
        cache_uptodate = is_file_newer(cachefile, bmarkfile);
        if (~timetest)
            LOG.warn('NOT testing cache timestamp (timetest)');
        elseif (timetest && ~cache_uptodate)
            LOG.warn(sprintf('Cache OUTDATED: %s', cachefile));
            rebuild = true;
        else
            LOG.warn(sprintf('Cache is up to date: %s', cachefile));
        end
    else
        LOG.warn(sprintf('Cache NOT FOUND: %s', cachefile));
        rebuild = true;
    end
    
    if (force)
        LOG.warn('Cache rebuild REQUIRED (force)');
        rebuild = true;
    else
        LOG.warn('NOT forcing rebuild (force)');
    end
    LOG.warn(sprintf('Rebuild required = %d', rebuild));
end

