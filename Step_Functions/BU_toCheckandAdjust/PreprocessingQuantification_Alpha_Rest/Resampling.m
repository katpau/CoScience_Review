function  OUTPUT = Resampling(INPUT, Choice, SubjectName, FilePath_to_Import);
% This script does the following: 
% It first determines and loads the EEGLAB data file.
% Then it removes channels not used in the analysis.
% In order to make the Information available for later, Accuracy
% (Performance) on the task is calculated. 
% Finally Data is resampled according to the forking choice 

%#####################################################################
%### Usage Information                                         #######
%#####################################################################
% This function requires the following inputs:
% INPUT = structure, containing at least the fields "Data" (containing the
%       EEGlab structure, "StephHistory" (for every forking decision). More 
%       fields can be added through other preprocessing steps.
% Choice = string, naming the choice run at this fork (included in "Choices")
% SubjectName = string, unique identifyer of each file (used
%       for saving/loading)
% FilePath_to_Import = string, pointing to the filepath where the raw file
%           is (raw file is already in EEGlab format)
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
StepName = "Resampling";
Choices = ["500", "250", "125"];
Conditional = ["NaN", "NaN", "NaN"];
SaveInterim = logical([0]);
Order = [0];



% ****** Updating the OUTPUT structure ****** 
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
tic % for keeping track of time
try % For Error Handling, all steps are positioned in a try loop to capture errors
   
%#####################################################################
%### Start Preprocessing Routine                               #######
%#####################################################################

    % ****** Load Data ******
    % As this is the first Step, the EEG data needs to be loaded
    % Get information on File ID and Filepath from provided inputs (Depends
    % on the individual Tasks!)
    % Get info on Task
    if contains(FilePath_to_Import, "Flanker")
        TaskName = "_task-Flanker";
    elseif contains(FilePath_to_Import, "Resting")
        TaskName = "_task-Resting";
    elseif contains(FilePath_to_Import, "Stroop")
        TaskName = "_task-Stroop";
    elseif contains(FilePath_to_Import, "Gambling")
        TaskName = "_task-Gambling";
    elseif contains(FilePath_to_Import, "UltimatumGame")
        TaskName = "_task-Ultimatum";
    elseif contains(FilePath_to_Import, "GoNoGo")
        TaskName = "_task-GoNoGo";
    end
    
    File_to_Import = char(strcat(SubjectName, TaskName, '_eeg.set'));
    FilePath_to_Import = char(strcat(FilePath_to_Import,SubjectName, "/eeg/"));
    % load the EEG File
    EEG = pop_loadset('filename',File_to_Import, 'filepath',FilePath_to_Import);
    
    % ****** Trim Channels ******
    % The imported files include many more channels, that we do not need 
    % for this hypothesis (e.g. ECG, Light Sensor etc.) These need to be 
    % excluded. Furthermore, we standardize the channels used in the project: 
    % Only channels that are common across all labs are included in the
    % analysis and preprocessing.
    Common_Channels =  {'FP1', 'FP2', 'AF7', 'AF8', 'AF3', 'AF4', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'FT7', 'FT8', 'FC5', 'FC6', 'FC3', 'FC4', ...
        'FC1', 'FC2', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'T7', 'T8', 'TP7', 'TP8', 'CP5', 'CP6', 'CP3', 'CP4', 'CP1', 'CP2', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6', ...
        'P7', 'P8', 'PO7', 'PO8', 'PO3', 'PO4', 'O1', 'O2', 'OZ', 'POZ', 'PZ', 'CPZ', 'CZ', 'FCZ', 'FZ', ... % 'AFZ', 'FPZ' are used as grounds in some labs
        'VOGabove', 'VOGbelow', 'HOGl', 'HOGr','MASTl', 'MASTr'};
    Common_Channels = Common_Channels(ismember(Common_Channels, {EEG.chanlocs.labels})); % some labs miss e.g. VOGabove
    EEG = pop_select( EEG, 'channel',Common_Channels);
        
    
    % ****** Resample Data ******
    % since we use different sampling rates across labs, this is dependent
    % on the current sampling rate (divide it by 2 or 4)
    if strcmpi(Choice,  "250")
        EEG = pop_resample(EEG, EEG.srate/2);
    elseif strcmpi(Choice , "125")
        EEG = pop_resample(EEG, EEG.srate/4);
    end
    
%#####################################################################
%### Wrapping up Preprocessing Routine                         #######
%#####################################################################   
    % ****** Export ******
    % Script creates an OUTPUT structure. Assign here what should be saved
    % and made available for next step. Always save the EEG structure in
    % the OUTPUT.data field, overwriting previous EEG information. 
    OUTPUT.data = EEG;
    OUTPUT.StepDuration = [toc];
    
    
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