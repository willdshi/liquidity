function results = parallel_config(results)
% Define parallelization setup
    
    global CONFG;
    global GRID;
    global LOG;
    
    if (~isempty(GRID))
        LOG.warn('');
        LOG.warn('***************************************************');
        LOG.warn('Call to parallel_config(), but GRID is not empty');
        LOG.warn('Returning to calling function without creating GRID');
        LOG.warn('***************************************************');
        LOG.warn('');
        return;
    end

    % Load some basic config info
    cfPfx = 'PARALLEL.';
    results.par.useParallel = CONFG.getPropBoolean([cfPfx 'useParallel']);
    
    if (results.par.useParallel)
        % Create a cluster object using parcluster, and define its
        % internal functions and properties
        GRID = parcluster();
        
        % Directory for transitory data for this specific job
        % e.g., '/home/TREASURY/floodm/tmp/grid'
        par.localStorageLocation = ...
            CONFG.getProp([cfPfx 'localStorageLocation']);
        
        % Host allowed to submit jobs to the cluster
        % e.g., 'd01ofrrh6gran1p.do.treas.gov';
        par.clusterHost = CONFG.getProp([cfPfx 'clusterHost']);
        
        % Root directory for your version of MATLAB
        % e.g., '/opt/ofropt/MATLAB/R2013a';
        par.ClusterMatlabRoot = CONFG.getProp([cfPfx 'ClusterMatlabRoot']);
        set(GRID, 'ClusterMatlabRoot', par.ClusterMatlabRoot);
        
        % Non-MPI, non communicating submit function
        % e.g., {@independentSubmitFcn,clusterHost,localStorageLocation};
        par.IndepSubmitFcn = CONFG.getProp([cfPfx 'IndependentSubmitFcn']);
        set(GRID, 'IndependentSubmitFcn', eval(par.IndepSubmitFcn));
        
        % MPI, or other communicating submit function
        % e.g., {@independentSubmitFcn,clusterHost,localStorageLocation};
        par.CommSubmitFcn = CONFG.getProp([cfPfx 'CommSubmitFcn']);
        set(GRID, 'CommunicatingSubmitFcn', eval(par.CommSubmitFcn));
        
        % Function to query job state
        % e.g., 'getJobStateFcn';
        par.GetJobStateFcn = CONFG.getProp([cfPfx 'GetJobStateFcn']);
        set(GRID, 'GetJobStateFcn', par.GetJobStateFcn);
        
        % Function to destroy a job
        % e.g., 'deleteJobFcn';
        par.DeleteJobFcn = CONFG.getProp([cfPfx 'DeleteJobFcn']);
        set(GRID, 'DeleteJobFcn', par.DeleteJobFcn);
        
        % Clean up
        par.useParallel = results.par.useParallel;
        results.par = par;
        clear par;
    end
end
