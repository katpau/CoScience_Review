%gmaFit – Gamma Model Analysis fits a Gamma PDF on data using GRNMA
%
%% Syntax
%   fitResult = gmaFit(channelData);
%   fitResult = gmaFit(channelData, 50);
%   fitResult = gmaFit(channelData, 50, 100);
%   fitResult = gmaFit(channelData * -1, invData = 1);
%   [fitResult, initialGuess, argsUsed] = gmaFit(channelData);
%
%% Description
%   Fits an initial guess of a Gamma probability density function on the largest
%   nonnegative interval (LNNI), found in  in the data and optimizes the fit
%   using Grid Restrained Nelder-Mead Algoritm (GRNMA).
%
%   GMA was developed by Kummer et al. (2020) to investigate empirical
%   event-related potential (ERP) components, by fitting a Gamma PDF on the EEG
%   data. The results provide specific shape-related and time-related parameters
%   of an ERP component.
%
%   This function works in multiple steps, given a data vector and time window
%   for a valid mode of a potential PDF, which could be fitted on it.
%   The default steps run as follows if each is successful:
%   1.  Find the (first) largest nonnegative interval (LNNI) with a minimum
%       length 20 data points (see <a href="matlab:help('nnegIntervals')">nnegIntervals</a>),
%       which intersects with the time window.
%   2.  Add zeros before the first point of the LNNI up to the first index in
%       the data (e.g. for an LNNI of [10, 55] nine zeros would be inserted).
%   3.  The parameters of a Gamma PDF will be estimated for the zero padded
%       LNNI, using close-form estimation (Ye & Chen, 2017,
%       see <a
%       href="matlab:help('presearch_closeform')">presearch_closeform</a>). The PDF mode must be within the time window.
%   4.  This initial fit will be optimized, using the Grid Restrained
%       Nelder-Mead Algorithm (Bűrmen et al., 2006, see <a href="matlab:help('grnma')">grnma</a>).
%   5.  The resulting (or any unsuccessful) fit will be returned as an instance
%       of the <a href="matlab:help('GmaResults')">GmaResults</a> class, which allows to access various parameters and
%       error measures. A successfully optimized fit, has real number
%       parameters, a mode inside the time window and correlates positively with
%       the data.
%
%   Notes:
%   The zero-padding of the PDF enhances the fit of data components, which are
%   close to the data limits and when fitting nonnegative intervals. It also
%   facilitates the comparison between the PDF parameters for data epochs of the
%   same length, but with different interval positions.
%
%   The precision of the method is limited by the underlying Gamma PDF
%   approximation (<a href="matlab:help('gammaPdf')">gammaPdf</a>), based on Lanczos (1964) algorithm which is
%   computationally fast but may deviate from more accurate estimations given
%   its relative error (below 2.0e-10). Nevertheless higher tolerances in the
%   optimization may yield slightly better results.
%
%% References
%   Bűrmen, Á., Puhan, J., & Tuma, T. (2006). Grid Restrained Nelder-Mead
%   Algorithm. Computational Optimization and Applications, 34(3), 359-375.
%   https://doi.org/10.1007/s10589-005-3912-z
%
%   Kummer, K., Dummel, S., Bode, S., & Stahl, J. (2020). The gamma model
%   analysis (GMA): Introducing a novel scoring method for the shape of
%   components of the event-related potential. J Neurosci Methods, 335, 108622.
%   https://doi.org/10.1016/j.jneumeth.2020.108622
%
%   Lanczos, C. (1964). A precision approximation of the gamma function. Journal
%   of the Society for Industrial and Applied Mathematics, Series B: Numerical
%   Analysis, 1(1), 86-96. https://doi.org/10.1137/070100
%
%   Ye, Z.-S., & Chen, N. (2017). Closed-Form Estimators for the Gamma
%   Distribution Derived From Likelihood Equations. The American Statistician,
%   71(2), 177-181. https://doi.org/10.1080/00031305.2016.1209129
%
%% Input
%   data            - [numeric] 1-dim array (vector) to fit
%   winStart        - [numeric {integer}] First data point of the search window
%                   for the component of interest; must be 1 ≤ winStart ≤
%                   length(data); (default = 1). The mode of the resulting
%                   fitted function must be greater or equal than winStart to
%                   pass as successful.
%   winLength       - [numeric {integer}] Length of the search window for the
%                   component of interest, from winStart in data points; must be
%                   winLength ≤ length(data) - (winStart - 1). Excessive values
%                   will be adjusted to the maximum length, which is also the
%                   default: winLast = max(1, length(data) - (winStart - 1)).
%                   The mode of the resulting fitted function must be less or
%                   equal than winStart to pass as successful.
%
%   [Optional] Name-value parameters
%   invData         - [logical] true: indicates that the data' polarity was 
%                   inverted (data * -1) before entering this function; 
%                   false (default): the data passed was not inverted. 
%                   This flag is purely informative, included in the results.
%   optimizeFull    - [logical] Sets the scope ot the GRNMA optmization to
%                   either the largest nonnegative interval with false (default)
%                   or the full data with true.
%   segMinLength    - [uint32] The minimum amount of consecutive nonnegative
%                   data points in the data. Default: 20 (data points).
%                   If no nonnegative intervals were found, the function exits
%                   early and does not try to fit a PDF. The close-form
%                   pre-search performs less reliable below 20 and cannot
%                   operate below three data points.
%   segPad          - [double {integer}] Amount of inserted zeros (zero-padding)
%                   before and after the largest nonnegative interval as a
%                   vector of two nonnegative values. If segExtension is set to
%                   true or values are infinite, they will always be limited to
%                   the data limits [1, numel(data)].
%                   Default: [inf, 0] will only zero-pad forward, which keeps
%                   the PDF parameters relative to the beginning of the data.
%   segExtension    - [logical] false (default) Allows the zero-padding (as set
%                   in segPad to exceed the original limits of the data.
%   maxSrcIt        - [numeric {integer}] Maximum iterations for the
%                   optimization function (here the Grid-restrained Nelder-Mead
%                   algorithm). (default = 1000)
%   logEnabled      - [logical] true (default): without another costFn set, logs
%                   messages to the command window (via fprintf()), false:
%                   disables output (using a NOP function).
%   logSrc          - [logical] true = logs the GRNMA search step messages in
%                   detail (which is a lot!); false (default) does not log any
%                   search messages, saving system ressources.
%   logFn           - [function handle] Any function taking a format
%                   specification (as in sprintf) and a variable amount of text
%                   arguments (varargin), which should be used for logging.
%                   A valid function handle sets logEnabled to true.
%   costFn          - [function handle] A cost function wrapping any objective
%                   function, used to determine the cost (e.g. the MSE) of a
%                   solution during the optimization. Default: @meeseeks (MSE
%                   cost).
%                   A custom function must take two arguments: the data and a
%                   vector containg the objective function parameters. It must
%                   return a scalar result (e.g. the mean square error).
%   psType          - [string] Type of pre-search for the initial guess:
%                   'closeform' (default): uses closed-form estimation, the
%                   fastest and the recommended method, resulting in the best
%                   guesses for most data.
%                   'random': uses random integers for shape, rate and scaling
%                   to find the lowest cost for a parameter set with a PDF with
%                   the search window.
%                   'random2': experimental(!) version of 'random' for small
%                   data samples, using more plausible ranges of random values
%                   and usually less iterations.
%   psMaxIt         - [numeric {integer}] Maximum iterations for the pre-search
%                   optimization function (used for the random pre-search types,
%                   ignored for the close-form search). Must be a positive value
%                   or 0 to use a pre-search's default (default = 0).
%   psRespectWin    - [logical] default: true
%   xtol            - [double] lower boundary for the absolute tolerance of
%                   differences for each step in the data, as used in the GRNMA.
%                   For more details, please consult the <a href="matlab:help('grnma')">grnma</a> help. (default =
%                   1e-8).
%   ftol            - [double] lower boundary of the absolute tolerance of value
%                   differences for the objective function. For more details,
%                   please consult the <a href="matlab:help('grnma')">grnma</a> help. (default = 1e-8)
%
%% Output
%   result      - [<a href="matlab:help('GmaResults')">GmaResults</a>] Instance
%               containing the optimized results.
%   x0          - [double] parameters of the initial guess by the presearch as
%               shape, rate and y-scaling values in a vector.
%
%% See also
%   GmaResults, nnegIntervals, grnma, gammaPdf,
%   presearch_random, presearch_random2, presearch_closeform, meeseeks

%% Attribution
%	Last author: Olaf C. Schmidtmann, last edit: 06.07.2023
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

function [result, x0, argsUsed] = gmaFit(data, winStart, winLength, args)
    arguments
        data(1, :) double
        winStart(1, 1) {mustBeInteger, mustBePositive} = 1
        winLength(1, 1) {mustBeInteger, mustBePositive} = length(data) - (winStart - 1)
        args.invData(1, 1) logical = false
        args.optimizeFull(1, 1) logical = false
        args.segMinLength(1, 1) uint32 = 20
        args.segPad(2, 1) double{mustBeNonnegative} = [inf, 0]
        args.segExtension(1, 1) logical = false
        args.maxSrcIt(1, 1) {mustBeInteger, mustBePositive} = 1000
        args.logEnabled(1, 1) logical = true
        args.logSrc(1, 1) logical = false
        args.logFn(1, 1) {mustBeA(args.logFn, 'function_handle')}
        args.costFn(1, 1) {mustBeA(args.costFn, 'function_handle')} = @meeseeks
        args.psType{mustBeMember(args.psType, {'random', 'random2', 'closeform'})} = 'closeform'
        args.psMaxIt(1, 1) {mustBeInteger} = 0
        args.psRespectWin(1, 1) logical = true
        args.xtol(1, 1) {mustBeInRange(args.xtol, 2.2204e-16, 1)} = 1e-8
        args.ftol(1, 1) {mustBeInRange(args.ftol, 2.2204e-16, 1)} = 1e-8
    end

    %% Constants

    % Fitting less than 3 data points would be useless (recommended min. is 20).
    SEG_MIN_PNTS = 3;

    nData = length(data);

    %% Validate arguments

    % Validate / enable logging
    if exist('args', 'var') && isfield(args, 'logFn')
        try
            logger = args.logFn;
            logger("Logger initialized" + newline);
        catch
            warning("Logging function handle invalid. Must be a a function " + ...
                "which accepts at least one char/string input.");
        end
    else
        % Use built-in loggers
        if args.logEnabled
            logger = @dumpFn;
        else
            logger = @NOP;
        end
    end

    % Validate search in-point
    if winStart > nData
        error(['The first data point for the search (winStart = %i) ', ...
            'cannot exceed length(data) = %i.', newline, ...
            'Please revisit the parameters.'], winStart, nData);
    end

    % Validate search window length
    maxWin = nData - (winStart - 1);
    if winLength > maxWin
        logger(['The search time window (%i data points) cannot ', ...
            'be longer than the data (%i samples).', newline, ...
            'Search window was adjusted to %i.'], ...
            winLength, nData, maxWin);
        winLength = maxWin;
    end
    % mode window
    mWin = [winStart, winStart + winLength - 1];

    % Check the cost function and if ok, insert the nonnegative interval
    if nargin(args.costFn) ~= 2
        error("The cost function must accept two parameters:\n a data " + ...
            "vector and a 3-column-vector of Gamma parameters for shape, " + ...
            "rate and a data scaling factor.");
    end

    %% Store arguments
    argsUsed = args;
    argsUsed.data = num2str(length(data));
    argsUsed.winStart = winStart;
    argsUsed.winLength = winLength;
    argsUsed.costFn = ['@', char(args.costFn)];
    argsUsed.logFn = ['@', char(logger)];

    logger('Gamma Model Analysis - Started')


    %% Find the longest viable interval of nonnegative values
    % which sufficiently overlaps the search window, i.e. could contain a mode.
    args.segMinLength = max(args.segMinLength, SEG_MIN_PNTS);
    [x0seg, ivMsg] = maxPosInterval(data, mWin, args.segMinLength, ...
        round(args.segMinLength * 0.5));
    logger(ivMsg);

    if isempty(x0seg)
        logger("[gmaFit] Aborted. No fitting nonnegative interval " + ...
            "(with min. samples=%i) found.", args.segMinLength);
        % EXIT with failed results.
        result = GmaResults(NaN, NaN, 1, data, win = mWin, seg = [NaN, NaN], ...
            isInverted = args.invData, isFullOpt = args.optimizeFull);
        x0 = [NaN, NaN, NaN];
        return;
    end


    %% Prepare data for the cost function of the pre-search and optimization
    % Prepare data for the cost function.
    dataSeg = data(:, x0seg(1):x0seg(2));
    nSeg = x0seg(2) - x0seg(1) + 1;

    % (Optional) Pad segment data, using padding factors.
    % Insert zeros ahead of the segment (factor times segments length).
    % If an extension is not allowed, the padded parts cannot exceed the data
    % limits. Inf values will always be limited to the data limits.
    xsegPre = 0;
    if args.segPad(1)
        xsegPre = round(args.segPad(1));
        if ~args.segExtension || isinf(args.segPad(1))
            xsegPre = min(x0seg(1) - 1, xsegPre);
        end
    end

    % Insert zeros after the segment (factor times segments length).
    xsegPost = 0;
    if args.segPad(2)
        xsegPost = round(args.segPad(2));
        if ~args.segExtension || isinf(args.segPad(2))
            xsegPost = min(nData - x0seg(2), xsegPost);
        end
    end

    logger("Data segment padded by [%i, %i]", xsegPre, xsegPost);

    % Data segment (with optional padding) embedded in cost function.
    dataSeg = [zeros(1, xsegPre), dataSeg, zeros(1, xsegPost)];
    costFn = @(p) args.costFn(dataSeg, p);
    gX = xsegPre + 1:xsegPre + nSeg;


    %% Initalize pre-search to find an initial guess
    % x0: Gamma PDF (rate, shape) and y-scaling factor

    logger('Start - Pre-Search');

    if args.psRespectWin
        preMwin = mWin - x0seg(1) + xsegPre;
    else
        preMwin = [1, numel(dataSeg)];
    end


    if strcmp(args.psType, 'random')
        % pre-search minimizing MSE using random parameters
        x0 = presearch_random(costFn, preMwin, imax = args.psMaxIt);
    elseif strcmp(args.psType, 'random2')
        % pre-search minimizing MSE using optimized random parameters
        x0 = presearch_random2(costFn, preMwin, imax = args.psMaxIt);
    else
        % pre-search using closed-form estimators within rel. search window
        x0 = presearch_closeform(dataSeg, 2, preMwin);
    end

    if anynan(x0)
        logger("[gmaFit] Initial guess is invalid or out of range.");
        % EARLY EXIT with NaN results, but provide the segment as information.
        result = GmaResults(NaN, NaN, 1, data, seg = x0seg, win = mWin, ...
            isInverted = args.invData, isFullOpt = args.optimizeFull);
        return;
    end


    %% (Optional) Full GRNMA optmization
    if args.optimizeFull
        % Use the all available data (instead of the nonnegative interval, only)
        % to optimize the PDF.
        costFn = @(p) args.costFn(data, p);
    end


    %% GRNMA Optmization
    % Start main search / optimization for the data, using the nelder-mead
    % algorithm with an initial guess and a cost function to minimize

    logger('Start - GRNMA Optimization')
    logger("Initial guess: shape=%g, rate=%g, yscale=%g", x0);

    [~, gFit, exitFlag, niter] = grnma(costFn, x0, args.maxSrcIt, ...
        logFn = logger, verbose = args.logSrc, xtol = args.xtol, ftol = args.ftol);

    logger("GRNMA exit flag: %i, iterations: %i", exitFlag, niter);


    %% Results
    % Create instance containing the fitted Gamma PDF and the results for the
    % orignal (unpadded) segment.
    result = GmaResults(gFit(1), gFit(2), gFit(3), data, ...
        gX, seg = x0seg, win = mWin, ...
        isInverted = args.invData, isFullOpt = args.optimizeFull);

    logger(newline, 'Gamma Model Analysis - Finished');

    %% Display Results
    if args.logEnabled; logger(result.resultStr); end
end

function [iv, msg] = maxPosInterval(data, win, minLength, minOverlap)
    %maxPosInterval Get the (first) largest nonnegative interval within a time
    %window
    %
    %   Returns the full interval, even if it only partly overlaps the window
    %   between the indices, i.e.

    arguments
        data (1, :)
        win = [1, numel(data)]
        minLength = 1
        minOverlap = 1
    end

    iv = [];

    % Search intervals of nonnegative values, both open and closed
    nnegIv = nnegIntervals(data);

    if isempty(nnegIv)
        msg = "No nonnegative intervals found in the data.";
        return;
    end

    % All intervals intersecting the window (from..to)
    ivWin = nnegIv(:, win(2) - nnegIv(1, :) >= minOverlap - 1 & ...
        nnegIv(2, :) - win(1) >= minOverlap - 1);
    ivWinInside = [max(ivWin(1, :), win(1)); min(ivWin(2, :), win(2))];

    if isempty(ivWinInside)
        msg = sprintf("No nonnegative intervals within the search window " + ...
            "[%i, %i] found.", win(1), win(2));
        return;
    end

    % Remove anything below the minimum length and select the largest
    ivSizes = diff(ivWinInside);
    minMask = ivSizes >= minLength;
    ivSizes = ivSizes(minMask);

    if isempty(ivSizes)
        msg = sprintf("No nonnegative intervals of sufficient length (%i " + ...
            "samples) found within the search window [%i .. %i].", ...
            minLength, win(1), win(2));
        return;
    end

    ivWin = ivWin(:, minMask);
    [~, maxIdx] = max(ivSizes);
    iv = ivWin(:, maxIdx);
    msg = sprintf("Largest nonnegative interval found at [%i, %i].", iv');
end

% Local function to handle console outputs, used as nested function
function dumpFn(fmt, varargin)
    if ~isempty(varargin), txt = sprintf(fmt, varargin{:});
    else, txt = fmt; end
    fprintf('%s\n', txt);
end

function NOP(varargin)
    %NOP Do nothing
end
