function  OUTPUT = Bad_Epochs(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following:
% if data has not been epoched before, it is epoched
% Depending on the forking choice,
% epochs containing artefacts are removed.
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
StepName = "Bad_Epochs";
Choices = ["FASTER", "Threshold_100", "Threshold_120", "Threshold_150", "Threshold_200", "Probability+Kurtosis+Frequency_3.29SD", "No_BadEpochs"];
Conditional = ["NaN", "NaN", "NaN", "NaN", "NaN", "NaN", "OccularCorrection ~= ""No_OccularCorrection"" & Bad_Segments ~= ""No_BadSegments"" "]; % Choice "None" only allowed if some Artcor was done before
SaveInterim = logical([0]);
Order = [12];

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
try % For Error Handling, all steps are positioned in a try loop to capture errors
    
    %#####################################################################
    %### Epoch Data before Cleaning                               #######
    %#####################################################################
    
    Conditions = fieldnames(INPUT.data);
    % [ocs] Analysis stored locally for brevity and faster access.
    AnalysisName = INPUT.AnalysisName;
    
    for i_cond = 1:length(Conditions)
        % Get EEGlab EEG structure from the provided Input Structure
        EEG = INPUT.data.(Conditions{i_cond});
        
        % only epoch if not already epoched
        if ~strcmp(INPUT.StepHistory.Epoching_AC, "epoched")
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
                    
                elseif AnalysisName == "Ultimatum_Offer"
                    Event_Window = [-0.500 1.000];
                    Relevant_Triggers = [1,2,3 ]; % Offer Onset
                    
                elseif AnalysisName == "Gambling_Theta" || AnalysisName == "Gambling_RewP"
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
            % [ocs] CHANGE There should be an error condition for unknown
            % analysis names… just in case.
            else
                error("Unknown INPUT.AnalysisName '%s'", AnalysisName);
            end
        end
        
        % ****** Resting Tasks are epoched in consecutive overlapping epochs ******
        if contains(AnalysisName,  "Resting") || AnalysisName == "Alpha_Context"
            % If Resting data was epoched before, concatenate the
            % non-overlapping epochs first.
            if strcmp(INPUT.StepHistory.Epoching_AC, "epoched")
                EEG = eeg_epoch2continuous(EEG);
                % Remove all "Boundaries", since there will be events for
                % start of epoch
                EEG.event(find(strcmp({EEG.event.type}, 'boundary'))) = [];
                % Remove X Triggers between consecutive epochs and include
                % 'boundary' between non-consecutive epochs
                IdxDelete = [];
                for ievent = 2:length(EEG.event)
                    if strcmp(EEG.event(ievent).type,'X')
                        if EEG.event(ievent).urepoch == (EEG.event(ievent-1).urepoch+1)
                            IdxDelete = [IdxDelete, ievent];
                        else
                            EEG.event(ievent).type = 'boundary';
                        end
                    end
                end
                EEG.event(IdxDelete) = [];
            end
            % ******  Epoch Resting Data into epochs of 2 second lengths with 50%
            % overlap
            EEG = eeg_regepochs(EEG, 1, [0 2], 0, 'X2', 'on');
        end
        
        
        
        if ~exist('EEG2', 'var')
            INTERIM.data.(Conditions{i_cond}) = EEG;
        else
            INTERIM.data = struct(Condition{1}, EEG1, Condition{2}, EEG2);
        end
        OUTPUT.data = INTERIM.data;
        
    end
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    
    Conditions = fieldnames(INTERIM.data);
    for i_cond = 1:length(Conditions)
        % Get EEGlab EEG structure from the provided Input Structure
        EEG = INTERIM.data.(Conditions{i_cond});
        
        
        % Initate Clean Epoch Mask
        Clean_Epochs_Mask = ones(EEG.trials, 1);
        
        % ****** Remove EOG & Reference Channels ******
        EEG_Channels = ismember({EEG.chanlocs.type}, {'EEG'}) &  ~ismember({EEG.chanlocs.labels}, EEG.ref) ;
        EEG_subset = pop_select( EEG, 'channel', find(EEG_Channels));
        
        
        % ****** Identify bad Epochs ******
        if ~strcmpi(Choice, "No_BadEpochs"  )
            if strcmpi(Choice, "FASTER")
                badFaster =   epoch_properties(EEG_subset, [1:EEG_subset.nbchan]);
                Clean_Epochs_Mask = ~min_z(badFaster);
                
            elseif contains(Choice, "Threshold")
                Threshold = strsplit(Choice, "_"); Threshold = str2double(Threshold{1,2});
                % Demean Data otherwise Thresholding does not work
                EEG_subset.data = EEG_subset.data - mean(EEG_subset.data,2);
                [~, badEpochs, ~, ~] = eegthresh(EEG_subset.data, EEG_subset.pnts, [1:EEG_subset.nbchan], -Threshold, Threshold, [EEG_subset.xmin EEG_subset.xmax], EEG_subset.xmin, EEG_subset.xmax);
                Clean_Epochs_Mask(badEpochs) = 0;
                
            elseif strcmpi(Choice, "Probability+Kurtosis+Frequency_3.29SD")
                threshold_DB = 90;
                threshold_SD = 3.29;
                % Demean Data otherwise Thresholding does not work
                EEG_subset.data = EEG_subset.data - mean(EEG_subset.data,2);
                
                % Frequency Spectrum
                [~, bad_Spectrum] = pop_rejspec(EEG_subset, 1, 'elecrange', [1:EEG_subset.nbchan], 'threshold', [-threshold_DB threshold_DB], 'freqlimits', [1 30]);
                Clean_Epochs_Mask(bad_Spectrum) = 0;
                
                % Kurtosis
                bad_Kurtosis = pop_rejkurt(EEG_subset, 1, [1:EEG_subset.nbchan],  threshold_SD,threshold_SD,0,0,0);
                bad_Kurtosis = find(bad_Kurtosis.reject.rejkurt);
                Clean_Epochs_Mask(bad_Kurtosis) = 0;
                
                % Probability open pop_jointprob
                bad_Probability = pop_jointprob(EEG_subset, 1, [1:EEG_subset.nbchan],  threshold_SD, threshold_SD,0,0,0);
                bad_Probability = find(bad_Probability.reject.rejjp);
                Clean_Epochs_Mask(bad_Probability) = 0;
                
            end
            
            
            % ****** Remove bad Epochs ******
            if  sum(Clean_Epochs_Mask) < 2
                e.message = 'All Trials marked as bad (100%!!) .';
                error(e.message);
            end
            EEG = pop_select( EEG, 'trial',find(Clean_Epochs_Mask));
        end
        
        %#####################################################################
        %### Wrapping up Preprocessing Routine                         #######
        %#####################################################################
        % ****** Export ******
        % Script creates an OUTPUT structure. Assign here what should be saved
        % and made available for next step. Always save the EEG structure in
        % the OUTPUT.data field, overwriting previous EEG information.
        OUTPUT.data.(Conditions{i_cond}) = EEG;
        OUTPUT.AC.(Conditions{i_cond}).Clean_Epochs_Mask = Clean_Epochs_Mask;
    end
    
    % ****** Error Management ******
catch e
    % If error ocurrs, create ErrorMessage(concatenated for all nested
    % errors). This string is given to the OUTPUT struct.
    ErrorMessage = string(e.message);
    for ierrors = 1:length(e.stack)
        ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
    end
    if  exist('Clean_Epochs_Mask', 'var')
        ErrorMessage = strcat(ErrorMessage,"extracted Epochs: ", num2str(length(Clean_Epochs_Mask)));
    end

    OUTPUT.Error = ErrorMessage;
end
end