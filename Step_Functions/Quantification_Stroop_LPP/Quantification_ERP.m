function  OUTPUT = Quantification_ERP(INPUT, Choice)
% This script does the following:
% Based on information of previous steps, and depending on the forking
% choice, ERPs are quantified based on Mean/Binned Means etc.
% Script also extracts Measurement error and reshapes Output to be easily
% merged into a R-readable Dataframe for further analysis.
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
StepName = "Quantification_ERP";
Choices = ["Mean", "Mean_Binned"];
Conditional = ["NaN", "~contains(TimeWindow, ""Relative"") "];
SaveInterim = logical([1]);
Order = [22];

%%%%%%%%%%%%%%%% Updating the SubjectStructure. No changes should be made here.
INPUT.StepHistory.Quantification_ERP = Choice;
OUTPUT = INPUT;
% Some Error Handling
try
    %%%%%%%%%%%%%%%% Routine for the analysis of this step
    % This functions starts from using INPUT and returns OUTPUT
    
    
    
    % ********************************************************************************************
    % **** Prepare Indexes of  Data to be exported ***********************************************
    % ********************************************************************************************
    
    EEG = INPUT.data.EEG;
    
    % **** Get Info on Electrodes ******
    if strcmp(INPUT.StepHistory.Electrodes, "Relative")
        Electrodes = upper(["AFz", "Fz", "Fcz", "Cz", "Cpz", "Pz", "Poz", "Oz", ...
            "AF3", "F1", "FC1", "C1", "CP1", "P1", "PO3", "O1", ...
            "AF4", "F2", "FC2", "C2", "CP2", "P2", "PO4", "O2"]);
    else
        Electrodes = upper(strsplit(INPUT.StepHistory.Electrodes , ","));
    end
    NrElectrodes = length(Electrodes);
    
    % Get Index on Electrodes ******
    Electrodes = strrep(Electrodes, " ", "");
    ElectrodeIdx = zeros(1, length(Electrodes));
    for iel = 1:length(Electrodes)
        [~, ElectrodeIdx(iel)] = ismember(Electrodes(iel), upper({EEG.chanlocs.labels})); % Do it in this loop to maintain matching/order of Name and Index!
    end
    % Update Nr on Electrodes for Final OutputTable
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        NrElectrodes = 1;
        Electrodes = strcat('Cluster ', join(Electrodes));
    end
    
    
    % ****** Get Info on TimeWindow ******
    TimeWindow = INPUT.StepHistory.TimeWindow;
    if ~contains(TimeWindow, "Relative")
        TimeWindow = str2double(strsplit(TimeWindow, ","));
    elseif strcmp(TimeWindow, "Relative_Subject")
        % find subset to find Peak
        [~, TimeIdx(1)]=min(abs(EEG.times - 300));
        [~, TimeIdx(2)]=min(abs(EEG.times - 1000));
        TimeIdx = TimeIdx(1):TimeIdx(2);
        ERP = mean(mean(EEG.data(ElectrodeIdx,TimeIdx,:),1),3);
        
        % Find Peak in this Subset
        [~, Latency] = Peaks_Detection(ERP, "POS");
        
        % Define Time Window Based on this
        TimeWindow = [EEG.times(Latency+(TimeIdx(1))) - 100, EEG.times(Latency+(TimeIdx(1))) + 100];
    elseif strcmp(TimeWindow, "Relative_Group")
        TimeWindow = [300 1000];
    end
    
    % Get Index of TimeWindow
    [~, TimeIdx(1)]=min(abs(EEG.times - TimeWindow(1)));
    [~, TimeIdx(2)]=min(abs(EEG.times - TimeWindow(2)));
    TimeIdx = TimeIdx(1):TimeIdx(2);

    % If Window is binned into early and later, then Adjust here
    if strcmp(Choice, "Mean_Binned")
        HalfWindow = (TimeWindow(2)-TimeWindow(1))/2;
        TimeWindow(2,1) = TimeWindow(1)+HalfWindow;
        TimeWindow(2,2) = TimeWindow(1,2);
        TimeWindow(1,2) = TimeWindow(2,1);
        HalfWindowIdx = ceil(length(TimeIdx)/2);
        NrTimeWindows = 2;
    else
        NrTimeWindows = 1;
    end
    
    
    
    
    % ********************************************************************************************
    % **** Epoch Data into different Conditions **************************************************
    % ********************************************************************************************
     % For saving ERP, select only relevant channels
     EEG_for_ERP = EEG;
     Electrodes_ERP = { 'FCZ', 'CZ', 'CPZ', 'PZ', 'POZ', 'C1', 'CP1', 'P1', 'PO3', 'C2', 'CP2', 'P2', 'PO4'};
     EEG_for_ERP = pop_select(EEG_for_ERP, 'channel',Electrodes_ERP);
     % For saving ERP, always downsample!
      EEG_for_ERP =  pop_resample(EEG_for_ERP, 100);
     
     %Info on Epochs
    Event_Window = [-0.300 1.000];
    Condition_Triggers =  [ 11, 12, 13, 14, 15, 16, 17, 18; 21, 22, 23, 24, 25, 26, 27, 28; 31, 32, 33, 34, 35, 36, 37, 38; ...
        41, 42, 43, 44, 45, 46, 47, 48; 51, 52, 53, 54, 55, 56, 57, 58; 61, 62, 63, 64, 65, 66, 67, 68; ...
        71, 72, 73, 74, 75, 76, 77, 78]; % Picture Onset
    Condition_Names = ["Tree", "Erotic_Couple", "Erotic_Man", "Neutral_ManWoman", "Neutral_Couple", "Positive_ManWoman", "Erotic_Woman"];
    NrConditions = length(Condition_Names);
    

     
    for i_Cond = 1:NrConditions
        % * Epoch Data around predefined window and save each
        Interim = pop_epoch( EEG_for_ERP, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
        ForRelative = pop_epoch( EEG, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
        ConditionData.(Condition_Names(i_Cond)) = ForRelative.data;
        % Calculate ERP
        ERP_toExport.(Condition_Names(i_Cond)) = mean(Interim.data,3);
    end
    ERP_toExport.times = Interim.times;
    ERP_toExport.chanlocs = Interim.chanlocs;
    
    
    
    % ********************************************************************************************
    % **** Loop Through each Condition and extract Data ******************************************
    % ********************************************************************************************
    % if depending on group, crop data and save data for now
    if strcmp(INPUT.StepHistory.TimeWindow, "Relative_Group") || strcmp(INPUT.StepHistory.Electrodes, "Relative")
        % for this ERP some montages do not have all channels
        ElectrodeIdx = ElectrodeIdx(ElectrodeIdx>0);
        Export.Data = EEG.data(ElectrodeIdx,TimeIdx,:);
        Export.Times = EEG.times(TimeIdx);
        Export.Electrodes = {EEG.chanlocs(ElectrodeIdx).labels};
        Export.ACC = EEG.ACC;
        
    else
        % if not dependent on group,
        % ****** Extract Amplitude, SME, Epoch Count ******
        InitSize = [NrElectrodes,NrConditions, NrTimeWindows];
        EpochCount = NaN(InitSize); ERP =NaN(InitSize); SME=NaN(InitSize);
        Trials = NaN(NrConditions);
        
        for i_Cond = 1:NrConditions
            % Select relevant Data
            Data = ConditionData.(Condition_Names(i_Cond))(ElectrodeIdx,TimeIdx,:);
            
            % check if Electrodes should be averaged across, or kept
            % separate
            if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                Data = mean(Data, 1); % first dimensions are Electrodes
            end
            
            % Count Epochs
            EpochCount(:,i_Cond,:) = size(Data,3);
            if Trials(i_Cond) < str2double(INPUT.StepHistory.Trials_MinNumber)
                ERP(:,i_Cond,:) = NaN;
                SME(:,i_Cond,:) = NaN;
            else
                % Calculate Mean if enough epochs there
                if ~strcmp(Choice, "Mean_Binned")
                    ERP(:,i_Cond,1) = mean(mean(Data,3),2);
                    SME(:,i_Cond,1) = Mean_SME(Data);
                else
                    ERP(:,i_Cond,1) = mean(mean(Data(:, 1:HalfWindowIdx,:),3),2);
                    SME(:,i_Cond,1) = Mean_SME(Data(:, 1:HalfWindowIdx,:));
                    ERP(:,i_Cond,2) = mean(mean(Data(:, HalfWindowIdx+1:length(TimeIdx),:),3),2);
                    SME(:,i_Cond,2) = Mean_SME(Data(:, HalfWindowIdx+1:length(TimeIdx),:));
                end
            end
        end
        
        % ********************************************************************************************
        % **** Prepare Output Table    ***************************************************************
        % ********************************************************************************************     
        % ****** Prepare Labels ****** 
        % Subject, Lab and experimenter is constant
        if isfield(INPUT, "Subject"); INPUT.SubjectName = INPUT.Subject; end
        Subject_L = repmat(INPUT.SubjectName, NrConditions*NrElectrodes*NrTimeWindows,1 );
        Lab_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodes*NrFreqWindow,1 );
        Experimenter_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodes*NrFreqWindow,1 );
        
        % Electrodes: if multiple electrodes, they simply alternate
        Electrodes_L = repmat(Electrodes', NrConditions*NrTimeWindows, 1);
        % Conditions are blocked across electrodes, but alternate across time windows
        Conditions_L = repelem(Condition_Names', NrElectrodes,1);
        Conditions_L = repmat([Conditions_L(:)], NrTimeWindows,1);
        % Time Window are blocked across electrodes and conditions
        TimeWindow_L = repmat(convertCharsToStrings(num2str(TimeWindow(1,:))), NrConditions*NrElectrodes, 1);
        if NrTimeWindows == 2
            TimeWindow_L = [TimeWindow_L; repmat(convertCharsToStrings(num2str(TimeWindow(2,:))), NrConditions*NrElectrodes, 1) ];
        end
        
        
        % ****** Prepare Table ****** 
        Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L, Electrodes_L, TimeWindow_L]),...
            num2cell([ERP(:), SME(:), EpochCount(:)])];
        
        % Add ACC
        Export = [Export, num2cell(repmat(EEG.ACC, size(Export,1), 1))]
    end
    OUTPUT.data = [];
    OUTPUT.data.Export = Export;
    OUTPUT.data.ERP = ERP_toExport;
    
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

%% house built functions to detect peaks (and bootstrap SME)
    function [Peaks, Latency] = Peaks_Detection(Subset, PeakValence)
        if PeakValence == "NEG"
            % Find possible Peak
            possiblePeaks = islocalmin(Subset,2);
            Subset(~possiblePeaks) = NaN;
            % Identify largest Peak
            [Peaks, Latency]  = min(Subset,[],2);
            
        elseif PeakValence == "POS"
            % Find Possible Peak
            possiblePeaks = islocalmax(Subset,2);
            Subset(~possiblePeaks) = NaN;
            % Identify largest Peak
            [Peaks, Latency]  = max(Subset,[],2);
        end
    end

% SME of Mean Values
    function SME = Mean_SME(Subset)
        % Calculate Mean per Trial
        Mean_perTrial = squeeze(mean(Subset,2));
        % Take SD of these means
        if size(Mean_perTrial,2) == 1
            SME = std(Mean_perTrial,[],1)/sqrt(length(Mean_perTrial));
        else
            SME = std(Mean_perTrial,[],2)/sqrt(length(Mean_perTrial));
        end
    end


end

