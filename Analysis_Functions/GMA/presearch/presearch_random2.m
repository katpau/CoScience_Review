%presearch_random2 Modified pre-Search of an initial guess for Gamma PDF
%Model Analysis (GMA) using random parameters to find the lowest MSE cost.
%
%
%% Description
%   EXPERIMENTAL! Do not use for production.
%   Should deliver better results at less iterations of the main search than
%   presearch_random for shorter data segments.
%   For the complete help, see <a href="matlab:help('presearch_random')">presearch_random</a>.
%
%   Modified random parameters:
%   - only calculates the cost, when the mode is within the range of the
%     data points
%   - 100 random value ranges per parameter:
%       shape:  2 .. 101
%       rate:   0.01 .. 10 (sampled at log normal probability)
%       yscale: 1..500
%
%% Syntax
%   costFnHandle = @(p) myCostFn(dataSeg, p);
%   x0 = presearch_random2(costFnHandle, [50, inf], imax = 1000);
%
%% Input
%   costFn      - function handle; Cost function (e.g. for mean square error),
%               containing the data
%   modeWin     - [numeric {integer}] first and last data point of the search 
%               window: the fitted Gamma function's mode (x, i.e. data point)
%               must be within this range to be acceptable. (default = [1, inf])
%
%   [Optional] Name-value parameters
%   imax        - [numeric {integer}] number of random parameter tripels, i.e.
%               iterations (default = 500). Also uses the default, if 0.
%
%% Output
%   bestGuess   - [double] Gamma PDF basic parameters with the best guess 
%               (lowest MSE) in a 3-column vector:
%               1: Gamma shape parameter (k = 2..101)
%               2: Gamma rate parameter (r = 0.01..10), weighted
%               3: Data scale factor (1..500)
%
%% See also
%   presearch_random, gmaFit

%% Attribution
%	Last author: Olaf C. Schmidtmann, last edit: 26.06.2023
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

function bestGuess = presearch_random2(costFn, modeWin, args)

    arguments
        costFn function_handle
        modeWin(1, 2) double = [1, inf]
        args.imax(1, 1) {mustBeInteger} = 500
    end

    % Use default, if set to 0.
    if args.imax == 0, args.imax = 5e3; end

    % Sample rate parameters, emphazising values around 1, by using a log normal
    % PDF (the parameters are an educated guess)
    mu = 1;
    sigma = 0.9;
    x = 0.01:0.01:10;
    y = lognpdf(x, mu, sigma);
    rsample = datasample(x, args.imax, Weights = y);

    gParam = [ ...
        randi([2, 101], 1, args.imax); ...
        rsample; ...
        datasample(1:500, args.imax)];

    % Lowest cost, to be replaced by any lower cost, found
    lowestCost = Inf;

    for i = 1:args.imax
        % Mode = (k − 1) / r for all k ≥ 1.
        mode = (gParam(1, i) - 1) / gParam(2, i);

        % Valid candidates must be within the given search area
        if mode >= modeWin(1) && mode <= modeWin(2)
            % Valid candidates must have the lowerest MSE (cost)
            cost = costFn(gParam(:, i));
            if lowestCost > cost
                lowestCost = cost;
                bestGuess = gParam(:, i);
                % fprintf('Lowest Cost Value - %g\n', lowestCost);
            end
        end
    end

    % No solution found
    if isinf(lowestCost)
        bestGuess = [NaN; NaN; NaN];
    end
end