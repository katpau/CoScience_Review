%lnGamma Approximate natural logarithm of the Gamma function (C. Lanczos, 1964)
%
%% Syntax
%		lgm = lnGamma(a);
%
%% Description
%   The log-Gamma approximation is based on the method by Lanczos (1964). The 
%   algorithm is computationally fast but, with a relative error of < 2e-10, 
%   less accurate that other methods.
%
%% References
%   Lanczos, C. (1964). A precision approximation of the gamma function. Journal
%   of the Society for Industrial and Applied Mathematics, Series B: Numerical
%   Analysis, 1(1), 86-96. https://doi.org/10.1137/070100
%
%% Input
%   shape   - [double] Gamma shape parameter
%
%% Output
%   f       - [double]
%

%% Attribution:
%	Last author: Olaf C. Schmidtmann, last edit: 03.07.2023>
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

function f = lnGamma(shape)
    % Persistent variables are slow in MATLAB and this is hardly an alternative:
    % sqrt2Pi = 2.5066282746310002416123552393401041626930236816406250;
    % so …
    sqrt2Pi = sqrt(2 * pi);

    NGamConstants = 6;
    GamConstants = [76.180091729406, -86.505320327112, 24.014098222230, ...
        -1.231739516140, 0.001208580030, -0.000005363820];
    A5 = 1.000000000178;

    shape = shape - 1;
    % More compact, but usually slower:
    % A5 = sum(GamConstants ./ ((1:6) + shapeZ)) + A5;
    for i = 1:NGamConstants
        A5 = A5 + (GamConstants(i) / (shape + i));
    end
    pwr = (shape + 0.5) * log(shape + 5.5);
    f = log(sqrt2Pi) + pwr - shape - 5.5 + log(A5);
end