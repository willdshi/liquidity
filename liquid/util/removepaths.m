% THIS SOFTWARE IS RELEASED INTO THE PUBLIC DOMAIN, SEP 2010.
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

function removepaths(extrapaths)
    global LOG;
    for i = 1:length(extrapaths)
        LOG.info([' - removing path:  ', extrapaths{i}]);
        rmpath(extrapaths{i});
    end
end
