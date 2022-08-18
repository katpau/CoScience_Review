function  OUTPUT = Bad_Channels(INPUT, Choice)
% This script does the following:
% It identifies bad channels based on forking criteria, and it interpolates
% these bad channels.
% It should be able to handle all options from "Choices" below (see Summary).


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
StepName = "Bad_Channels";
Choices = ["EPOS", "Makoto", "HAPPE", "PREP", "FASTER", "APPLE", "CTAP", "None"];
Conditional = ["NaN", "NaN", "NaN", "NaN", "NaN", "NaN", "NaN", "NaN"];
SaveInterim = logical([0]);
Order = [3];

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
tic % for keeping track of time
try % For Error Handling, all steps are positioned in a try loop to capture errors
    
    %#####################################################################
    %### Resting Data processed for each Condition/Run separately  #######
    %#####################################################################
    % Triggers and Name of Condition
    Triggers = [11 12 21 22 31 32];
    ConditionName = {'R1_open' 'R1_closed' 'R2_open' 'R2_closed' 'R3_open' 'R3_closed'};

    % Restructure INPUT.data so that it is a structure of six fields (number
    % of conditions). Name every field like the condition and put subset of
    % EEG there as continous data
    
    ContinousData = INPUT.data;
    INPUT.data = [];
    OUTPUT.data = [];
    for i_cond = 1:length(ConditionName)
    EEG = pop_epoch(ContinousData, {num2str( Triggers(i_cond))}, [0  60], 'epochinfo', 'yes');
    EEG = eeg_epoch2continuous(EEG);
    EEG = pop_editeventvals( EEG, 'sort', {'latency' 0}); 
    EEG.filename = strrep(EEG.filename, "eeg.set", strcat(ConditionName(i_cond), "_eeg.set"));   
    INPUT.data.(ConditionName{i_cond}) = EEG;
    end
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    Conditions = fieldnames(INPUT.data);
    for i_cond = 1:length(Conditions)
    % Get EEGlab EEG structure from the provided Input Structure
    EEG = INPUT.data.(Conditions{i_cond});
    
    % Initalize Clean ChannelMask (1 = clean, 0 = to be interpolated)
    Clean_Channel_Mask = ones(EEG.nbchan, 1);
    % Initalize number of bad channel 
    BadChannels_Index = [];

    % run only if any correction is applied
    if ~strcmpi(Choice, "None" )
        % ****** Create Subset ******
        % External channels are excluded from the search since they usually
        % exceed the limits, and because EOGs are needed for later correction
        % methods (correlations with bipolar VEOG). Also exclude Mastoids as
        % these are needed for rereferencing later.
        
        % select EEG Channels
        EEG_Channels = zeros(EEG.nbchan, 1);
        EEG_Channels = ismember({EEG.chanlocs.type}, {'EEG'}) ... % only of type EEG
            & ~contains({EEG.chanlocs.labels}, "MAST") ... % exclude Mastoids
            & ~ismember({EEG.chanlocs.labels}, EEG.ref); % exclude Reference
        
        % Create a subset with only relevant EEG Channels to identify outliers
        EEG_subset = pop_select( EEG, 'channel', find(EEG_Channels));
        
        if strcmpi(Choice, "EPOS")
            [~, bad_prob, ~] = pop_rejchan(EEG_subset, 'threshold',3.29,'norm','on','measure','prob'); 		%we look for probability
            [~, bad_kurt, ~] = pop_rejchan(EEG_subset,'threshold',3.29,'norm','on','measure','kurt');           %we look for kurtosis
            [~, bad_freq, ~] = pop_rejchan(EEG_subset, 'threshold',3.29,'norm','on','measure','spec','freqrange',[1 125] );	%we look for frequency spectra
            BadChannels_Index = sort(unique([bad_prob,bad_kurt,bad_freq]));
            
            
        elseif strcmpi(Choice, "Makoto" )
            EEG_subset = pop_eegfiltnew(EEG_subset, 'locutoff', 1, 'hicutoff', []); % works better on low pass filtered Data
            Cleaned = clean_artifacts(EEG_subset, 'FlatlineCriterion', 5, 'ChannelCriterion',  0.85, 'LineNoiseCriterion',  4,  ... % use only defaults
                'BurstCriterion','off', 'WindowCriterion', 'off', 'Highpass', 'off'); % No ASR etc.
            [~, BadChannels_Index] = setdiff( {EEG_subset.chanlocs.labels}, {Cleaned.chanlocs.labels});
            
            
        elseif strcmpi(Choice,"HAPPE")
            [EEG_removed, ~, ~] = pop_rejchan(EEG_subset, 'threshold',[-3 3],'norm','on','measure','spec','freqrange',[1 125] );
            [EEG_removed, ~, ~]= pop_rejchan(EEG_removed, 'threshold',[-3 3],'norm','on','measure','spec','freqrange',[1 125] ); % is applied twice!
            BadChannels_Index=  setdiff({EEG_subset.chanlocs.labels},{EEG_removed.chanlocs.labels});
            BadChannels_Index = find(ismember({EEG.chanlocs.labels}, BadChannels_Index));
            
            
        elseif strcmpi(Choice, "PREP")
            EEG_removed = findNoisyChannels(EEG_subset);
            BadChannels_Index = EEG_removed.noisyChannels.all;
            
        elseif strcmpi(Choice,"FASTER")
            % needs info on a reference channel, use FZ
            Faster_estimate = channel_properties(EEG, 1:EEG_subset.nbchan, find({EEG.chanlocs.labels} == "FZ"));
            BadChannels_Index = find(min_z(Faster_estimate))';
            
        elseif strcmpi(Choice,"APPLE")
            % combines Faster
            % needs info on a reference channel, use FZ
            AC.badChannels_Info.bad_faster = channel_properties(EEG, 1:EEG_subset.nbchan, find({EEG.chanlocs.labels} == "FZ"));
            AC.badChannels_Info.Faster = find(min_z(AC.badChannels_Info.bad_faster ))';
            % & EEGLAB
            [~, AC.badChannels_Info.bad_kurt, AC.badChannels_Info.kurt_info] = pop_rejchan(EEG_subset,'measure','kurt');
            BadChannels_Index =  sort(unique([ AC.badChannels_Info.Faster,AC.badChannels_Info.bad_kurt]));
            
        elseif strcmpi(Choice,"CTAP")
            [BadChannels_Index, ~, ~] = eeg_detect_bad_channels(EEG,  EEG.Reference_Channel, 'channels', 1:EEG_subset.nbchan);
            BadChannels_Index = find(BadChannels_Index);
        end
        
        % save Bad Channels as a Mask of all channels
        EEG_Channels_Mask = ones(sum(EEG_Channels),1);
        EEG_Channels_Mask(BadChannels_Index) = 0;
        Clean_Channel_Mask(logical(EEG_Channels)) = EEG_Channels_Mask;
        
        % Check that not too many Channels marked as bad, otherwise throw
        % an error
        if sum(Clean_Channel_Mask) < (length(Clean_Channel_Mask)*0.15)
            error('Note more than 85% of channels were marked as bad');
        end
        
        % Interpolate in the complete dataset if a channel was marked as
        % bad
        if sum(Clean_Channel_Mask) < (length(Clean_Channel_Mask)*0.15)
            EEG = pop_interp(EEG, find(Clean_Channel_Mask), 'spherical');
            EEG = eeg_checkset( EEG );
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
    OUTPUT.AC.Clean_Channel_Mask.(Conditions{i_cond}) = Clean_Channel_Mask;
    OUTPUT.AC.Bad_Channel_Names.(Conditions{i_cond}) = {EEG.chanlocs(~Clean_Channel_Mask).labels};
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
    if exist('Clean_Channel_Mask', 'var') & sum(Clean_Channel_Mask)<1
        ErrorMessage = strcat(ErrorMessage, "Note: All Channels marked as bad") ;
    end
    OUTPUT.Error = ErrorMessage;
end
end
