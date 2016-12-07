function domex(cfile, mpath)
%DOMEX - Generate an *.m file that runs "mex" on a dynamically chosen
%               (i.e., at runtime) *.c source file.  Then actually run the
%               new mexmaster.m function to compile the *.c source into 
%               a mex executable.
%
% Syntax:      domex(cfile, mpath)
%
% Inputs:
%              cfile - nobs x nvar matrix of series, ready for estimation
%              mpath - Matlab GARCH specification, via garchset
%
% Outputs: none
%
% Example: 
%              path_mex_src = '..\lib\UCSD_GARCH-2.0.13\MEX Source\';
%              path_garchcore = ['"' path_mex_src 'garchcore.c"'];
%              path_mex_temp = '..\..\build\temp\mex\';
%              LOG.info(['Compiling garchcore: ', path_garchcore]);
%              LOG.info([' - with temp path:   ', path_mex_temp]);
%              domex(path_garchcore, path_mex_temp);
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
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
% Nov 2010; Last revision: 12-Jan-2011

%------------- BEGIN CODE --------------
    
    % Create a new *.m file in the mpath directory:
    mfile = [mpath 'mexmaster.m'];
    fid = fopen(mfile, 'w');
    fprintf(fid, '\nfunction mexmaster()');
    fprintf(fid, '\n    mex %s', cfile);
    fprintf(fid, '\nend');
    
    % Run the newly generated file:
    addpath(mpath);
    eval('mexmaster');
    rmpath(mpath);
end