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

function val = get(logger,propName)
    % GET Get logger property from the specified object
    % and return the value. Property names are: 
    %    name, filepath, and level
    switch propName
    case 'name'
       val = logger.name;
    case 'filepath'
       val = logger.filepath;
    case 'level'
       val = logger.level;
    otherwise
       error([propName ,'Is not a valid logger property'])
    end
end