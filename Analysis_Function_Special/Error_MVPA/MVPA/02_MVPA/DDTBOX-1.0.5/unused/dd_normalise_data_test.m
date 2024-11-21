function [output_data] = dd_normalise_data_test(input_data, feature_min_vals, feature_max_vals)
%
% Normalises values within the 0-1 range for each feature. Data are
% normalised for each feature separately, and are normalised across
% instances/epochs. Normalisation helps run SVMs much faster, and SVM 
% classification using normalised values can also be more accurate. 
% See the documentation for LIBSVM for further information.
%
%
% Inputs:
%
%   input_data  This is a feature by epoch matrix used for training/test
%               the classifier or regression model. 
%
%  feature_min_vals     Minimum values for each feature, calculated from
%                       the dataset used for training the classifier.
%
%  feature_max_vals     Maximum values for each feature, calculated from
%                       the dataset used for training the classifier.
%
%		
% Outputs:
%
%  output_data  Normalised data produced by the function, for subsequent
%               classification or regression with SVMs
%
%
%
% Usage: [output_data] = dd_normalise_data(input_data, feature_min_vals, feature_max_vals)
%
%
% Copyright (c) 2013-2020: DDTBOX has been developed by Stefan Bode 
% and Daniel Feuerriegel with contributions from Daniel Bennett and 
% Phillip M. Alday. 
%
% This file is part of DDTBOX and has been written by Daniel Feuerriegel
%
% DDTBOX is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.



%% Normalise the Input Data

% Normalise the data to be between 0 and 1 (results in faster SVMs with
% better performance)

% Normalise within features (across instances), and not across
% instances/trials! We will also need to save the values calculated
% during normalisation, so that they can be used to normalise the
% test set data in exactly the same way.

% Subtract the minimum values from the data for each feature
% Here, bsxfun tends to be faster than repmat or a loop over features
norm_input_data = bsxfun(@minus, ...
    input_data, ...
    feature_min_vals);    

% Divide by the maximum values for each feature
norm_input_data = bsxfun(@rdivide, ...
    norm_input_data, ...
    feature_max_vals);



%% Prepare Outputs

% Allocate normalised data to output_data matrix
output_data = norm_input_data;


