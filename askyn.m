
% askyn.m, mlandry@mit.edu for help
%
% ASKYN   Asks you a yes or no question, returns your choice.
%
%     C = ASKYN prints two choices, namely "yes" and "no" with the pointer
%     positioned initially on "yes". Press Up and Down to select "yes" and "no"
%     respectively, then Enter to confirm your choice. Another way to declare
%     your choice is to simply press 'y' or 'n'. C is boolean.
%
%     ASKYN(DEFAULT) initially selects "yes" if DEFAULT is 'y' and "no" if
%     DEFAULT is 'n'.
%
%     Note that the focus on the command window is lost when using ASKYN. This
%     happens since the only way I could get user input was to have a figure
%     open and focused. This figure is named "ASKYN FIGURE". Closing it returns
%     the user's last selected choice.
%
%     See also: CHOICE, QUESTDLG.
function c = askyn(default)
    if nargin == 0; default = 'y'; end
    assert(any(strcmpi({'y', 'n'}, default)), ...
        'Second argument must be either ''y'' or ''n''')
    
    h = figure('Name', 'ASKYN FIGURE', 'NumberTitle', 'Off');
    set(h, 'units', 'normalized', 'outerposition', [0 0 0 0]);
    c = ~strcmpi(default, 'n');
    
    if c; fprintf('> yes\n  no'); else; fprintf('  yes\n> no'); end
    while 1
        try
            waitforbuttonpress
        catch
            fprintf('\n')
            return
        end
        k = double(get(h, 'CurrentCharacter'));
        if any([30, 121, 89] == k)
            if ~c; fprintf('\b\b\b\b\b\b\b\b\b\b> yes\n  no'); end
            c = true;
        end
        if any([31, 110, 78] == k)
            if c; fprintf('\b\b\b\b\b\b\b\b\b\b  yes\n> no'); end
            c = false;
        end
        if any([13, 121, 89, 110, 78] == k)
            fprintf('\n')
            close(h)
            return
        end
    end
end





