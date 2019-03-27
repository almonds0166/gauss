
% choice.m, mlandry@mit.edu for help
%
% CHOICE   Prints a list of options and returns your choice.
%
%     N = CHOICE(O) prints the options contained in the cell array O next to the
%     numbers 1 through <numel(O)> and returns which option you decided on.
%
%     CHOICE(..., 'zero') marks the first option in O as '0' instead of '1'.
%     This also sets the default choice to the first option in O -- that is, an
%     input of '' corresponds to '0'.
%
%     CHOICE(..., 'many') allows the user to return multiple choices separated
%     by spaces or commas or semicolons.
%
%     CHOICE(..., 's') returns the raw char vector entered instead of the
%     numeric value.
%
%     CHOICE(..., 'prompt', P) changes the default prompt from '> ' to P.
%
%     See also QUESTDLG, ASKYN.

function n = choice(O, varargin)
    assert(nargin >= 1, 'Expected at least 1 argument.')
    o = struct('prompt', '> ');
    o = cog(o, varargin, {'prompt'}, {'zero', 's', 'many'});
    
    indices = cellfun(@num2str, num2cell((1:numel(O)) - o.zero), ...
        'UniformOutput', false);
    tab = 4 * ceil((0.5 + max(cellfun(@numel, indices))) / 4);
    output = '';
    for i = 1:numel(indices)
        s = O{i};
        rightside = ' ';
        while numel(s) > 80 - tab - 1
            j = find(s == ' ', Inf); j = max(j(j <= 80 - tab));
            assert(~isempty(j), ...
                ['The option corresponding to choice ''' indices{i} ''' (''' ...
                O{i}(1:7) '...'') is too long. Consider adding spaces.'])
            rightside = [rightside s(1:(j - 1)) '\n' repmat(' ', 1, 1 + tab)];
            s = s((j + 1):end);
        end
        rightside = [rightside s '\n'];
        output = [output sprintf(['%' num2str(tab) 's'], indices{i}) ...
            sprintf(rightside)];
    end
    
    while 1
        fprintf(output);
        n = input(o.prompt, 's');
        N = regexp(n, '[\s,;]', 'split');
        N = N(~strcmp(N, ''));
        if ~isempty(N)
            if ~o.many && numel(N) > 1; continue; end
            cont = false;
            for i = 1:numel(N)
                if ~any(strcmp(indices, N{i})); cont = true; break; end
            end
            if cont
                continue
            elseif o.s
            elseif o.many
                n = cell2mat(cellfun(@str2double, N, 'UniformOutput', false));
            else
                n = str2double(N{1});
            end 
            break
        elseif o.zero
            if o.s; return; else; n = 0; return; end
        end
    end
end