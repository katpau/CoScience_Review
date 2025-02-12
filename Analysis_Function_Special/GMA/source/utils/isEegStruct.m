% isEegStruct Check if the EEG struct is viable for GMA (or even EEGLAB-like).
% 
%% Syntax
%	isViable = isEegStruct(EEG);
%   [isGmaViable, isEegLike] = isEegStruct(EEG);
%   [isGmaViable, isEegLike, isEEGLAB] = isEegStruct(EEG);
%
%% Description
%   Checks if the fields required to be stored in GmaResults are present and if 
%   so, to what extend. The minimum of required fields 'data', 'setname' and
%   'srate', which renders the first output (isGmaViable) to true.
%   If so, the struct can be used for GmaResults.addEegInfo or gmaFitEEG.
%
%   With two output arguments, the function checks all fields, typically present
%   in EEGLAB data (as of v2022.0).
%   If true, the struct can be used to store extended informatin via
%   GmaResults.addEegInfo.
%
%   With three output arguments, EEGLAB's eeg_checkset is used to verify the EEG
%   struct validity. This is not necessary to be use in GmaResults.
%
%% Input
%   EEG             - [struct] A struct, which is supposedly EEGLAB compatible. 
%
%% Output
%   isGmaViable     - [logical] true: the minimum of required fields 'data', 
%                   'setname' and 'srate' are present. Otherwise: false.
%   isEegLike       - [logical] true: all fields, typically present in EEGLAB 
%                   data are present (channel locations are not validated!); 
%                   false, otherwise.
%   isEEGLAB        - [logical] true: the struct passes a check by EEGLAB's 
%                   eeg_checkset without error.
%   EEG             - [struct] A struct containing the data and meta information
%                   which must at least contain the fields 'data', 'setname' and
%                   'srate'. The channels in data will be accessed as rows.
%                   Ideally this should be an EEGLAB EEG struct or contain the
%                   same fields.
%
%% See also
%   gmaFitEEG, GmaResults, GmaResults.addEegInfo


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

function [isGmaViable, isEegLike, isEEGLAB] = isEegStruct(EEG)
    
    isEegLike = false;
    isEEGLAB = false;

    % Check if the struct at least contains the essential fields for GMA
    reqGmaFields = {'data', 'setname', 'srate'};
    isGmaViable = all(isfield(EEG, reqGmaFields));

    %% EARLY EXIT
    if ~isGmaViable || nargout == 1
        return;
    end

    % Check all necessary EEGLAB fields as of v2022.0 without using eeg_checkset
    eegFields = {'setname', 'filename', 'filepath', 'subject', 'group', ...
        'condition', 'session', 'comments', 'nbchan', 'trials', 'pnts', ...
        'srate', 'xmin', 'xmax', 'times', 'data', 'icaact', 'icawinv', ...
        'icasphere', 'icaweights', 'icachansind', 'chanlocs', 'urchanlocs', ...
        'chaninfo', 'ref', 'event', 'urevent', 'eventdescription', 'epoch', ...
        'epochdescription', 'reject', 'stats', 'specdata', 'specicaact', ...
        'splinefile', 'icasplinefile', 'dipfit', 'history', 'saved', 'etc'};

    isEegLike = all(isfield(EEG, eegFields));

    if nargout > 2
        % Check if EEGLAB's eeg_checkset function is available and in a path
        % containing 'eeglab' (a bit of an unsave check).
        csPath = which('eeg_checkset');
        if contains(csPath, 'eeglab')
            try
                eeg_checkset(EEG);
                isEEGLAB = true;
            catch
                isEEGLAB = false;
            end
        end
    end
end