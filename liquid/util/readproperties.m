% THIS SOFTWARE IS RELEASED INTO THE PUBLIC DOMAIN, JULY 2013.
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

function [props] = readproperties(filepath)
    % Reads properties (key=value pairs) from a text file on disk,
    % and returns them as a Matlab Map object.
    %     filepath is a char string pointing to a text file on disk
    %     returns a Map object with char keys and values
    % Read the external file:
    fid = fopen(filepath);
    cellarr = textscan(fid, '%s', 'delimiter','\n', 'commentStyle','#');
    fclose(fid);
    % Create a properties map:
    cellcount = length(cellarr{1});
    keys = cell(cellcount);
    vals = cell(cellcount);
    clear keys;
    clear vals;
    for i=1:cellcount
        [k, v] = strtok(char(cellarr{1}(i)), '=');
        v = v(2:length(v));
        keys(i) = {['' k '']};
        vals(i) = {['' v '']};
    end
    props = containers.Map(keys, vals, 'uniformvalues', true);
end

% function [props] = readproperties(filepath)
%     % Reads properties (key=value pairs) from a text file on disk,
%     % and returns them as a Matlab Map object.
%     %     filepath is a char string pointing to the text file on disk
%     %     returns a Map object with char keys and values
%     
%     % Read the external file:
%     fid = fopen(filepath);
%     cellarr = textscan(fid, '%s %s', 'delimiter','=', 'commentStyle','#');
%     fclose(fid);
%     
%     % Create a properties map:
%     cellcount = length(cellarr{1});
%     keys = cell(cellcount);
%     vals = cell(cellcount);
%     clear keys;
%     clear vals;
%     for i=1:cellcount
%         keys(i) = {['' char(cellarr{1}(i)) '']};
%         vals(i) = {['' char(cellarr{2}(i)) '']};
%     end
%     props = containers.Map(keys, vals);
%     
% end
