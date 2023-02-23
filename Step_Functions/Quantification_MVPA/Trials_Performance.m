function  OUTPUT = Trials_Performance(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following:
% Depending on the forking choice, trials are excluded based on
% performance in that trial. The event structure of the CoScience Data
% includes details on each trial (Performance, RT, Condition etc.).
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
StepName = "Trials_Performance";
Choices = ["RTs", "None"];
Conditional = ["NaN", "NaN"];
SaveInterim = logical([0]);
Order = [16];

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
try % For Error Handling, all steps are positioned in a try loop to capture errors
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    if ~strcmp(Choice, "None")
        Conditions = fieldnames(INPUT.data);
        for i_cond = 1:length(Conditions)
            % Get EEGlab EEG structure from the provided Input Structure
            EEG = INPUT.data.(Conditions{i_cond});
            
            % Mark Trials with RTs faster than 0.1 and slower than 0.8s
            IdxKeep = cellfun(@(x)~isempty(x) && x > 0.1 && x <0.8, {EEG.event.RT});

            
            Epochs_to_Keep = {EEG.event.epoch};
            Epochs_to_Keep = unique([Epochs_to_Keep{IdxKeep}]);
            
            % ****** Keep only marked Trials ******
            EEG = pop_select( EEG, 'trial', Epochs_to_Keep);
            
            %#####################################################################
            %### Wrapping up Preprocessing Routine                         #######
            %#####################################################################
            % ****** Export ******
            % Script creates an OUTPUT structure. Assign here what should be saved
            % and made available for next step. Always save the EEG structure in
            % the OUTPUT.data field, overwriting previous EEG information.
            OUTPUT.data.(Conditions{i_cond}) = EEG;
        end
    end
    
    
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
