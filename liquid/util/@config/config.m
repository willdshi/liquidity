classdef config < handle
% CONFIG configuration class constructor.
%
% Syntax:      config(filepath, [extrakeys, extravals])
%
% Inputs:
%              filepath - Name of a configuration file on disk (e.g.,
%                 stresstest.conf)
%              extrakeys - String array of optional extra key names.  
%                 Must appear with a matching extravals array. 
%                 If any of the extrakeys collide with key names in the
%                 config file, the extrakeys will override.
%              extravals - String array of optional extra property values.  
%                 Must appear with a matching extrakeys array. 
%
% Outputs:     Any output is directed to a log file
%
% Example: 
%              % Create a new config object:
%              cfg = config('testing.conf')
%
% Other m-files required: none
%
% Subfunctions: 
%              prop = getProp(cfg, key)
%              prop = getPropDouble(cfg, key)
%              prop = getPropSingle(cfg, key)
%              prop = getPropInt(cfg, key)
%
% MAT-files required: ./../../../build/cache/STATE.mat
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
% THIS SOFTWARE IS RELEASED INTO THE PUBLIC DOMAIN, NOV 2010.

% Author: Mark D. Flood
% Division of Bank Regulation, Federal Housing Finance Agency
% Nov 2010; Last revision: 24-Nov-2010

%------------- BEGIN CODE --------------

    %% Object properties
    properties(SetAccess=private)
       filepath
    end
    properties(Access=private)
       propmap
    end

    %% Public methods
    methods
        %% The constructor - returns a new config object
        function cfg = config(varargin)
            
            switch nargin
            case 0
              throw(MException('config:TooFewArguments', ...
              ['Too few arguments (%.0f) for config.  Usage: \n'...
               'config(file, [extrakeys, extravals])', nargin]));
            case 1
              cfg.filepath = varargin{1};
            case 2
              throw(MException('config:WrongNumArguments', ...
              ['Too many arguments (%.0f) for config.  Usage: \n'...
               'config(file, [extrakeys, extravals])', nargin]));
            case 3
              cfg.filepath = varargin{1};
              extrakeys = varargin{2};
              extravals = varargin{3};
            otherwise
              throw(MException('config:TooManyArguments', ...
              ['Too many arguments (%.0f) for config.  Usage: \n'...
               'config(file, [extrakeys, extravals])', nargin]));
            end
            
            % Test the inputs
            if not(isa(cfg.filepath,'char'))
                throw(MException('config:FirstArgumentNonchar', ...
                'Filename arg for config must have char type.'));
            end
%             if (exist('extrakeys','var') && not(isa(extrakeys,'char')))
%                 throw(MException('config:ExtrakeysArgumentNonchar', ...
%                 'Extrakeys arg for config must have char type.'));
%             end
%             if (exist('extravals','var') && not(isa(extravals,'char')))
%                 throw(MException('config:ExtravalsArgumentNonchar', ...
%                 'Extravals arg for config must have char type.'));
%             end
            
            % Build the map
            if (strcmp(cfg.filepath, ''))
                % Instantiate an empty config; all
                % properties should provided as extra arguments
                cfg.propmap = containers.Map;
            elseif not(exist(cfg.filepath,'file'))
                throw(MException('config:NonexistentPath', ...
                'File path (%s) not found.', cfg.filepath));
            else
                % The filepath points to a real file -- read it:
                cfg.propmap = readproperties(cfg.filepath);
            end
            
            % Now layer on any extra key-value pairs
            if exist('extrakeys','var') 
                for i = 1:length(extrakeys)
                    cfg.propmap(extrakeys{i}) = extravals{i};
                end
            end
        end

        %% Getter methods
        function ks = getKeys(cfg)
            % Return all configuration keys
            ks = keys(cfg.propmap);
        end
        
        function prop = getProp(cfg, key)
            % Return the indicated property, as a string
            global LOG;
            prop = cfg.propmap(key);
            if (not(isempty(LOG)))
                LOG.info(['Retrieving property: ' key '=' prop]);
            end
        end
        
        function prop = getPropDouble(cfg, key)
            % Return the indicated property as a double precision number
            strProp = cfg.getProp(key);
            prop = str2double(strProp);
        end
        
        function prop = getPropSingle(cfg, key)
            % Return the indicated property as a single precision number
            strProp = cfg.getProp(key);
            prop = single(str2double(strProp));
        end
        
        function prop = getPropBoolean(cfg, key)
            % Return the indicated property as a true/false value
            strProp = cfg.getProp(key);
            prop = false;
            if (strcmpi(strProp, 'T'))
                prop = true;
            elseif (strcmpi(strProp, 'TRUE'))
                prop = true;
            elseif (str2double(strProp)>0)
                prop = true;
            end
        end
        
        function prop = getPropInt(cfg, key)
            % Return the indicated property as an integer
            strProp = cfg.getProp(key);
            propDbl = str2double(strProp);
            if (intmin('int8')<propDbl && propDbl<intmax('int8'))
                prop = int8(propDbl);
            elseif (intmin('int16')<propDbl && propDbl<intmax('int16'))
                prop = int16(propDbl);
            elseif (intmin('int32')<propDbl && propDbl<intmax('int32'))
                prop = int32(propDbl);
            else
                prop = int64(propDbl);
            end
        end
        
        function propMap = getSubmap(cfg, keyRegexp)
            % Return a new map of properties whose keys match the regexp
            propMap = containers.Map;
            ks = getKeys(cfg);
            for k = 1:length(ks)
                thiskey = ks{k};
                if (not(isempty(regexp(thiskey, keyRegexp, 'once'))))
                    propMap(thiskey) = cfg.getProp(thiskey);
                end
            end
        end
    end    % methods

    %% Private methods
    methods(Access=private)
%         function [props] = readproperties(filepath)
%             % Reads properties (key=value pairs) from a text file on disk,
%             % and returns them as a Matlab Map object.
%             %     filepath is a char string pointing to a text file on disk
%             %     returns a Map object with char keys and values
%             % Read the external file:
%             fid = fopen(filepath);
%             cellarr = ...
%                textscan(fid, '%s %s', 'delimiter','=', 'commentStyle','#');
%             fclose(fid);
%             % Create a properties map:
%             cellcount = length(cellarr{1});
%             keys = cell(cellcount);
%             vals = cell(cellcount);
%             clear keys;
%             clear vals;
%             for i=1:cellcount
%                 keys(i) = {['' char(cellarr{1}(i)) '']};
%                 vals(i) = {['' char(cellarr{2}(i)) '']};
%             end
%             props = containers.Map(keys, vals, 'uniformvalues', true);
%         end
        
    end % methods(Access=private)
    
end % classdef


