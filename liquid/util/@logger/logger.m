% THIS SOFTWARE IS RELEASED INTO THE PUBLIC DOMAIN, NOV. 2008.
%
% THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND,
% EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
% WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
% IN NO EVENT SHALL THE AUTHORS OR THEIR EMPLOYERS BE LIABLE FOR ANY
% SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
% OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
% WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY
% THEORY OF LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
% PERFORMANCE OF THIS SOFTWARE.

classdef logger < handle
    % LOGGER logger class constructor.
    % lgr = logger(filepath, name, level)
    %     name is a name for referencing the logger instance
    %     filepath is the target text file for the logger output
    %     level is the threshold above which statements are output
    properties(SetAccess=private, Constant=true, Hidden=false)
       OFF = 7;
       FATAL = 6;
       ERROR = 5;
       WARN = 4;
       INFO = 3;
       DEBUG = 2;
       TRACE = 1;
       ALL = 0;
       TAGS={'ALL'; 'TRACE'; 'DEBUG'; 'INFO'; 'WARN'; ...
         'ERROR'; 'FATAL'; 'OFF'};
    end
    properties(SetAccess=private)
       filepath
       name
       indent
    end
    properties
       level
    end
    properties(Access=private)
       fid
       this
    end

    methods
        function lgr = logger(varargin)
            % Returns a new logger object
            switch nargin
            case {0,1}
              throw(MException('logger:TooFewArguments', ...
              ['Too few arguments (%.0f) for logger.  Usage: \n'...
               'logger(name, file, level)', nargin]));
            case 2
              lgr.name = varargin{1};
              lgr.filepath = varargin{2};
              lgr.level = lgr.ALL;
            case 3
              lgr.name = varargin{1};
              lgr.filepath = varargin{2};
              lgr.level = varargin{3};
            otherwise
              throw(MException('logger:TooManyArguments', ...
              ['Too many arguments (%.0f) for logger.  Usage: \n'...
               'logger(name, file, level)', nargin]));
            end
            if not(isa(lgr.name,'char'))
                throw(MException('logger:FirstArgumentNonchar', ...
                'First arg for logger must have char type.'));
            end
            if not(isa(lgr.filepath,'char'))
                throw(MException('logger:SecondArgumentNonchar', ...
                'Second arg for logger must have char type.'));
            end
            if not(isa(lgr.level,'numeric'))
                throw(MException('logger:ThirdArgumentNoninteger', ...
                'Third arg (%.4f) for logger must have integer type.', ...
                lgr.level));
            end
            filpath = fileparts(lgr.filepath);
            if not(exist(filpath,'dir'))
              throw(MException('logger:NonexistentPath', ...
              'File path (%s) not found.', filpath));
            end
            lgr.fid = fopen(lgr.filepath, 'w');
        end

        function log(lgr, message, priority)
            tag = '       ';
            tagword = [lgr.TAGS{priority+1} ':'];
            tag(1:length(tagword)) = tagword;
            if (priority>=lgr.level)
                fprintf(lgr.fid, '\n%s %s%s', tag, lgr.indent, message);
            end
        end
        function fatal(lgr, message)
            lgr.log(message, lgr.FATAL);
        end
        function err(lgr, message)
            lgr.log(message, lgr.ERROR);
        end
        function warn(lgr, message)
            lgr.log(message, lgr.WARN);
        end
        function info(lgr, message)
            lgr.log(message, lgr.INFO);
        end
        function debug(lgr, message)
            lgr.log(message, lgr.DEBUG);
        end
        function trace(lgr, message)
            lgr.log(message, lgr.TRACE);
        end

        function logArray(lgr, frmat, array, priority)
            tag = '        ';
            tagword = lgr.TAGS{priority+1};
            tag(1:length(tagword)+1) = [tagword ':'];
            frm = ['\n' tag frmat];
            if (priority>=lgr.level)
                fprintf(lgr.fid, frm, array');
            end
        end

        function logMap(lgr, message, config, priority)
            lgr.log(message, priority);
            lgr.log('------------------------------------------------', ...
                priority);
            ks = config.getKeys();
            for k=ks,
                config.getProp(char(k));
            end
            lgr.log('------------------------------------------------', ...
                priority);
        end
        
        function enterfunction(lgr, mfile, p)
            switch nargin
            case {0, 1}
                throw(MException('logger:enterfunction:NoArgs', ...
                  'Min of one argument required in enterfunction().'));
            case 2
                % Default priority is 4 (i.e., 'WARN')
                p = 4;
            case 3
                % no need to act here TODO:check datatype
            otherwise
                throw(MException('logger:enterfunction:ExcessArgs', ...
                  'Max of two arguments allowed in enterfunction().'));
            end
            tic;
            lgr.log('', p);
            lgr.log('\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\', p);
            lgr.log([' Entering ' mfile]', p);
            lgr.log(' - - - - - - - - - - - - - - - - - - - - - - - -', p);
            lgr.log('', p);
            lgr.indent = [lgr.indent '    '];
        end

        function exitfunction(lgr, mfile, p)
            switch nargin
            case {0,1}
                throw(MException('logger:exitfunction:NoArgs', ...
                  'Min of one argument required in exitfunction().'));
            case 2
                % Default priority is 4 (i.e., 'WARN')
                p = 4;
            case 3
                % no need to act here TODO:check datatype
            otherwise
                throw(MException('logger:exitfunction:ExcessArgs', ...
                  'Max of two arguments allowed in exitfunction().'));
            end
            tElapsed = toc;
            indlen = max(0, length(lgr.indent)-4);
            lgr.indent = '';
            for i = 1:indlen
                lgr.indent = [lgr.indent ' '];
            end
            lgr.log('', p);
            lgr.log(' - - - - - - - - - - - - - - - - - - - - - - - -', p);
            lgr.log([' Exiting ' mfile]', p);
            lgr.log(['  - Elapsed time: ' num2str(tElapsed)]', p);
            lgr.log('////////////////////////////////////////////////', p);
            lgr.log('', p);
        end 
        
        function close(lgr)
            fclose(lgr.fid);
        end
        
   end % methods
end % classdef


