function  OUTPUT = Epoching_AC(INPUT, Choice)
% This script does the following:
% Depending on the forking choice, it epochs the data for preprocessing, or
% it keeps it continously.
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

StepName = "Epoching_AC";
Choices = ["no_continous", "epoched"];
Conditional = ["NaN", "NaN"];
SaveInterim = logical([0]);
Order = [7];

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
tic % for keeping track of time
try % For Error Handling, all steps are positioned in a try loop to capture errors
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    if strcmpi(Choice , "epoched")
        Conditions = fieldnames(INPUT.data);
        for i_cond = 1:length(Conditions)
            % Get EEGlab EEG structure from the provided Input Structure
            EEG = INPUT.data.(Conditions{i_cond});
            
            if contains(Conditions{i_cond}, 'Resting')
                % Epoch Data in 1s intervals
                EEG = eeg_regepochs(EEG, 1,[0 1], 0, 'X', 'on');
                % Keep Collumn with urepochs to check continuity later
                [EEG.event.urepoch] = deal(EEG.event.epoch);
                % Function added Triggers at beginning and end of epoch. Delete
                % the Triggers at the end of the epoch
                IndexDelete = [];
                XTriggers = find(ismember({EEG.event.type} , 'X'));
                for ievent = [XTriggers(2): XTriggers(end)]
                    if EEG.event(ievent).type == 'X' & EEG.event(ievent-1).type == 'X'
                        if  EEG.event(ievent-1).latency == EEG.event(ievent).latency
                            IndexDelete = [IndexDelete, ievent-1];
                        end
                    end
                end
                EEG.event(IndexDelete) =[];
                EEG = eeg_checkset( EEG );
                
                OUTPUT.data.(Conditions{i_cond}) = EEG;
            elseif contains(Conditions{i_cond}, 'Gambling')
                Event_Window = [-0.500 1.000];
                Relevant_Triggers = [100, 110, 150, 101, 111, 151]; % FB Onset
                Event_WindowAnt = [-2.0 0];
                Event_WindowCon = [0 3.5];
                EEG_Ant = pop_epoch( EEG, num2cell(Relevant_Triggers), Event_WindowAnt, 'epochinfo', 'yes');
                EEG_Con = pop_epoch( EEG, num2cell(Relevant_Triggers), Event_WindowCon, 'epochinfo', 'yes');
                OUTPUT.data.Gambling_Anticipation = EEG_Ant;
                OUTPUT.data.Gambling_Consumption = EEG_Con;
                OUTPUT.data =rmfield(OUTPUT.data,'Gambling');
                
            elseif contains(Conditions{i_cond}, 'Stroop')
                Relevant_Triggers = [ 11, 12, 13, 14, 15, 16, 17, 18, 21, 22, 23, 24, 25, 26, 27, 28, 31, 32, 33, 34, 35, 36, 37, 38, ...
                    41, 42, 43, 44, 45, 46, 47, 48, 51, 52, 53, 54, 55, 56, 57, 58, 61, 62, 63, 64, 65, 66, 67, 68, ...
                    71, 72, 73, 74, 75, 76, 77, 78]; % Picture Onset
                Event_WindowAnt = [-1.0 0];
                Event_WindowCon = [0 1];
                EEG_Ant = pop_epoch( EEG, num2cell(Relevant_Triggers), Event_WindowAnt, 'epochinfo', 'yes');
                EEG_Con = pop_epoch( EEG, num2cell(Relevant_Triggers), Event_WindowCon, 'epochinfo', 'yes');
                OUTPUT.data.Stroop_Anticipation = EEG_Ant;
                OUTPUT.data.Stroop_Consumption = EEG_Con;
                OUTPUT.data =rmfield(OUTPUT.data,'Stroop');
            end
            
            
            
            
            %#####################################################################
            %### Wrapping up Preprocessing Routine                         #######
            %#####################################################################
            % ****** Export ******
            % Script creates an OUTPUT structure. Assign here what should be saved
            % and made available for next step. Always save the EEG structure in
            % the OUTPUT.data field, overwriting previous EEG information.
            % OUTPUT.data defined above.
        end
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