function  OUTPUT = Quantification_Asymmetry(INPUT, Choice)
% This script does the following:
% Depending on the forking choice, it uses the choices from the previous
% steps to quantify Alpha Asymmetry
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
StepName = "AsymmetryScore";
Choices = ["diff", "separate"];
Conditional = ["NaN", "NaN"];
SaveInterim = logical([0]);
Order = [21];

%****** Updating the OUTPUT structure ******
INPUT.StepHistory.AsymmetryScore = Choice;
OUTPUT = INPUT;
tic
try

    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    
    Conditions = fieldnames(INPUT.data);
    EEG = INPUT.data.(Conditions{1}); % get one EEG file to index Electrodes
    
    % **** Get Info on Electrodes ******
    Electrodes = upper(strsplit(INPUT.StepHistory.Electrodes , ", "));
    [~, ElectrodeIdx] = ismember(Electrodes, {EEG.chanlocs.labels});  
    NrElectrodes = length(Electrodes);
    
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        NrElectrodes = 1;
        Electrodes = strcat('Cluster  ', join(Electrodes));
    end
    
    % ****** Get Info on Frequency Band ******
    FrequencyChoice = INPUT.StepHistory.FrequencyBand;
    nfft = 2^nextpow2(EEG.pnts);    % Next power of 2 from length of epochs
    frequencies = EEG.srate/2*linspace(0,1,nfft/2+1);
    FreqIdx = [];
    
    % for every Condition
    power_AllConditions =[];
    FreqData=[];
    
    % Initate Power Array filled with NaNs
    Trials = [];
      for i_cond = 1:length(Conditions)
          Trials = [Trials,  INPUT.data.(Conditions{i_cond}).trials];
      end   
    power_AllConditions = repmat(NaN, length(ElectrodeIdx), nfft/2+1, max(Trials), length(Conditions));
    
    for i_cond = 1:length(Conditions)
        FreqData = [];
        % Get EEGlab EEG structure from the provided Input Structure
        EEG = INPUT.data.(Conditions{i_cond});
        
        % ****** Calculate FFT for every condition ******
        Data = EEG.data(ElectrodeIdx,:,:);
        
        % check if min number of trials included, otherwise replace by
        % NaN
        if EEG.trials*EEG.pnts/EEG.srate/60 < str2num(INPUT.StepHistory.MinimumData)
            Data = repmat(NaN, size(Data));
        end
        
        % Apply Hanning Window
        if INPUT.StepHistory.Hanning == "100"
            Data = Data.*[hann(EEG.pnts)]';
        elseif  INPUT.StepHistory.Hanning == "10"
        end
        
        % Calculate FFT
        for ielectrode = 1:length(ElectrodeIdx)
            for   itrial = 1:EEG.trials
            FreqData(ielectrode, :, itrial) = fft(Data(ielectrode,:,itrial),nfft)/EEG.pnts;    % Calculate Frequency Spectrum
            % Array of Electrodes : Frequencies : Trials
            end
        end 
        power = abs(FreqData(:, 1:nfft/2+1, :)); % take only frequencies of Nyquist plus DC
        power_AllConditions(:,:, 1:EEG.trials, i_cond) = power; % Keep Power for individual trials
    end
    
 
    
    % **** Get Info on Frequency Window ******
    if contains(FrequencyChoice, "relative")
        % Window is dependent on maximum of frontal electrodes
        % Take peak within alpha range
        [~, Broadwindow(1)]  = min(abs(frequencies - 8));
        [~, Broadwindow(2)]  = min(abs(frequencies - 13));
        % take only frontal electrodes
        if ~contains(INPUT.StepHistory.Electrodes, "P3") % only Frontal ones
            FrontalPower = mean(mean(mean(power_AllConditions(:,[Broadwindow(1):Broadwindow(2)],:), 3,'omitnan' ) ,1,'omitnan' ),4,'omitnan' );
        elseif ~contains(INPUT.StepHistory.Electrodes, "P5") % only one electrode pair
            FrontalPower = mean(mean(mean(power_AllConditions([1:2],[Broadwindow(1):Broadwindow(2)],:), 3, 'omitnan' ) ,1, 'omitnan' ),4, 'omitnan' );
        else % three electrode pairs
            FrontalPower = mean(mean(mean(power_AllConditions([7:12],[Broadwindow(1):Broadwindow(2)],:), 3, 'omitnan' ) ,1, 'omitnan' ),4, 'omitnan' );
        end
        
        % Identify Maximum Power
        [~, MaxIdx] = max(FrontalPower);
        MaxFreq = frequencies(Broadwindow(1) + MaxIdx -1);
        
        % Set individualised Frequency Ranges
        if  contains(FrequencyChoice, "single")
            FrequencyBand = [MaxFreq-4, MaxFreq+2];
        elseif contains(FrequencyChoice, "double")
            FrequencyBand = [MaxFreq-4, MaxFreq; MaxFreq, MaxFreq+2];
        end
        
    elseif ~contains(FrequencyChoice, "relative")
        % Window is set
        FreqChoice = strsplit(FrequencyChoice, "_");
        FreqChoice = FreqChoice(2);
        if  contains(FrequencyChoice, "single")
            FrequencyBand = strsplit(FreqChoice, "-");
        elseif contains(FrequencyChoice, "double")
            FreqChoice = strsplit(FreqChoice, ";");
            FrequencyBand = [strsplit(FreqChoice(1), "-"); strsplit(FreqChoice(2), "-")];
        end
    end
    
    % Get index of frequencies
    [~,FreqIdx(1,1)] = min(abs(frequencies - str2num(FrequencyBand(1,1))));
    [~,FreqIdx(1,2)] = min(abs(frequencies - str2num(FrequencyBand(1,2))));
    
    if contains(FrequencyChoice, "double")
        [~,FreqIdx(2,1)] = min(abs(frequencies - str2num(FrequencyBand(2,1))));
        [~,FreqIdx(2,2)] = min(abs(frequencies - str2num(FrequencyBand(2,2))));
    end
    
    
    
    % ****Calculate Average across Electrodes ******
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        if contains(INPUT.StepHistory.Electrodes, "F5")
            BU_power = power_AllConditions;
            power_AllConditions = [];
            power_AllConditions(1,:,:,:) = mean(BU_power([1,3,5], :, :,:),1, 'omitnan' );
            power_AllConditions(2,:,:,:) = mean(BU_power([2,4,6], :, :,:),1, 'omitnan' );
            if contains(INPUT.StepHistory.Electrodes, "P3")
                power_AllConditions(3,:,:,:) = mean(BU_power([7,9,11], :, :,:),1, 'omitnan' );
                power_AllConditions(4,:,:,:) = mean(BU_power([8,10,12], :, :,:),1, 'omitnan' );
            end
        end
    end
    
    
    
    % **** Calculate Average across frequency range ******
    Alpha = mean(power_AllConditions(:,FreqIdx(1,1):FreqIdx(1,2),:,:), 2, 'omitnan' );
    
    if contains(FrequencyChoice, "double")
        Alpha = [Alpha; mean(power_AllConditions(:,FreqIdx(2,1):FreqIdx(2,2),:,:), 2, 'omitnan' )];
    end

     % Mean across Trials
    Alpha_Export = log(mean(Alpha, 3, 'omitnan' ));

    %% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %% !! IF DIFF; then calc diff on each trial and take SME OF THAT
    %% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    % Add missing!!!
    %% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
    %% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    % Calculate Difference Score of logs and mean of SME
    if INPUT.StepHistory.Quantification_Asymmetry == "diff"
        Alpha_Export = log(Alpha_Export ([1:2:size(Alpha_Export ,1)],:,:,:)) - log(Alpha_Export ([2:2:size(Alpha_Export ,1)],:,:,:));
        SingleTrial = log(Alpha(1:2:size(Alpha ,1)],:,:,:)) - log(Alpha(2:2:size(Alpha ,1)],:,:,:)) ;
        SME_Export = std(SingleTrial, [], 3, 'omitnan')/sqrt(size(SingleTrial, 3));
        SME_Export = (SME_Export([1:2:size(SME_Export ,1)],:,:,:) + SME_Export([2:2:size(SME_Export ,1)],:,:,:))/2;
    else
        SME_Export = std(log(Alpha), [], 3, 'omitnan' )/sqrt(size(Alpha, 3));

    end
    
    % ****  Prepare Output Table ****
    % Prepare Labels
    
    if INPUT.StepHistory.AsymmetryScore == "diff"
        NrAlphas = 1;
        switch INPUT.StepHistory.Electrodes
            case "F3, F4"
                ElectrodeNames = ["F4-F3"];
                Localisation = "Frontal";
                
                
            case "F3, F4, F5, F6, AF3, AF4"
                if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                    ElectrodeNames = ["F4,F6,AF4-F3,F5,AF3"];
                    Localisation = "Frontal";
                    
                else
                    ElectrodeNames = ["F4-F6", "F6-F5", "AF4-AF3"];
                    Localisation = ["Frontal","Frontal","Frontal"];
                end
                
            case "F3, F4, P3, P4"
                ElectrodeNames = ["F4-F3", "P4-P3"];
                Localisation = ["Frontal", "Parietal"];
                
                
            case "F3, F4, F5, F6, AF3, AF4, P3, P4, P5, P6, PO3, PO4"
                if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                    ElectrodeNames = ["F4,F6,AF4-F3,F5,AF3", "P4,P6,PO4-P3,P5,PO3"];
                    Localisation = ["Frontal", "Parietal"];
                else
                    ElectrodeNames = ["F4-F6", "F6-F5", "P4-P3", "P6-P5", "PO4-PO3"];
                    Localisation = ["Frontal", "Frontal", "Frontal", "Parietal", "Parietal", "Parietal"];
                end
        end
        AlphaType = repmat("diff", size(Localisation));
        
    elseif INPUT.StepHistory.AsymmetryScore == "separate"
        switch  INPUT.StepHistory.Electrodes
            case "F3, F4"
                ElectrodeNames = Electrodes;
                Localisation = repmat("Frontal", size(Electrodes));
                AlphaType = ["left", "right"];
                
            case "F3, F4, F5, F6, AF3, AF4"
                if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                    ElectrodeNames = ["F3,F5,AF3", "F4,F6,AF4"];
                    Localisation = ["Frontal", "Parietal"];
                    AlphaType = ["left", "right"];
                    
                else
                    ElectrodeNames = Electrodes;
                    Localisation = sort(repmat(["Frontal", "Parietal"],1,length(Electrodes)/2));
                    AlphaType = repmat(["left", "right"],1,length(Electrodes)/2);
                end
                
                
            case "F3, F4, P3, P4"
                ElectrodeNames = Electrodes;
                Localisation = sort(repmat(["Frontal", "Parietal"], 1, 2));
                AlphaType = repmat(["left", "right"],1,length(Electrodes)/2);
                
            case "F3, F4, F5, F6, AF3, AF4, P3, P4, P5, P6, PO3, PO4"
                if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                    ElectrodeNames = ["F3,F5,AF3", "F4,F6,AF4", "P3,P5,PO3", "P4,P6,PO4"];
                    Localisation = ["Frontal","Frontal", "Parietal", "Parietal"];
                    AlphaType = ["left",  "right", "left", "right"];
                    
                else
                    ElectrodeNames = Electrodes;
                    Localisation = sort(repmat(["Frontal", "Parietal"],1,length(Electrodes)/2));
                    AlphaType = repmat(["left", "right"],1,length(Electrodes)/2);
                end
        end
        
    end
    
    
    
    % Restructure Alpha
    % Alpha is of size: NrElectrodes*FreqWindow times Conditions
    NrConditions = length(Conditions);
    NrElectrodes = length(ElectrodeNames);
    NrFreqWindow =  size(FreqIdx,1);
    % Repeat Labels
    % Electrodes, Alpha, Freq alternate
    Electrodes_L = repmat([AlphaType;ElectrodeNames;Localisation], 1, NrConditions*NrFreqWindow);
    % Conditions same for all electrodes
    Conditions_L = repmat(repelem(Conditions', 1, NrElectrodes)',NrFreqWindow,1);
    % EpochCount Bound to Conditinos
    EpochCount = size(Alpha, 3)';
    EpochCount = repmat(repelem(Trials, 1, NrElectrodes)',NrFreqWindow,1);    
    % Frequencies same across electrodes
    Freq_L = repelem(string(num2str(frequencies(FreqIdx)))', 1, NrElectrodes*NrConditions)';
    % Subject is constant
    Subject_L = repmat(INPUT.SubjectName, NrConditions*NrElectrodes*NrFreqWindow,1 );
    
    % Prepare Table
    % in Format Subject - Condition - AlphaType - Electrode - Localisation - FreqWindow - Alpha - SME - Epoch Count
  
    Alpha_Table = cellstr([Subject_L, Conditions_L, Electrodes_L', Freq_L, [Alpha_Export(:)], [SME_Export(:)], EpochCount]);

    
    %#####################################################################
    %### Wrapping up Preprocessing Routine                         #######
    %#####################################################################
    % ****** Export ******
    % Script creates an OUTPUT structure. Assign here what should be saved
    % and made available for next step. Always save the EEG structure in
    % the OUTPUT.data field, overwriting previous EEG information.

    OUTPUT.data = []; % remove old EEG data
    OUTPUT.data = Alpha_Table; % save new structure
   
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
