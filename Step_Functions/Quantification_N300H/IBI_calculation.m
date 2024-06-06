function  OUTPUT = IBI_calculation(INPUT, Choice)
% Last Checked by:
% Planned Reviewer:
% Reviewed by:

% This script does the following:
% Script detects R peaks, calculates a contionues Interbeat Interval (IBI)
% signal, detects artifacts within the IBI signal, and remove them.


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
StepName = "IBI_calculation";
Choices = ["no_interpolation", "interpolation"];
Order = [17];

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;

try
    %% prepare EEG and ECG/IBI data for CECT analsis
    ECG = INPUT.ECG;

    % Calculate IBIs from raw ECG signal using the ecg2ibi wrapper function
    IBI = ecg2ibi(ECG, INPUT.Subject, Choice);

    % add continous IBI channel to ECG data
    ECG.data(end+1,:) = IBI.data(1,:);
    % Update channel labels
    ECG.chanlocs(end+1).labels = 'IBI';
    % Update number of channels
    ECG.nbchan = ECG.nbchan + 1;

    % save percentage of bad IBI points
    OUTPUT.AC.ECG.artifactPercentage = IBI.artifacts.residuals.percentBadSignal;
    
    % ****** Updating the OUTPUT structure ******
    % No changes should be made here.
    OUTPUT.StepHistory.(StepName) = Choice;
    OUTPUT.ECG = ECG;
   

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
