%gridsrc Implementation of the GRNMA (Grid-restrained Nelder-Mead algorithm)
%
%% Description
%   Using the adjusted grid-restrained Nelder-Mead algorithm (Bűrmen et al.,
%   2006), this heuristic search method to ﬁnds the local minimum (a
%   stationary point) of a cost function by moving and reshaping a simplex
%   (a polytope with n + 1 vertices).
%
%   This implementation is closely modeled around the original code of Árpád
%   Bűrmen and optimized for execution speed, as well as cleaned up to
%   improve readability/maintainability.
%
%   The algorithm runs until a) the maximum number of iterations (of either
%   the whole procedure or of the cost function) is reached or b) the value
%   difference of a step are below the tolerance threshold, for the cost
%   function and the simplex point (x value).
%
%   Details on numeric tolerances
%
%       Below the tolerance thresholds the value differences of the simplex
%       values or the objective function values, the algorithm will stop.
%       Very small thresholds do not necessarily result in a more precise
%       estimation, but bare the risk of futile iterations.
%
%       MATLAB's max. double-precision is 2^-52, but the smallest relative
%       float point accuracy depends on the least significant bit of the
%       actual values (i.e., x < x + 0.5 * eps(x) would be considered
%       FALSE).
%
%% References
%   Bűrmen, Á., Puhan, J., & Tuma, T. (2006). Grid Restrained Nelder-Mead
%   Algorithm. Computational Optimization and Applications, 34(3), 359-375.
%   https://doi.org/10.1007/s10589-005-3912-z
%
%% Input
%   costFn      - [function_handle] Cost function, returning a scalar result 
%               (e.g. the mean square error) from a single input parameter 
%               vector of simplex point values.
%   x0          - [numeric] initial guess (i.e. origin point) for the search 
%               with columns for the simplex points
%   maxiter     - [numeric {integer}] maximum number of full optimization iterations
%               before the algorithm stops (default = 1000)
%   maxfniter   - [numeric {integer}] maximum number of running the objective (cost)
%               function before the algorithm stops. default = maxiter *
%               numel(x0), as it depends on the dimensions of the origin
%               point.
%   logFn       [function_handle] logging function, which accepts one to many
%               text/char parameter(s) for logging
%   verbose     [logical] only applicable with a logging function set: 
%               true = detailed log messages for each optimization step;
%               false (default) = log main status messages, only.
%               text/char parameter(s) for logging
%   xtol        [double] lower boundary for the absolute tolerance of
%               differences for each step of x in costFn(x). Values can
%               range from 2^(-52), which is the smallest spacing of double
%               floats in MATLAB (see <a href="matlab:help('eps')">eps</a>), to 1.
%               (default = 1e-15, as proposed by Bűrmen et al.)
%   ftol        [double] lower boundary of the absolute tolerance of value
%               differences for the objective function. Values can
%               range from 2^(-52), which is the smallest spacing of double
%               floats in MATLAB (see <a href="matlab:help('eps')">eps</a>), to 1. 
%               (default = 1e-15, as proposed by Bűrmen et al.)
%
%% Output
%   cost        - [double]
%   fit         - [double] optimal (min. cost) simplex, grid-restrained
%   exitFlag    - [double] 0, 1
%   niter       - [double {integer}]
%   
%% Examples
%   
%
%% See also
% eps

%% Attribution
%	Last author: Olaf C. Schmidtmann, last edit: 27.06.2023
%   Code adapted (2022) from the original version by Árpád Bűrmen from 2011
%   (source: https://fides.fe.uni-lj.si/~arpadb/software-grnm.html), GPLv2.1.
%   Source: https://github.com/0xlevel/gma
%	MATLAB version: 2023a
%
%	Copyright (c) 2023, Olaf C. Schmidtmann, University of Cologne
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

function [cost, fit, exitFlag, niter] = grnma(costFn, x0, maxiter, args)
    
    arguments
        costFn(1, 1) function_handle
        x0 double{mustBeVector}
        maxiter(1, 1) {mustBeInteger, mustBePositive} = 1000
        args.maxfniter(1, 1) {mustBeInteger, mustBePositive} = maxiter * numel(x0)
        args.logFn(1, 1) function_handle = @NOP
        args.verbose(1, 1) logical = false
        args.xtol(1, 1) {mustBeInRange(args.xtol, 2.2204e-16, 1)} = 1e-15
        args.ftol(1, 1) {mustBeInRange(args.ftol, 2.2204e-16, 1)} = 1e-15
    end

    % Validate / enable logging
    try
        logger = args.logFn;
        logger("Logger initialized" + newline);
        logEnabled = true;
    catch
        warning("Logging function handle invalid. Must be a function " + ...
            "which accepts at least one char/string input.");
        logEnabled = false;
        logger = @NOP;
        vlog = @NOP;
    end

    if logEnabled
        if args.verbose, vlog = logger;
        else, vlog = @NOP; end
    end

    %% Mainsettings of the Gridfunction

    % Check tolerances
    xtol = args.xtol;
    ftol = args.ftol;

    if xtol < eps || ftol < eps
        logger("The step precision tolerances (xtol = %.2e, ftol = %.2e)\n" + ...
            "may be set too low (tol < 2^(-52)), which will most likely " + ...
            "result in futile iterations.\n", xtol, ftol);
    end

    % NM scaling coefficients:
    % reflection: rho > 0
    % expansion: chi > 1, chi > rho (Nelder-Mead default is 2.0)
    % contraction: 0 < psi < 1
    % inner contraction: -1 < psiinv < 0
    % shrinkage: 0 < sigma < 1
    rho = 1.0;
    chi = 1.2;
    psi = 0.5;
    psiinv = -0.5;
    sigma = 0.25;

    % Bad shape factor
    shapefact = 1e-6;

    % Grid settings:
    % size factor, difference and tolerances
    normfact = 2.0;
    normfactmax = 2^52;
    gridreltol = 2^-52;
    gridabstol = 1e-100;

    % Origin point count
    nx = numel(x0);
    sqnx = sqrt(nx);
    onesnx = ones(1, nx);
    one2nx = 1:nx;

    % Simplex point count / dimensions (columns)
    ns = nx + 1;
    onesns = ones(1, ns);
    one2ns = 1:ns;

    %% Initial simplex
    % Setup initial simplex side vector lengths aligned around the origin with
    % the cartesian basis. As suggested by L.Pfeffer (Stanford):
    % - use 5 percent deltas for non-zero terms
    % - use an even smaller delta for zero elements of x
    d = abs(x0 * 0.05 + (x0 == 0) * 0.00025);

    % Construct simplex around the initial guess
    smplx = [x0, x0 * onesnx + diag(d)];

    % Initial grid scaling
    gridsize = onesnx.' * min(d) / 10;
    gridsize = gridsnap(gridsize, x0, gridreltol, gridabstol);
    gridfc = sqnx * norm(gridsize) / 2;

    % Evaluate initial simplex
    cost = onesns;
    for i = one2ns
        [cost(:, i)] = costFn(smplx(:, i));
    end

    logger("Start GRNMA optimization");

    %% Main loop
    % Initialize cost function evaluation and algorithm counter
    fniter = ns;
    niter = 1;

    while fniter < args.maxfniter

        [smplx, cost] = sortSimplex(smplx, cost);

        % Get centroid
        xc = mean(smplx(:, one2nx), 2);

        % Worst point
        xw = smplx(:, end);
        fw = cost(end);

        % Second worst point
        fsw = cost(end - 1);

        % Best point
        fb = cost(1);

        % Set failure flag to 0
        failed = 0;

        % Try reflection
        xr = xc - rho * (xw - xc);
        xr = ptrx(xr, x0, gridsize);
        fr = costFn(xr(:, 1));
        fniter = fniter + 1;

        if fr < fsw
            if fb <= fr
                cost(end) = fr;
                smplx(:, end) = xr;
            else
                % Try expansion
                xe = xc - chi * (xw - xc);
                xe = ptrx(xe, x0, gridsize);
                fe = costFn(xe(:, 1));
                fniter = fniter + 1;

                if fe < fr
                    cost(end) = fe;
                    smplx(:, end) = xe;
                else
                    cost(end) = fr;
                    smplx(:, end) = xr;
                end
            end
        else
            if fr >= fw
                % Try inner contraction
                xci = xc - psiinv * (xw - xc);
                xci = ptrx(xci, x0, gridsize);
                fci = costFn(xci(:, 1));
                fniter = fniter + 1;

                if fci < fsw
                    cost(end) = fci;
                    smplx(:, end) = xci;
                else
                    failed = 1;
                end
            else
                % Try outer contraction
                xco = xc - psi * (xw - xc);
                xco = ptrx(xco, x0, gridsize);
                fco = costFn(xco(:, 1));
                fniter = fniter + 1;

                if fco < fsw
                    cost(end) = fco;
                    smplx(:, end) = xco;
                else
                    failed = 1;
                end
            end
        end

        % Dump NM step info
        if logEnabled
            if failed == 1, txt = 'FAIL';
            else, txt = 'OK  '; end
            vlog('%s:NM %s n=%d. mse=%.10g', 'Mr.Meeseeks', ...
                txt, fniter, min(cost));
        end

        %% Probe loop
        if failed == 1
            % NM iteration failed

            % Not reshaped in this probe cycle
            reshaped = 0;

            % Pseudo-expand, assume it failed
            pefailed = 1;

            [smplx, cost] = sortSimplex(smplx, cost);

            % Simplex sides' length
            v = smplx(:, 2:end) - smplx(:, 1) * onesnx;
            vnorm = sqrt(sum(v.^2));
            % Sorting all columns is necessary
            v = sortrows([vnorm; v]')';

            % Check shape by means of QR decomp.
            % QR is (according to the algorithm) needed only if NM iteration fails
            [Q, R] = qr(v(2:end, :));
            RD = diag(R);
            rdmin = min(abs(RD));
            detv = rdmin / (shapefact * sqnx * norm(gridsize) / 2);

            % If NM iteration failed and the shape is bad, reshape in the probe loop
            badshape = (detv < 1) && (failed == 1);

            % Best point
            xb = smplx(:, 1);
            fb = cost(1);

            if badshape
                % Do a reshape, if needed
                vlog('Reshape before PE');
                baseresh = clipbasis(Q, RD, normfact * gridfc, normfactmax * gridfc);
                % Reshaped base vectors and the pseudo-expand vector
                dresh = [baseresh, -sum(baseresh, 2) / nx * (chi - rho) / rho];
                % Get and evaluate the frame points
                xnew = xb * onesns + dresh;
                xnew = ptrx(xnew, x0, gridsize);
                fnew = onesnx;
                for i = one2nx
                    [fnew(:, i)] = costFn(xnew(:, i));
                end

                % xnew and fnew contain the pseudo-expand point and all points
                % except the origin (original best)
                fniter = fniter + nx;
                % Signal that the simplex was reshaped
                reshaped = 1;
            else
                % No reshape needed, just evaluate pseudo-expand
                xcw = sum(smplx(:, 2:end), 2) / nx;
                xpe = xb + (chi - rho) / rho * (xb - xcw);
                xpe = ptrx(xpe, x0, gridsize);
                fpe = costFn(xpe(:, 1));

                fniter = fniter + 1;
                % xnew and fnew contain the pseudo-expand point and all points
                % except the origin (original best)
                xnew = [smplx(:, 2:end), xpe];
                fnew = [cost(:, 2:end), fpe];
            end

            % Reshape leaves the best point (xb, fb) unchanged
            if min(fnew) < fb
                % Pseudo-expand and reshape OK, best point changed
                pefailed = 0;
                vlog('%s:PE OK   n=%d. mse=%.10g', 'Mr.Meeseeks', ...
                    fniter, min(fnew));
            else
                % Pseudo-expand and reshape failed to produce a better point
                vlog('%s:PE FAIL n=%d. mse=%.10g', 'Mr.Meeseeks', ...
                    fniter, min(fnew));
            end

            %% Inner probe loop
            if pefailed == 1
                % Pseudo-expand failed

                ncredit = 0;
                % If the base is reshaped, one base is already evaluated,
                % otherwise no bases are evaluated yet
                nprobe = reshaped;

                while min(fnew) >= fb
                    % If pseudo-expand didn't reshape the base, consider reshaping
                    if ~reshaped
                        vlog('Reshape');
                        dresh = clipbasis(Q, RD, normfact * gridfc, normfactmax * gridfc);
                        % Remember that the base is reshaped
                        reshaped = 1;
                    else
                        % Remove the pseudo-expand point from the probe loop
                        dresh = dresh(:, one2nx);
                        % Shrink only after 2 bases have been evaluated and the
                        % number of base evaluations is even
                        if (nprobe >= 2) && (mod(nprobe, 2) == 0)
                            % Shrink only if both dresh and -dresh were examined
                            % Shrink and mirror frame
                            dresh = -dresh * sigma;
                            % Set the number of allowed grid refinements
                            ncredit = 1;
                        else
                            % Only mirror frame
                            dresh = -dresh;
                        end % if shrink
                    end

                    % Check grid
                    if ncredit > 0
                        % We are allowed to change the grid (2 probe steps
                        % failed, orthogonal maximal positive base examined)
                        [lmin, imin] = min(sqrt(sum(dresh.^1, 1)));
                        vmin = dresh(:, imin);

                        % Do we need a finer grid
                        if (lmin < normfact * gridfc)
                            % Shortest side: division in any coordinate direction
                            % should be less than lmin/n
                            gshort = max(abs(vmin) / (250 * normfact * nx), ...
                                lmin / (250 * normfact * nx^1.5));

                            % Longest side should have at least 500 div per direction
                            % Choose minimal grid step for every direction
                            gridsizenew = min([gshort, gridsize], [], 2);
                            x0 = xb;

                            % Limit the grid to machine precision and embed it in previous grid
                            [gridsize, clipped] = gridsnap(gridsizenew, xb, gridreltol, gridabstol);
                            gridfc = sqnx * norm(gridsize) / 2;

                            if logEnabled
                                if sum(clipped) > 0, txt = 'CLIP';
                                else, txt = '    '; end
                                vlog('%s:PR %s n=%d. mse=%.10g', 'Mr.Meeseeks', ...
                                    txt, fniter, min(cost));
                            end
                        end
                    end

                    % Evaluate probe points
                    xnew = xb * onesnx + dresh;
                    xnew = ptrx(xnew, x0, gridsize);

                    fnew = onesnx;
                    for i = one2nx
                        [fnew(:, i)] = costFn(xnew(:, i));
                    end
                    fniter = fniter + nx;

                    if logEnabled
                        if min(fnew) < fb, txt = 'OK  ';
                        else, txt = 'FAIL';
                        end
                        vlog('%s:PR %s n=%d. mse=%.10g', 'Mr.Meeseeks', ...
                            txt, fniter, min([fb, fnew]));
                    end

                    % Increase the iteration counter
                    nprobe = nprobe + 1;

                    % Check tolerances: stop if below min tolerance
                    if isTolf([fb, fnew], ftol) && isTolx([xb, xnew], xtol)
                        break;
                    end
                end
            end

            %% Form a new simplex
            % xnew is either the reshaped simplex + pseudo-expand point or the
            % original simplex + pseudo-expand point m=n+1 xnew and fnew contain
            % the pseudo-expand point and all points except the origin (original
            % best) m-th point is pseudo-expand
            [~, imin] = min(fnew);
            if imin < ns
                % Pseudo-expand is not the best
                smplx = [xb, xnew(:, one2nx)];
                cost = [fb, fnew(one2nx)];

            else
                % Pseudo-expand is the best
                smplx = xnew;
                cost = fnew;
            end
        end

        % Check tolerances
        if isTolf(cost, ftol) && isTolx(smplx, xtol)
            vlog('Exit. Values below precision tolerances.');
            break;
        end

        niter = niter + 1;
    end

    % Best Gamma PDF
    [cost, imin] = min(cost);
    fit = smplx(:, imin);
    fit = ptrx(fit, x0, gridsize);

    %% Evaluate termination criteria
    if fniter >= args.maxfniter
        exitFlag = 0;
        logger("Optimization terminated. Maximum iterations reached.");
    else
        exitFlag = 1;
        logger("Optimization successful. Optimization criteria satisfied.");
    end
    logger("Iterations: %i/%i cost function, %i/%i algorithm.", ...
        fniter, args.maxfniter, niter, maxiter);

end

function [sSmplx, sCost] = sortSimplex(smplx, cost)
    %SORTSIMPLEX Sort simplex solutions by cost
    [sCost, idx] = sort(cost);
    sSmplx = smplx(:, idx);
end

function x1 = ptrx(x, x0, d)
    %PTRX Insert grid point
    ncolones = ones(1, size(x, 2));
    x0 = x0 * ncolones;
    d = d * ncolones;
    n = round((x - x0) ./ d);
    x1 = x0 + n .* d;
end

function [g, clipped] = gridsnap(gridsize, origin, reltol, abstol)
    %GRIDSNAP Snap to grid
    gmin = max(abs(origin) * reltol, abstol);
    clipped = gridsize < gmin;
    g = max(gmin, gridsize);
end

function [Vout] = clipbasis(Q, D, RminGrid, RmaxGrid)
    %CLIPBASIS Clip base
    SD = sign(D);
    SD = SD + (SD == 0);
    D = max(RminGrid, min(abs(D), RmaxGrid));
    Vout = Q * diag(SD .* D);
end

function exceeded = isTolf(f, ftol)
    %ISTOLF Check if f tolerance is exceeded (true)
    % MATLAB fminsearch-like criterium: a bit slower, but prevents excessively
    % low tolerances
    % The best point is first in f
    exceeded = max(abs(f(1) - f(2:end))) <= max(ftol, 10 * eps(f(1)));
end

function exceeded = isTolx(s, xtol)
    %ISTOLF Check if x tolerance is exceeded (true)
    % MATLAB fminsearch-like criterium: a bit slower, but prevents excessively
    % low tolerances
    % The best point is first in the simplex
    exceeded = max(abs(s(:, 2:end) - s(:, 1)), [], 'all') <= max(xtol, 10 * eps(max(s(:, 1))));
end

function NOP(varargin)
    %NOP Do nothing
end
