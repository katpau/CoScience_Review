%gmaFitEeg Gamma Model Analysis fits a Gamma PDF for EEG data
%
%% Syntax
%
%   fitResult = gmaFitEeg(EEG);
%   fitResult = gmaFitEeg(EEG, eegChannel);
%   fitResult = gmaFitEeg(EEG, eegChannel, 50);
%   fitResult = gmaFitEeg(EEG, eegChannel, 50, 100);
%   fitResult = gmaFitEeg(EEG, eegChannel, 50, 100, invData = true);
%   [fitResult, initialGuess, argsUsed] = gmaFitEeg(EEG, eegChannel);
%
%% Description
%   A comfort wrapper for <a href="matlab:help('gmaFit')">gmaFit</a> to faciliate the usage of EEG data in the
%   EEGLAB (struct) format or with a lesser extend a struct with the minimum
%   fields 'data', 'setname' and 'srate'.
%
%   The data can be selected from the EEG channels and inverted. Most of all,
%   after the GMA is fitted, the EEG sampling rate, name and other meta data
%   will be added to the GmaResults (via GmaResults.addEegInfo), as well as the
%   arguments used by gmaFit. This information can be retrieved from the fields
%   of the result's GmaResults.eegInfo.
%
%% Input
%   EEG             - [struct] A struct containing the data and meta information
%                   which must at least contain the fields 'data', 'setname' and
%                   'srate'. The channels in data will be accessed as rows.
%                   Ideally this should be an EEGLAB EEG struct or contain the
%                   same fields.
%   chIdx           - [double {integer}] The index of the channel, i.e., the row
%                   in the field 'data' which will be passed to gmaFit.
%   winStart        - [numeric {integer}] Just passed to gmaFit: First data
%                   point of the search window for the component of interest
%                   (default = 1).
%   winLength       - [numeric {integer}] Just passed to gmaFit: Length of the
%                   search window for the component of interest.
%
%   [Optional] Name-value parameters
%   invData         - [logical] true: the polarity of the EEG data's selected 
%                   channel (chIdx) will be reversed (data * -1), before being 
%                   committed to gmaFit;
%                   false (default): the data will not be inverted.
%
%   The remaining optional parameters are passed unvalidated to <a href="matlab:help('gmaFit')">gmaFit</a>.
%
%% Output
%   result      - [<a href="matlab:help('GmaResults')">GmaResults</a>] Instance
%               containing the optimized results.
%   x0          - [double] parameters of the initial guess by the presearch as
%               shape, rate and y-scaling values in a vector.
%   argsUsed    - [struct]
%
%
%% See also
%   gmaFit, isEegStruct, GmaResults, GmaResults.addEegInfo

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

function [results, x0, argsUsed] = gmaFitEeg(EEG, chIdx, winStart, winLength, args)

    arguments
        EEG(1, 1) struct
        chIdx(1, 1) {mustBeInteger, mustBePositive} = 1
        winStart(1, 1) {mustBeInteger, mustBePositive} = 1
        winLength(1, 1) {mustBeInteger, mustBePositive} = max(1, size(EEG.data, 2))
        args.invData(1, 1) logical = false

        % The following are just passed to gmaFit (no checks here)
        args.optimizeFull
        args.segMinLength
        args.segPad
        args.segExtension
        args.maxSrcIt
        args.logEnabled
        args.logSrc
        args.logFn
        args.costFn
        args.psType
        args.psMaxIt
        args.xtol
        args.ftol
    end

    [isGmaViable, isEegLike] = isEegStruct(EEG);

    % EARLY EXIT if check minimal of requirements of the EEG-like struct fails
    if ~isGmaViable || ~numel(EEG.data)
        eidType = 'gmaFitEeg:invalidStruct';
        msgType = ['Invalid EEG-like struct.\n', ...
            'Input must be a valid EEGLAB structure or at least a struct \n', ...
            'with the fields ''data'', ''setname'' and ''srate''.\n', ...
            'The data channels (rows) must not be empty.'];
        throw(MException(eidType, msgType))
    end

    if isEegLike && EEG.trials > 1
        warning(['The EEG contains multiple trials (epochs).', newline, ...
            'Use a single trial or averaged data for GMA.']);
    end

    if chIdx > size(EEG.data, 1)
        error("Channel index out of range.");
    end

    data = EEG.data(chIdx, :);
    if args.invData
        data = data * -1;
    end

    params = namedargs2cell(args);

    [results, x0, argsUsed] = gmaFit(data, winStart, winLength, params{:});
    try
        EEG.etc.gma.argsUsed = argsUsed;
        EEG.etc.gma.x0 = x0;
        results.addEegInfo(EEG, chIdx);
    catch ME
        warning(ME.identifier, ...
            "Adding EEG info to GmaResults failed. Error: %s", ME.message);
    end
end
