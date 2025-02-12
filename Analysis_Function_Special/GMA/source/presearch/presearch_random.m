%presearch_random Pre-Search of an initial guess for Gamma PDF Model
% Analysis using random integer parameters to find the lowest MSE cost.
%
%% Syntax
%   costFnHandle = @(p) myCostFn(dataSeg, p);
%   x0 = presearch_random(costFnHandle, [50, inf]);
%
%% Description
%   Generates a list of random parameter tupels (see Output for ranges) for a 
%   Gamma PDF returns the tupel with the lowest cost, given by a cost function, 
%   which wraps the data and parameterized Gamma PDF.
%   If no PDF solution with a mode inside the could be found, returns NaN.
%
%   Formula used for PDF mode.
%   Mode = (k − 1) / r for all k ≥ 1.
%   where k is the shape and r is the rate parameter of the Gamma PDF
%   function (the shape parameter would be s = 1/r).
%
%% References
%   Kummer, K., Dummel, S., Bode, S., & Stahl, J. (2020). The gamma model 
%   analysis (GMA): Introducing a novel scoring method for the shape of
%   components of the event-related potential. J Neurosci Methods, 335, 108622.
%   https://doi.org/10.1016/j.jneumeth.2020.108622
%
%% Input
%   costFn      - [function handle] Cost function (e.g. for mean square error),
%               containing the data vector.
%   modeWin     - [numeric {integer}] first and last data point of the search 
%               window: the fitted Gamma function's mode (x, i.e. data point)
%               must be within this range to be acceptable. (default = [1, inf])
%
%   [Optional] Name-value parameters
%   imax        - [numeric {integer}] number of random parameter tripels, i.e.
%               iterations (default = 5000). Also uses the default, if 0.
%
%% Output
%   bestGuess   - [double] Gamma PDF basic parameters with the best guess 
%               (lowest MSE) in a 3-column vector:
%               1: Gamma shape parameter (k = 2..500)
%               2: Gamma rate parameter (r = 1..500)
%               3: Data scale factor (1..500)
%               Returns [NaN; NaN; NaN] if no guess with a mode inside the 
%               modeWin could be found.
%
%% See also
%   gmaFit

%% Attribution
%
%	Last author: Olaf C. Schmidtmann, last edit: 26.06.2023
%   Source: https://github.com/0xlevel/gma
%   Code adapted from the original version by Kilian Kummer.
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

function bestGuess = presearch_random(costFn, modeWin, args)

    arguments
        costFn function_handle
        modeWin(1, 2) double = [1, inf]
        args.imax(1, 1) {mustBeInteger} = 5e3
    end

    % Use default, if set to 0.
    if args.imax == 0, args.imax = 5e3; end

    % Randomize Gamma PDF parameters with shape ≥ 2 (for a defined
    % mode) and rate, yscale ≥ 1
    gParam = randi([2, 500], 1, args.imax);
    gParam = [gParam; randi([1, 500], 2, args.imax)];

    % Lowest cost, to be replaced by any lower cost, found
    lowestCost = Inf;

    for i = 1:args.imax
        mode = (gParam(1, i) - 1) / gParam(2, i);

        % Valid candidates must be within the given search area
        if mode >= modeWin(1) && mode <= modeWin(2)
            % Valid candidates must have the lowerest MSE (cost)
            cost = costFn(gParam(:, i));
            if lowestCost > cost
                lowestCost = cost;
                bestGuess = gParam(:, i);
            end
        end
    end

    % No solution found
    if isinf(lowestCost)
        bestGuess = [NaN; NaN; NaN];
    end
end