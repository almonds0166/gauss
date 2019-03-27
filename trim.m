
% Trims a character array of certain characters.
%     TRIM(STR) trims the left and right sides of whitespaces.
%
%     TRIM(STR, CHRS) trims the left and right side of STR of any characters
%     in CHRS. CHRS cannot (yet) be a cell of character arrays.
%
%     TRIM(STR, CHRS, 'border') is the same as above.
%
%     TRIM(STR, CHRS, 'every') removes all characters from CHRS within STR.
%
%     TRIM(SRT, CHRS, 'left') and TRIM(SRT, CHRS, 'right') trims only the left
%     side and right side respectively.
%
%     If more than one option is given, TRIMS uses the first given.
function trimmed = trim(str, chrs, varargin)
    assert(nargin >= 1, 'Expected at least 1 argument, encountered 0.');
    if nargin == 1; chrs = ' '; end
    if nargin <= 2; mode = 'border'; else; mode = varargin{1}; end
    trimmed = str;
    switch(mode)
        case 'every'
            trimmed(ismember(trimmed, chrs)) = [];
        case 'left'
            n = 0;
            for i = 1:numel(str)
                if any(strcmp(chrs, str(i))); n = n + 1; else; break; end
            end
            if n > 0; trimmed(1:n) = []; end
        case 'right'
            n = numel(str) + 1;
            for i = numel(str):-1:1
                if any(strcmp(chrs, str(i))); n = n - 1; else; break; end
            end
            if n < numel(str) + 1; trimmed(n:end) = []; end
        otherwise % mode = 'border'
            trimmed = trim(trimmed, chrs, 'left');
            trimmed = trim(trimmed, chrs, 'right');
    end
end