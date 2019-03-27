
% Imports data from some UV-Vis .csv file. Takes about 6 seconds to load,
% depending on the size of the file. This script will remove any "Blank"
% measurements. w_range is the desired range of wavelength, sln_range is the
% desired range of solutions. Default is all the available data ([220 750] and
% [1 Inf], respectively). Recommendation is to save your variable as a dotmat so
% it is quickly rather than slowly loaded when needed.
%
% Example of use:
%     % Import all spectra from 'test.csv', only wavelengths 350 thru 750 nm
%     M = csv2matrix('test.csv', [350, 750], [1, inf]);
function Output = csv2matrix(filename, wav_range, sln_range)

    % Initialize variables
    delimiter = ',';
    start_pos = [1, 32]; end_pos = [inf, 562];
    
    if nargin == 2
        sln_range = [1, inf];
    elseif nargin == 1
        wav_range   = [220, 750];
        sln_range = [1, inf];
    end

    % Format of our particular .csv
    formatSpec = ...
        strcat(repmat('%*q', 1, 24), repmat('%q', 1, 651), '%[^\n\r]');

    % Open the file
    fileID = fopen(filename, 'r');

    % Read all columns of data according to formatSpec
    % Errors can occur here if you try reading another type of .csv
    dataArray = textscan(fileID, ...
             formatSpec, end_pos(1)-start_pos(1) + 1, ...
            'Delimiter',                    delimiter, ...
          'HeaderLines',             start_pos(1) - 1, ...
        'ReturnOnError',                        false, ...
            'EndOfLine',                       '\r\n');

    % Close the file
    fclose(fileID);

    % Convert the contents of columns containing numeric text to numbers
    % Replace non-numeric text with NaN
    raw = repmat({''}, length(dataArray{1}), length(dataArray) - 1);
    for col = 1:length(dataArray) - 1
        raw(1:length(dataArray{col}), col) = dataArray{col};
    end
    numericData = NaN(size(dataArray{1}, 1), size(dataArray, 2));

    % Used expressions
    regexstr = [ '(?<prefix>.*?)(?<numbers>' ...
        '([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|' ...
        '([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))' ...
        '(?<suffix>.*)' ];
    thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';

    for col = 1:651
        rawData = dataArray{col};
        for row = 1:size(rawData, 1)
            try
                result = regexp(rawData{row}, regexstr, 'names');
                numbers = result.numbers;

                invalidThousandsSeparator = false;
                if any(numbers == ',')
                    if isempty(regexp(numbers, thousandsRegExp, 'once'))
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end

                % Convert numeric text to numbers.
                if ~invalidThousandsSeparator
                    numbers = textscan(strrep(numbers, ',', ''), '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
                end
            catch me
            end
        end
    end

    % Replace non-numeric cells with NaN
    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw);
    raw(R) = {NaN};

    % Create output variable
    Output = cell2mat(raw);
    if end_pos(2) == inf
        end_pos(2) = size(Output, 2);
    end
    Output = Output(:, start_pos(2):end_pos(2));
    
    % Remove any "NaN rows" from Blank measurements
	rtr = zeros(1, size(Output, 1));
    for row = 1:size(Output, 1)
        if isnan(Output(row, 1))
            rtr(row) = row;
        end
    end
    Output(rtr(rtr ~= 0), :) = [];
    
    % Return only the desired wavelengths and desired solutions. This
    % assumes the lowest wavelength is 220 nm and the maximum wavelength is
    % 750 nm.
    Output = Output(:, (wav_range(1) - 220 + 1):(wav_range(2) - 220 + 1));
    Output = [ Output(1, :); Output( ...
        (sln_range(1) +1):(min(size(Output, 1) -1, sln_range(2)) +1), ...
        :) ];
    
end








