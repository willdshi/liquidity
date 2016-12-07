function testarg(booleantest, errid, errmsg)
%TESTARG - Assess a boolean test, and throw an error if it evaluates true
%
% Syntax:      testarg(booleantest, msg)
%
% Inputs:
%              booleantest - Test that will generate an exception when true
%              errmsg - Message to embed in an exception, if thrown
%
% Outputs: none
%
% Example: 
%              % Run the step:
%              x = 2;
%              y = 2;
%              testarg((x+y~=4), 'myfunc:AddOk', 'Basic addition fails');
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
% Nov 2010; Last revision: 13-Jan-2011

%------------- BEGIN CODE --------------
    global LOG;
    
    if (booleantest)
        LOG.err(errmsg);
        throw(MException(errid, errmsg));
    end
end
