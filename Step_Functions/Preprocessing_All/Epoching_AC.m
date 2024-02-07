function  OUTPUT = Epoching_AC(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

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
    
    % Get EEGlab EEG structure from the provided Input Structure
    EEG = INPUT.data.EEG;

    % [ocs] Analysis stored locally for brevity and faster access.
    AnalysisName = INPUT.AnalysisName;    

     % ****** for Resting Tasks remove 2s after change in instruction
     if contains(AnalysisName,  "Resting") 
        % remove 2s after Change in instruction
        changeInstr = [EEG.event(find(ismember({EEG.event.type}, ['11'; '12'; '22'; '21'; '31'; '32']))).latency];
        changeInstr = [changeInstr', changeInstr'+EEG.srate*2];
        EEG = pop_select(EEG, 'nopoint', changeInstr);
     end      
            
    if strcmpi(Choice , "epoched")
        % ****** Define Triggers and Window based on Analysis ******
        if ~(contains(AnalysisName, 'Resting')) && ~(contains(AnalysisName, 'Alpha'))           
            if AnalysisName == "Flanker_Error"
                Event_Window = [-0.500 0.800]; % Epoch length in seconds
                Relevant_Triggers = [ 106, 116, 126,  136, 206, 216, 226, 236, ...
                    107, 117, 127, 137, 207, 217, 227, 237, 108, 118, 128, 138,  208, 218, ...
                    228, 238, 109, 119, 129, 139, 209, 219, 229, 239  ]; %Responses
                

            elseif AnalysisName == "Flanker_MVPA" 
                  Event_Window = [-0.300 0.300]; % Epoch length in seconds
                  Relevant_Triggers = [ 106, 116, 126,  136, ...
                      107, 117, 127, 137, 108, 118, 128, 138, ...
                      109, 119, 129, 139  ]; %Responses Experimenter Absent

              elseif AnalysisName == "GoNoGo_MVPA" 
                  Event_Window = [-0.300 0.300]; % Epoch length in seconds
                  Relevant_Triggers = [211, 220 ]; %Responses Speed/Acc emphasis

              elseif AnalysisName == "Flanker_GMA"
                  Event_Window = [-0.500 0.800]; % Epoch length in seconds
                  Relevant_Triggers = [ 106, 116, 126,  136, ...
                      107, 117, 127, 137, 108, 118, 128, 138, ...
                      109, 119, 129, 139  ]; %Responses Experimenter Absent

              elseif AnalysisName == "GoNoGo_GMA"
                  Event_Window = [-0.500 0.800]; % Epoch length in seconds
                  Relevant_Triggers = [211, 220 ]; %Responses Speed/Acc emphasis
                
            elseif AnalysisName == "Flanker_Conflict"
                Event_Window = [-0.500 .650];
                Relevant_Triggers = [ 104, 114, 124, 134]; % Target Onset experimenter absent
                
            elseif AnalysisName == "GoNoGo_Conflict" 
                Event_Window = [-0.200 0.500];
                Relevant_Triggers = [101, 102, 201, 202 ]; % Target Onset
                
            elseif AnalysisName == "Ultimatum_Quant" || AnalysisName == "Ultimatum_Fairness"
                    Event_Window = [-0.500 1.000];
                    Relevant_Triggers = [1,2,3 ]; % Offer Onset
                
            elseif AnalysisName == "Gambling_Quant" || AnalysisName == "Gambling_RewP"
                Event_Window = [-0.500 1.000];
                Relevant_Triggers = [100, 110, 150, 101, 111, 151, 200, 210, 250, 201, 211, 251]; % FB Onset
                
            elseif AnalysisName == "Gambling_N300H"
                Event_Window = [-0.200 2.000];
                Relevant_Triggers = [100, 110, 150, 101, 111, 151, 200, 210, 250, 201, 211, 251]; % FB Onset
                
            elseif AnalysisName == "Stroop_LPP"
                Event_Window = [-0.300 1.000];
                Relevant_Triggers = [ 11, 12, 13, 14, 15, 16, 17, 18, 21, 22, 23, 24, 25, 26, 27, 28, 31, 32, 33, 34, 35, 36, 37, 38, ...
                    41, 42, 43, 44, 45, 46, 47, 48, 51, 52, 53, 54, 55, 56, 57, 58, 61, 62, 63, 64, 65, 66, 67, 68, ...
                    71, 72, 73, 74, 75, 76, 77, 78]; % Picture Onset
            % [ocs] CHANGE There should be an error condition for unknown
            % analysis names… just in case.
            else
                error("Unknown INPUT.AnalysisName '%s'", AnalysisName);
            end
            % ****** Epoch Data around predefined window ******
            EEG = pop_epoch( EEG, num2cell(Relevant_Triggers), Event_Window, 'epochinfo', 'yes');
            
            
            
            % ****** Alpha Tasks are split into different analytical
            % procedures within the tasks (Anticipation and Consumption) ******
        elseif AnalysisName == "Stroop_Alpha"
            Relevant_Triggers = [ 11, 12, 13, 14, 15, 16, 17, 18, 21, 22, 23, 24, 25, 26, 27, 28, 31, 32, 33, 34, 35, 36, 37, 38, ...
                41, 42, 43, 44, 45, 46, 47, 48, 51, 52, 53, 54, 55, 56, 57, 58, 61, 62, 63, 64, 65, 66, 67, 68, ...
                71, 72, 73, 74, 75, 76, 77, 78]; % Picture Onset
            Event_Window = [-1 1];
            
            % Anticipation
            EEG1 = pop_epoch( EEG, num2cell(Relevant_Triggers), [-1 0], 'epochinfo', 'yes');
            % Consumption
            EEG2 = pop_epoch( EEG, num2cell(Relevant_Triggers), [0 1], 'epochinfo', 'yes');
            
            % Combine Conditions to Output: Name Conditions
            Condition = {'Stroop_Anticipation', 'Stroop_Consumption'};
            
        elseif AnalysisName == "Gambling_Alpha"
            Relevant_Triggers = [100, 110, 150, 101, 111, 151, 200, 210, 250, 201, 211, 251]; % FB Onset
            % Anticipation
            EEG1 = pop_epoch( EEG, num2cell(Relevant_Triggers), [-2 0], 'epochinfo', 'yes');
            % Consumption
            EEG2 = pop_epoch( EEG, num2cell(Relevant_Triggers), [0 3.5], 'epochinfo', 'yes');
            
            % Combine Conditions to Output: Name Conditions
            Condition = {'Gambling_Anticipation', 'Gambling_Consumption'};
            
            % ****** Resting Tasks are epoched in consecutive epochs ******
        elseif contains(AnalysisName,  "Resting") || AnalysisName == "Alpha_Context"                       
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
            EEG = eeg_checkset(EEG );
        
        % [ocs] CHANGE There should be an error condition for unknown
        % analysis names… just in case.
        else
            error("Unknown INPUT.AnalysisName '%s'", AnalysisName);
        end
    end
    
    
    %#####################################################################
    %### Wrapping up Preprocessing Routine                         #######
    %#####################################################################
    % ****** Export ******
    % Script creates an OUTPUT structure. Assign here what should be saved
    % and made available for next step. Always save the EEG structure in
    % the OUTPUT.data field, overwriting previous EEG information.
    if ~exist('EEG2', 'var')
        OUTPUT.data.EEG = EEG;
    else
        OUTPUT.data = struct(Condition{1}, EEG1, Condition{2}, EEG2);
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