function  OUTPUT = Bad_Segments(INPUT, Choice)

% This script does the following:
% Depending on the forking choice, very bad data segments are removed.
% These should exclude the worst data parts, that could affect the ICA
% and further cleaning algorithms. Note: long breaks are already
% excluded from the CoScience Datasets
% This is mostly done on epoched data (only ASR works on continous data).
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
StepName = "Bad_Segments";
Choices = ["ASR", "Threshold_500", "Threshold_300", "Probability+Kurtosis+Frequency", "EPOS", "None"];
Conditional = ["Epoching_AC == ""no_continous"" ", "Epoching_AC == ""epoched"" ", "Epoching_AC == ""epoched"" ", "Epoching_AC == ""epoched"" ", "Epoching_AC == ""epoched"" ", "Epoching_AC == ""epoched"" "];
SaveInterim = logical([1]);
Order = [9];

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
    
    
    % Initalize Clean Segment Mask of length Trials or, if continous, then Sampling Points
    if EEG.trials > 1
        Clean_Segment_Mask = ones(EEG.trials,1);
    else
        Clean_Segment_Mask = ones(EEG.pnts,1);
    end
    
    if ~strcmpi(Choice, "None")
        % ****** Exclude VEOG and Reference Channels ******
        % VEOG channels should be excluded here as eye artefacts might
        % exceed thresholds
        % The Reference Channel should be excluded (as it contains only 0s)
        EEG_Channels = ismember({EEG.chanlocs.type}, {'EEG'}) &  ~ismember({EEG.chanlocs.labels}, EEG.ref) ;
        
        % create artifical subset to work with
        EEG_subset = pop_select( EEG, 'channel', find(EEG_Channels));
        
        
        % ****** Apply Identification of Bad Segments ******
        if strcmpi(Choice,"ASR")
            % ASR only works on filtered data. Create copy of data, and
            % highpassfilter it with 1 Hz
            % Needs to be filtered first
            EEG_fil = pop_eegfiltnew(EEG_subset, 'locutoff', 1, 'hicutoff', []);
            EEG_cleaned = clean_asr(EEG_fil, 50 );
            % Above procedure already corrects bad segments => identify
            % changes by comparing it with the original (filtered) dataset
            Clean_Segment_Mask = sum(abs(EEG_fil.data-EEG_cleaned.data),1) < 1e-6;
            
            
        elseif strcmpi(Choice, "Threshold_500")
            [~, badTrials, ~, ~] = eegthresh(EEG_subset.data, EEG_subset.pnts, 1:EEG_subset.nbchan, -500, 500, [EEG_subset.xmin EEG.xmax], EEG.xmin, EEG.xmax);
            Clean_Segment_Mask(badTrials) = 0;
            
        elseif strcmpi(Choice, "Threshold_300")
            [~, badTrials, ~, ~] = eegthresh(EEG_subset.data, EEG_subset.pnts, 1:EEG_subset.nbchan, -300, 300, [EEG_subset.xmin EEG.xmax], EEG.xmin, EEG.xmax);
            Clean_Segment_Mask(badTrials) = 0;
            
        elseif strcmpi(Choice,  "Probability+Kurtosis+Frequency")
            threshold_DB = 60;
            threshold_SD = 4;
            % Frequency Spectrum
            [~, bad_Spectrum] = pop_rejspec(EEG_subset, 1, 'elecrange', 1:EEG_subset.nbchan, 'threshold', [-threshold_DB threshold_DB], 'freqlimits', [1 30])
            Clean_Segment_Mask(bad_Spectrum) = 0;
            
            % Probability
            bad_Probability = pop_jointprob(EEG_subset, 1, 1:EEG_subset.nbchan,  threshold_SD,threshold_SD,0,0,0);
            bad_Probability = find(bad_Probability.reject.rejjp);
            Clean_Segment_Mask(bad_Probability) = 0;
            
            % Kurtosis
            bad_Kurtosis = pop_rejkurt(EEG_subset, 1, 1:EEG_subset.nbchan,  threshold_SD,threshold_SD,0,0,0);
            bad_Kurtosis = find(bad_Kurtosis.reject.rejkurt);
            Clean_Segment_Mask(bad_Kurtosis) = 0;
            
        elseif strcmpi(Choice, "EPOS")
            threshold_SD = 4;
            % Approach of rejecting data based on artefactous ICA
            % components requires filterd data. Create copy of data and
            % highpassfiltere it with 1 Hz
            EEG_temp = pop_eegfiltnew(EEG_subset, 'locutoff', 1, 'hicutoff', []);
            % Run ICA
            % correct Rank based on interpolated & available channels
            rank = sum(logical(EEG_Channels)' & logical(INPUT.AC.Clean_Channel_Mask));
            % if common average reference is used, reduce rank by one
            if INPUT.StepHistory.Reference_AC == 'AV'
                rank = rank-1;
            end
            EEG_temp = pop_runica(EEG_temp,'icatype','runica','pca',rank);
            EEG_temp.icaact = eeg_getica(EEG_temp);
            
            % Probability on ICA components
            bad_Probability = pop_jointprob(EEG_temp, 0, 1:size(EEG_temp.icaact,1), 20,threshold_SD,0,0,0);
            bad_Probability = find(bad_Probability.reject.icarejjp);
            Clean_Segment_Mask(bad_Probability) = 0;
            
            % Kurtosis on ICA components
            bad_Kurtosis = pop_rejkurt(EEG_temp, 0, 1:size(EEG_temp.icaact,1), 20,threshold_SD,0,0,0);
            bad_Kurtosis = find(bad_Kurtosis.reject.icarejkurt);
            Clean_Segment_Mask(bad_Kurtosis) = 0;
        end
        
        
        
        % ****** Remove Bad Segments ******
        if EEG.trials > 1
            EEG = pop_rejepoch( EEG, ~Clean_Segment_Mask ,0);
        else
            % for continous data, the indices need to be reshaped. The
            % reject function only accepts ranges, not points. Therefore we
            % need to identify the range that covers the clean data
            % segments.
            retain_data_intervals = reshape(find(diff([false Clean_Segment_Mask false])),2,[])';
            retain_data_intervals(:,2) = retain_data_intervals(:,2)-1;
            % keep only clean range
            EEG = pop_select(EEG, 'point', retain_data_intervals);
        end
        
        % Check that not too many Segments marked as bad
        if sum(Clean_Segment_Mask) < (length(Clean_Segment_Mask)*0.15)
            error('more than 85% of segments were marked as bad');
        end
        
        
    end
    %#####################################################################
    %### Wrapping up Preprocessing Routine                         #######
    %#####################################################################
    % ****** Export ******
    % Script creates an OUTPUT structure. Assign here what should be saved
    % and made available for next step. Always save the EEG structure in
    % the OUTPUT.data field, overwriting previous EEG information.
    OUTPUT.data.(Conditions{i_cond}) = EEG;
    OUTPUT.AC.Clean_Segment_Mask.(Conditions{i_cond}) = Clean_Segment_Mask;
    
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
    if exist('Clean_Segment_Mask', 'var') & sum(Clean_Segment_Mask) < (length(Clean_Segment_Mask)*0.15)
        ErrorMessage = strcat(ErrorMessage, 'more than 85% of segments were marked as bad');
    end
    
    OUTPUT.Error = ErrorMessage;
    
    
end
end
