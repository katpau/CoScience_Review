function  OUTPUT = IBI_epoching(INPUT, Choice)
% Last Checked by:
% Planned Reviewer:
% Reviewed by:

% This script does the following:
% For the CECT analysis it is crucial that the EEG and IBI data have
% identical segments. This script segments the continious IBI data and
% removes segments that contained EEG artifacts. Furthermore, IBI artifacts
% are removed from IBI as well as the EEG data. Lastly, IBI
% segments are baseline corrected


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
StepName = "IBI_epoching";
Choices = ["-500 0", "firstTP"];
Order = [18];

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;

try
    %% Prepare IBI and ECG data for CECT analysis

    EEG = INPUT.data.EEG;
    ECG = INPUT.ECG;
    % Define the relevant stimuli triggers for segmentation
    Relevant_Triggers = [100, 110, 150, 101, 111, 151, 200, 210, 250, 201, 211, 251]; % FB Onset
    % Define size for IBI segments
    Event_Window = [-0.500 5.000];

    % check which (ur-)events in the ECG/IBI data are (not) contained in the segmented EEG data
    event_idx = zeros(length(ECG.event),1);
    for i=1:size(ECG.event,2)
        if ismember(ECG.event(i).urevent, [EEG.epoch.eventurevent])
            event_idx(i) = 1;
        else
            event_idx(i) = 0;
        end
    end
    event_idx = find(~event_idx);

    % Delete events that are not contained in the EEG structure from the ECG structure
    ECG = pop_editeventvals(ECG,'delete', event_idx);

    %% Segment ECG/IBI data
    ECG = pop_epoch( ECG, num2cell(Relevant_Triggers), Event_Window, 'epochinfo', 'yes');

    % check if ECG/IBI and EEG segments are identical, if not send error
    % (a potential error will be catched and will not cause termination of
    % the script)
    if~(size(ECG.event,2) == size(EEG.event,2) && ...
            sum([ECG.event.Trial] - [EEG.event.Trial]) == 0)
        error('ECG/IBI segments do not match EEG segments.' )
    else
    end

    %% Detect IBI artifacts
    % IBI artifacts are marked as NaNs within the contionous signal by the
    % ecg2ibi.m function. 
    % Detect in which segments NaNs/artifacts occur:
    ind_ecg = find(isnan(ECG.data));
    [~,~,k_ecg] = ind2sub(size(ECG.data), ind_ecg);
    arti_idx_ecg = unique(k_ecg);
    seg_artifacts_ecg = zeros(size(ECG.data,3),1); % initilaize artifact bool
    seg_artifacts_ecg(arti_idx_ecg) = 1; % "bad epochs mask"

    % remove these (IBI) artifact-laden segments from IBI and EEG data
    ECG = pop_select(ECG, 'trial', find(~seg_artifacts_ecg));
    EEG = pop_select(EEG, 'trial', find(~seg_artifacts_ecg));


    %% Remove baseline data from EEG and IBI segments
    if strcmp(Choice, '-500 0')
        ECG = pop_rmbase(ECG, [-500 0]);
    elseif strcmp(Choice, 'firstTP')
        ECG = pop_rmbase(ECG, [-1 0]);
    end

    % ****** Updating the OUTPUT structure ******
    % No changes should be made here.
    OUTPUT.StepHistory.(StepName) = Choice;
    OUTPUT.ECG = ECG;
    OUTPUT.data.EEG = EEG;
    OUTPUT.AC.ECG.Clean_Epochs_Mask = ~seg_artifacts_ecg;

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


