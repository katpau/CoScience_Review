function  OUTPUT = TimeWindow(INPUT, Choice)
% This script does the following:
% Uses information of previous steps to reduce the data.
% First, based on the included trials, ERPs are calculated
% (averaged across trials), for every electrode & condition.
% Second, only possibly relevant electrodes & timepoints are kept
% with the complete trial information (reducing file size).
% Trial information is relevant to estimate the Measurement
% Error.
% Quantification of ERP is done in other Step(Quantificiation ERP).

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
StepName = "TimeWindow";
Choices = ["200,400", "150,350", "200,500", "200,350;350,500"];
Conditional = ["NaN", "NaN", "NaN"];
SaveInterim = logical([1]);
Order = [21];


% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
tic % for keeping track of time
try % For Error Handling, all steps are positioned in a try loop to capture errors
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    
    % Get EEGlab EEG structure from the provided Input Structure
    EEG = INPUT.data;
    
    
    % ****** Condition information ******
    % diff Congruency Level, fast & slow Responses merged
    Triggers = {'107', '117', '127', '137', '106', '116', '126', '136'; ...
        '207', '217', '227', '237', '206', '216', '226', '236'; ...
        '109', '119', '129', '139', '108', '118', '128', '138'; ...
        '209', '219', '229', '239', '208', '218',  '228', '238'};
    
    Conditions = ["Correct_ExpAbsent",
        "Correct_ExpPresent",
        "Error_ExpAbsent",
        "Error_ExpPresent"];
    
    
    % ****** Rearrange Data (4th Dim = Conditions) ******
    % Initiate array of NaN (trials are then NaN filled for compatible
    % length)
    Reshaped_Data = NaN(EEG.nbchan, EEG.pnts, EEG.trials, length(Conditions));
    for iCondition = 1:length(Conditions)
        % find relevant Epochs
        ConditionIdx = ismember({EEG.event.type}, Triggers(iCondition,:));
        ConditionIdx = [EEG.event(ConditionIdx).epoch];
        Reshaped_Data(:,:,1:length((ConditionIdx)),iCondition) = EEG.data(:, :, ConditionIdx);
    end
    
    % ****** Calculate ERP for each Condition ******
    ERP.data = mean(Reshaped_Data,3, 'omitnan');
    
    % Create ERP structure with Info on Channels & Timing
    ERP.chanlocs = EEG.chanlocs;
    ERP.times = EEG.times;
    
    % ****** Extract Relevant Datapoints ******
    % Step1: Extract Relevant Electrodes
    Electrodes = upper(strsplit(INPUT.StepHistory.Electrodes , ", "));
    % Find Index of Electrodes
    [~, ElectrodeIdx] = ismember(Electrodes, {EEG.chanlocs.labels});
        
    % Step2: Extract Relevant Times
    Times = strsplit(Choice, ",");
    if length(Times)>2
        % Pe has one option with two time windows
        Times = Times([1,3]); % keep only outer bonds
    end
    Times = str2double(Times);
    % increase time window in case GAV peak is right at border
    Times = Times + [-55, 55];
    % Find Index of Timepoints
    [~,TimeIdx(1)] = min(abs(EEG.times - Times(1)));
    [~,TimeIdx(2)] = min(abs(EEG.times - Times(2)));
    TimeIdx = TimeIdx(1) : TimeIdx(2);
    
    % Step3: Extract Data
    Reshaped_Data = Reshaped_Data(ElectrodeIdx, TimeIdx, :, :);
    % Create data structure with relevant information
    data.data = Reshaped_Data;
    data.times = EEG.times(TimeIdx);
    data.chanlocs = EEG.chanlocs(ElectrodeIdx);
    data.srate = EEG.srate;
    data.Conditions = Conditions;
    
    
    %#####################################################################
    %### Wrapping up Preprocessing Routine                         #######
    %#####################################################################
    % ****** Export ******
    % Script creates an OUTPUT structure. Assign here what should be saved
    % and made available for next step. Always save the EEG structure in
    % the OUTPUT.data field, overwriting previous EEG information.
    OUTPUT.data = data;
    OUTPUT.ERP = ERP;
    OUTPUT.AC = INPUT.AC;
    OUTPUT.ACC = INPUT.data.ACC;
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
