% gauss.m, mlandry@mit.edu for help
%
% GAUSS   Decomposes a matrix of spectrophotometric data into a superposition of
%         gaussian curves, based on analytical derivatives and multiple least-
%         squares algorithms.
%
%     W = GAUSS(M, G) takes the matrix of data M and the guess matrix G and
%     attempts to best decompose the data into a superposition of gaussian
%     curves. G is a <Npks> x 2 matrix, Npks being the assumed number of
%     underlying peaks. The first column of G represents positions and the
%     second column represents widths.
%
%     W is a structure with the following fields:
%
%               Field  Meaning
%     ---------------  --------------------------------
%                Npks  The number of peaks used in the model
%                Nwav  The number of wavelengths in M
%              domain  Vector of all wavelengths in M, the first row of M
%                Nsln  The number of measurements in M
%                   i  The number of iterations it took to reach the final state
%                 toc  The time it took to reach the final state
%                   G  Final guess matrix
%                  Gi  Initial guess matrix
%              DeltaG  Final minus initial guess matrix
%                   M  Matrix of experimental data
%                   Y  Matrix of experimental data, M with small changes
%                   A  Matrix of calculated absorbances, A = EH
%                   E  Calculated exponential terms
%                   H  Nonnegative least-squares height matrix
%                   R  Matrix of residuals, R = Y - A
%                  r2  Coefficient of determination at each iteration
%                  X2  Sum of squared residuals at each iteration
%                 DX2  Forward change in X2 at each iteration
%               alpha  Final value of shift-cutting factor, see below
%                 rfq  The reason GAUSS ceased iterating
%
%     Each of these are vectors with length equal to the number of iterations.
%
%     GAUSS(..., 'Display') prints info at the command window during and at the
%     end of iterating.
%
%     GAUSS(..., 'MaxIter', I) specifies the maximum number of iterations
%     allowed. Default is 20.
%
%     GAUSS(..., 'Tol', EPSILON) specifies the arbitrary tolerance value used in
%     assessment of W at different points along iterations. Default is 1e-4.
%
%     GAUSS(..., 'Cut', ALPHA) specifies the shift-cutting factor used. For
%     info, see the "Improved versions" section of the Gauss-Newton algorithm
%     page at Wikipedia. Default is 0.65.
%
%     GAUSS(..., 'Floor', F) specifies the lower limits the parameters in G can
%     move within. F can be <Npks> x 2 as well as 1 x 2. Default is equivalent
%     to zeros(size(G)).
%
%     GAUSS(..., 'Ceil', C) specifies the upper limits the parameters in G can
%     move within. C can be <Npks> x 2 as well as 1 x 2. Default is equivalent
%     to inf(size(G)).
%
%     GAUSS(..., 'FixX') restricts the position parameters in G from moving.
%     This automatically sets the lower and upper limits described above.
%
%     GAUSS(..., 'FixW') restricts the width parameters in G from moving. This
%     automatically sets the lower and upper limits described above.
%
%     If both the 'FixX' and 'FixW' flags are set, then W will only go through
%     one iteration, only solving for the best-fit nonnegative height matrix.
%
%     See also: UVVIS, FMINSEARCH, LSQNONNEG.
function W = gauss(M, Gi, varargin)
    assert(nargin >= 2, ...
        ['Expected at least 2 arguments (encountered ' num2str(nargin) ').'])
    global o
    o = struct(...
        'MaxIter', 20, ...
        'Tol', 1e-4, ...
        'Floor', zeros(size(Gi)), ...
        'Ceil', inf(size(Gi)), ...
        'Cut', 0.65);
    o = cog(o, varargin, ...
        {'MaxIter', 'Tol', 'Floor', 'Ceil'}, {'Display', 'FixX', 'FixW'});
    if o.FixX
        o.Floor(:, 1) = Gi(:, 1);
        o.Ceil(:, 1)  = Gi(:, 1);
    end
    if o.FixW
        o.Floor(:, 2) = Gi(:, 2);
        o.Ceil(:, 2)  = Gi(:, 2);
    end
    
    if o.FixX && o.FixW
        no_error = 'Solved for heights only';
        o.MaxIter = 1;
    else
        no_error = 'Reached desired maximum iteration';
    end
    
    global k g
    k = 4 * log(2);         % Model constant of proportionality
    g = (-1 + sqrt(5)) / 2; % Discrete geometric change in shift-cutting factor
    
    tic
    
    W.G      = Gi;
    W.Gi     = Gi;
    W.M      = M;
    W.Npks   = size(Gi, 1);
    W.Nsln   = size(M, 1) - 1;
    W.Nwav   = size(M, 2);
    W.domain = M(1, :);
    W.Y      = transpose(M(2:end, :));
    W.X2     = zeros(o.MaxIter, 1);
    W.DX2    = zeros(o.MaxIter, 1);
    W.r2     = zeros(o.MaxIter, 1);
    W.alpha  = o.Cut;
    
    W.E = supplyE(Gi);
    W.H = supplyH(W.E);
    W.A = W.E * W.H;
    W.R = W.Y - W.A;
    W.i = 1;
    
    global SStot
    SStot    = sum((mean(W.Y(:)) - W.Y(:)) .^ 2);
    W.X2(1)  = sum(W.R(:) .^ 2);
    W.DX2(1) = -Inf;
    W.r2(1)  = max(1 - W.X2(1) / SStot, 0);
    
    W.rfq = no_error;
    
    for i = 2:o.MaxIter
        update_model;
        if ~strcmp(W.rfq, no_error); break; end
    end
    
    if o.MaxIter > W.i
        W.X2((W.i + 1):end)  = [];
        W.DX2((W.i + 1):end) = [];
        W.r2((W.i + 1):end)  = [];
    end
   
    W.DeltaG = W.G - W.Gi;
    W.toc = toc;
    
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
        for sln = 1:W.Nsln
            H(:, sln) = lsqnonneg(E, W.Y(:, sln));
        end
    end

    function update_model
        DG = supplyDG;
        while true
            G = min(max(W.G + W.alpha * DG, o.Floor), o.Ceil);
            E = supplyE(G);
            H = supplyH(E);
            A = E * H; R = W.Y - A; X2 = sum(R(:) .^ 2);
            if X2 <= W.X2(W.i)
                W.E = E;
                W.H = H;
                W.A = A;
                W.R = R;
                W.i = W.i + 1;
                W.G = G;
                W.X2(W.i) = X2;
                W.DX2(W.i) = X2 - W.X2(W.i - 1);
                W.r2(W.i) = max(1 - X2 / SStot, 0);
                if -W.DX2(W.i) / X2 < W.alpha * o.Tol
                    W.rfq = 'Change in residuals became small';
                else
                    W.alpha = min(W.alpha / g, o.Cut);
                end
                return
            elseif W.alpha > o.Tol
                W.alpha = W.alpha * g;
            else
                W.rfq = 'Shift-cutting factor became small';
                return
            end
        end
    end

    function DG = supplyDG
        DG = zeros(W.Npks, 2);
        for pk = 1:W.Npks
            Z = coeff(pk);
            S = zeros(W.Npks); S(pk, pk) = 1;
            DE = (2 * k / W.G(pk, 2)) * Z * W.E * S;
            DG(pk, 1) = pinv(jacobian(DE)) * W.R(:);
            DE = Z * DE;
            DG(pk, 2) = pinv(jacobian(DE)) * W.R(:);
        end
    end

    % See math for details
    function Z = coeff(pk)
        Z = eye(W.Nwav);
        for wav = 1:W.Nwav
            Z(wav, wav) = (W.M(1, wav) - W.G(pk, 1)) / W.G(pk, 2);
        end
    end

    function J = jacobian(DE)
        J = DE * W.H + W.E / (W.E.' * W.E) * ...
            (DE.' * W.Y - (DE.' * W.E + W.E.' * DE) * W.H);
        J = J(:);
    end
end



















