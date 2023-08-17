%nnegIntervals Get x-intervals of nonnegative regions.
%
%% Syntax
%   xIv = nnegIntervals(x);
%   [xIv, xClose] = nnegIntervals(x);
%   [xIv, xClose] = nnegIntervals(x, false);
%
%% Description
%   Returns the x-axis intervals between intercepts (including zero), i.e.
%   all returned y values within the interval(s) are nonnegative.
%
%   With default parameters, the function returns open and closed intervals. A
%   nonnegative interval is open, if it begins or ends with the first or last
%   element of y, which is not positive.
%
%   However, if all values are nonnegative and the first and the last y are 0,
%   the interval is also considered as closed.
%
%% Input
%   y           - [numeric] vector of real numbers
%   inclOpen    - [logical] true = (default) include open intervals of
%               nonnegative values with a single x-intercept;
%               false = only include closed intervals between two
%               x-intercepts
%
%% Output
%   iv          - [numerical {integer}] start and end indices (rows) for each 
%               nonnegative interval (column); if inclOpen is true, it may
%               include open intervals
%   closed      - [logical] flag for each interval (column index of iv):
%               true = closed interval, false = open interval;
%               Returns empty, if no intervals were found. Returns 0 if all
%               values are nonnegative. Returns 1, if all values are positive,
%               but 0 in the first and the last.
%
%% Examples
%   % Plot only closed nonnegative intervals
%   y1 = [repmat(repelem([1, 0, -1, 0], 3), 1, 3), 1, 1];
%   y1iv = nnegIntervals(y1, false);
%   figure; hold on;
%   plot(y1);
%   plot(y1iv, zeros(2, length(y1iv)), LineWidth = 5);
%
%   % Get the (first) largest nonnegative interval:
%   [~, maxidx] = max(diff(y1iv));
%   seg = y1iv(:, maxidx);

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

function [iv, closed] = nnegIntervals(y, inclOpen)

    arguments
        y(1, :) {mustBeNumeric}
        inclOpen(1, 1) logical = true
    end

    nY = length(y);
    y = real(y);

    % Round y to the significant decimal.
    dsig = abs(ceil(log10(eps(max(abs(y))))));
    y = round(y, dsig);

    yp = y >= 0;

    iv = [];
    closed = [];

    %% Special case, early return: all values of y are nonnegative.
    % Always returns one interval for the full data, even if it is not closed.
    % If the first and the last values of y are zero, the interval is marked as
    % closed; otherwise it is open.

    if inclOpen && all(yp)
        iv = [1; nY];
        closed = y(1) == 0 & y(nY) == 0;
        return;
    elseif all(~yp)
        return;
    end

    signChg = [0, diff(yp)];
    icpt = find(signChg);
    swing = signChg(icpt);

    % Single intercept
    if length(icpt) < 2 && ~inclOpen
        return;
    end

    % Deal with first downward or last upward x-intercepts
    isOpen = false(1, 2);
    if inclOpen
        % Store open interval(s), if they are preceded (first) or followed
        % (last) by nonnegative values, otherwise drop them.
        if swing(1) < 0
            if all(yp(1:icpt(1) - 1))
                icpt = [1, icpt];
                isOpen(1) = 1;
            else
                icpt(1) = [];
            end
        end
        if swing(end) > 0
            if all(yp(icpt(end):nY))
                icpt(end + 1) = nY + 1;
                isOpen(2) = 1;
            else
                icpt(end) = [];
            end
        end
    else
        % Remove open interval(s)
        if swing(1) < 0, icpt(1) = []; end
        if swing(end) > 0, icpt(end) = []; end
    end

    iv = reshape(icpt, 2, []);
    iv(2, :) = iv(2, :) - 1;
    niv = size(iv, 2);
    closed = ones(1, niv);
    ivrng = [1, niv];
    closed(ivrng(isOpen)) = 0;
end