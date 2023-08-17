%gammaPdf Approximate Gamma probability density function
%
%% Syntax
%   y = gammaPdf(1:100, 10, 0.25);
%
%% Description
%   Returns an approximate Gamma distribution with the shape parameter, and the
%   rate parameter evaluated at the values in x.
%
%   In contrast to MATLAB's <a href="matlab:help('gampdf')">gampdf</a>, which uses the scale parameter, this method
%   uses the rate parameter (scale = 1/rate). The results of the methods are
%   the same, only if rounded to ~10 decimal places due to the relative error of
%   lnGamma, the log Gamma approximation (Lanczos, 1964). On the upside, this
%   approximation is much more efficient than the MATLAB implementation.
%
%   This function is optimized for high performance and not for fail safety!
%   Thus the arguments will NOT be checked and should be validated before
%   entering the function.
%   The PDF parameters, shape and rate, must be positive!
%
%% References
%   Lanczos, C. (1964). A precision approximation of the gamma function. Journal
%   of the Society for Industrial and Applied Mathematics, Series B: Numerical
%   Analysis, 1(1), 86-96. https://doi.org/10.1137/070100
%
%% Inputs
%   x       - [double] Vector of x-values
%   shape   - [double] Scalar shape parameter (α) for the Gamma PDF function,
%           with α > 0 (not validated).
%   rate    - [double] Scalar rate parameter (β) for the Gamma PDF function, with
%           β > 0  (not validated). 
%           Use rate = 1/scale for the shape-scale format as used in MATLAB's
%           gampdf.
%
%% Outputs
%   y       - [double] The Gamma PDF values for x with a relative error < 2e-10.
%
%% Examples
%   ggpdf = gammaPdf(1:1000, 20, 1/10);
%   % Using MATLAB, but MUCH slower:
%   ggpdf_matlab = gampdf(1:1000, 20, 10);
%   % They are not exactly equal!
%   all(ggpdf == ggpdf_matlab)
%   % The max. abs. difference is quite small…
%   deltagg = abs(ggpdf - ggpdf_matlab);
%   max(deltagg)
%   % and they are equal, if rounded to 10 decimals:
%   all(round(ggpdf,10) == round(ggpdf_matlab, 10))
%
%% See also
%   lnGamma, gamPdf

%% Attribution
%
%	Last author: Olaf C. Schmidtmann, last edit: 26.06.2023
%   Source: https://github.com/0xlevel/gma
%   Code adapted from the original version of Kilian Kummer.
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

function y = gammaPdf(x, shape, rate)
    lnRate = repmat(log(rate), 1, numel(x));
    lnT = log(x);
    y = exp((lnRate * shape + lnT .* (shape - 1)) -rate .* x - lnGamma(shape));
end