function  OUTPUT = Bad_Channels(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

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
Choices = ["EPOS", "Makoto", "HAPPE", "PREP", "FASTER", "APPLE", "CTAP", "No_BadChannels"];
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
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    
    % Get EEGlab EEG structure from the provided Input Structure
    EEG = INPUT.data.EEG;
    
    % Initalize Clean ChannelMask (1 = clean, 0 = to be interpolated)
    Clean_Channel_Mask = ones(EEG.nbchan, 1);
    % Initalize number of bad channel
    BadChannels_Index = [];
    
    % run only if any correction is applied
    if ~strcmpi(Choice, "No_BadChannels" )       
        if strcmpi(Choice, "EPOS")
            [~, bad_prob, ~] = pop_rejchan(EEG, 'threshold',3.29,'norm','on','measure','prob'); 		%we look for probability
            [~, bad_kurt, ~] = pop_rejchan(EEG,'threshold',3.29,'norm','on','measure','kurt');           %we look for kurtosis
            [~, bad_freq, ~] = pop_rejchan(EEG, 'threshold',3.29,'norm','on','measure','spec','freqrange',[1 125] );	%we look for frequency spectra
            BadChannels_Index = sort(unique([bad_prob,bad_kurt,bad_freq]));
            
            
        elseif strcmpi(Choice, "Makoto" )
            EEG_fil = pop_eegfiltnew(EEG, 'locutoff', 1, 'hicutoff', []); % works better on low pass filtered Data
            EEG_removed = clean_artifacts(EEG_fil, 'FlatlineCriterion', 5, 'ChannelCriterion',  0.85, 'LineNoiseCriterion',  4,  ... % use only defaults
                'BurstCriterion','off', 'WindowCriterion', 'off', 'Highpass', 'off'); % No ASR etc.
            [~, BadChannels_Index] = setdiff( {EEG_fil.chanlocs.labels}, {EEG_removed.chanlocs.labels});
            
            
        elseif strcmpi(Choice,"HAPPE")
            [EEG_removed, ~, ~] = pop_rejchan(EEG, 'threshold',[-3 3],'norm','on','measure','spec','freqrange',[1 125] );
            [EEG_removed, ~, ~]= pop_rejchan(EEG_removed, 'threshold',[-3 3],'norm','on','measure','spec','freqrange',[1 125] ); % is applied twice!
            BadChannels_Index=  setdiff({EEG.chanlocs.labels},{EEG_removed.chanlocs.labels});
            BadChannels_Index = find(ismember({EEG.chanlocs.labels}, BadChannels_Index));
            
            
        elseif strcmpi(Choice, "PREP")
            EEG_removed = findNoisyChannels(EEG);
            BadChannels_Index = EEG_removed.noisyChannels.all;
            
        elseif strcmpi(Choice,"FASTER")
            % needs info on a reference channel, use FZ
            Faster_estimate = channel_properties(EEG, 1:EEG.nbchan, find({EEG.chanlocs.labels} == "FZ"));
            BadChannels_Index = find(min_z(Faster_estimate))';
            
        elseif strcmpi(Choice,"APPLE")
            % combines Faster
            % needs info on a reference channel, use FZ
            AC.badChannels_Info.bad_faster = channel_properties(EEG, 1:EEG.nbchan, find({EEG.chanlocs.labels} == "FZ"));
            AC.badChannels_Info.Faster = find(min_z(AC.badChannels_Info.bad_faster ))';
            % & EEGLAB
            [~, AC.badChannels_Info.bad_kurt, AC.badChannels_Info.kurt_info] = pop_rejchan(EEG,'measure','kurt');
            BadChannels_Index =  sort(unique([ AC.badChannels_Info.Faster,AC.badChannels_Info.bad_kurt]));
            
        elseif strcmpi(Choice,"CTAP")
            [BadChannels_Index, ~, ~] = eeg_detect_bad_channels(EEG,  find({EEG.chanlocs.labels} == "FZ"), 'channels', 1:EEG.nbchan);
            BadChannels_Index = find(BadChannels_Index);
        end
        
        % save Bad Channels as a Mask of all channels
        Clean_Channel_Mask = ones(EEG.nbchan,1);
        Clean_Channel_Mask(BadChannels_Index) = 0;

   
        % Interpolate in the complete dataset if a channel was marked as
        if ~isempty(BadChannels_Index)  
            if  sum(Clean_Channel_Mask) == 0 
                e.message = 'All Channels marked as bad (100%!!) .';
                error(e.message);
            end
            if ~contains(INPUT.AnalysisName, "MVPA")
                EEG = pop_interp(EEG, find(~Clean_Channel_Mask), 'spherical');
                EEG = eeg_checkset( EEG );
            end
        end
        
    end
    
    %#####################################################################
    %### Wrapping up Preprocessing Routine                         #######
    %#####################################################################
    % ****** Export ******
    % Script creates an OUTPUT structure. Assign here what should be saved
    % and made available for next step. Always save the EEG structure in
    % the OUTPUT.data field, overwriting previous EEG information.
    OUTPUT.data.EEG = EEG;
    OUTPUT.StepDuration = [OUTPUT.StepDuration; toc];
    OUTPUT.AC.EEG.Clean_Channel_Mask = Clean_Channel_Mask;
    OUTPUT.AC.EEG.Bad_Channel_Names = {EEG.chanlocs(~Clean_Channel_Mask).labels};
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
