
% monte.m
%
% MONTE   Suggest a guess matrix G using a Monte Carlo method
%
%     Usage: G = MONTE(M, NPKS). G is in ascending order by peak position.
%
%     Specify the allowed range of positions in nm by using 'X'. The default is
%     [220, 840]. The most extreme wavelengths I've encountered are ~230 and
%     ~750.
%
%     Specify the allowed range of bandwidths in nm by using 'W'. The default is
%     [15, 500]. The most extreme widths I've encountered are 19.6 and ~300.
%
%     Specifiy the desired number of iterations per peak using 'N'. An
%     "iteration" is defined so that the sum of squared residuals always
%     decreases at each iteration. The default is 5.
%
%     Due to the above definition, sometimes a peak cannot be improved. Specify
%     the maximum number of improvement attempts per iteration using 'TRIALS'.
%     The default is also 20.
%
%     MONTE currently selects its random positions and widths from a discrete
%     uniform distribution (specified by your fields 'X' and 'W' respectively).
%     In the future I would like to improve this algorithm by changing the
%     distribution to one close to the real-life distribution of UV-Vis peak
%     positions and widths.
function G = monte(Npks, M, varargin)
    assert(nargin >= 2, ['Expected at least 2 arguments, encountered ' ...
        num2str(nargin) '.'])
    o = struct('n', 5, 'trials', 20, 'x', [220, 840], 'w', [15, 500]);
    o = cog(o, varargin, {'n', 'tirals', 'x', 'w'}, {'debug'});
    T = tic;
    G = [o.x(1), o.w(1)] + zeros(Npks, 2);
    for p = 1:Npks; G(p, :) = [randi(o.x), randi(o.w)]; end
    W = gauss(M, G, 'maxiter', 1);
    for p = 1:Npks
        if o.debug; fprintf('\n[///////////// p = %d /////////////]\n', p); end
        i = 1;
        t = 1;
        while i <= o.n && t <= o.trials
            if o.debug; fprintf('i = %d: ', i); end
            g = [G(1:(p - 1), :); [randi(o.x), randi(o.w)]; G((p + 1):end, :)];
            w = gauss(M, g, 'maxiter', 1);
            if w.X2 < W.X2
                G = g;
                W = w;
                i = i + 1;
                if o.debug; fprintf('Residuals decreased!\n'); end
            elseif o.debug
                t = t + 1;
                fprintf('Residuals did not decrease ...\n');
            end
        end
    end
    [~, I] = sort(G, 1);
    G = G(I(:, 1), :);
    if o.debug
        fprintf('\nFinal r^2 = %g\n', W.r2);
        toc(T)
        fprintf('\n')
    end
end



