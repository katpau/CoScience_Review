%GmaResults Class containing the results of a fitted the Gamma PDF
%
%% Syntax
%   gg = GmaResults(fitShape, fitRate, fitScaling, obsData, dataX);
%   gg = GmaResults(fitShape, fitRate, fitScaling, obsData, dataX, minCorr=0.5);
%   gg = GmaResults(fitShape, fitRate, fitScaling, obsData, dataX, minCorr=0.5, seg=fitSeg);
%   gg = GmaResults(fitShape, fitRate, fitScaling, obsData, dataX, minCorr=0.5, seg=fitSeg, win=modeWin);
%
%% Description
%   GmaResults extends the <a href="matlab:help('GammaDist')">GammaDist</a> class to hold the results of gmaFit
%   and the fitted data.
%   As its superclass <a href="matlab:help('GammaDist')">GammaDist</a>, it is a copyable handle class, which
%   encapsulates the Gamma parameters and the results of <a href="matlab:help('gmaFit')">gmaFit</a> with various
%   error and correlation measures, as well as utility methods for unit
%   conversions and plotting.
%
%   As GmaResults encapsulates the results of the fit, the settings can be
%   altered post-hoc (e.g., changing the premitted mode window). A fit of a
%   segment within the data (seg property) can also be related to the whole data
%   or re-fitted (using  <a href="matlab:help('GmaResults.relateWhole')">relateWhole</a> or <a href="matlab:help('GmaResults.fullRefit')">fullRefit</a>). Doing so will reference the
%   fitted PDF's parameters to its absolute position within the data while
%   retaining its shape.
%
%   A successful fit between the data and the PDF, as given by <a href="matlab:help('GmaResults.isFit')">isFit</a>, must meet
%   the following requirements:
%
%       - the correlation between the PDF and the data is at least equal to
%       the minimum correlation (minCorr), which is always postive
%       - the mode of the PDF is within the time window (win)
%       - all PDF values are real numbers (not complex),
%       - and the PDF parameters (implicitely): shape > 1 and rate > 0 and the
%       scaling factor, yscale > 0.
%
%   Unsuccessful attempts of fitting by gmaFit will set parameters to NaN.
%   Keep in mind that the correlation is not a proper goodness-of-fit measure.
%
%% GmaResults Properties
%   data        - [double] Data vector used for the fit
%   eegInfo     - [struct] [read-only] Additional information about the EEG data
%   isInverted  - [logical] true indicates reversed polarity of the data
%   minCorr     - [double] Minimal correlation between data and the PDF
%   seg         - [double] The fitted segment in data (start, end)
%   win         - [double] The window for successful fitting modes (start, end)
%
%   Static:
%   EEG_INFO_TYPE	- [char] Identificator for the type field in eegInfo.
%   MIN_PTNS	    - [double {integer}] Minium length of segments
%   REL_DATE	    - [char] Release date of this version
%   REL_VERSION	    - [char] Version of GmaResults
%
%   Inherited Properties from <a href="matlab:help('GammaDist')">GammaDist</a>:
%   shape       - [double] Gamma PDF shape parameter (shape > 0 or NaN)
%   rate        - [double] Gamma PDF rate parameter (rate > 0 or NaN)
%   yscale      - [double] Scaling factor for the PDF values (yscale > 0)
%   scale       - [double] [read-only] Scale parameter for the PDF values
%               The inverse of rate: scale = 1/rate
%   x           - [double] Input values (x) for the Gamma PDF (nonnegative,
%               equidistant, continuously increasing)
%   y           - [double] [read-only] Resulting Gamma PDF values for x, scaled
%
%% GmaResults Methods
%   <a href="matlab:help('GmaResults.GmaResults')">Constructor</a>     - [GmaResults] Construct an instance
%
%   <a href="matlab:help('GmaResults.addEegInfo')">addEegInfo</a>	    - Add eegInfo from a suitable EEGLAB-like struct
%   <a href="matlab:help('GmaResults.isAligned')">isAligned</a>	    - [logical] Does the PDF start with the first data point?
%   <a href="matlab:help('GmaResults.isFit')">isFit</a>	        - [logical] Does the PDF meet all the criteria for a fit?
%   <a href="matlab:help('GmaResults.modeInWindow')">modeInWindow</a>    - [logical] Is the mode of the PDF within the time window?
%   <a href="matlab:help('GmaResults.pnt2ms')">pnt2ms</a>          - [double] Convert a unitless data point to milliseconds
%
%   Correlation and Error Measures:
%   <a href="matlab:help('GmaResults.mae')">mae</a>	            - [double] Mean absolute error (MAE)
%   <a href="matlab:help('GmaResults.mse')">mse</a>	            - [double] Mean-squared error (MSE)
%   <a href="matlab:help('GmaResults.nrmse')">nrmse</a>	        - [double] Normalized root-mean-squared error (nRMSE)
%   <a href="matlab:help('GmaResults.rmse')">rmse</a>	        - [double] Root-mean-squared error (RMSE / RMSD)
%   <a href="matlab:help('GmaResults.r')">r</a>	            - [double] Pearson product-moment correlation coefficient
%
%   Formatted Output and Export:
%   <a href="matlab:help('GmaResults.disp')">disp</a>            - Custom display.
%   <a href="matlab:help('GmaResults.asStruct')">asStruct</a>	    - [struct] Return a struct with the main result data.
%   <a href="matlab:help('GmaResults.asTable')">asTable</a>		    - [table] Return a table with the main results.
%   <a href="matlab:help('GmaResults.resultStr')">resultStr</a>	    - [string]  Get results as string array.
%   <a href="matlab:help('GmaResults.dump')">dump</a>	        - Display verbose results in command window.
%
%   Changing Fitting Scope:
%   <a href="matlab:help('GmaResults.fullRefit')">fullRefit</a>       - [GmaResults] Re-run GMA with a zero-padded version
%   <a href="matlab:help('GmaResults.relateWhole')">relateWhole</a>	    - [GmaResults] Relate fitted PDF to the full data range
%
%   Plotting Helpers:
%   <a href="matlab:help('GmaResults.getTailFront')">getTailFront</a>    - [double] Get the part of the PDF before the fitted segment
%   <a href="matlab:help('GmaResults.getTailRear')">getTailRear</a>     - [double] Get the part of the PDF after the fitted segment
%
%   Protected:
%   <a href="matlab:help('GmaResults.invalidate')">invalidate</a>      - Resets properties dependent on y and data.
%   <a href="matlab:help('GmaResults.onChangeData')">onChangeData</a>	- Called whenever the data or the segment changed.
%   <a href="matlab:help('GmaResults.onChangeX')">onChangeX</a>	    - Called whenever x values of the Gamma PDF changed.
%   <a href="matlab:help('GmaResults.onChangeY')">onChangeY</a>	    - Called whenever y values of the Gamma PDF changed.
%
%   Static:
%   <a href="matlab:help('GmaResults.emptyEegInfo')">emptyEegInfo</a>	- [struct] Minimum (default) EEG Info struct
%   <a href="matlab:help('GmaResults.emptyTable')">emptyTable</a>	    - [table] Create an empty table with common result variables
%   <a href="matlab:help('GmaResults.isEegInfo')">isEegInfo</a>	    - [logical] Is a struct a valid GmaResults eegInfo struct?
%   <a href="matlab:help('GmaResults.version')">version</a>	        - [string] Version information as composed string
%
%   Inherited Methods from <a href="matlab:help('GammaDist')">GammaDist</a>:
%   <a href="matlab:help('GammaDist.isValidPdf')">isValidPdf</a>  - [logical] True, if the Gamma PDF parameters are positive.
%   <a href="matlab:help('GmaResults.iqr')">iqr</a>         - [double] Get the PDF interquartile range (x) using gaminv.
%
%   Overridden Time-dependent Parameters, adjusted to the full data epoch:
%   <a href="matlab:help('GmaResults.ip1')">ip1</a>         - [double] Get the first local inflection point of the PDF.
%   <a href="matlab:help('GmaResults.ip2')">ip2</a>         - [double] Get the second local inflection point of the PDF.
%   <a href="matlab:help('GmaResults.mean')">mean</a>        - [double] Get the expected local mean (x) of the PDF.
%   <a href="matlab:help('GmaResults.median')">median</a>      - [double] Get the expected local median (x) of the PDF.
%   <a href="matlab:help('GmaResults.mode')">mode</a>        - [double] Get the expected local mode of the PDF.
%
%   Shape-dependent Parameters of the distribution:
%   <a href="matlab:help('GammaDist.excess')">excess</a>      - [double] Get the excess of the PDF
%   <a href="matlab:help('GammaDist.skew')">skew</a>        - [double] Get the skewness of the PDF
%
%   <a href="matlab:help('GammaDist.var')">var</a>         - [double] Get the variance of the PDF (expected deviation)
%
%   Inherited Methods of <a href="matlab:help('handle')">handle</a>
%   Inherited Methods of <a href="matlab:help('matlab.mixin.Copyable')">Copyable</a>
%
%% See also
%   GammaDist, gmaFit

%% Attribution
%	Last author: Olaf C. Schmidtmann, last edit: 15.11.2023
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

classdef GmaResults < GammaDist

    properties
        % data          - [double] Data vector used for the fit.
        %               [SETTER]
        %               Changed values invalidate the error and correlation
        %               measures via onChangeData(). Changing the data can
        %               shrink the seg property, if it does not fit. The PDF
        %               values (y, x) will not be altered
        data(1, :) double
        % seg           - [double {integer}] The fitted segment as a vector of
        %               two indices (start, end) within both the data and the
        %               PDF (usually marking nonnegative interval or the full
        %               data range).
        %               It will be used for all correlation and error measures
        %               between the data and the PDF values, with a minimum
        %               length of 3 (GmaResults.MIN_PNTS).
        %               Input values will be adjusted to the permitted range of
        %               indices (via <a href="matlab:help('getValidSegment')">getValidSegment</a>) or to NaN.
        %               [SETTER]
        %               Changed values invalidate the error and correlation
        %               measures via onChangeData().
        seg(1, 2) double
        % win           - [double {integer}] The window of data points (start,
        %               end) of the PDF mode as a vector of two indices. A Mode
        %               located within this window is a prerequisite for a
        %               successful fit. Empty values will be rendered to NaN.
        %               [SETTER]
        %               Changed values invalidate the error and correlation
        %               measures via onChangeData().
        win(1, 2) double % integer indices
        % isInverted    - [logical] true: indicates that the data's polarity was
        %               reversed (data * -1), false: data is unchanged.
        isInverted(1, 1) logical
        % isFullOpt     - [logical] true: indicates that the whole data range 
        %               was used for optimization; false: the optimization was 
        %               performed on the nonnegative interval, only
        isFullOpt(1, 1) logical
        % minCorr       - [double] Minimal correlation between data and the PDF
        %               (y) a criterion for a successful fit. Must at least
        %               barely positive, between the smallest double precision
        %               accuracy (2^-52 =~ 2.2204e-16) and 1.
        minCorr(1, 1) double{mustBeInRange(minCorr, 2.2204e-16, 1)} = 2.2204e-16
    end

    properties (SetAccess = private)
        % eegInfo       - [struct] [read-only] A struct containing additional information
        %               about the EEG data (at least the fields 'data',
        %               'setname' and 'srate').
        %               eegInfo can be set using <a href="matlab:help('GmaResults.addEegInfo')">addEegInfo</a>.
        eegInfo struct = struct.empty
    end

    properties (Access = private)
        % r_ for lazy access of r
        r_ double
        % mse_ for lazy access of mse
        mse_ double
        % inConstr a hacky way to mark calls from inside the constructor, used 
        % to simplyfy the loading process for (somewhat dependend) setters
        inConstr logical = false
    end

    properties (Constant)
        % Version number (Major.Minor.Patch) of GmaResults.
        REL_VERSION = '0.9.5';
        % Release date of this version (yyyy-mm-dd)
        REL_DATE = '2023-11-16';
        % Identificator for the type field in the info struct.
        EEG_INFO_TYPE = 'GmaInfo';
        % Minium points for segments (especially for correlations)
        MIN_PTNS = 3;
    end

    methods

        %% Constructor

        function obj = GmaResults(shape, rate, yscale, data, x, args)
            %gmaResults Construct an instance of GmaResults
            %
            % Description
            %   GmaResults is usually created as a result of the GMA fitting
            %   process (e.g. of <a href="matlab:help('gmaFit')">gmaFit</a>).
            %   It does not fit a Gamma PDF on the data by itself.
            %
            % Syntax
            %   gg = GmaResults(fitShape, fitRate, fitScaling, obsData, dataX);
            %   gg = GmaResults(fitShape, fitRate, fitScaling, obsData, dataX, minCorr=0.5);
            %   gg = GmaResults(fitShape, fitRate, fitScaling, obsData, dataX, minCorr=0.5, seg=fitSeg);
            %   gg = GmaResults(fitShape, fitRate, fitScaling, obsData, dataX, minCorr=0.5, seg=fitSeg, win=modeWin);
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
            %   [Optional] Name-value parameters
            %   isInverted  - [logical] true: the polarity of the data was 
            %               inversed; false (default: the polarity of the data
            %               was not changed
            %   isFullOpt   - [logical] true: indicates that the whole data 
            %               range was used for optimization; false (default):
            %               the optimization was performed on the nonnegative
            %               interval, only
            %   minCorr     - [double] Minimal correlation between data and the
            %               PDF for a valid fit: Must be larger than 2.2204e-16
            %               (~eps(1) is fine) and 1. Default: 2.2204e-16
            %               see <a href="matlab:help('GmaResults.minCorr')">minCorr</a>
            %   seg         - [double] The fitted segment as indices (start,
            %               end) within both the data and the PDF.
            %               Default: [min(1, numel(x)), numel(x)]
            %               see <a href="matlab:help('GmaResults.seg')">seg</a>
            %   win         - [double] The window for successful fitting modes
            %               as a vector (start, end).
            %
            % See also
            %   gmaFit

            arguments
                shape = NaN
                rate = NaN
                yscale = 1
                data = []
                x = min(1, numel(data)):numel(data)
                args.seg = [min(1, numel(data)), numel(data)]
                args.win = [min(1, numel(data)), numel(data)]
                args.isInverted = false
                args.isFullOpt = false
                args.minCorr = 2.2204e-16
            end
            obj@GammaDist(shape, rate, yscale, x);
            obj.inConstr = true;
            obj.data = data(:);
            obj.seg = args.seg;
            obj.win = args.win;
            obj.isInverted = args.isInverted;
            obj.isFullOpt = args.isFullOpt;

            % Range between barely positive and 1.
            obj.minCorr = max(2.2204e-16, min(1, args.minCorr));
            obj.inConstr = false;
        end


        %% Setters

        function set.data(obj, v)
            %data Data Setter
            %
            % Input
            %   v   - [double] The data as vector, fitted by gmaFit. An empty
            %       vector will be stored as NaN and set the segment to NaN,
            %       thus disabling any correlation or error measure
            %       calculations.

            if isempty(v), v = NaN; end
            if isempty(obj.data) || any(v ~= obj.data)
                oldData = obj.data;
                obj.data = v;
                obj.onChangeData(oldData, v);
            end
        end

        function set.seg(obj, v)
            % Sets the segment for the fit to permitted values
            %
            % Input
            %   v   - [double] Segment in the data, which was fit.
            %
            % See also
            %   GmaResults.getValidSegment

            if isequaln(obj.seg, [0,0]) && ~obj.inConstr %#ok<MCSUP>
                % HACK: Assume we load data, bypassing the constructor and set 
                % seg directly:
                obj.seg = v;
            else
                newSeg = obj.getValidSegment(v);
                if ~isequaln(newSeg, obj.seg)
                    if all(v) && ~isequaln(v, newSeg)
                        fprintf("[GmaResults] Data segment input [%i, %i] out " + ...
                            "of bounds or too short. \n" + ...
                            "It was automatically adjusted to [%i, %i].\n", v, newSeg);
                    end
                    obj.seg = newSeg;
                    obj.onChangeData();
                end
            end
        end


        %% Public methods

        function disp(obj)
            %DISP Custom display function (OVERRIDE)
            for i = 1:numel(obj)
                fprintf(1, ...
                    'GmaResults: segment=[%i, %i], isFit=%i\n', ...
                    obj(i).seg, obj(i).isFit);
                disp@GammaDist(obj(i));
            end
        end

        function offset = localOffset(obj)
            %localOffset Relative offset of the PDF x within the full data
            %
            % Syntax
            %   offset = myGmaResults.localOffset;
            %
            % Description
            %   Difference between the values at the first indices of the
            %   segment to fit and the PDF x values, used to transpose the PDF x
            %   to their absolute position within the full data range.
            %   These values can differ, if the PDF was created using
            %   zero-padding beyond the first data point.
            %   Example: when the segment starts at index 1 of the data, but
            %   the PDF had been fitted to data, preceded by 20 zero values,
            %   then seg = 1, x =
            %
            %
            % Output
            %   offset  - [double {integer}] seg(1) - x(1), which is integer or
            %           NaN, if the segment is NaN.

            if ~isnan(obj.seg(1))
                offset = obj.seg(1) - obj.x(1);
            else
                offset = NaN;
            end
        end

        function aligned = isAligned(obj)
            %isAligned Does the PDF fit start with the first data point?
            %
            % Syntax
            %   aligned = myGmaResults.isAligned;
            %
            % Description
            %   See output
            %
            % Output
            %   aligned - [logical] true, if the first data point (x) of the
            %           Gamma PDF equals segment start index, which the contains
            %           the fitted data (x(1) == seg(1)).

            aligned = obj.x(1) == obj.seg(1);
        end

        function modeFits = modeInWindow(obj)
            %isFit Is the mode of the Gamma PDF within the time window?
            %
            % Syntax
            %   modeFits = myGmaResults.modeInWindow;
            %
            % Description
            %   See output
            %
            % Output
            %   modeFits    - [logical] true, if the PDF mode is within the
            %               permitted window, otherwise false, as:
            %               modeFits = mode >= win(1) && mode <= win(2)

            modeFits = obj.mode >= obj.win(1) && obj.mode <= obj.win(2);
        end

        function fit = isFit(obj)
            %isFit Does the Gamma PDF meet all the criteria for a fit?
            %
            % Description
            %   Requirements for a sccuessful fit between the data and the PDF:
            %
            %       - the correlation between the PDF y and the data is at least
            %       equal to the minimum correlation (minCorr), which is always
            %       postive (this is not a proper goodness-of-fit measure,
            %       though!)
            %       - the mode of the PDF is within the time window (win)
            %       - all PDF values are real numbers (not complex),
            %       - and (implicitely) the PDF parameters: shape > 1 and rate >
            %       0 and the scaling factor, yscale > 0.
            %
            % Output
            %   fit     - [logical] true, if the conditions for a fit are met;
            %           false, otherwise

            fit = obj.r >= obj.minCorr && obj.modeInWindow && isreal(obj.y);
        end

        function addEegInfo(obj, EEG, channel)
            %addEegInfo Add information from an EEGLAB-like struct or a former
            % GmaResults.eegInfo
            %
            % Syntax
            %
            % Description
            %   Extracts fields from a struct, which must at least contain the
            %   fields 'setname' and 'srate' and stores them in eegInfo or
            %   throws an error, otherwise.
            %   If the struct is a former GmaResults.eegInfo, the content will
            %   be set unchecked.
            %   If the struct is EEGLAB-like (i.e., contains the fields
            %   typically present in such EEG data; see <a href="matlab:help('isEegStruct')">isEegStruct</a>), more
            %   information will be extracted:
            %       - the channel name (by its index or name) and the channel
            %       data from the chanlocs
            %       - the EEG.filename, EEG.filepath, EEG.xmin
            %       - the EEG.subject, EEG.group, EEG.condition, EEG.session
            %       - any field in EEG.etc.gma (if present)
            %
            % Input
            %   EEG     - [struct] Extracts fields from a struct, which must at
            %           least contain the fields 'setname' and 'srate' or throws
            %           an error, otherwise. If the struct is a former
            %           GmaResults.eegInfo, the content will be set unchecked.
            %
            %   channel - [numeric {integer}|char|string] The channel index in
            %           EEG.data or its name
            %
            % See also
            %   isEegStruct, GmaResults.isEegInfo, GmaResults.emptyEegInfo

            arguments
                obj
                EEG(1, 1) struct
                channel = 1
            end

            [isGmaViable, isEegLike] = isEegStruct(EEG);

            % EARLY EXIT
            if nargin < 2 || ~isGmaViable
                fprintf("[GmaResults] FAILED to set EEG minimum information. " + ...
                    "Missing or invalid EEG struct containing the fields " + ...
                    "'setname' and 'srate'.\n");
                return;
            end

            % Valid EegInfo structs will be set directly
            if GmaResults.isEegInfo(EEG)
                obj.eegInfo = EEG;
                return;
            end

            % Otherwise, extract information from fields.
            info = GmaResults.emptyEegInfo;
            info.setname = EEG.setname;
            info.srate = EEG.srate;
            % Set xmin (the time at the first data point in milliseconds)
            if isfield(EEG, 'xmin')
                info.xmin = EEG.xmin;
            else
                info.xmin = 0;
            end

            % Store a preliminary label
            chLoc = struct;
            if isnumeric(channel)
                chLabel = num2str(channel);
            else
                chLabel = channel;
            end

            % Additional information for EEGLAB-like structs
            % KLUDGE: quite horrible condition-stacking!
            if isEegLike
                if ~isempty(EEG.chanlocs) && isfield(EEG.chanlocs, 'labels') && ...
                        ~isempty(EEG.chanlocs(channel).labels)

                    % Try to retrieve channel info (throws an error if out of bounds)
                    if isnumeric(channel)
                        chLoc = EEG.chanlocs(channel);
                        chLabel = chLoc.labels;
                    elseif ischar(channel) || isstring(channel) || iscellstr(channel)
                        chIdx = find(strcmpi({EEG.chanlocs.labels}, channel));
                        if ~isempty(chIdx), chLoc = EEG.chanlocs(chIdx); end
                    end
                end

                info.filename = EEG.filename;
                info.filepath = EEG.filepath;
                info.xmin = EEG.xmin;

                % Membership info of the dataset:
                info.subject = EEG.subject;
                info.group = EEG.group;
                info.condition = EEG.condition;
                info.session = EEG.session;

                if isfield(EEG.etc, 'gma')
                    % The gma struct in EEG.etc may contain additional
                    % information like a description or the used parameters.
                    flds = fieldnames(EEG.etc.gma);
                    for iFld = 1:length(flds)
                        cpFld = flds{iFld};
                        if ~isfield(info, cpFld) || isempty(info.(cpFld))
                            info.(cpFld) = EEG.etc.gma.(cpFld);
                        else
                            warning("eegInfo field %s already exists or " + ...
                                "is not empty.");
                        end
                    end
                end
            end

            info.chLabel = chLabel;
            info.chLoc = chLoc;
            obj.eegInfo = info;

        end

        function [x, y] = getTailRear(obj, tailEnd)
            %getTailRear Get the part of the PDF after the fitted segment
            %
            %   Returns PDF x and y values for the first data point up to and
            %   including the first fitted point of the segment (for plotting).
            %
            % Output
            %   x   - [double {integer}] PDF x indices for the unfitted area
            %       preceding the fitted segment.
            %   y   - [double] PDF y values for the unfitted area preceding
            %       the fitted segment.
            %
            % See also
            %   gammaPdf

            if nargin < 2, tailEnd = numel(obj.data); end

            x = [];
            y = [];

            if obj.isValidPdf && tailEnd > obj.seg(2)
                x = (obj.seg(2):tailEnd) - obj.localOffset;
                y = gammaPdf(x, obj.shape, obj.rate) .* obj.yscale;
            end
        end

        function [x, y] = getTailFront(obj)
            %getTailFront Get the part of the PDF before the fitted segment
            %
            %   Returns PDF x and y values from and including the last fitted
            %   point of the segment until the last data point (for plotting).
            %
            % Output
            %   x   - [double {integer}] PDF x indices for the unfitted area
            %       following the fitted segment.
            %   y   - [double] PDF y values for the unfitted area following
            %       the fitted segment.
            %
            % See also
            %   gammaPdf

            x = [];
            y = [];

            if obj.isValidPdf && obj.seg(1) > 1
                x = (1:obj.seg(1)) - obj.localOffset;
                x = x(x > 0);
                y = gammaPdf(x, obj.shape, obj.rate) .* obj.yscale;
            end
        end

        function fullFit = fullRefit(obj)
            %fullRefit Re-run GMA for the largest nonnegative interval with all
            %surrounding data set to zero.
            %
            % Syntax
            %   fullRefit = myGmaResults.fullRefit;
            %
            % Description
            %   Fits a Gamma PDF on the largest nonnegative interval (LNNI) as
            %   used by the original GMA including the surrounding data set to
            %   zero, thus retaining the fitted PDF's absolute position in the
            %   data.
            %   After re-fitting, the data will be replaced by the orginal data,
            %   to measure the error and correlation for the complete epoch.
            %
            %   The returned GmaResults object's local parameters (ip1, mode,
            %   ip2) will be close to those in the original instance, but very
            %   likely not identical. All other parameters and measures will
            %   change due to the new basic parameters (shape, rate, yscale).
            %
            %   Exception: if the LNNI already started with the first point of
            %   the orginal data or the zero-padding already covered all
            %   data points preceeding the LNNI (e.g., running gmaFit with the
            %   segPad(1) parameter set to inf), only the error measures and the
            %   correlation will change.
            %
            %   Note:
            %   This function exists to keep the data comparable to the old GMA
            %   fitting method, which always optimized the whole data epoch in
            %   contrast to the new version, which fits on the LNNI, only.
            %   It will run a rather expensive second gmaFit, unless the LNNI
            %   is already aligned to the data, i.e. <a href="matlab:help('isAligned')">isAligned</a>
            %   is true, which runs a less taxing relateFullData, instead.
            %
            % Output
            %   fullFit - [GmaResults] GMA results for the full data epoch,
            %           using the PDF parameters and mode window criteria of
            %           this instance.
            %
            % See also
            %   gmaFit, relateWhole, isAligned

            if obj.isAligned
                fullFit = obj.relateWhole();
            else
                paddedData = [zeros(1, obj.seg(1) - 1), ...
                    obj.data(:, obj.seg(1):obj.seg(2)), ...
                    zeros(1, numel(obj.data) - obj.seg(2))];
                fullFit = gmaFit(paddedData, ...
                    obj.win(1), obj.win(2) - obj.win(1) + 1, ...
                    segPad = [1, numel(obj.data)], segExtension = 0, ...
                    logEnabled = 0);

                fullFit.data = obj.data;
                fullFit.addEegInfo(obj.eegInfo, obj.eegInfo.chLabel);
            end
        end

        function fullFit = relateWhole(obj)
            %relateWhole Return a copy of the fitted PDF, related to the full
            %data range
            %
            % Syntax
            %   fullGma = myGmaResults.relateWhole;
            %
            % Description
            %   Whereas the error and correlation measures of a GmaResults
            %   instance returned by gmaFit only refer to the fitted segment,
            %   this method returns a copy of its instance which relates them to
            %   the complete data.
            %
            %   Note:
            %   You might want to consider chaning the minimum correlation for
            %   the full data range.
            %
            % Requirements
            %   As a prerequisite, the first x of the PDF must match the segment
            %   start index, i.e., <a href="matlab:help('isAligned')">isAligned</a> must be true.
            %   This can be safely achieved by setting the forward zero-padding
            %   for the initial gmaFit to inf.
            %
            % Output
            %   fullFit - [GmaResults] Copy of this instance related to the full
            %           data epoch.
            %
            % See also
            %   gmaFit, isAligned

            if ~obj.isAligned
                msg = sprintf("Relating PDF to the full data failed.\n" + ...
                    "The fitted segment onset differs from the first x of the " + ...
                    "Gamma PDF.\nTry using fullRefit(), instead.");
                error(msg);
                fullFit = GmaResults;
            else
                fullFit = obj.copy;
                fullFit.x = 1:numel(obj.data);
                fullFit.seg = [1, numel(obj.data)];
            end
        end

        function pntMs = pnt2ms(obj, pnt, srate, xoriginSec)
            % pntMs Convert a unitless data point to milliseconds
            %
            % Syntax
            %   ip1ms = myGmaResults.pnt2ms(myGmaResults.ip1);
            %   ip1ms = myGmaResults.pnt2ms(myGmaResults.ip1, sampleRate);
            %   ip1ms = myGmaResults.pnt2ms(myGmaResults.ip1, sampleRate, xoffSet);
            %
            % Description
            %   Converts a unit-free data point into milliseconds, using either
            %   the provided sampling rate (srate) or the one stored in
            %   eegInfo.srate. A shifted origin of a data epoch (i.e., time = 0
            %   is not at index 1) can be compensated (substracted) by setting
            %   an offset in seconds
            %   (xoriginSec). If the parameter is not set, it will be retrieved
            %   from eegInfo.xmin.
            %
            % Input
            %   pnt         - [double] A unitless data point.
            %   srate       - [double] The sampling rate of the data in Hz.
            %               Default: eegInfo.srate; if both are unset, throws an
            %               error.
            %   xoriginSec  - [double] The offset of the origin (t=0 in the
            %               data) in seconds.
            %               Default: eegInfo.xmin; if both are unset, throws an
            %               error.
            %
            % Output
            %   pntMs       - [double] Milliseconds at the given data point.
            %
            % Example
            %   % The EEG dataset was recorded with a sampling rate of 500 Hz
            %   % and the epochs ranged from -100 to 250 ms (xoriginSec = 0.1).
            %   % Thus, the a sample at 111 would be at 120 ms:
            %   gResults = GmaResults
            %   smp1 = gr.pnt2ms(111, 500, 0.1);

            arguments
                obj
                pnt
                srate(1, 1) double = NaN
                xoriginSec(1, 1) double = NaN
            end

            if isnan(srate)
                if ~isfield(obj.eegInfo, 'srate')
                    error("The sampling rate (srate) must be either provided " + ...
                        "as a paramater or be available as eegInfo.srate.");
                else
                    srate = obj.eegInfo.srate;
                end
            end

            if isnan(xoriginSec)
                if ~isfield(obj.eegInfo, 'xmin')
                    error("The zero-point (xorigin) must be either provided " + ...
                        "as a paramater or be available as eegInfo.xmin.");
                else
                    xoriginSec = -obj.eegInfo.xmin;
                end
            end

            pntMs = (pnt - (xoriginSec * srate + 1)) * 1000 / srate;
        end


        %% Pseudo-"dependent" Getters

        function ip = ip1(obj)
            %ip1 First inflection point (x) within the data
            %
            % Description
            %   The returned x is relative to the full data epoch, i.e. adjusted
            %   by the segments's localOffset.
            %
            %   [Overridden] <a href="matlab:help('GammaDist.ip1')">GammaDist.ip1</a>
            %
            % Output
            %   ip1     - [double] First inflection in the unit of x.
            %
            % See also
            %   GammaDist.ip1, localOffset

            ip = ip1@GammaDist(obj) + obj.localOffset;
        end

        function ip = ip2(obj)
            %ip2 Second inflection point (x) within the data
            %
            % Description
            %   The returned x is relative to the full data epoch, i.e. adjusted
            %   by the segments's localOffset.
            %
            %   [Overridden] <a href="matlab:help('GammaDist.ip2')">GammaDist.ip2</a>
            %
            % Output
            %   ip2     - [double] Second inflection in the unit of x.
            %
            % See also
            %   GammaDist.ip2, localOffset

            ip = ip2@GammaDist(obj) + obj.localOffset;
        end

        function md = mode(obj)
            %mode PDF mode (x) within the data
            %
            % Description
            %   The mode is the maximum and turning point of the Gamma PDF.
            %
            %   The returned x is relative to the full data epoch, i.e. adjusted
            %   by the segments's localOffset.
            %
            %   [Overridden] <a href="matlab:help('GammaDist.mode')">GammaDist.mode</a>
            %
            % Output
            %   md      - [double] Mode in the unit of x.
            %
            % See also
            %   GammaDist.mode, localOffset

            md = mode@GammaDist(obj) + obj.localOffset;
        end

        function x = mean(obj)
            %MEAN Expected mean x of the PDF
            %
            % Description
            %   Returns the exact (not rounded) estimated x of the PDF mean,
            %   relative to the full data epoch, i.e. adjusted by the segments's
            %   localOffset.
            %
            %   [Overridden] <a href="matlab:help('GammaDist.mean')">GammaDist.mean</a>
            %
            % Output
            %   x       - [double] x of the PDF mean; NaN for an invalid PDF.
            %
            % See also
            %   GammaDist.mean, gamstat

            x = mean@GammaDist(obj) + obj.localOffset;
        end

        function x = median(obj)
            %MEDIAN Expected median x of the PDF
            %
            % Description
            %   Uses the Gamma inverse cumulative distribution function (gaminv)
            %   to obtain the median (x) of the scaled PDF
            %
            %   [Overridden] <a href="matlab:help('GammaDist.median')">GammaDist.median</a>
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
            %   GammaDist.median, gaminv

            x = median@GammaDist(obj) + obj.localOffset;
        end

        %% Pseudo-"dependent" Getters
        % Not really dependent getters (slow in MATLAB).
        % Return values are stored in a private variable for lazy access (i.e.,
        % only computed the first time, when accessed, unless invalidated) for
        % costly computations or, otherwise calculated on access.
        % Can be overridden! :)

        function [r, rmat, pmat, rlo, rup] = r(obj, alpha)
            %R Pearson product-moment correlation coefficient btw. pdf and data
            %
            %   Considers only complete rows (i.e., omits rows containing NaN
            %   values).
            %   The Pearson correlation coefficient will be returned as NaN, if
            %       - the data or PDF size is below 3
            %       - the data or PDF variance is zero, infinite or undefined.
            %
            %   [LAZY] Lazy access of the correlation coefficient for a single
            %   output parameter, only.
            %
            % Input
            %   alpha   - [double] Significance level between 0 and 1.
            %           Default: 0.05
            %
            % Output
            %   r       - [numeric] Correlation coefficient ranging from -1 to 1,
            %           with -1 = direct, negative correlation, 0 = no
            %           correlation, and 1 = (perfect) direct, positive
            %           correlation.
            %   rmat    - [numeric] 2-by-2 matrix with the correlation
            %           coefficients along the off-diagonal.
            %   pmat    - [numeric] Matrix of p-values.
            %   rlo     - [numeric] Matrix of the 95% confidence interval lower
            %           bound for the corresponding coefficient in R. Use alpha
            %           to set the confidence level.
            %   rlo     - [numeric] Matrix of the 95% confidence interval upper
            %           bound for the corresponding coefficient in R. Use alpha
            %           to set the confidence level.
            %
            % See also
            %   corrcoef

            arguments
                obj
                alpha = 0.05
            end

            errorCause = 0;

            if ~isempty(obj.r_) && nargout == 1
                r = obj.r_;
            elseif anynan(obj.seg)
                errorCause = 1;
            elseif numel(obj.y) < GmaResults.MIN_PTNS || numel(obj.data) < GmaResults.MIN_PTNS
                errorCause = 2;
            elseif ~var(obj.data) || ~var(obj.y)
                errorCause = 3;
            else
                ds = obj.seg(1):obj.seg(2);
                ys = 1:numel(ds);

                if nargout <= 2
                    % Correlation only
                    rmat = corrcoef(obj.y(ys), obj.data(ds), Rows = "complete");
                elseif nargout < 3
                    % Correlation and p-values
                    [rmat, pmat] = corrcoef(obj.y(ys), obj.data(ds), Rows = "complete");
                else
                    % Correlation, p-values and boundaries of the correlation
                    % coefficient
                    [rmat, pmat, rlo, rup] = corrcoef(obj.y(ys), obj.data(ds), ...
                        Rows = "complete", Alpha = alpha);
                end

                r = rmat(1, 2);
                r(isnan(r)) = 0;
                obj.r_ = r;
            end

            if errorCause
                r = NaN;
                obj.r_ = r;
                rmat = nan(2, 2);
                pmat = nan(2, 2);
                rlo = nan(2, 2);
                rup = nan(2, 2);

                if nargout ~= 1
                    fprintf("[GmaResults] Correlation coefficient undefined. ");
                    switch errorCause
                        case 1
                            % Should never happen.
                            fprintf("Segment is not defined.\n");
                        case 2
                            fprintf("Data and PDF sizes must have a minimum " + ...
                                "length of 3.\n");
                        case 3
                            fprintf("Neither the data nor the PDF can have a " + ...
                                "variance of zero or infinite.\n");
                    end
                end
            end
        end

        function e = mse(obj)
            %mse Mean-squared error (MSE) between the pdf and the data.
            %
            % Output
            %   e   - [double] Mean-squared error (MSE) (mean-squared deviation,
            %       MSD) between the pdf and the data.

            if ~isempty(obj.mse_)
                e = obj.mse_;
            elseif anynan(obj.seg) || isempty(obj.y)
                e = NaN;
                obj.mse_ = e;
            else
                ds = obj.seg(1):obj.seg(2);
                ys = 1:numel(ds);
                e = (norm(obj.data(ds) - obj.y(ys), 2).^2) / numel(ds);
                obj.mse_ = e;
            end
        end

        function e = mae(obj)
            %mae Mean absolute error (MAE) of the paired Gamma PDF and the
            %observed data divided by the sample size.
            %
            % Description
            %   The mean absolute error (MAE) is scale-dependent. In comparison
            %   to the MSE or RMSE it is less biased by outliers.
            %
            % Output
            %   e   - [double] Mean absolute error (MAE) between the PDF and the
            %       observed data .

            if anynan(obj.seg) || isempty(obj.y)
                e = NaN;
            else
                ds = obj.seg(1):obj.seg(2);
                ys = 1:numel(ds);
                e = sum(abs(obj.data(ds) - obj.y(ys))) / numel(ds);
            end
        end

        function e = rmse(obj)
            %RMSE Root-mean-squared error (RMSE) between the PDF and the data.
            %
            % Description
            %   Returns a nonnegative number, where 0 would be a perfect fit and
            %   lower numbers indicate a better fit. The RMSE is scale-dependent
            %   and sensitive to outliers.
            %   Note: Same as MATLAB rmse (since R2022b)
            %
            % Output
            %   e   - [double] Root-mean-squared error (RMSE) or ...deviation
            %       (RMSD) between PDF and the observed data.
            %
            % See also
            %   rmse

            e = sqrt(obj.mse);
        end

        function e = nrmse(obj, norm)
            %NRMSE The residuals as normalized root-mean-squared error (nRMSE)
            %of the (predicted) PDF over the observed data sample.
            %
            % Description
            %
            %   General formula:
            %   nRMSE = abs(RMSE / abs(norm));
            %
            %   Values for normalization (norm) can be selected:
            %   'sd':     standard deviation of the observed data (default);
            %   'gamsd':  estimated standard deviation of the Gamma PDF using
            %             VAR_pdf = shape / rate^2, as in GammaDist.var;
            %   'mean':   the data mean; not very useful for data ranging
            %             containing positive and negative values.
            %   'range':  the range of the data max(data) - min(data)
            %   'iqr':    the interquartile range of the predicted Gamma PDF
            %             (Q3 - Q1), retrieved from the Gamma inverse cumulative
            %             distribution function (gaminv).
            %             Requires the Statistics and Machine Learning Toolbox
            %             (displays a warning if not found).
            %
            %   'dist':   NRMSE is calculated without the RMSE, as the Euclidean
            %             distance of the Gamma PDF and the data points divided
            %             by the Euclidean distance of the data points to their
            %             mean.
            %
            %   A minimum of two data points are required!
            %
            % Input
            %   norm    - [char] The norm value; any of: 'sd' - standard
            %   deviation (default), 'mean' - data mean, 'range' - data max-min,
            %   'iqr' - interquartile range of the predicted(!) PDF (Q3-Q1) or
            %   'dist' - which uses the euclidean distances.
            %
            % Output
            %   e   - [double] the normalized error measure NRMSE as a
            %   nonnegative number from zero to infinity, with 0 indicating a
            %   perfect fit. The NRMSE is not dependent on the data scale, but
            %   tends to be imprecise for small samples.
            %
            % See also
            %   mean, range, GammaDist.var, GammaDist.iqr, gaminv

            arguments
                obj
                norm{mustBeMember(norm, ...
                    {'sd', 'mean', 'range', 'iqr', 'gamsd', 'dist'})} = 'sd'
            end

            if anynan(obj.seg)
                e = NaN;
                return
            end

            obsData = obj.data(obj.seg(1):obj.seg(2));

            if numel(obsData) < 2
                e = NaN;
                fprintf("[GmaResults] Insufficient data points to calculate NRMSE.\n");
                return
            end

            switch norm
                case 'mean'
                    e = sqrt(obj.mse) / mean(obsData);
                case 'range'
                    e = sqrt(obj.mse) / vrange(obsData);
                case 'iqr'
                    e = sqrt(obj.mse) / obj.iqr;
                case 'gamsd'
                    e = sqrt(obj.mse / obj.var);
                case 'dist'
                    e = norm(obsData - obj.y(1:numel(obsData))) / ...
                        norm(obsData - mean(obsData));
                otherwise
                    % same: e = obj.rmse / std(obsData);
                    e = sqrt(obj.mse / var(obsData));
            end

            e = abs(e);
        end


        %% Export methods

        function dump(obj)
            %DUMP Display verbose results in command window.
            %
            % See also
            %   resultStr

            msg = obj.resultStr;
            disp(strjoin(msg, newline));
        end

        function tbl = asTable(obj)
            %asTable Return a table with the main results.
            %
            % Description
            %   For legacy compatibility ip1 and ip2 are named poi1 and poi2.
            %
            % Output
            %   tbl     - [table] A table with the common variables as columns,
            %           listed below with temporal measures in milliseconds
            %           'shape', 'rate', 'yscale', 'poi1', 'mode', 'poi2',
            %           'skew', 'excess', 'rmse', 'nrmse', 'r', 'fit',
            %           'inverted'.
            %
            % See also
            %   GmaResults.asStruct

            if isempty(obj.eegInfo)
                rf = 1;
                % Empty EEG info
                eegValues = {'n/a', '', 0, 0, 1, '', ''};
            else
                info = obj.eegInfo;
                rf = 1000 / info.srate;
                eegValues = {info.setname, info.chLabel, ...
                    info.srate, info.filename, info.filepath};
            end

            gmaValues = {obj.isInverted, obj.isFit, obj.win(1) * rf, obj.win(2) * rf, ...
                obj.seg(1) * rf, obj.seg(2) * rf, ...
                obj.shape, obj.rate, obj.yscale, obj.ip1 * rf, obj.mode * rf, obj.ip2 * rf, ...
                obj.skew, obj.excess, obj.mse, obj.rmse, obj.nrmse, obj.r};

            values = [eegValues, gmaValues];

            tbl = obj.emptyTable;
            tbl(1, :) = values;
        end

        function rStruct = asStruct(obj)
            %asStruct Return a struct with the main results.
            %
            % Description
            %   For legacy compatibility ip1 and ip2 are named poi1 and poi2.
            %
            % Output
            %   rStruct - [struct] A table with the common variables as fields,
            %           listed below with unitless temporal measures (data
            %           points) 'shape', 'rate', 'yscale', 'poi1', 'mode',
            %           'poi2', 'skew', 'excess', 'rmse', 'nrmse', 'r', 'fit',
            %           'inverted'.
            %
            % See also
            %   GmaResults.asTable

            resFlds = {'shape', 'rate', 'yscale', 'poi1', 'mode', 'poi2', ...
                'skew', 'excess', 'rmse', 'nrmse', 'r', 'fit', 'inverted'};
            resDat = num2cell([obj.shape, obj.rate, obj.yscale, obj.ip1, ...
                obj.mode, obj.ip2, obj.skew, obj.excess, obj.rmse, ...
                obj.nrmse, obj.r, obj.isFit, obj.isInverted]);
            rStruct = cell2struct(resDat(:), resFlds(:));
        end

        function msg = resultStr(obj)
            %resultStr The main results as string array
            %
            % Output
            %   str     - [string] Common result variables formatted to be
            %           printed in the command window.

            function str = prnFld(label, value, dec)
                if nargin < 3, dec = 3; end
                str = sprintf(['%s=%.', num2str(dec), 'f'], ...
                    label, value);
            end

            msg = "";

            if obj.isFit, successStr = "Successful";
            else, successStr = "NO"; end
            msg(end + 1) = sprintf("%s GMA fit of mode inside search window " + ...
                "between [%i, %i] samples.", successStr, obj.win);

            if obj.isInverted
                msg(end + 1) = "Original data was INVERTED to achieve a fit.";
            end

            msg(end + 1) = sprintf("%s\t%s\t%s", prnFld("shape", obj.shape), ...
                prnFld("rate", obj.rate), prnFld("yscale", obj.yscale));
            msg(end + 1) = sprintf("%s\t%s", ...
                prnFld("skewness", obj.skew), prnFld("excess", obj.excess));
            msg(end + 1) = sprintf("%s\t%s\t%s\t%s", prnFld("ip1", obj.ip1), ...
                prnFld("mode", obj.mode), prnFld("ip2", obj.ip2));
            msg(end + 1) = sprintf("%s\t%s\t%s", ...
                prnFld("rmse", obj.rmse, 4), prnFld("nrmse", obj.nrmse, 4), ...
                prnFld("r", obj.r, 4));
        end
    end


    %% Protected methods

    methods (Access = protected)

        function onChangeY(obj)
            %onChangeY Called whenever y values of the Gamma PDF changed.

            obj.invalidate();
        end

        function onChangeX(obj)
            %onChangeX Called whenever x values of the Gamma PDF changed.

            obj.invalidate();
        end

        function onChangeData(obj, oldData, newData)
            %onChangeData Called whenever the data or the segment changed.
            %
            % Description
            %   Updates the offset the x values of the pdf, in case the
            %   segment was padded.
            %   Invalidates all dependent measures (correlations, error
            %   measures).

            % Update the segment, in case data shrinked.
            if nargin > 1 && numel(oldData) > numel(newData)
                obj.seg = obj.seg;
            end

            obj.invalidate();
        end

        function invalidate(obj)
            %INVALIDATE Resets properties dependent on y and data.
            %
            % Description
            %   Resets the correlation coefficient r and the error measure mse,
            %   which also affects the dependent rmse and nrmse('sd').

            obj.r_ = [];
            obj.mse_ = [];
        end
    end


    %% Private methods

    methods (Access = private)

        function seg = getValidSegment(obj, v)
            %updateSeg Return a segment fitting inside the data and the PDF x
            %
            %Description
            %   The segment's start and end indices (sorted) must meet the
            %   minimum length of 3 (as defined in GmaResults.MIN_PTNS) and fit
            %   within the indice ranges of the PDF x and data x. Otherwise the
            %   funtion will try to move the segment them to fit at start or end
            %   of the possible range within the x values – whatever is closer.
            %   NaN and zero inputs will pass as NaN, as an invalid segment.
            %
            % Input
            %   v       - [double {integer}] The start and end index of the
            %           segment.

            if anynan(obj.data) || anynan(obj.x) || anynan(v) || ~all(v)
                seg = [NaN, NaN];
            else
                v = sort(fix(v));
                s1min = max(1, obj.x(1));
                s2max = min(obj.x(end), numel(obj.data));

                limV = [max(v(1), s1min), min(v(2), s2max)];

                if limV(2) - limV(1) + 1 < GmaResults.MIN_PTNS
                    % segment is too short or scalar and property auto-expanded.
                    if any(([v(2), limV(2)] + GmaResults.MIN_PTNS - 1) > s2max)
                        v(2) = s2max;
                        v(1) = s2max - GmaResults.MIN_PTNS + 1;
                    else
                        if any([v(1), limV(1)] < s1min)
                            v(1) = s1min;
                        end
                        v(2) = v(1) + GmaResults.MIN_PTNS - 1;
                    end
                end
                seg = [max(v(1), s1min), min(v(2), s2max)];
            end
        end

    end


    %% Static methods


    methods (Static)

        function [info, version, date] = version()
            %VERSION Version information as composed string
            %
            % Output
            %   info    - [string] Class name, version number
            %           (Major.Minor.Patch) and release date (yyyy-mm-dd).
            fname = mfilename;
            version = GmaResults.REL_VERSION;
            date = GmaResults.REL_DATE;
            info = sprintf("%s v%s (%s)", fname, version, date);
        end

        function tbl = emptyTable(rows)
            % emptyTable Create an empty table with common result variables
            %
            % Description
            %   A convenience function for creating tables for pre-allocation or
            %   export with named colunms, the data type and with units
            %   (in milliseconds, 'ms', if applicable).
            %
            %   The included columns contain meta information about the data
            %   (file name, channel, sampling rate ...), the basic PDF
            %   parameters  and the fitting results (time-dependent,
            %   shape-dependend as well as correlation and error measures).
            %
            % Input
            %   rows    - [double {integer}] Number of rows for the new table.
            %           Default: 0.
            %
            % Output
            %   tbl     - [table] A table with the common result variables

            if nargin < 1, rows = 0; end

            eegFlds = {'eegName', 'eegChLabel', ...
                'eegRate', 'eegFile', 'eegPath'};
            eegTypes = {'string', 'string', ...
                'double', 'string', 'string'};

            eegUnits = ["", "", "Hz", "", ""];


            gmaFlds = {'inverted', 'fit', 'win1', 'win2', ...
                'seg1', 'seg2', ...
                'shape', 'rate', 'yscale', 'ip1', 'mode', 'ip2', ...
                'skew', 'excess', 'mse', 'rmse', 'nrmse', 'r'};

            gmaTypes = {'logical', 'logical', 'double', 'double', ...
                'double', 'double', ...
                'double', 'double', 'double', 'double', 'double', 'double', ...
                'double', 'double', 'double', 'double', 'double', 'double'};

            gmaUnits = ["", "", "ms", "ms", ...
                "ms", "ms", ...
                "", "", "", "ms", "ms", "ms", ...
                "", "", "", "", "", ""];

            varnames = [eegFlds, gmaFlds];
            types = [eegTypes, gmaTypes];
            units = [eegUnits, gmaUnits];
            fldCnt = numel(varnames);

            tbl = table(Size = [rows, fldCnt], VariableNames = varnames, ...
                VariableTypes = types);
            tbl.Properties.VariableUnits = units;
        end

        function info = emptyEegInfo()
            %emptyEegInfo Minimum (default) EEG Info struct
            %
            % Output
            %   info    - [struct] Struct with the default minimum required
            %           fields 'type', 'setname' and 'srate' to be stored in
            %           eegInfo, with type = GmaResults.EEG_INFO_TYPE and
            %           srate = 1.
            info = struct;
            info.type = GmaResults.EEG_INFO_TYPE;
            info.setname = '';
            info.srate = 1;
        end

        function valid = isEegInfo(infoStruct)
            % isEegInfo Checks, if a struct is a valid GmaResults EEG Info
            %
            % Input
            %   infoStruct  - [struct] Struct to be checked.
            %
            % Output
            %   valid       - [logical] true, if infoStruct is a struct with the
            %               minimum required fields 'type', 'setname' and
            %               'srate', where type equals GmaResults.EEG_INFO_TYPE.

            valid = false;
            if ~isstruct(infoStruct), return; end

            reqFields = fieldnames(GmaResults.emptyEegInfo);
            if all(isfield(infoStruct, reqFields)) && ...
                    strcmp(infoStruct.type, GmaResults.EEG_INFO_TYPE)
                valid = true;
            end
        end

    end
end
