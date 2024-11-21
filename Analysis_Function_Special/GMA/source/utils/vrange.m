function xr = vrange(x)
    %VRANGE Vector range.
    %
    %% Syntax
    %   xrange = vrange(x);
    %
    %% Description
    %   Returns the range as max(x) - min(x) of a vector.
    %   Replacement for range(), which requires the Statistics and Machine
    %   Learning Toolbox.
    %
    %% Input
    %   x           - [numeric] vector
    %
    %% Output
    %   xr          - [numeric] range of x

    %% Attribution
    %	Last author: Olaf C. Schmidtmann, last edit: 14.11.2023
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

    xr = max(x) - min(x);
end
