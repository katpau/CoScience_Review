% presearch_closeform Gamma PDF fitting using closed-form estimators
%
%% Syntax
%   pEst = presearch_closeform(data);
%   pEst = presearch_closeform(data, 4);
%   pEst = presearch_closeform(data, 4, [50, 100]);
%   pEst = presearch_closeform(data, sgolayWin=0);
%
%% Description
%   Finds Gamma PDF parameters for a nonnegative interval (y ≥ 0), using
%   closed-form estimation with a finite number of standard operations (using
%   Ye and Chen's method, 2017, as <a href="matlab:help('gammaEstCf')">gammaEstCf</a>).
%   As a minimum, the data must contain at least three positive values, whereby
%   20 values are considered to achieve fairly good estimates.
%
%   The scaling will be estimated from the relation of the ranges of three data
%   points: the first, the last and at the PDF mode. To reduce outliers caused
%   by noise, the data will be smoothed using a Savitzky-Golay filter with a
%   window size of 10 (default).
%
%% References
%   Ye, Z.-S., & Chen, N. (2017). Closed-Form Estimators for the Gamma
%   Distribution Derived From Likelihood Equations. The American Statistician,
%   71(2), 177-181. https://doi.org/10.1080/00031305.2016.1209129
%
%% Input
%   data        - [numeric] Vector of containing at least 3 nonnegative data points
%               (preferably ≥ 20).
%   precision   - [numeric] Determines sample size of the close-form estimation
%               (gammaEstCf). Minimum: 1; 2 (default) results in a fairly
%               good estimate, values of 3-4 are stil reasonable, whereas
%               values equal or above 5 have a diminishing increase of the
%               estimate precision, at an exponentially increased speed and
%               memory cost.
%   modeWin     - [numeric {integer}] Vector with two indices (integer) for the 
%               start and the end of the mode window. The mode of the estimated
%               PDF must be greater or equal than the start and less or equal
%               the end value. Default: first and last index of data.
%
%   [Optional] Name-value parameters
%   sgolayWin   - [numeric {integer}] Window size for the Savitzky-Golay filter 
%               to smooth the data before estimating the scaling. Default = 10. 
%               Use 0 to disable the filter.
%               
%% Output
%   estPdf      - [double] Estimated Gamma PDF parameters in a 3-column vector:
%               1: Gamma shape parameter
%               2: Gamma rate parameter
%               3: Data scaling factor
%               Or [NaN; NaN; NaN] if the estimated PDF mode is outside the
%               modeWin.
%
%% Examples
%   testSignal = cos(-0.5 * pi:0.05:0.5 * pi);
%   testSignal = testSignal .* abs(randn(1, length(testSignal)));
%   pEst = presearch_closeform(testSignal, 3, sgolayWin=5);
%   x = 1:length(testSignal);
%   estgg = gampdf(x, pEst(1), 1/pEst(2));
%   estgg = estgg * pEst(3);
%   figure; plot(x, testSignal, x, estgg, LineStyle=":", LineWidth=2);
%
%% See also
%   gammaEstCf, smoothdata

%% Attribution
%	Last author: Olaf C. Schmidtmann, last edit: 14.11.2023
%   Code adapted from the original version by André Mattes and Kilian Kummer.
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

function estGuess = presearch_closeform(data, precision, modeWin, args)

    arguments
        data(1, :) double
        precision(1, 1) double = 2
        modeWin(1, 2) double = [1, numel(data)]
        args.sgolayWin(1, 1) double = 10;
    end

    valPoints = sum(data > 0);
    if valPoints < 3
        fprintf("[presearch_closeform] Invalid sample. Requires at least " + ...
            "three data points (preferably more than 20) above zero.\n");
        estGuess = [NaN; NaN; NaN];
        return;
    end

    modeWin = fix(modeWin);
    modeWin = [max(1, modeWin(1)), min(modeWin(2), numel(data))];
    if modeWin(1) > modeWin(2)
        warning("Invalid modeWin: value at index 1 is larger than value " + ...
            "at index 2. Using default.");
        modeWin = [1, numel(data)];
    end

    [shape, rate] = gammaEstCf(data, 1, precision);
    yscale = 1;

    if shape > 1 && rate > 0
        % Estimated mode
        estMode = (shape - 1) / rate;

        % EARLY EXIT, if mode is outside the mode window
        if estMode < modeWin(1) || estMode > modeWin(2)
            estGuess = [NaN; NaN; NaN];
            return;
        end

        % Estimate scaling
        gy = gammaPdf([1, estMode, length(data)], shape, rate);
        smData = data;
        if args.sgolayWin
            args.sgolayWin = min(round(args.sgolayWin), range(modeWin) + 1);
            try
                smData = smoothdata(data, "sgolay", args.sgolayWin);
            catch
                warning("Smoothing the data failed. Using unchanged data.");
            end
        end
        yscale = round(vrange(smData) / vrange(gy), 4);
    end

    estGuess = [shape; rate; yscale];
end