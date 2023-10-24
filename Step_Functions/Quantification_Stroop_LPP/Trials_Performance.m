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
Choices = ["Correct_RTs-300", "Correct_RTs-100", "RTs-300", "RTs-100", "AllTrials"];
Conditional = ["NaN", "NaN", "NaN",  "NaN",  "NaN"];
SaveInterim = logical([0]);
Order = [17];

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
try % For Error Handling, all steps are positioned in a try loop to capture errors
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    
    Conditions = fieldnames(INPUT.data);
    for i_cond = 1:length(Conditions)
        % Get EEGlab EEG structure from the provided Input Structure
        EEG = INPUT.data.(Conditions{i_cond});
        
        % ****** Find Trials to be excluded ******
        if ~strcmpi(Choice, "AllTrials")
            
            % Get critical RTs
            % Unclear Error - sometimes wrong Format
            if iscell(EEG.event(1).RT) 
                for ic = 1:length(EEG.event)
                    EEG.event(ic).RT = cell2mat(EEG.event(ic).RT);
                    if ~isnumeric( EEG.event(ic).RT )
                        if strcmp(EEG.event(ic).RT,  'NA')
                           EEG.event(ic).RT  = NaN;
                        else
                           EEG.event(ic).RT  = str2num( EEG.event(ic).RT );
                        end
                    end
                end
            end

            RT = strsplit(Choice, "-"); RT = str2double(RT(2))/1000;
            % Mark Trials with RTs faster than critical value
            IdxKeep =  cellfun(@(x)~isempty(x) && x > RT, {EEG.event.RT});
            
            if contains(Choice, "Correct")
                IdxKeep2 = cellfun(@(x)~isempty(x) && isequal(x, 1), {EEG.event.ACC});
                IdxKeep = and(IdxKeep, IdxKeep2);
            end
            
            Epochs_to_Keep = {EEG.event.epoch};
            Epochs_to_Keep = unique([Epochs_to_Keep{IdxKeep}]);
            
            % ****** Keep only marked Trials ******
            EEG = pop_select( EEG, 'trial', Epochs_to_Keep);
        end
        
        %#####################################################################
        %### Wrapping up Preprocessing Routine                         #######
        %#####################################################################
        % ****** Export ******
        % Script creates an OUTPUT structure. Assign here what should be saved
        % and made available for next step. Always save the EEG structure in
        % the OUTPUT.data field, overwriting previous EEG information.
        OUTPUT.data.(Conditions{i_cond}) = EEG;
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
end
