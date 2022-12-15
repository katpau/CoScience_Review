function  OUTPUT = ECG_Artefact(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following: (order needs to be decided)
% removes same epochs/timepoints as from EEG
% adjust peak criteria
% Extract HP Trace
% Finds bad IBI with Artifact Algorithm
% interpolates or removes ECG data - to be added!
% Baseline Correct



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
StepName = "ECG_Artefact";
Choices = ["remove", "interpolate"];
Conditional = ["NaN", "NaN"];
SaveInterim = logical([0]);
Order = [21];

try
    % Get Data with Sampling Rate, times, events etc.
    ECG = INPUT.ECG;
    
    % setup some information
    % Epoching Infos
    Event_Window = [-0.500 5];
    Condition_Triggers =  {100, 110, 150, 101, 111, 151};
    
    % ********************************************************************************************
    % **** Remove same Data as from EEG *******************************************************
    % ********************************************************************************************
    
    if strcmp(INPUT.StepHistory.Epoching_AC, "no_continous")
        % remove continous data
        retain_data_intervals = reshape(find(diff([false INPUT.AC.EEG.Clean_Segment_Mask' false])),2,[])';
        retain_data_intervals(:,2) = retain_data_intervals(:,2)-1;
        % keep only clean range
        ECG.chanlocs(1).labels = 'ECG_bipolar';
        ECG = pop_select(ECG, 'point', retain_data_intervals);
        % epoch data
        ECG = pop_epoch( ECG, Condition_Triggers, Event_Window, 'epochinfo', 'yes');
        % remove bad epochs
        ECG = pop_rejepoch( ECG, ~INPUT.AC.EEG.Clean_Epochs_Mask ,0);
    else
        % epoch data
        ECG = pop_epoch( ECG, Condition_Triggers, Event_Window, 'epochinfo', 'yes');
        % remove bad epochs first Step
        ECG = pop_rejepoch( ECG, ~INPUT.AC.EEG.Clean_Segment_Mask ,0);
        % remove bad epochs second Step
        ECG = pop_rejepoch( ECG, ~INPUT.AC.EEG.Clean_Epochs_Mask ,0);
    end
    
    % Remove Mean across Epoch  [for detecting peaks! if slow drift in there !]
    ECG = pop_rmbase( ECG, [] ,[]);
    
    % Get Timewindow for BL
    TimeIdx_BL = findTimeIdx(ECG.times, -0.5, 0);
    
    % ********************************************************************************************
    % **** Adjust Peak Criteria  *******************************************************
    % ********************************************************************************************
    
    % criteria for peaks
    minpeakdist= ECG.srate*0.4; % multiply by Sampling rate to get from seconds to sampling points that need to be between two consecutive peaks
    threshold= 200;
    
    % Adjust peak Criteria to reflect expected number of peaks
    [~,peakPosition] = findpeaks(ECG.data(:),'minpeakheight',threshold, 'minpeakdistance',minpeakdist);
    ExpectedBeats = 5;
    range_Expected = 2;
    if length(peakPosition) > ECG.trials * (ExpectedBeats + range_Expected)
        while length(peakPosition) > ECG.trials * (ExpectedBeats + range_Expected)
            threshold = threshold + 50;
            [~,peakPosition] = findpeaks(ECG.data(:),'minpeakheight',threshold, 'minpeakdistance',minpeakdist);
        end
    elseif length(peakPosition) < ECG.trials * (ExpectedBeats - range_Expected)
        while length(peakPosition) > ECG.trials * (ExpectedBeats - range_Expected)
            threshold = threshold - 50;
            [~,peakPosition] = findpeaks(ECG.data(:),'minpeakheight',threshold, 'minpeakdistance',minpeakdist);
        end
    end
    
    
    % ********************************************************************************************
    % ****  Create HP Trace, detect bad IBI and correct *****************************************
    % ********************************************************************************************
    % detect peaks and create continous trace
    ECGPeaks = NaN(size(ECG.data,2), size(ECG.data,3));
    
    for iTrial = 1:ECG.trials
        % find Peaks
        [~,peakPosition] = findpeaks(squeeze(ECG.data(:,:,iTrial)),'minpeakheight',threshold, 'minpeakdistance',minpeakdist);
        
        % calculate time difference between Peak
        IBI=diff(ECG.times(peakPosition)); % in Milliseconds
        
        
        % run ARTiiFACT's implementation of the Berntson algorithm
        % unclear if epochs are long enough or if this should be done on continous data??
        [artifactPos, ~]=detectArtifactsBerntson(IBI'/1000); % IBI in Seconds
        
        
        % create continous trace with distance at each sampling point
        for ipeak = 1:length(peakPosition)-1
            ECGPeaks(peakPosition(ipeak):peakPosition(ipeak+1), iTrial) = IBI(ipeak);
        end
        
        if ~isempty(artifactPos) & strcmp(Choice, "remove")
            ECGPeaks(:,iTrial) = NaN;
        else
            % create continous trace with distance at each sampling point
            for ipeak = 1:length(peakPosition)-1
                ECGPeaks(peakPosition(ipeak):peakPosition(ipeak+1), iTrial) = IBI(ipeak);
            end
            if ~isempty(artifactPos)
                % how to interpolate this?
            end
            
        end
        
        % ********************************************************************
        % **** Baseline Correction   *****************************************
        % ********************************************************************
        % Division or Substraction???
        if strcmp(INPUT.StepHistory.ECG_Baseline, "-500 0")
            % ?? what if no peak in the first ms? then no change?
            BLDiff = nanmean(ECGPeaks(TimeIdx_BL,iTrial));
            if ~isnan(BLDiff)
                ECGPeaks(:,iTrial) = ECGPeaks(:,iTrial) - BLDiff;
            end
        else strcmp(INPUT.StepHistory.ECG_Baseline, "firstTP")
            ECGPeaks(:,iTrial) = ECGPeaks(:,iTrial) - IBI(1);
        end
    end
    
    
    % ****** Prepare Export ******
    % Replace ECG Data with Distance in Peaks
    ECG.data(1,:,:) = ECGPeaks;
    % save some additional data
    ECG.times = ECG.times;
    
    % ****** Updating the OUTPUT structure ******
    % No changes should be made here.
    INPUT.StepHistory.(StepName) = Choice;
    OUTPUT = INPUT;
    OUTPUT.ECG = ECG;
    
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

