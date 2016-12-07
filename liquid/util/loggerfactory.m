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

classdef loggerfactory < handle
   % LOGGER logger class constructor. 
   % lgr = logger(filepath, name, level)
   %     name is a name for referencing the logger instance
   %     filepath is the target text file for the logger output
   %     level is the threshold above which statements are output
   properties(SetAccess=private, Constant=true, Hidden=true)
      LOGGERMAP = containers.Map;
   end
   
   methods(Access=private)
      % Hide the constructor, to ensure a singleton.
      function fact = loggerfactory()
      end
   end
   
   methods(Static)
      % Retrieve the singleton instance.
      function fact = instance()
         persistent singletonInstance;
         if isempty(singletonInstance)
            fact = loggerfactory();
            singletonInstance = fact;
         else
            fact = singletonInstance;
         end
      end
   end
   
   methods
      % Retrieve an existing logger
      function lgr = getLogger(varargin)
         inst = loggerfactory.instance();
         switch nargin
         case 1
            % if no input arguments, throw an exception
            throw(MException('loggerfactory:getLogger:ZeroArgs', ...
              'Name argument required for loggerfactory.getLogger().'));
         case 2
            name = varargin{2};
            lgr = inst.LOGGERMAP(name);
         otherwise
            throw(MException('loggerfactory:getLogger:ExcessArgs', ...
              'Only one argument allowed in loggerfactory.getLogger().'));
         end
      end
      
      % Create and return a new logger
      function lgr = getNewLogger(varargin)
         inst = loggerfactory.instance(); 
         % Input validation
         switch nargin
            case 1
              throw(MException('loggerfactory:getNewLogger:ZeroArgs', ...
              'Name argument required for loggerfactory.getLogger().'));
            case 2
              throw(MException('loggerfactory:getNewLogger:OneArg', ...
              'Name argument required for loggerfactory.getLogger().'));
            case 3
              name = varargin{2};
              filepath = varargin{3};
              if not(isempty(inst.LOGGERMAP(name)))
                throw(MException('loggerfactory:getNewLogger:NameCollision',...
                'A logger already exists with the name:  %s.', name));
              end
              lgr = logger(name, filepath);
              inst.LOGGERMAP(name) = lgr;
            case 4
              name = varargin{2};
              filepath = varargin{3};
              level = varargin{4};
              try
                 inst.LOGGERMAP(name);
              catch ME
                 if (strcmp(ME.identifier,'MATLAB:Containers:Map:NoKey'))
                     % Great: no name collision, this is what we want
                 else
                     rethrow(ME)
                 end
              end
              lgr = logger(name, filepath, level);
              inst.LOGGERMAP(name) = lgr;
            otherwise
              throw(MException('loggerfactory:getNewLogger:ExcessArgs',...
              'Too many args (%.0f) for loggerfactory.getNewLogger().',...
              nargin));
         end
      end
      
   end
end % classdef


