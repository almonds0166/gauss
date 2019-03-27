
% uvvis.m, mlandry@mit.edu for help
%
% UVVIS   Imports UV-Vis csv files as a matrix; an improved version over
%         csv2matrix.
%
%     M = UVVIS(FILENAME) imports the UV-Vis csv FILENAME as a numeric. The
%     first row of M contains all the wavelengths, while the remaining rows
%     contain the absorbance values, just as it appears in the csv.
%
%     UVVIS(FILENAME, [L U]) imports only wavelengths L through U. If omitted,
%     UVVIS detects the min and max wavelengths used in the first meaningful
%     measurement, either 220 and 750, or 190 and 840. Based on testing with
%     ddH2O samples, 275 nm and above has desireable variance.
%
%     UVVIS is an improved version over CSV2MATRIX in that UVVIS is generally
%     faster and will automatically detect the wavelength range used at the
%     DeNovix instrument.
%
%     See also: CSV2MATRIX.
function M = uvvis(filename, range)
    narginchk(1, 2)
    assert(logical(exist(filename, 'file')), ...
        ['There seems to exist no file ''' filename '''. ' ...
        'Check spelling and current path.'])

    fid = fopen(filename, 'r');

    ex =     repmat('%*q', 1, 2);
    ex = [ex repmat('%*s', 1, 14)];
    ex = [ex repmat('%*q', 1, 2)];
    ex = [ex repmat( '%q', 1, 2)];
    ex = [ex repmat('%*q', 1, 5)];
    ex = [ex repmat( '%q', 1, 651)];
    ex = [ex '%[^\n\r]'];

    cols = textscan(fid, ex, Inf, 'Delimiter', ',', ...
        'HeaderLines', 0, 'ReturnOnError', false, 'EndOfLine', '\r\n');

    fclose(fid);

    if nargin < 2
        range = [190 840];
        nm    = {cols{1}, cols{2}};
        for col = 1:2
            for row = 1:length(nm{col})
                str = nm{col}{row};
                if ~strcmp(str, '')
                    flt = textscan(str, '%f');
                    if numel(flt{1})
                        range(col) = flt{1};
                        break
                    end
                end
            end
        end
    else
        range(1) = max(190, range(1));
        range(2) = min(840, range(2));
    end
    if range(2) - range(1) < 0; M = []; return; end

    M = NaN(length(cols{1}), range(2) - range(1) + 1);
    for col = 1:(range(2) - range(1) + 1)
        for row = 1:length(cols{2 + col})
            str = cols{2 + col + range(1) - 190}{row};
            if ~strcmp(str, '')
                flt = textscan(str, '%f');
                if numel(flt{1})
                    M(row, col) = flt{1};
                end
            end
        end
    end
    
    row = 1;
    while row < size(M, 1)
        if isnan(M(row, 1))
            M(row, :) = [];
        else
            row = row + 1;
        end
    end

end