
% spec.m; v 1.3.6; mlandry@mit.edu for help
%
% SPEC Plots spectra.
%
% 1ST use of SPEC (when first argument is numeric matrix M, ie from CSV2MATRIX):
%
%     H = SPEC(M) plots all spectra of matrix M and returns the current figure
%     handle.
%
%     SPEC(..., 'color', C) gives color to the curves, where C is a matrix of
%     colors with <number of solutions in M> rows and 3 columns. Example:
%
%         >> pH = csvread(my_pH_file);
%         >> SPEC(M, 'Color', redblue(pH))
%
%     SPEC(..., 'holdon') uses the current figure instead of creating a new one.
%
%     SPEC(..., 'first', PH) only plots the solutions for which PH is
%     increasing.
%
%     SPEC(..., 'last', PH) only plots the solutions for which PH is decreasing.
%
% 2ND use of SPEC (when first argument is a model structure W, ie from DECOMP):
%
%     H = SPEC(W) plots the data and the model allowing the user to visually
%     comprehend how well the model fits, and it returns the handle for the last
%     solution to be plotted.
%
%     SPEC(..., 'detailed') provides the widths of the peaks in addition to the
%     positions, in the legend, that is. Also displays current solution.
%
%     SPEC(..., 'color', C) gives color to the peaks, where C is a matrix of
%     colors with <number of peaks in model W> rows and 3 columns. Default is
%     flipud(jet(W.Npks)).
%
%     SPEC(..., 'time', T) specifies the amount of time in seconds to pause
%     between displaying the solutions. Default is 0 to speed through the series
%     as quickly as possible.
%
%     SPEC(..., 'bell') shows the actual gaussian components instead of the
%     "sticks."
%
%     SPEC(..., 't', F) where F is a function handle instead of a char vector T.
%     In this case, the input argument is the current solution number already in
%     string form. Example:
%
%         >> SPEC(W, 't', @(i) ['Sln ' i])
%
%     SPEC(..., 'gif', {FILE, DELAY}) creates a gif slideshow at FILE of all the
%     solutions at the delay time of DELAY. DELAY is in milliseconds.
%
%     SPEC(..., 'f', F) specifies some FontSize properties to F.
%
%     SPEC(..., 'legendoff') does not show the legend.
%
%     SPEC(..., 'grid', M) places a vertical grid at every multiple of M.
%
% These remaining options apply to both uses of SPEC:
%
%     SPEC(..., 'only', SET) plots only those spectra corresponding to SET. For
%     example, if M had 20 measurements, SET may be [1 10 11 20 15 5], etc.
%
%     SPEC(..., 'subplot', [m n p]) plots the spectra in position p of an m-by-n
%     subplot handle.
%
%     SPEC(..., 'x', X) specifies x-label to be used instead of the default of
%     'Wavelength (nm)'.
%
%     SPEC(..., 'y', Y) is the same, but for the y-label. Default is
%     '1-cm Absorbance'.
%
%     SPEC(..., 't', T) specifies the title to T (default is no title).
%
%     SPEC(..., 'domain', [L U]) specifies the x limits. Default is
%     [<min wavelength>, <max wavelength>].
%
%     SPEC(..., 'range', [L U]) specifies the lower and upper bounds for the y-
%     axis. Default is [0 ceil(<max absorbance>)].
%
%     SPEC(..., 'pos', [X Y DX DY]) specifies the (normalized) outer position of
%     the figure. Default is [0 0.05 0.7 0.8] 'cause it looks good.
%
%     SPEC(..., 'width', W) specifies the line width. Default is 1.
%
%     SPEC(..., 'tick', W) specifies the distance between ticks in the same
%     units as the x-axis. Default is 50.
%
%     See also:
%         PLOT, GAUSS, DECOMP, REDBLUE, UVVIS.
function h = spec(MorW, varargin)
    assert(nargin > 0, ...
        ['Expected at least 1 argument (encountered ' num2str(nargin) ').'])
    assert(isnumeric(MorW) || isstruct(MorW), ...
        ['Expected the class of the first argument to be ''numeric'' or ' ...
        '''structure'', encountered class ''' class(MorW) ''' instead.'])
    o = struct(...
        'subplot', [1 1 1], ...
        'x', 'Wavelength (nm)', ...
        'y', '1-cm Absorbance', ...
        't', '', ...
        'pos', [0 0.05 0.7 0.8], ...
        'width', 1, ...
        'tick', 50, 'f', 15);
    
    if isnumeric(MorW)
        M = MorW;
        o.domain = [min(M(1, :)) max(M(1, :))];
        o = cog(o, varargin, {'subplot', 'only', 'x', 'y', 't', 'color', ...
            'pos', 'range', 'width', 'domain', 'first', 'last', 'tick'}, ...
            {'holdon'});
        if isfield(o, 'first') && ~isfield(o, 'last')
            i = find(o.first == max(o.first), 1, 'last');
            M = [M(1, :); M(1 + 1:i, :)];
            o.first = o.first(1:i);
            o.color = o.color(1:i, :);
        elseif isfield(o, 'last') && ~isfield(o, 'first')
            i = find(o.last == max(o.last), 1, 'last');
            M = [M(1, :); M(1 + (i + 1):end, :)];
            o.last = o.last((i + 1):end);
            o.color = o.color((i + 1):end, :);
        end
        %o.domain = [max(min(M(1, :)), o.domain(1)), min(max(M(1, :)), o.domain(2))];
        if ~isfield(o, 'only'); o.only = 1:(size(M, 1) - 1); end
        if ~isfield(o, 'range')
            o.range = [0 ceil(max(max(M(1 + o.only, :))))];
        end
        
        if o.holdon; h = gcf; else; h = figure; end
        subplot(o.subplot(1), o.subplot(2), o.subplot(3));
        hold on
        
        x = M(1, :);
        %x = (1:size(M, 2)) + min(M(1, :)) - 1;
        for sln = 1:numel(o.only)
            y = M(1 + o.only(sln), :);
            p = plot(x, y, 'LineWidth', o.width);
            if isfield(o, 'color'); p.Color = o.color(o.only(sln), :); end
        end
        
        xlabel(o.x); ylabel(o.y); title(o.t)
        xlim(o.domain); ylim(o.range)
        set(h, 'units', 'normalized', 'outerposition', o.pos);
        set(gca, 'XTick', (o.tick * floor(o.domain(1) / o.tick)):o.tick:...
            (o.tick * ceil(o.domain(2) / o.tick)))
        
        hold off
        
    else % isstruct
        W = MorW;
        if isa(W.G, 'cell')
            W.G = W.G{end};
            W.E = W.E{end};
            W.H = W.H{end};
            W.A = W.A{end};
            W.R = W.R{end};
        end
        o.time = 0;
        o.domain = [min(W.M(1, :)) max(W.M(1, :))];
        o = cog(o, varargin, {'subplot', 'only', 'x', 'y', 't', 'color', ...
            'pos', 'range', 'width', 'domain', 'time', 'gif', 'f', 'tick', ...
            'grid'}, {'detailed', 'bell', 'legendoff'});
        o.domain = [max(min(W.M(1, :)), o.domain(1)), ...
            min(max(W.M(1, :)), o.domain(2))];
        if ~isfield(o, 'only'); o.only = 1:W.Nsln; end
        if ~isfield(o, 'range')
            o.range = [-0.01 ceil(max(max(W.M(1 + o.only, :))))];
        end
        if ~isfield(o, 'color'); o.color = flipud(jet(W.Npks)); end
        
        k = 4 * log(2);
        x = (1:W.Nwav) + min(W.M(1, :)) - 1;
        for sln = o.only
            h = clf;
            subplot(o.subplot(1), o.subplot(2), o.subplot(3));
            hold on
            
            if isfield(o, 'grid')
                for i = (o.grid * floor(W.M(1, 1) / o.grid)):o.grid: ...
                        (o.grid * ceil(W.M(1, end) / o.grid))
                    plot([i i], o.range, '--', 'color', [0.5 0.5 0.5], 'linewidth', 0.7)
                end
            end
            
            xlabel(o.x, 'FontSize', o.f); ylabel(o.y, 'FontSize', o.f);
            
            if isa(o.t, 'function_handle')
                title(o.t(num2str(sln)), 'FontSize', o.f)
            else
                title(o.t, 'FontSize', o.f)
            end
            
            xlim(o.domain); ylim(o.range)
            set(h, 'units', 'normalized', 'outerposition', o.pos);
            
            P = repmat(line, 1, 2 + W.Npks);
            L = repmat({''}, 1, 2 + W.Npks);
            
            for p = 1:W.Npks
                if o.bell
                    y = W.H(p, sln) * ...
                        exp(-k * ((x - W.G(p, 1)) ./ W.G(p, 2)) .^ 2);
                    P(2 + p) = plot(x, y, ':', ...
                        'Color', o.color(p, :), 'LineWidth', 1.5 * o.width);
                else
                    P(2 + p) = plot([W.G(p, 1), W.G(p, 1)], ...
                        [0 W.H(p, sln)], '-', ...
                        'Color', o.color(p, :), 'LineWidth', o.width);
                    plot([(W.G(p, 1) - W.G(p, 2) / 2), ...
                        (W.G(p, 1) + W.G(p, 2) / 2)], ...
                        [W.H(p, sln) / 2, W.H(p, sln) / 2], ...
                        ':', 'Color', o.color(p, :), 'LineWidth', 1.5 * o.width)
                end
                L{2 + p} = ['~' num2str(round(W.G(p, 1))) ' nm'];
                if o.detailed
                    L{2 + p} = [L{2 + p} ...
                        ', ~' num2str(round(W.G(p, 2))) ' nm'];
                end
            end
            
            P(1) = plot(x, W.Y(:, sln), '-', 'LineWidth', o.width, ...
                'Color', [0.1 0.3 1.0]);
            P(2) = plot(x, W.A(:, sln), '-', 'LineWidth', o.width, ...
                'Color', [1.0 0.1 0.0]);
            L{1} = 'Measured';
            if o.detailed; L{1} = [L{1} ' (sln ' num2str(sln) ')']; end
            L{2} = 'Fitted';
            
            if ~o.legendoff; legend(P, L, 'fontsize', max(1, o.f - 2)); end
            set(gca, 'XTick', (o.tick * floor(W.M(1,1) / o.tick)):o.tick: ...
                (o.tick * ceil(W.M(1,end) / o.tick)), 'YTick', [])
            hold off
            
            if isfield(o, 'gif')
                gif(o.gif{1}, 'delay', o.gif{2});
            end
            
            pause(o.time)
            
        end
        
    end
end











