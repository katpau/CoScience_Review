%% GammaDist - Gamma probability density function
%
%% Syntax
%   gDist = GammaDist;
%   gDist = GammaDist(shapeParameter, rateParamater);
%   gDist = GammaDist(shapeParameter, rateParamater, scalingFactor);
%   gDist = GammaDist(shapeParameter, rateParamater, scalingFactor, xValues);
%
%% Description
%   GammaDist is a copyable handle class, which encapsulates the Gamma
%   parameters and facilliates the access of of PDF properties, such its
%   time-based parameters (e.g., the mode).
%   Is is also intended as a superclass for specialized Gamma PDF classes.
%
%   As a handle class, the instance has to be copied explicitly (using copy),
%   otherwise an assigned variable holds (and may alter) the same reference.
%
%   This implementation is based upon the two-parameter form with $\alpha$ as
%   shape and $\beta$ as rate (which is the inverse of the  scale parameter
%   $\theta$ used by MATLAB's <a href="matlab:help('gmapdf')">gmapdf</a>.
%
%   Even though the Gamma PDF is only defined, if shape and rate > 1, the
%   function also accepts NaN values to mark invalid distributions. Non-NaN
%   parameter values will be checked for validity, though.
%
%   The precision of the method is limited by the underlying Gamma PDF
%   approximation (<a href="matlab:help('gammaPdf')">gammaPdf</a>), based on Lanczos (1964) algorithm with a
%   relative error only below 2.0e-10.
%
%   Implementation Details
%   The access of the PDF values (y) is lazy via dependent access to avoid
%   unnecessary computations. The values will will only be multiplied by the
%   scaling factor (yscale). In case the PDF parameters (shape, rate) or the
%   x-values change, y will be invalidated and re-computed upon the next access.
%   Such a changes will also call the onChangeY method (or onChangeX if x
%   changed) method, which can be implemented by subclasses as a substitue for
%   events.
%
%   Most PDF properties (e.g., the mode or the excess) are implemented as
%   (pseudo-dependent) functions instead of getters. Even though this has some
%   drawbacks in terms indexing, they can be overridden (extended) by
%   subclasses, which getters in MATLAB sadly do not allow. Until version 2023a,
%   they are also faster.
%
%% GammaDist Properties
%   shape   - [double] Gamma PDF shape parameter (shape > 0 or NaN)
%   rate    - [double] Gamma PDF rate parameter (rate > 0 or NaN)
%   yscale  - [double] Scaling factor for the PDF values (yscale > 0)
%   scale   - [double] [read-only] Scale parameter for the PDF values
%             The inverse of rate: scale = 1/rate
%   x       - [double] Input values (x) for the Gamma PDF (nonnegative,
%             equidistant, continuously increasing)
%   y       - [double] [read-only] Resulting Gamma PDF values for x, to scale
%
%% GammaDist Methods
%   <a href="matlab:help('GammaDist.GammaDist')">Constructor</a> - [GammaDist] Construct an instance
%
%   disp        - Custom display (override).
%   <a href="matlab:help('GammaDist.isValidPdf')">isValidPdf</a>  - [logical] True, if the Gamma PDF parameters are positive.
%
%   Location Parameters:
%   <a href="matlab:help('GammaDist.ip1')">ip1</a>         - [double] Get the first inflection point of the PDF.
%   <a href="matlab:help('GammaDist.ip2')">ip2</a>         - [double] Get the second inflection point of the PDF.
%   <a href="matlab:help('GammaDist.iqr')">iqr</a>         - [double] Get the PDF interquartile range (x) using gaminv.
%   <a href="matlab:help('GammaDist.mean')">mean</a>        - [double] Get the expected mean (x) of the PDF
%   <a href="matlab:help('GammaDist.median')">median</a>      - [double] Get the expected median (x) of the PDF using gaminv.
%   <a href="matlab:help('GammaDist.mode')">mode</a>        - [double] Get the expected mode of the PDF.
%
%   Shape-dependent Parameters:
%   <a href="matlab:help('GammaDist.excess')">excess</a>      - [double] Get the excess of the PDF
%   <a href="matlab:help('GammaDist.skew')">skew</a>        - [double] Get the skewness of the PDF
%
%   <a href="matlab:help('GammaDist.var')">var</a>         - [double] Get the variance of the PDF (expected deviation)
%
%   Inherited Methods of <a href="matlab:help('handle')">handle</a>
%   Inherited Methods of <a href="matlab:help('matlab.mixin.Copyable')">Copyable</a>
%
%% Requirements:
%   The Statistics and Machine Learning Toolbox (ST) is currently required for
%   the methods median and iqr, which rely on the gaminv function. They will
%   throw a warning and return NaN, if ST is not present.
%
%% See also
%   gammaPDF, handle, matlab.mixin.Copyable, GmaResults

%% Attribution
%	Last author: Olaf C. Schmidtmann, last edit: 27.06.2023
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

classdef GammaDist < matlab.mixin.Copyable
    properties
        % shape     - [double] Gamma PDF shape parameter.
        %           Must be: shape > 0 or NaN (indicating an invalid PDF).
        %           [SETTER]
        %           A changed value invalidates y and triggers onChangeY().
        shape(1, 1) double
        % rate      - [double] Gamma PDF rate parameter.
        %           Must be: rate > 0 or NaN (indicating an invalid PDF).
        %           [SETTER]
        %           A changed value invalidates y and triggers onChangeY().
        rate(1, 1) double
        % yscale    - [double] Scaling factor for the PDF values.
        %           Must be: yscale > 0 or NaN (indicating an invalid PDF).
        %           Nonpositive values will be set as NaN.
        %           [SETTER]
        %           A changed value triggers onChangeY(), but does not
        %           invalidate y.
        yscale(1, 1) double
        % x         - [double] Input values (x) for the Gamma PDF.
        %           Values must be nonnegative, equidistant and continuously
        %           increasing; otherwise throws an error.
        %           Equidistance will be checked within tolerance of 1e-6 for
        %           single and 1e-12 for double-precision to compensate for
        %           rounding errors. x is usually one- or zero-based; Values
        %           with increments
        %           apart from 1, will implicitely scale the (time) unit, as 
        %           this class does not consider the sampling rate.
        %
        %           [SETTER]
        %           A changed value triggers onChangeY(), but does not
        %           invalidate y.
        x(1, :) double
    end

    properties (Dependent)
        % scale     - [double] Scale parameter for the PDF values.
        %           The inverse of rate: scale = 1/rate.
        %
        %           [DEPENDEND]
        %           (read-only)
        scale(1, 1) double
        % y         - [double] Resulting Gamma PDF values for x, to scale.
        %           Lazy access of the unscaled y values, multiplied by yscale.
        %
        %           [DEPENDEND][LAZY]
        %           (read-only)
        y(1, :) double
    end

    properties (Access = private)
        y_(1, :) double
    end

    
    %% Constructor

    methods
        function obj = GammaDist(shape, rate, yscale, x)
            %GAMMADIST Construct an instance of GammaDist
            %
            % Syntax
            %   gg = GammaDist(2.1, 1/333, 1, 1:2000);
            %
            % Input
            %   shape   - [double] Gamma PDF shape parameter. Must be positive 
            %           or NaN (indicating an invalid PDF). Default = NaN.
            %   rate    - [double] Gamma PDF rate parameter. Must be positive 
            %           or NaN (indicating an invalid PDF). Default = NaN.
            %   yscale  - [double] Scaling factor for the PDF. Valid values are 
            %           positive; otherwise they will be rendered to NaN. 
            %           Default = 1.
            %   x       - [double] Vector of x values fed into the PDF. The 
            %           values must be nonnegative, equidistant, continuously
            %           increasing. Default = 0.
            %           As a rule of thumb, 1:(shape + sqrt(shape)) / rate 
            %           should be enough room for a given PDF. Increments except
            %           from 1 are disencouraged, to facilitate the conversion 
            %           into time units.
            %
            % Output
            %   obj     - [GammaDist] Instance of GammaDist

            arguments
                shape = NaN
                rate = NaN
                yscale = 1
                x = 0
            end

            obj.shape = shape;
            obj.rate = rate;
            obj.yscale = yscale;
            obj.x = x;
        end


        %% Setters

        function set.shape(obj, v)
            %shape Gamma PDF (first parameter) shape property.
            %
            % Input
            %   v       - [double] Gamma PDF shape parameter

            if obj.shape ~= v
                if isnan(v) || v <= 0
                    obj.shape = NaN;
                else
                    obj.shape = v;
                end
                obj.invalidateY();
            end
        end

        function set.rate(obj, v)
            %rate Gamma PDF (second parameter) rate property.
            %
            % Input
            %   v       - [double] Gamma PDF rate parameter

            if obj.rate ~= v
                if isnan(v) || v <= 0
                    obj.rate = NaN;
                else
                    mustBePositive(v);
                    obj.rate = v;
                end
                obj.invalidateY();
            end
        end

        function set.yscale(obj, v)
            %yscale Gamma PDF scaling of the y values.
            %
            % Input
            %   v       - [double] Scaling factor of the Gamma PDF values

            if obj.yscale ~= v
                if isnan(v) || v <= 0
                    obj.yscale = NaN;
                else
                    obj.yscale = v;
                end
                obj.onChangeY();
            end
        end

        function set.x(obj, v)
            %x Gamma PDF x-values
            %
            % Input
            %   v       - [double] Vector of Gamma PDF x values, for which the 
            %           y will be calculated. Throws an error, if values are not
            %           nonnegative, equidistant or continuously increasing.

            if numel(obj.x) ~= numel(v) || any(obj.x ~= v)
                mustBeNonnegative(v);

                % Ensure equidistance
                dv = diff(v);
                if numel(v) > 1 && (~all(dv) || ~all(ismembertol(dv, dv(1))))
                    error("x values for the Gamma PDF must be continuously increasing.");
                end

                obj.x = v;
                obj.onChangeX();
                obj.invalidateY();
            end
        end


        %% Public methods

        function disp(obj)
            %DISP Custom display function
            %
            %   [Overridden] <a href="matlab:help('disp')">MATLAB disp</a>
            fprintf(1, ...
                ['GammaDist PDF: shape=%g, rate=%g (scale=%g), scaling=%g*[y] \n', ...
                'x[1:%g] %s\n'], ...
                obj.shape, obj.rate, obj.scale, obj.yscale, numel(obj.x), ...
                strjoin(string(obj.x(1:min(numel(obj.x), 8))), ", "));
        end

        function valid = isValidPdf(obj)
            %isValidPdf Are the Gamma PDF parameters positive?
            %
            % Output
            %   valid   - [logical] true, if shape and rate are positive.

            valid = obj.shape > 0 && obj.rate > 0;
        end

        
        %% Dependent Getters

        function sc = get.scale(obj)
            %scale Get the scale parameter of the PDF (= 1 / rate)
            sc = 1 / obj.rate;
        end

        function y = get.y(obj)
            %Y Gamma PDF y values for the range of x [LAZY].
            %
            %   [LAZY] Lazy access of the Gamma PDF, but multiplied by yscale
            %   upon access. Expensive on the first call and after invalidating
            %   the Gamma PDF by changing the shape, rate or x properties.
            %
            % Output
            %   y       - [double] Values of PDF(x), multiplied by yscale. The
            %           values may be real or complex.

            if ~isempty(obj.y_)
                y = obj.y_ .* obj.yscale;
            elseif ~isValidPdf(obj)
                y = [];
            else
                y = gammaPdf(obj.x, obj.shape, obj.rate);
                obj.y_ = y;
                % Return scaled
                y = y .* obj.yscale;
            end
        end


        %% Pseudo-"dependent" Getters
        % Not really dependent getters (slow in MATLAB).
        % Return values are stored in a private variable for lazy access (i.e.,
        % only computed the first time, when accessed, unless invalidated) for
        % costly computations or, otherwise calculated on access.
        % Can be overridden! :)

        function ip = ip1(obj)
            %ip1 First inflection point
            %
            % Output
            %   ip      - [double] x of first inflection point, preceding the
            %           mode (i.e. the point at which the slope of the function
            %           changes sign from negative to positive).
            %           NaN for shape <= 2 or invalid PDF.
            %
            % See also
            %   GammaDist.isValidPdf

            if ~isValidPdf(obj)
                ip = NaN;
            else
                if obj.shape <= 1, ip = NaN;
                else
                    shp = obj.shape - 1;
                    ip = (shp - sqrt(shp)) / obj.rate;
                end
            end
        end

        function ip = ip2(obj)
            %ip2 Second inflection point
            %
            % Output
            %   ip      - [double] x of second inflection point, after the mode
            %           (i.e. the point at which the slope of the function
            %           changes sign from negative to positive).
            %           NaN for shape <= 1 or invalid PDF.
            %
            % See also
            %   GammaDist.isValidPdf

            if ~isValidPdf(obj)
                ip = NaN;
            else
                if obj.shape <= 1, ip = NaN;
                else
                    shp = obj.shape - 1;
                    ip = (shp + sqrt(shp)) / obj.rate;
                end
            end
        end

        function md = mode(obj)
            %MODE Expected PDF mode
            %
            % Output
            %   md      - [double] x of the mode (the maximum and turning point)
            %           Zero for shape < 1. NaN for an invalid PDF.
            %
            % See also
            %   GammaDist.isValidPdf

            if ~isValidPdf(obj)
                md = NaN;
            elseif obj.shape < 1
                md = 0;
            else
                md = (obj.shape - 1) / obj.rate;
            end
        end

        function x = mean(obj)
            %MEAN Expected mean x of the PDF
            %
            % Description
            %   Returns the exact (not rounded) estimated x of the PDF mean as:
            %   mean_pdf = shape / rate;
            %
            %   To get the closest x in GammaDist.x, use:
            %       approxMeanX = gg.x(gg.x == round(gg.mean));
            %
            %   Expected value at the mean (x) of the scaled PDF:
            %       meanVal = gammaPdf(gg.mean, gg.shape, gg.rate) * gg.yscale;
            %
            % Output
            %   x       - [double] x of the PDF mean; NaN for an invalid PDF.
            %
            % See also
            %   GammaDist.isValidPdf, gamstat

            if ~isValidPdf(obj)
                x = NaN;
            else
                x = obj.shape / obj.rate;
            end
        end

        function x = median(obj)
            %MEDIAN Expected median x of the PDF using the Gamma inverse
            % cumulative distribution function (gaminv)
            %
            % Description
            %   To get the expected value at the median (x) of the scaled PDF:
            %       medVal = gammaPdf(gg.median, gg.shape, gg.rate) * gg.yscale;
            %
            % Requirements
            %   Statistics and Machine Learning Toolbox (displays a warning if
            %   not found).
            %
            % Output
            %   x       - [double] Expected median x of the PDF.
            %           NaN for shape <= 2 or invalid PDF or when the Statistics
            %           and Machine Learning Toolbox has not been found.
            %
            % See also
            %   gaminv

            if ~isValidPdf(obj)
                x = NaN;
            else
                try
                    x = gaminv(0.5, obj.shape, obj.scale);
                catch
                    if ~matlab.addons.isAddonEnabled("ST")
                        warning("[GammaDist.median] requires gaminv from the " + ...
                            "Statistics and Machine Learning Toolbox to run.");
                    end
                    x = NaN;
                end
            end
        end

        function iqr = iqr(obj)
            %IQR PDF interquartile range (x) using the Gamma inverse
            %cumulative distribution function (gaminv)
            %
            % Requirements
            %   Statistics and Machine Learning Toolbox (displays a warning if
            %   not found).
            %
            % Output
            %   x       - [double] Expected interquartile range x of the PDF.
            %           NaN for an invalid PDF or when the Statistics and
            %           Machine Learning Toolbox has not been found.
            %
            % See also
            %   gaminv

            if ~isValidPdf(obj)
                iqr = NaN;
            else
                try
                    qx = gaminv([0.25, 0.75], obj.shape, obj.scale);
                    iqr = qx(2) - qx(1);
                catch
                    if ~matlab.addons.isAddonEnabled("ST")
                        warning("[GammaDist] iqr() requires gaminv from the " + ...
                            "Statistics and Machine Learning Toolbox to run.");
                    end
                    iqr = NaN;
                end
            end
        end

        function v = var(obj)
            %var Variance of the PDF (expected deviation)
            %
            %   var_pdf = shape / rate^2
            %
            % Output
            %   v       - [double] Variance of the PDF as var = shape / rate^2.
            %           NaN for shape <= 2 or invalid PDF.
            %
            % See also
            %   GammaDist.isValidPdf, gamstat

            if ~isValidPdf(obj)
                v = NaN;
            else
                v = obj.shape / obj.rate^2;
            end
        end

        function sk = skew(obj)
            %skew Skewness of the PDF
            %
            % Output
            %   sk      - [double] Skewness of the PDF; NaN for an invalid PDF.

            if ~isValidPdf(obj)
                sk = NaN;
            else
                sk = 2 / sqrt(obj.shape);
            end
        end

        function ex = excess(obj)
            %excess Excess of the PDF
            %
            % Output
            %   ex      - [double] Excess of the PDF; NaN for an invalid PDF.

            if ~isValidPdf(obj)
                ex = NaN;
            else
                ex = 6 / obj.shape;
            end
        end

    end

    
    %% Protected methods

    methods (Access = protected)
        function onChangeX(obj) %#ok<MANU>
            %onChangeX Called whenever x values of the Gamma PDF were changed.
            %   Override in subclasses to react.
        end

        function onChangeY(obj) %#ok<MANU>
            %onChangeY Called whenever y values of the Gamma PDF were changed.
            %   Override in subclasses to react.
        end
    end

    
    %% Private methods

    methods (Access = private)

        function invalidateY(obj)
            % invalidateY Invalidates the stored y_ and calls onChangeY to let
            % subclasses react to the change.

            obj.y_ = [];
            obj.onChangeY();
        end
    end

end
