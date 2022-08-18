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
           % if sum(Clean_Epochs_Mask) < (length(Clean_Epochs_Mask)*0.15)
           %     error('more than 85% of epochs were marked as bad')
           % end
            
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
    Split_Conditions = fieldnames(OUTPUT.data);
    % If Run exist, merge it
    if any(contains(Split_Conditions, 'R1_open'))
        EEG = pop_mergeset(OUTPUT.data.R1_open, OUTPUT.data.R1_closed, 0);
        OUTPUT.data.R1 = EEG;
    end
    if any(contains(Split_Conditions, 'R2_open'))
        EEG = pop_mergeset(OUTPUT.data.R2_open, OUTPUT.data.R3_closed, 0);
        OUTPUT.data.R2 = EEG;
    end
    if any(contains(Split_Conditions, 'R3_open'))
        EEG = pop_mergeset(OUTPUT.data.R2_open, OUTPUT.data.R3_closed, 0);
        OUTPUT.data.R3 = EEG;
    end
    % Remove all Split Conditions
    OUTPUT.data =rmfield(OUTPUT.data,Split_Conditions);
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