function  OUTPUT = Bad_Epochs(INPUT, Choice)
% This script does the following:
% Data is already epoched, so epochs containing artefacts are removed.
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
Choices = ["FASTER", "Threshold_100", "Threshold_120", "Threshold_150", "Threshold_200", "Probability+Kurtosis+Frequency_3.29SD", "None"];
Conditional = ["NaN", "NaN", "NaN", "NaN", "NaN", "NaN", "NaN", "NaN"];
SaveInterim = logical([0]);
Order = [13];

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
tic % for keeping track of time

try % For Error Handling, all steps are positioned in a try loop to capture errors
    
    %#####################################################################
    %### Epochdata before bad epochs can be excluded               #######
    %#####################################################################
    
    
    Conditions = fieldnames(INPUT.data);
    for i_cond = 1:length(Conditions)
        EEG = INPUT.data.(Conditions{i_cond});
        % Resting has to be reepoched either way, since epochs were
        % non-overlapping of 1s. Concatenation happened already in Step Run_ICA
        if contains(Conditions{i_cond}, 'Resting')
            % Epoch every 1s, Window length of 2s = 50% overlap
            EEG = eeg_regepochs(EEG, 1, [0 2], 0, 'X', 'on');
            INPUT.data.(Conditions{i_cond}) = EEG;
        else
            % if Gambling/Stroop have not been epoched before:
            if strcmp(INPUT.StepHistory.Epoching_AC, "no_continous")
                if contains(Conditions{i_cond}, 'Gambling')
                    Relevant_Triggers = [100, 110, 150, 101, 111, 151, 200, 210, 250, 201, 211, 251]; % FB Onset
                    Event_WindowAnt = [-2.0 0];
                    Event_WindowCon = [0 3.5];
                    EEG_Ant = pop_epoch( EEG, num2cell(Relevant_Triggers), Event_WindowAnt, 'epochinfo', 'yes');
                    EEG_Con = pop_epoch( EEG, num2cell(Relevant_Triggers), Event_WindowCon, 'epochinfo', 'yes');
                    INPUT.data.Gambling_Anticipation = EEG_Ant;
                    INPUT.data.Gambling_Consumption = EEG_Con;
                    INPUT.data =rmfield(INPUT.data,'Gambling');
                    
                elseif contains(Conditions{i_cond}, 'Stroop')
                    Relevant_Triggers = [ 11, 12, 13, 14, 15, 16, 17, 18, 21, 22, 23, 24, 25, 26, 27, 28, 31, 32, 33, 34, 35, 36, 37, 38, ...
                        41, 42, 43, 44, 45, 46, 47, 48, 51, 52, 53, 54, 55, 56, 57, 58, 61, 62, 63, 64, 65, 66, 67, 68, ...
                        71, 72, 73, 74, 75, 76, 77, 78]; % Picture Onset
                    Event_WindowAnt = [-1.0 0];
                    Event_WindowCon = [0 1];
                    EEG_Ant = pop_epoch( EEG, num2cell(Relevant_Triggers), Event_WindowAnt, 'epochinfo', 'yes');
                    EEG_Con = pop_epoch( EEG, num2cell(Relevant_Triggers), Event_WindowCon, 'epochinfo', 'yes');
                    INPUT.data.Stroop_Anticipation = EEG_Ant;
                    INPUT.data.Stroop_Consumption = EEG_Con;
                    INPUT.data =rmfield(INPUT.data,'Stroop');
                end
            else
                % Baseline Correct All previously epoched data (Occular
                % correction might have shifted them)
                EEG = pop_rmbase( EEG, [] ,[]);
                INPUT.data.(Conditions{i_cond}) = EEG;
            end
        end
    end
    OUTPUT = INPUT;
    
    
    
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    
    Conditions = fieldnames(INPUT.data);
    for i_cond = 1:length(Conditions)
        % Get EEGlab EEG structure from the provided Input Structure
        EEG = INPUT.data.(Conditions{i_cond});
        
        Clean_Epochs_Mask = ones(EEG.trials, 1);
        
        % ****** Remove EOG & Reference Channels ******
        EEG_Channels = ismember({EEG.chanlocs.type}, {'EEG'}) &  ~ismember({EEG.chanlocs.labels}, EEG.ref) ;
        EEG_subset = pop_select( EEG, 'channel', find(EEG_Channels));
        
        
        % ****** Identify bad Epochs ******
        if ~strcmpi(Choice, "None"  )
            if strcmpi(Choice, "FASTER")
                badFaster =   epoch_properties(EEG_subset, [1:EEG_subset.nbchan]);
                Clean_Epochs_Mask = ~min_z(badFaster);
                
            elseif contains(Choice, "Threshold")
                Threshold = strsplit(Choice, "_"); Threshold = str2double(Threshold{1,2});
                [~, badEpochs, ~, ~] = eegthresh(EEG_subset.data, EEG_subset.pnts, [1:EEG_subset.nbchan], -Threshold, Threshold, [EEG_subset.xmin EEG_subset.xmax], EEG_subset.xmin, EEG_subset.xmax);
                Clean_Epochs_Mask(badEpochs) = 0;
                
            elseif strcmpi(Choice, "Probability+Kurtosis+Frequency_3.29SD")
                threshold_DB = 90;
                threshold_SD = 3.29;
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
            
            % Check that not too many Epochs marked as bad
            if sum(Clean_Epochs_Mask) < (length(Clean_Epochs_Mask)*0.15)
                error('more than 85% of epochs were marked as bad')
            end
            
            % ****** Remove bad Epochs ******
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
        OUTPUT.AC.Clean_Epochs_Mask.(Conditions{i_cond}) = Clean_Epochs_Mask;
    end
    
    %% Resting Data needs to be merged. This is last Artefact correction step,
    % so Eyes open and Eyes closed can be merged
    Conditions = fieldnames(OUTPUT.data);
    if contains(Conditions, 'Resting')
        Resting_Conditions = Conditions(contains(Conditions, 'Resting'));
        EEG = pop_mergeset(OUTPUT.data.(Resting_Conditions{1}), OUTPUT.data.(Resting_Conditions{2}), 0);
        OUTPUT.data.Resting = EEG;
        OUTPUT.data =rmfield(OUTPUT.data,Resting_Conditions);
        OUTPUT.AC.Clean_Epochs_Mask.Resting =  OUTPUT.AC.(Resting_Conditions{1}) + OUTPUT.AC.(Resting_Conditions{2});
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
    
    if  exist('Clean_Epochs_Mask', 'var') && sum(Clean_Epochs_Mask)<1
        ErrorMessage = strcat(ErrorMessage, "Note: All Epochs marked as bad") ;
    end
    OUTPUT.Error = ErrorMessage;
end
end