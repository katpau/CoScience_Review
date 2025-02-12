%gammaEstCf Gamma PDF closed-form estimation based on the
% generalized Gamma distribution and log-likelihood functions.
%
%% Syntax
%   [estShape, estRate] = gammaEstCf(data)
%
%% Description
%   An efficient and less biased alternative to maximum likelihood or moment
%   methods, which also converges on small α (shape) parameters.
%   The algorithm if based on (eq. 8) and the bias correction proposed by
%   Zhi-Sheng Ye & Nan Chen (2017), which achieved superior performance for
%   small sample sizes (n = 20). Samples below 20 data points are not
%   recommended.
%
%   The returned estimated parameters represent a pure Gamma PDF without any
%   y-axis shift, nor any scaling of the sampled data. Thus, in most
%   cases, to achieve an accurate valuation of the error, the estimated PDF
%   must be shifted and scaled to fit the approx. baseline and mode (the
%   maximum amplitude) of a potentially noisy data sample.
%
%   The precision value determines the sample size drawn from the data:
%   Higher values increase the precision by using larger sample sizes.
%   Example of an idealized PDF with 100 non-zero values:
%       1: n=500, rmse = 1.2e-4
%       2: n=5000,  rmse = 1.6e-5
%       3: n=50000, rmse = 2.9e-6
%       4: n=500000, rmse = 2.9e-7
%   Increasing the precision above 5 yields only very small gains in
%   accuracy at a much greater cost of memory and speed.
%
%% References
%   Ye, Z.-S., & Chen, N. (2017). Closed-Form Estimators for the Gamma
%   Distribution Derived From Likelihood Equations. The American
%   Statistician, 71(2), 177-181.
%   https://doi.org/10.1080/00031305.2016.1209129
%
%% Input
%   y         - [double] vector of data points
%   corrected - [logical| true (default) returns bias corrected values
%               [(n-1)/(n+2)], which improves the estimation performance.
%               Especially useful for small sample sizes and for lower
%               precision (< 5).
%   precision - [numeric] Precision modelled as sample size drawn from the
%               data as a multiplier of the number of non-zero members in y,
%               relative to its range: sample_size = 10^precision /
%               range(y). Minimum: 1, a value of 2 (default) results in a
%               fairly good estimate, values >5 yield only very slight
%               gains.
%
%% Output
%   The returned estimated Gamma PDF parameters as
%   shape     - Gamma PDF shape parameter
%   rate      - Gamma PDF rate parameter (inverse of scale: rate = 1/scale)
%
%% Examples
%   % Create a Gamma PDF with shape 23 and scale 9 (rate = 0.1111)
%   ggpdf = gampdf(x, 23, 9);
%   [estShape, estRate] = gammaEstCf(ggpdf)
%   estgg = gampdf(1:length(x), estShape, 1 / estRate) .* yscale;
%   figure; plot(estgg, LineWidth = 2); hold on;
%   plot(ggpdf, LineStyle=":", LineWidth = 2);
%
%   % Compare with a higher precision (again with enabled bias correction):
%   [estShape_hp, estRate_hp] = gammaEstCf(ggpdf, 1, 4)

%% Attribution
%	Last author: Olaf C. Schmidtmann, last edit: 13.11.2023
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

function [shape, rate] = gammaEstCf(y, corrected, precision)
    if nargin < 3, precision = 2;
    else, precision = max(1, precision); end
    if nargin < 2, corrected = true; end

    yr = vrange(y);
    if ~yr
        % Early exit for flat data
        shape = nan;
        rate = nan;
        return;
    else
        % Sample non zero values from density distribution
        ysp = y * power(10, precision) / yr;
        s = repelem(1:length(y), round(ysp - min(ysp)));
    end

    % Compute numeric estimators (at scale 1)
    n = length(s);
    ss = sum(s);
    lgs = log(s);
    nls = n * sum(s .* lgs) - sum(lgs) .* ss;

    % Bias correction
    if corrected, biasf = (n - 1) / (n + 2);
    else, biasf = 1; end

    shape = biasf * ((n * ss) ./ nls);
    rate = biasf * ((n^2) ./ nls);
end
