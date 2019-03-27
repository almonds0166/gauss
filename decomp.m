
% decomp.m; v 3.3.2; mlandry@mit.edu for help
%
% DECOMP   Tool created to fit spectrophotometric data as the superposition of
%          gaussian curves
%
%     W = DECOMP(M, G) returns a structure W similar to the output of GAUSS with
%     a few differences (see below). M is the matrix of data, with the first row
%     the vector of wavelengths and the following rows the absorbance values. G
%     is a Npks x 2 matrix -- Npks being the assumed number of underlying peaks.
%     The first column of G represents positions and the second column
%     represents widths. Currently DECOMP only supports 1 <= Npks <= 12.
%
%     A figure will open displaying the first spectrum along with its initial
%     fit. Here, the user can manipulate the guess matrix in a visual way. The
%     program works nearly entirely with key presses -- pressing certain keys
%     will perform useful actions. The following actions are always available:
%
%                 Key  Effect
%     ---------------  --------------------------------
%                   =  Increase sensitivity by a factor of 2
%                   -  Decrease sensitivity by a factor of 2
%                 1-9  Select a peak to modify
%               a,b,c  Select peaks 10, 11, or 12
%                   l  Toggle legend
%                   r  Plot the average residuals
%
%     Otherwise, there are two modes. The initial mode is at startup and means
%     no peak is selected. These actions are available only in this mode:
%
%                 Key  Effect
%     ---------------  --------------------------------
%                   i  Fit the positions, widths, and heights, by one iteration
%                   w  Fit the widths and heights only, by one iteration
%                   x  Fit the positions and heights only, by one iteration
%                   z  Undo the last fitting action
%           leftarrow  Decrement the current solution number displayed
%          rightarrow  Increment the current solution number displayed
%                   g  Print the current guess matrix in the command window
%                   q  Reset shift-cutting factor back to original
%
%     When a peak is selected, these actions are instead possible:
%
%                 Key  Effect
%     ---------------  --------------------------------
%           leftarrow  Move the position of the peak toward lower wavelength
%          rightarrow  Move the position of the peak toward higher wavelength
%             uparrow  Increase the width of the peak
%           downarrow  Decrease the width of the peak
%                   w  Lock/unlock the width from changing
%                   x  Lock/unlock the position from changing
%              escape  Deselect the peak, return to initial mode
%
%     All peaks are initially unlocked in both position and width. Sensitivity
%     determines how many solutions to skip when browsing the spectra in the
%     first mode as well as the change in position and width of a peak in the
%     second mode. The minimum and initial sensitivity is 1x, and the maximum
%     sensitivity is 128x.
%
%     With GAUSS, the output W has numerics for fields G, E, H, A, and R. With
%     DECOMP, these fields are instead cells containing numerics at different
%     iterations. HPH and SPEC will still accept a W structure from DECOMP as
%     the first argument despite these differences.
%
%     DECOMP(M, NPKS) starts DECOMP with a NPKS x 2 guess matrix with uniformly-
%     spaced positions and identical widths.
%
%     DECOMP(..., 'PeakNames', C) places names for each of the peaks on the
%     legend. C is a cell array of length Npks. If C has an empty char array as
%     an element, the corresponding peak will receive the default name.
%
%     DECOMP(..., 'x', X) changes the name of the horizontal axis from
%     'Wavelength (nm)' to X.
%
%     DECOMP(..., 'y', Y) changes the name of the vertical axis from
%     '1-cm Absorbance' to Y.
%
%     DECOMP(..., 'Position', P) specifies the normalized outer position of the
%     figure. Default is [0 0.05 0.75 0.85], because it looks nice.
%
%     DECOMP(..., 'domain', [L U]) specifies the waverange to focus on. Default
%     is the entire waverange of M.
%
%     DECOMP(..., 'Width', W) changes the default line width from 1 to W.
%
%     DECOMP(..., 'xTick', DX) specifies the distance between tick marks to have
%     on the horizontal axis. The default is 25.
%
%     DECOMP(..., 'yTick', DY) specifies the distance between tick marks to have
%     on the vertical axis. The default is 0.4.
%
%     DECOMP(..., 'Bell') displays the underlying gaussian curves instead of the
%     traditional "sticks" visual.
%
%     DECOMP(..., 'Cut', ALPHA) specifies the shift-cutting factor used. For
%     info, see the "Improved versions" section of the Gauss-Newton algorithm
%     page at Wikipedia. Default is 0.65.
%
%     DECOMP(..., 'Tol', EPSILON) specifies the arbitrary tolerance value.
%
%     DECOMP(..., 'pH', PH) displays the pH value at each solution in addition
%     to the solution number.
%
%     DECOMP(..., 'hph', {PH, PEAK}) displays the height-versus-pH plot to the
%     right of the main plot for a given peak PEAK and pH list PH.
%
%     See also: GAUSS, HPH, SPEC, UVVIS.
function W = decomp(M, Gi, varargin)
    assert(nargin >= 2, ...
        ['Expected at least 2 arguments, encountered ' num2str(nargin) '.'])
    global o
    o = struct('x', 'Wavelength (nm)', ...
        'y', '1-cm Absorbance', ...
        'Position', [0 0.05 0.75 0.85], ...
        'Width', 1, ...
        'xTick', 25, ...
        'yTick', 0.4, ...
        'Cut', 0.65, ...
        'Tol', 1e-4, ...
        'domain', [0 Inf], ...
        'DX', 1, ...
        'DW', 1);
    o = cog(o, varargin, ...
        {'PeakNames', 'x', 'y', 'Position', 'Width', 'xTick', 'yTick', ...
        'Cut', 'Tol', 'Color', 'pH', 'hph', 'domain'}, ...
        {'Bell', 'Debug'});
    
    W = struct;
    fdebug('Parameters parsed.');
    
    if numel(Gi) == 1
        Gi = uniformG(Gi, [M(1, 1) M(1, end)]);
        fdebug(['Using uniform G with ' num2str(size(Gi, 1)) ' peaks.']);
    end
    
    global k g
    k = 4 * log(2);
    g = (-1 + sqrt(5)) / 2;

    global i sln atp selected sp
    i = 1;
    sln = 1;
    atp = false;
    selected = 0;
    sp = 1;
    
    W.M = M;
    W.G = {Gi};
    W.Npks   = size(Gi, 1);
    W.Nsln   = size(M, 1) - 1;
    W.Nwav   = size(M, 2);
    W.domain = M(1, :);
    W.Y      = transpose(M(2:end, :));
    W.alpha  = o.Cut;
    W.E = {supplyE(Gi)};
    W.H = {supplyH(W.E{i})};
    W.A = {W.E{i} * W.H{i}};
    W.R = {W.Y - W.A{i}};
    
    if ~isfield(o, 'PeakNames'); o.PeakNames = repmat({''}, 1, W.Npks); end
    if ~isfield(o, 'Color'); o.Color = flipud(jet(W.Npks)); end
    if isfield(o, 'pH')
        o.pH = cellfun(@num2str, num2cell(o.pH), 'UniformOutput', false);
        o.pH = strcat(' (pH~', o.pH, ')');
    else
        o.pH = repmat({''}, 1, W.Nsln);
    end
   
    global Gfloor Gceil
    Gfloor = zeros(size(Gi));
    Gceil  = inf(size(Gi));
    
    global SStot
    SStot = sum((mean(W.Y(:)) - W.Y(:)) .^ 2);
    W.X2  = sum(sum(W.R{1} .^ 2));
    W.DX2 = -inf;
    W.r2  = max(1 - W.X2(1) / SStot, 0);
    
    fdebug('Initialized W structure.');
    
    global h
    h = figure('Name', ['DECOMP [' num2str(W.Npks) ' PEAKS]'], ...
        'NumberTitle', 'Off');
    set(h, 'units', 'normalized', 'outerposition', o.Position)
    
    set(h, 'KeyPressFcn', @pressedkey);
    
    drawsln;
    fdebug;
    uiwait(h);
    
    function fdebug(str)
        if nargin < 1
            atp = true;
            str = 'Ready';
        else
            if o.Debug; fprintf('%s\n', str); end
        end
        if exist('h', 'var')
            title(str);
            drawnow;
        end
        W.debug = str;
    end
    
    function G = uniformG(pks, range)
        G = zeros(pks, 2);
        for p = 1:pks
            G(p, 1) = floor((p * range(2) + (pks - p + 1) * range(1)) ...
                / (pks + 1));
            G(p, 2) = floor((range(2) - range(1)) / (2 * pks));
        end
    end

    function E = supplyE(G)
        E = zeros(W.Nwav, W.Npks);
        for wv = 1:W.Nwav
            for pk = 1:W.Npks
                E(wv, pk) = exp(-k * ((W.M(1, wv) - G(pk, 1)) / G(pk, 2)) ^ 2);
            end
        end
    end
    
    function H = supplyH(E)
        H = zeros(W.Npks, W.Nsln);
        for s = 1:W.Nsln
            H(:, s) = lsqnonneg(E, W.Y(:, s));
        end
    end

    function pressedkey(~, ~, ~)
        if ~atp; return; end
        atp = false;
        switch(get(h, 'CurrentKey'))
            case 'equal'
                if sp < 128; sp = sp * 2; end
                fdebug(['Sensitivity at ' num2str(sp) 'x']);
                atp = true; return
            case 'hyphen'
                if sp > 1; sp = sp / 2; end
                fdebug(['Sensitivity at ' num2str(sp) 'x']);
                atp = true; return
            case{'1', '2', '3', '4', '5', '6', '7', '8', '9'}
                if str2double(get(h, 'CurrentKey')) > W.Npks
                    fdebug(['There is no peak #' get(h, 'CurrentKey') '!'])
                    atp = true; return
                end
                selected = str2double(get(h, 'CurrentKey'));
                fdebug(['Selected peak ' get(h, 'CurrentKey')]);
                i = i + 1;
                W.E{i}   = W.E{i - 1};
                W.H{i}   = W.H{i - 1};
                W.A{i}   = W.A{i - 1};
                W.R{i}   = W.R{i - 1};
                W.G{i}   = W.G{i - 1};
                W.X2(i)  = W.X2(i - 1);
                W.DX2(i) = W.DX2(i - 1);
                W.r2(i)  = W.r2(i - 1);
                atp = true; return
            case{'a', 'b', 'c'}
                if str2double(get(h, 'CurrentKey')) > W.Npks
                    fdebug(['There is no peak #' get(h, 'CurrentKey') '!'])
                    atp = true; return
                end
                selected = double(get(h, 'CurrentKey')) - 87;
                fdebug(['Selected peak ' num2str(selected)]);
                i = i + 1;
                W.E{i}   = W.E{i - 1};
                W.H{i}   = W.H{i - 1};
                W.A{i}   = W.A{i - 1};
                W.R{i}   = W.R{i - 1};
                W.G{i}   = W.G{i - 1};
                W.X2(i)  = W.X2(i - 1);
                W.DX2(i) = W.DX2(i - 1);
                W.r2(i)  = W.r2(i - 1);
                atp = true; return
            case 'l'
                if isfield(o, 'hph')
                    subplot(1, 2, 1); legend('toggle')
                    subplot(1, 2, 2); legend('toggle')
                else
                    legend('toggle')
                end
            case 'r'
                f = figure('Name', 'DECOMP [AVERAGE RESIDUALS]', ...
                    'NumberTitle', 'Off');
                hold on
                plot([W.M(1, 1), W.M(1, end)], [0 0], '-k')
                plot((1:W.Nwav) + W.M(1, 1) - 1, ...
                    mean(W.R{end}, 2), '*', 'Color', 'Green')
                xlim([max(o.domain(1), W.M(1, 1)), ...
                    min(o.domain(2), W.M(1, end))])
                xlabel('Wavelength (nm)')
                ylabel('Mean residuals over all measurements')
                title(['X^2 = ' num2str(W.X2(end)) ...
                    ', r^2 = ' num2str(W.r2(end))])
                uiwait(f)
        end
        if selected
            G = W.G{i};
            switch(get(h, 'CurrentKey'))
                case 'escape'
                    selected = 0;
                    fdebug;
                case 'x'
                    if Gfloor(selected, 1) > 0
                        Gfloor(selected, 1) = 0;
                        Gceil(selected, 1) = inf;
                        if strcmp(o.PeakNames{selected}, '')
                            fdebug(['POITION of PEAK ' num2str(selected) ...
                                ' UNLOCKED'])
                        else
                            fdebug(['POSITION of ''' o.PeakNames{selected} ...
                                ''' UNLOCKED'])
                        end
                    else
                        Gfloor(selected, 1) = G(selected, 1);
                        Gceil(selected, 1) = G(selected, 1);
                        if strcmp(o.PeakNames{selected}, '')
                            fdebug(['PEAK ' num2str(selected) ...
                                ' LOCKED into POSITION ' ...
                                num2str(Gfloor(selected, 1)) ' nm'])
                        else
                            fdebug(['''' o.PeakNames{selected} ...
                                ''' LOCKED into POSITION ' ...
                                num2str(Gfloor(selected, 1)) ' nm'])
                        end
                    end
                case 'w'
                    if Gfloor(selected, 2) > 0
                        Gfloor(selected, 2) = 0;
                        Gceil(selected, 2) = inf;
                        if strcmp(o.PeakNames{selected}, '')
                            fdebug(['WIDTH of PEAK ' num2str(selected) ...
                                ' UNLOCKED'])
                        else
                            fdebug(['WIDTH of ''' o.PeakNames{selected} ...
                                ''' UNLOCKED'])
                        end
                    else
                        Gfloor(selected, 2) = G(selected, 2);
                        Gceil(selected, 2) = G(selected, 2);
                        if strcmp(o.PeakNames{selected}, '')
                            fdebug(['PEAK ' num2str(selected) ...
                                ' LOCKED into WIDTH ' ...
                                num2str(Gfloor(selected, 2)) ' nm'])
                        else
                            fdebug(['''' o.PeakNames{selected} ...
                                ''' LOCKED into WIDTH ' ...
                                num2str(Gfloor(selected, 2)) ' nm'])
                        end
                    end
                case 'leftarrow'
                    if floor(G(selected, 1)) - sp * o.DX >= Gfloor(selected, 1)
                        G(selected, 1) = floor(G(selected, 1)) - sp * o.DX;
                        W.G{i} = G;
                        W.E{i} = supplyE(G);
                        W.H{i} = supplyH(W.E{i});
                        W.A{i} = W.E{i} * W.H{i};
                        R = W.Y - W.A{i};
                        W.R{i} = R;
                        X2 = sum(R(:) .^ 2);
                        W.X2(i)  = X2;
                        W.DX2(i) = X2 - W.X2(i - 1);
                        W.r2(i)  = max(1 - X2 / SStot, 0);
                        drawsln;
                        if strcmp(o.PeakNames{selected}, '')
                            fdebug(['Decreased position of PEAK ' ...
                                num2str(selected) ' to ' ...
                                num2str(G(selected, 1)) ' nm'])
                        else
                            fdebug(['Decreased position of ''' ...
                                num2str(o.PeakNames{selected}) ''' to ' ...
                                num2str(G(selected, 1)) ' nm']);
                        end
                    else
                        fdebug('Reached floor!')
                    end
                case 'rightarrow'
                    if ceil(G(selected, 1)) + sp * o.DX <= Gceil(selected, 1)
                        G(selected, 1) = ceil(G(selected, 1)) + sp * o.DX;
                        W.G{i} = G;
                        W.E{i} = supplyE(G);
                        W.H{i} = supplyH(W.E{i});
                        W.A{i} = W.E{i} * W.H{i};
                        R = W.Y - W.A{i};
                        W.R{i} = R;
                        X2 = sum(R(:) .^ 2);
                        W.X2(i)  = X2;
                        W.DX2(i) = X2 - W.X2(i - 1);
                        W.r2(i)  = max(1 - X2 / SStot, 0);
                        drawsln;
                        if strcmp(o.PeakNames{selected}, '')
                            fdebug(['Increased position of PEAK ' ...
                                num2str(selected) ' to ' ...
                                num2str(G(selected, 1)) ' nm'])
                        else
                            fdebug(['Increased position of ''' ...
                                num2str(o.PeakNames{selected}) ''' to ' ...
                                num2str(G(selected, 1)) ' nm']);
                        end
                    else
                        fdebug('Reached ceiling!')
                    end
                case 'uparrow'
                    if ceil(G(selected, 2)) + sp * o.DW <= Gceil(selected, 2)
                        G(selected, 2) = ceil(G(selected, 2)) + sp * o.DW;
                        W.G{i} = G;
                        W.E{i} = supplyE(G);
                        W.H{i} = supplyH(W.E{i});
                        W.A{i} = W.E{i} * W.H{i};
                        R = W.Y - W.A{i};
                        W.R{i} = R;
                        X2 = sum(R(:) .^ 2);
                        W.X2(i)  = X2;
                        W.DX2(i) = X2 - W.X2(i - 1);
                        W.r2(i)  = max(1 - X2 / SStot, 0);
                        drawsln;
                        if strcmp(o.PeakNames{selected}, '')
                            fdebug(['Increased width of PEAK ' ...
                                num2str(selected) ' to ' ...
                                num2str(G(selected, 2)) ' nm'])
                        else
                            fdebug(['Increased width of ''' ...
                                num2str(o.PeakNames{selected}) ''' to ' ...
                                num2str(G(selected, 2)) ' nm']);
                        end
                    else
                        fdebug('Reached ceiling!')
                    end
                case 'downarrow'
                    if floor(G(selected, 2)) - sp * o.DW >= Gfloor(selected, 2)
                        G(selected, 2) = floor(G(selected, 2)) - sp * o.DW;
                        W.G{i} = G;
                        W.E{i} = supplyE(G);
                        W.H{i} = supplyH(W.E{i});
                        W.A{i} = W.E{i} * W.H{i};
                        R = W.Y - W.A{i};
                        W.R{i} = R;
                        X2 = sum(R(:) .^ 2);
                        W.X2(i)  = X2;
                        W.DX2(i) = X2 - W.X2(i - 1);
                        W.r2(i)  = max(1 - X2 / SStot, 0);
                        drawsln;
                        if strcmp(o.PeakNames{selected}, '')
                            fdebug(['Decreased width of PEAK ' ...
                                num2str(selected) ' to ' ...
                                num2str(G(selected, 2)) ' nm'])
                        else
                            fdebug(['Decreased width of ''' ...
                                num2str(o.PeakNames{selected}) ''' to ' ...
                                num2str(G(selected, 2)) ' nm']);
                        end
                    else
                        fdebug('Reached floor!')
                    end
            end
            atp = true;
            return
        end
        switch(get(h, 'CurrentKey'))
            case 'q'
                W.alpha = o.Cut;
                fdebug(['Set alpha to ' num2str(o.Cut)]);
                atp = true;
                return
            case 'w'
                DG = supplyDG('w');
                fdebug('Updating widths and heights only ...');
            case 'x'
                DG = supplyDG('x');
                fdebug('Updating positions and heights only ...');
            case 'i'
                DG = supplyDG('w', 'x');
                fdebug('Updating guess matrix ...');
            case 'z'
                if i > 1
                    fdebug('Undoing action ...')
                    W.E(i)   = [];
                    W.H(i)   = [];
                    W.A(i)   = [];
                    W.R(i)   = [];
                    W.G(i)   = [];
                    W.X2(i)  = [];
                    W.DX2(i) = [];
                    W.r2(i)  = [];
                    i = i - 1;
                    drawsln;
                end
                fdebug;
                return
            case 'leftarrow'
                sln = 1 + mod(sln - sp - 1, W.Nsln);
                drawsln;
                fdebug;
                return
            case 'rightarrow'
                sln = 1 + mod(sln + sp - 1, W.Nsln);
                drawsln;
                fdebug;
                return
            case 'g'
                format shortG
                disp('G = ');
                disp(W.G{i});
                atp = true;
                return
            otherwise
                atp = true;
                return
        end
        while true
            G = min(max(W.G{i} + W.alpha * DG, Gfloor), Gceil);
            E = supplyE(G);
            H = supplyH(E);
            A = E * H; R = W.Y - A; X2 = sum(R(:) .^ 2);
            if X2 <= W.X2(i)
                i = i + 1;
                W.E{i}   = E;
                W.H{i}   = H;
                W.A{i}   = A;
                W.R{i}   = R;
                W.G{i}   = G;
                W.X2(i)  = X2;
                W.DX2(i) = X2 - W.X2(i - 1);
                W.r2(i)  = max(1 - X2 / SStot, 0);
                W.alpha  = min(W.alpha / g, o.Cut);
                break
            elseif W.alpha > o.Tol
                W.alpha = W.alpha * g;
            else
                fdebug('Shift-cutting factor became small!');
                atp = true;
                return
            end
        end
        drawsln;
        fdebug;
    end

    function DG = supplyDG(varargin)
        DG = zeros(W.Npks, 2);
        G = W.G{i};
        R = W.R{i};
        for pk = 1:W.Npks
            Z = coeff(pk);
            S = zeros(W.Npks); S(pk, pk) = 1;
            DE = (2 * k / G(pk, 2)) * Z * W.E{i} * S;
            if any(strcmpi(varargin, 'x'))
                DG(pk, 1) = pinv(jacobian(DE)) * R(:);
            end
            if any(strcmpi(varargin, 'w'))
                DE = Z * DE;
                DG(pk, 2) = pinv(jacobian(DE)) * R(:);
            end
        end
    end

    function Z = coeff(pk)
        Z = eye(W.Nwav);
        G = W.G{i};
        for wav = 1:W.Nwav
            Z(wav, wav) = (W.M(1, wav) - G(pk, 1)) / G(pk, 2);
        end
    end

    function J = jacobian(DE)
        J = DE * W.H{i} + W.E{i} / (W.E{i}.' * W.E{i}) * ...
            (DE.' * W.Y - (DE.' * W.E{i} + W.E{i}.' * DE) * W.H{i});
        J = J(:);
    end

    function drawsln
        fdebug(['Drawing sln ' num2str(sln) ' ...']);
        
        clf;
        if isfield(o, 'hph')
            subplot(1, 2, 1)
        end
        hold on
        
        legendplots  = repmat(line, 1, 2 + W.Npks);
        legendlabels = [{['Measured (sln ' num2str(sln) ')' o.pH{sln}], ...
            'Fitted'} o.PeakNames];
        
        G = W.G{i}; H = W.H{i}; A = W.A{i};
        x = (1:W.Nwav) + W.M(1, 1) - 1;
        
        legendplots(1) = plot(x, W.Y(:, sln), '-', 'LineWidth', o.Width, ...
            'Color', [0.1 0.3 1.0]);
        legendplots(2) = plot(x, A(:, sln), '-', 'LineWidth', o.Width, ...
            'Color', [1.0 0.1 0.0]);
        for p = 1:W.Npks
            if o.Bell
                y = H(p, sln) * ...
                    exp(-k * ((x - G(p, 1)) ./ G(p, 2)) .^ 2);
                legendplots(2 + p) = plot(x, y, ':', ...
                    'Color', o.Color(p, :), 'LineWidth', 1.5 * o.Width);
            else
                legendplots(2 + p) = plot([G(p, 1), G(p, 1)], ...
                    [0 H(p, sln)], '-', 'Color', o.Color(p, :), ...
                    'LineWidth', 1.5 * o.Width);
                plot([(G(p, 1) - G(p, 2) / 2), (G(p, 1) + G(p, 2) / 2)], ...
                    [H(p, sln) / 2, H(p, sln) / 2], ':', ...
                    'Color', o.Color(p, :), 'LineWidth', 1.5 * o.Width);
            end
            if strcmp(legendlabels{2 + p}, '')
                legendlabels{2 + p} = ['Peak ' num2str(p) ', ' ...
                    num2str(round(G(p, 1), 1)) ' nm (' ...
                    num2str(round(G(p, 2), 1)) ' nm)'];
            end
        end
        
        legend(legendplots, legendlabels)
        xlim([max(o.domain(1), W.M(1, 1)), min(o.domain(2), W.M(1, end))])
        ylim([-0.01, 1.1 * max(W.Y(:))])
        xlabel(o.x); ylabel(o.y)
        set(gca, 'XTick', M(1, 1):o.xTick:M(1, end))
        set(gca, 'YTick', 0:o.yTick:(1.1 * max(W.Y(:))))
        
        if isfield(o, 'hph')
            subplot(1, 2, 2)
            hph(W, o.hph{1}, o.hph{2}, 'holdon', 'subplot', [1 2 2]);
            subplot(1, 2, 1)
        end
        
        hold off
    end
end
























