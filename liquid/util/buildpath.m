% THIS SOFTWARE IS RELEASED INTO THE PUBLIC DOMAIN, SEP. 2010.
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

function dirname = buildpath(basedirname, reldirname, ceatedir)
    switch nargin
        case 0
            throw(MException('buildpath:startup:NoArgs', ...
              'Min of one argument required in buildpath().'));
        case 1
            reldirname = '';
            ceatedir = true;
        case 2
            ceatedir = true;
        case 3
            % Nothing to do; all args are specified
        otherwise
            throw(MException('buildpath:startup:ExcessArgs', ...
              'Max of two arguments allowed in buildpath().'));
    end
    
    % Ensure the basedirname ends with a filesep
    if (isempty(regexp(basedirname, [filesep '$'], 'once')))
        basedirname = [basedirname filesep];
    end
    
    % Combine base dir name with the relative path
    dirname = [basedirname reldirname];
    
    % Ensure the dirname ends with a filesep
    if (isempty(regexp(dirname, [filesep '$'], 'once')))
        dirname = [dirname filesep];
    end
    
    % Create the directory if it doesn't yet exist
    if (ceatedir==true && not(exist(dirname, 'dir')))
        mkdir(dirname);
    end
end