function A = combinestructures(A, B)
%COMBINESTRUCTURES - Adds all of the fields of structure B to structure A
%
% Syntax:      A = combinestructures(A, B)
%
% Inputs:
%              A - An arbitrary structure variable
%              B - An arbitrary structure variable
%
% Outputs:
%              A - The input structure A, augmented with the 
%                  contents of B
% Example: 
%              % Combine both sets of states:
%              USA_1865 = combinestructures(union, confederacy);
%
% Other m-files required: None
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
% Nov 2010; Last revision: 12-Nov-2010

%------------- BEGIN CODE --------------

    fields = fieldnames(B);
    for i = 1:length(fields)
        eval(['A.' fields{i} ' = B.' fields{i} ';']);
    end
end