function RSLT = initialize(configfile, logfile)
    
    global LOG;
    global CONFG;

    % Capture the launch time as early in the process as possible:
    processInfo.launchtime = datestr(now);

    % Need to add the path to the config class:
    [localpath, ~, ~] = fileparts(mfilename('fullpath'));
    addpath([localpath filesep 'util']);
    
    % Read in the config, and log properties for confirmation
    if (isempty(CONFG))
        CONFG = config(configfile);
    end
    
    %% Create the logger and log file
    
    % Set up the key files, depending on Windows vs. Linux
    [comp_str, comp_maxsize] = computer;
    RSLT.buildDir = CONFG.getProp('output_directory');
    if (strcmpi(RSLT.buildDir(1:1),'.'))
        RSLT.buildDir = [pwd filesep RSLT.buildDir];
    end
    RSLT.cacheDir = CONFG.getProp('cache_directory');
    if (strcmpi(comp_str(1:5),'pcwin'))
        RSLT.inputDir = CONFG.getProp('input_directory_win');
        RSLT.buildDir = strrep(RSLT.buildDir, '/', filesep);
        RSLT.cacheDir = strrep(RSLT.cacheDir, '/', filesep);
    else
        RSLT.inputDir = CONFG.getProp('input_directory_lin');
        RSLT.buildDir = strrep(RSLT.buildDir, '\', filesep);
        RSLT.cacheDir = strrep(RSLT.cacheDir, '\', filesep);
    end
    
    % Create a processInfo structure
    processInfo.computer_os = comp_str;
    processInfo.computer_maxarray = num2str(comp_maxsize);
    processInfo.computer_arch = computer('arch');
    processInfo.matlab_version = version;
    processInfo.matlab_versiondate = version('-date');
    processInfo.matlab_versionjvm = version('-java');
    processInfo.config = CONFG;
    
    logVerbosity = CONFG.getPropDouble('log_verbosity');
    logDir = buildpath(RSLT.buildDir, ...
        CONFG.getProp('log_relative_directory'));
    logfile = [logDir logfile];
    RSLT.logfile = logfile;
    if (isempty(LOG))
        logName = CONFG.getProp('log_name');
        logfact = loggerfactory.instance();
        LOG = logfact.getNewLogger(logName, logfile, logVerbosity);
    end
    LOG.warn('----------------------------------------------------------');
    LOG.warn([' Log file:  ' logfile]);
    LOG.warn('');
    LOG.warn([' Date:      ' processInfo.launchtime]);
    LOG.warn([' Input:     ' RSLT.inputDir]);
    LOG.warn([' Output:    ' RSLT.buildDir]);
    LOG.warn([' Log level: ' num2str(logVerbosity)]);
    LOG.warn('');
    LOG.warn(' System Information:');
    LOG.warn(['  - Matlab:    ', version ', ' version('-date')]);
    LOG.warn(['  - Java VM:   ', version('-java')]);
    LOG.warn(['  - OS:        ', comp_str ', ' computer('arch')]);
    LOG.warn(['  - Max array: ', num2str(comp_maxsize)]);
    LOG.warn('----------------------------------------------------------');
    LOG.warn('');
    
    % Log the configuration
    LOG.logMap(['Configuration, as read from disk (' configfile '): '], ...
        CONFG, 3);

    %% Initialize paths
    
    % Set up some basic locations
    RSLT.search_path = CONFG.getProp('search_path');
    RSLT.search_path = strrep(RSLT.search_path, '/', filesep);
    RSLT.search_path = strrep(RSLT.search_path, '\', filesep);
    pathtokens = strsplit(RSLT.search_path,';');

    [loc_path, ~, ~] = fileparts(mfilename('fullpath'));
    LOG.info('');
    LOG.info(['Base path is: ' loc_path]);
    for i=1:length(pathtokens)
        newpath = [loc_path filesep pathtokens{i}];
        LOG.info([' -- adding path: ' newpath]);
        addpath(newpath);   
    end
    
    LOG.info('');
    LOG.info(['Input directory (inputDir): ' RSLT.inputDir]);
    if (~exist(RSLT.inputDir, 'dir'))
        LOG.warn([' -- inputDir missing, creating: ' RSLT.inputDir]);
        mkdir(RSLT.inputDir);
    end
    LOG.info(['Build directory (buildDir): ' RSLT.buildDir]);
    if (~exist(RSLT.buildDir, 'dir'))
        LOG.warn([' -- buildDir missing, creating: ' RSLT.buildDir]);
        mkdir(RSLT.buildDir);
    end
    LOG.info(['Cache directory (cacheDir): ' RSLT.cacheDir]);
    if (~exist(RSLT.cacheDir, 'dir'))
        LOG.warn([' -- cacheDir missing, creating: ' RSLT.cacheDir]);
        mkdir(RSLT.cacheDir);
    end
    
end
