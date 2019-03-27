
% hph.m, mlandry@mit.edu for help
%
% HPH Plots height versus pH.
%
%     H = HPH(W, PH, PKS) plots the height of each peak in PKS versus the
%     corresponding value in PH and returns the figure handle.
%
%     [H, FITS] = HPH(..., 'poly', DEGREES) plots polynomial fits along with
%     each peak data. FITS is a numel(PKS) x numel(DEGREES) cell containing the
%     fitting constants with the zero-order constant leftmost and the highest-
%     order constant rightmost.
%
%     HPH(..., 'x', X) changes the x-label to X. Default is none.
%
%     HPH(..., 'y', Y) changes the y-label to Y. Default is none.
%
%     HPH(..., 't', T) changes the title to char vector T. Default is no title.
%
%     HPH(..., 't', FUNC) changes the title using a function handle where the
%     input is the char version of PKS.
%
%     HPH(..., 'width') changes the width of the fitted lines. Default is 1.
%
%     HPH(..., 'size', X) changes the size of the markers to X. Default is 6.
%
%     HPH(..., 'domain', [L, U]) changes the x-limits to [L, U] with L < U.
%     Default is [2, 12] with expanding if needed.
%
%     HPH(..., 'range', [L, U]) changes the y-limits to [L, U], with L < U.
%     Default is [0, <the halfinteger nearest to the maximum height in W.H in
%     the positive direction>], in English, a little more room than necessary.
%
%     HPH(..., 'pos', [X Y DX DY]) sets outer position of figure. Default is
%     [0 0.05 0.7 0.8].
%
%     HPH(..., 'subplot', [M N P]) plots the data in position P of an M-by-N
%     subplot handle.
%
%     HPH(..., 'holdon') uses the current open figure instead of creating a new
%     one.
%
%     HPH(..., 'redblue') colors the points based on pH. This will only take
%     effect if the number of peaks is 1.
%
%     HPH(..., 'markers') specifies the markers to use corresponding to a peak.
%
%     WARNING: As of writing this, 'show' does not work properly. I broke it
%     accidentally.
%     HPH(..., 'show', [M N]) displays all your PKS on an M x N figure. Probably
%     the most useful option here. Title can be cell array. For example, try
%     this (with W.Npks >= 4):
%
%         >> HPH(W, x, 1:4, 'show', [2 2], 't', @(p) ['Peak number ' p])
%
%     HPH(..., 'fraction') displays the relative heights of all the peaks.
%
%     HPH(..., 'legendoff') hides any legends.
%
%     HPH(..., 'hidex') hides x-label.
%
%     HPH(..., 'hidey') hides y-label.
%
%     See also: DECOMP, GAUSS, SPEC.
function [h, fits] = hph(W, pH, pks, varargin)
    if isa(W.G, 'cell')
        W.G = W.G{end};
        W.H = W.H{end};
    end
    o = struct('t', '', ...
        'width', 1, ...
        'size', 8, ...
        'markers', '*x+o.sdv^<>ph*x+o.sdv^<>ph*x+o.sdv^<>ph*x+o.sdv^<>ph', ...
        'domain', [min([2, 1.1 * pH(:)']), max([12, 1.1 * pH(:)'])], ...
        'range', [0, ceil(max(max(W.H)) * 2) / 2], ...
        'x', '', 'y', '', ...
        'pos', [0 0.05 0.7 0.8], ...
        'poly', [], 'color', flipud(lines(size(W.H, 1))));
    o = cog(o, varargin,  {'poly', 'width', 'size', 'markers', 'subplot', ...
        'x', 'y', 't', 'domain', 'range', 'pos', 'show', 'color', 'peaknames'}, ...
        {'redblue', 'detailed', 'holdon', 'fraction', 'legendoff'});
    fits = repmat([], numel(pks), numel(o.poly));
    
    if o.holdon; h = gcf; else; h = figure; end
    if isfield(o, 'subplot'); subplot(o.subplot(1), o.subplot(2), o.subplot(3)); end
    
    if numel(pks) == 0; return; end
    
    if o.fraction
        % There's probably a more efficient way to code this
        for i = 1:numel(pH)
            W.H(pks, i) = W.H(pks, i) / sum(W.H(pks, i));
        end
        o.range = [-0.01 1.01];
    end
    
    if isfield(o, 'show')
        h = clf;
        if ~isa(o.t, 'cell'); o.t = repmat({o.t}, o.show(1), o.show(2)); end
        dx = 0; dy = 0.0; DX = (1 - 2 * dx) / (o.show(2)); DY = (1 - 2*dy) / (o.show(1));
        for i = 1:numel(pks)
            subplot('position', [(dx + mod(i - 1, o.show(2))) / (o.show(2) + 2*dx), ...
                (dy + mod(o.show(1) * o.show(2) - i, o.show(1)) / (o.show(1) + 2*dy)), ...
                DX, ...
                DY])
            set(gca, 'ColorOrder', o.color(i, :))
            hph(W, pH, pks(i), 'holdon', ...
                'width', o.width, 'size', o.size, ...
                'markers', o.markers, 'domain', o.domain, ...
                'range', o.range, 'pos', o.pos, ...
                'poly', o.poly, 't', o.t{i}, 'color', o.color);
            if ~mod(i - 1, o.show(2)); xlabel(o.x); else; set(gca,'Yticklabel',[]); end
            if ~mod(o.show(1) * o.show(2) - i, o.show(1)); ylabel(o.y); else; set(gca,'Xticklabel',[]); end
            if o.legendoff; hold on; legend('off'); hold off; end
        end
        return
    end
    
    hold on
        
    if o.redblue && numel(pks) == 1
        n = numel(W.H(pks, :));
        assert(n > 3, ['The sample size needs to be more than 3 for use of ' ...
            '''redblue'' (numel(W.H(pks, :)) = ' num2str(n) ').'])
        fsirt = find(pH == min(pH), 1, 'first');
        lsat  = find(pH == max(pH), 1, 'first');
        P = repmat(line, 1, numel(pH));
        L = repmat({''}, 1, numel(pH));
        for i = 1:numel(pH)
            P(i) = plot(pH(i), W.H(pks, i), o.markers(pks), ...
                'MarkerSize', o.size, 'Color', redblue(pH(i)));
            L{i} = ['pH ~' num2str(round(pH(i), 1))];
        end
        legend(P([fsirt lsat]), L{[fsirt lsat]})
    else
        x = linspace(min(pH), max(pH), ceil(2.7 * numel(pH)));
        for p = pks
            if ~o.detailed
                plot(pH, W.H(p, :), o.markers(p), 'DisplayName', ['Peak ' ...
                    num2str(p) ' (~' num2str(round(W.G(p, 1))) ' nm)'], ...
                    'MarkerSize', o.size, 'MarkerFaceColor', o.color(p, :), ...
                    'MarkerEdgeColor', min(1, 1.25 * o.color(p, :)), 'linewidth', o.width)
            else
                plot(pH, W.H(p, :), o.markers(p), 'DisplayName', ['Peak ' ...
                    num2str(p) ' (~' num2str(round(W.G(p, 1))) ' nm, ~' ...
                    num2str(round(W.G(p, 2))) ' nm)'], 'MarkerSize', o.size, ...
                    'MarkerFaceColor', o.color(p, :), ...
                    'MarkerEdgeColor', min(1, 1.25 * o.color(p, :)), 'linewidth', o.width)
            end
            for d = o.poly
                z = ones(1, numel(x));
                for k = 1:d
                    z = [z; z(k, :) .* x];
                end
                fits{p, d} = fliplr(polyfit(pH, W.H(p, :), d));
                y = fits{p, d} * z;
                if ~o.detailed
                    plot(x, y, 'DisplayName', ['Degree ' num2str(d)], ...
                        'LineWidth', o.width)
                else
                    t = nd(round(fits{p, d}, 2));
                    t = replace(t, 'Peaks ', ''); t = replace(t, 'Peak ', '');
                    plot(x, y, 'DisplayName', t, ...
                        'LineWidth', o.width)
                end
            end
        end
        legend('show')
    end
    
    if ~strcmp(o.x, ''); xlabel(o.x); end
    if ~strcmp(o.y, ''); ylabel(o.y); end
    
    if isa(o.t, 'function_handle')
        title(o.t(num2str(pks)))
    else
        title(o.t)
    end
    xlim(o.domain); ylim(o.range)
    if ~o.holdon; set(gcf, 'units', 'normalized', 'outerposition', o.pos); end
    if o.legendoff
        if isfield(o, 'subplot')
            for m = 1:(o.subplot(1) * o.subplot(2))
                subplot(o.subplot(1), o.subplot(2), m)
                legend('off')
            end
        else
            legend('off')
        end

    end

    function str = nd(s)
        str = '';
        if nargin == 0; return; end
        nel = numel(s);
        switch(nel)
            case 0
            case 1
                str = ['Peak ' num2str(s)];
            case 2
                str = ['Peaks ' num2str(s(1)) ' and ' num2str(s(2))];
            otherwise
                for j = 1:nel
                    if j < nel
                        str = [str ', ' num2str(s(j))];
                    else % i == nel
                        str = [str ', and ' num2str(s(j))];
                    end
                end
                str([1 2]) = ''; str = ['Peaks ' str];
        end
    end    

end

    
    
    
    
    
    
    