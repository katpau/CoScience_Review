function  OUTPUT = Run_ICA(INPUT, Choice)
% This script does the following:
% Depending on the forking choice, an ICA decomposition is calculated,
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
StepName = "Run_ICA";
Choices = ["ICA", "No"];
SaveInterim = logical([1]);
Order = [10];

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
    Conditions = fieldnames(INPUT.data);
    
    
    % make Resting Data continous again
    if strcmp(INPUT.StepHistory.Epoching_AC, "epoched")
        for i_cond = 1:length(Conditions)
            % Get EEGlab EEG structure from the provided Input Structure
            EEG = INPUT.data.(Conditions{i_cond});
            
            EEG = eeg_epoch2continuous(EEG);
            EEG = pop_editeventvals( EEG, 'sort', {'latency' 0});
            % Remove Boundary Triggers if adjacent epochs are continous
            boundaryTriggers = find(ismember({EEG.event.type} , 'boundary'));
            IndexDelete=[];
            for ievent = boundaryTriggers
                if  EEG.event(ievent-1).urepoch == (EEG.event(ievent+1).urepoch-1) | EEG.event(ievent-1).urepoch == EEG.event(ievent).urepoch
                    IndexDelete = [IndexDelete, ievent];
                end
            end
            % delete "non"boundaries
            EEG.event(IndexDelete) =[];
            % delete 'X" triggers
            EEG.event(find(ismember({EEG.event.type} , 'X'))) =[];
            INPUT.data.(Conditions{i_cond}) = eeg_checkset( EEG );
        end
        OUTPUT = INPUT;
    end
    
    % Run ICA for every Subset if chosen
    if ~strcmpi(Choice, "No")
        for i_cond = 1:length(Conditions)
            % Get EEGlab EEG structure from the provided Input Structure
            EEG = INPUT.data.(Conditions{i_cond});
            
            % ****** Filter Data before running ICA ******
            % Create copy of the original EEG Data and low pass filter with 1 Hz
            EEG_ica = pop_eegfiltnew(EEG, 'locutoff',1,'plotfreqz',0);
            
            % ****** Adjust ICA Rank ******
            % For running ICA, adjust number of reliable components based on
            % not-interpolated channels
            rank = sum(INPUT.AC.Clean_Channel_Mask.(Conditions{i_cond}));
            % adjust rank based on reference
            if INPUT.StepHistory.Reference_AC == 'AV' | INPUT.StepHistory.Reference_AC == 'Cz'
                rank = rank -1;
            elseif INPUT.StepHistory.Reference_AC == 'Mastoids'
                rank = rank -2;
            end
            
            % ****** Run ICA ******
            EEG_ica = pop_runica(EEG_ica,'icatype','runica','pca',rank);
            
            % ****** Apply ICA weights to original data ******
            EEG.icaweights = EEG_ica.icaweights;
            EEG.icasphere  = EEG_ica.icasphere;
            EEG = eeg_checkset(EEG, 'ica');
            
            
            
            %#####################################################################
            %### Wrapping up Preprocessing Routine                         #######
            %#####################################################################
            % ****** Export ******
            % Script creates an OUTPUT structure. Assign here what should be saved
            % and made available for next step. Always save the EEG structure in
            % the OUTPUT.data field, overwriting previous EEG information.
            OUTPUT.data.(Conditions{i_cond}) = EEG;
            
            % some artefact correction methods use the filtered data, not only
            % the component activation (e.g. MARA), so the filtered dataset
            % needs to be  saved (temporarily).
            OUTPUT.filteredData.(Conditions{i_cond}) = EEG_ica;
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