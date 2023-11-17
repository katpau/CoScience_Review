%distseeks Euclidean distance between the Gamma PDF and the data points
% divided by the Euclidean distance of the data points to their mean.
%
%% Syntax
%   dataVec = rand(100, 1);
%   pdfParams = [10, 0.25, 1];
%   cost = distseeks(dataVec, pdfParams);
%
%% Description
%   Uses the euclidean distances between a Gamma PDF, created by the values in 
%   shrasf (shape, rate and scaling factor), and the data.
%   This method is slower, but potentially more robust against outliers than the
%   mean-squared error (MSE).
%
%   The Gamma PDF uses a custom gammaPdf instead of the MATLAB function gampdf. 
%   The results differ slightly, but are equal, when rounded to ~10 decimal
%   places.
%   The MSE is also not calculated by MATLAB's immse to improve performance.
%
%   This function is optimized for high performance as a optimization cost
%   function and not for fail safety. Thus the arguments will NOT be checked and
%   should be validated before entering the function.
%   Calculate the Gamma PDF using a custom gammaPdf instead of the MATLAB
%   function gampdf. The results differ slightly, but are equal, when
%   rounded to ~10 decimal places.
%
%% Inputs
%   data        - [numerical] vector of original data. Validity will not be 
%               checked, but it must not be empty.
%   shrasc      - [double] 3-column-vector of Gamma PDF parameters: 
%               shape, rate and a scaling factor (multiplier). Validity will not
%               be checked, but all values must be > 0.
%
%% Outputs
%   cost        - [double] Euclidean distance between the Gamma PDF and the data 
%               points divided by the Euclidean distance of the data points to 
%               their mean.
%
%% See also
%   gammaPdf

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

function e = distseeks(data, shrasf)
    pdfY = gammaPdf(1:length(data), shrasf(1), shrasf(2));
    pdfY(isnan(pdfY) | isinf(pdfY)) = 0;
    scY = pdfY * shrasf(3);
    e = norm(data(:) - scY(:), 2) / norm(data - mean(data), 2);
end