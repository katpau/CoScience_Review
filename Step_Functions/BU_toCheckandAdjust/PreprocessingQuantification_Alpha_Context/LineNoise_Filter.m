function  OUTPUT = LineNoise_Filter(INPUT, Choice)
% This script does the following:
% Depending on the forking choice, it applies a line noise filter as
% implemented in the PREP pipeline, or not

% It is able to handle all options from "Choices" below (see Summary).


%#####################################################################
%### Usage Information                                         #######
%#####################################################################
% This function requires the following inputs:
% INPUT = structure, containing at least the fields "Data" (containing the
%       EEGlab structure, "StephHistory" (for every forking decision). More
%       fields can be added through other preprocessing steps.
% Choice = string, naming the choice run at this fork (included in "Choices")
%
% This function gives the following output:
% OUTPUT = struct, similiar to the INPUT structure. StepHistory and Data is
%           updated based on the new calculations. Additional fields can be
%           added below


%#####################################################################
%### Summary from the DESIGN structure                         #######
%#####################################################################
% Gives the name of the Step, all possible Choices, as well as any possible
% Conditional statements related to them ("NaN" when none applicable).
% SaveInterim marks if the results of this preprocessing step should be
% saved on the harddrive (in order to be loaded and forked from there).
% Order determines when it should be run.
StepName = "LineNoise_Filter";
Choices = ["PREP", "None"];
Conditional = ["NaN", "NaN"];
SaveInterim = logical([1]);
Order = [6];

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
tic % for keeping track of time
try % For Error Handling, all steps are positioned in a try loop to capture errors
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    % ****** Apply Line Noise Filter ******
    if strcmpi(Choice, "PREP")
        % Get EEGlab EEG structure from the provided Input Structure
        EEG = INPUT.data;
        % initiate struct with all relevant setting
        lineNoiseIn = struct('lineNoiseMethod', 'clean', ...
            'lineNoiseChannels', 1:EEG.nbchan,...
            'Fs', EEG.srate, ...
            'lineFrequencies', [50 100 150 200],...
            'p', 0.01, ...
            'fScanBandWidth', 2, ...
            'taperBandWidth', 2, ...
            'taperWindowSize', 4, ...
            'taperWindowStep', 4, ...
            'tau', 100, ...
            'pad', 2, ...
            'fPassBand', [0 EEG.srate/2], ...
            'maximumIterations', 10);
        
        % Apply Filter
        [EEG, ~] = cleanLineNoise(EEG, lineNoiseIn);
        
        
        
        %#####################################################################
        %### Wrapping up Preprocessing Routine                         #######
        %#####################################################################
        % ****** Export ******
        % Script creates an OUTPUT structure. Assign here what should be saved
        % and made available for next step. Always save the EEG structure in
        % the OUTPUT.data field, overwriting previous EEG information.
        OUTPUT.data= EEG;
        
    end
    OUTPUT.StepDuration = [OUTPUT.StepDuration; toc];
    
    % ****** Error Management ******
catch e
    % If error ocurrs, create ErrorMessage(concatenated for all nested
    % errors). This string is given to the OUTPUT struct.
    
    ErrorMessage = string(e.message);
    for ierrors = 1:length(e.stack)
        ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
    end
    OUTPUT.Error = ErrorMessage;
end
end
