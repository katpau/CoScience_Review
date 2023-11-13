%nnegIntervals Get x-intervals of nonnegative regions.
%
%% Syntax
%   xIv = nnegIntervals(x);
%   [xIv, xClose] = nnegIntervals(x);
%   [xIv, xClose] = nnegIntervals(x, false);
%
%% Description
%   Returns the x-axis intervals between intercepts (including zero values),
%   i.e., all returned y values within the interval(s) are nonnegative.
%
%   With default parameters, the function returns open and closed intervals.
%   Closed intervals are nonnegative values of y, enclosed by negative values.
%   As a special case, a vector of only nonnegative values, will be searched for
%   positive intervals, enclosed by zero values, if srcPositive is set to true.
%   A vector of identical nonnegative values will always be treated as a single
%   open interval.
%   All y values will be rounded to their significant decimal before processing
%   to avoid future rounding errors.
%
%% Input
%   y           - [numeric] vector of real numbers
%   inclOpen    - [logical] true = (default) include open intervals of
%               nonnegative values with none or a single x-intercept;
%               false = only include closed intervals between two
%               x-intercepts (see srcPositive for pure nonnegative data).
%   srcPositive - [logical] true = (default) Allows to search for positive
%               intervals, in case all values in y are nonnegative.
%               If set to false, vector of nonnegative values will yield the
%               whole vector as interval, if inclOpen is tue or no interval, if
%               inclOpen is false.
%
%% Output
%   iv          - [numerical {integer}] start and end indices (rows) for each
%               nonnegative interval (column); if inclOpen is true, it may
%               include open intervals
%   closed      - [logical] flag for each interval (column index of iv):
%               true = closed interval, false = open interval;
%               Returns empty, if no intervals were found. Returns false if all
%               values are nonnegative. Returns true, if all values are positive,
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
%	Last author: Olaf C. Schmidtmann, last edit: 24.08.2023
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

%% Todo
%   - Refactor: extract search inside positive values and abstract both search
%     types

function [iv, closed] = nnegIntervals(y, inclOpen, srcPositive)

    arguments
        y(1, :) {mustBeNumeric}
        inclOpen(1, 1) logical = true
        srcPositive(1, 1) logical = true
    end

    iv = [];
    closed = false(0);

    % EARLY return, if empty, flat or all negative
    if isempty(y) || all(y < 0) || all(y(1) == y), return; end

    % Round y to the significant decimal.
    y = real(y);
    dsig = abs(ceil(log10(eps(max(abs(y))))));
    y = round(y, dsig);

    yp = y >= 0;
    nY = length(y);

    if all(yp)
        % Special case: all values are nonnegative
        if srcPositive && sum(y == 0) > 2

            % Mark positive intervals, only
            signChg = [0, diff(y > 0)];

        else
            if inclOpen
                iv = [1; nY];
                closed = false;
            end
            return;
        end

    else
        % Mark nonnegative intervals, first zero is marked (special case)
        if inclOpen
            signChg = [0, diff(yp)];
        else
            signChg = diff([y(1) ~= 0, yp]);
        end
    end

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
    closed = true(1, niv);
    ivrng = [1, niv];
    closed(ivrng(isOpen)) = false;
end