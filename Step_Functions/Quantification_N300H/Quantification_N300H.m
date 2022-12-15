function  OUTPUT = Quantification_ERP(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following:
% Based on information of previous steps, and depending on the forking
% choice, N300H is calculated and Exported.
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
StepName = "Quantification_N300H";
Choices = ["Mean", "Bins", "Maximum"];
Conditional = ["NaN", "NaN", "NaN"];
SaveInterim = logical([1]);
Order = [24];


%%%%%%%%%%%%%%%% Updating the SubjectStructure. No changes should be made here.
INPUT.StepHistory.Quantification_ERP = Choice;
OUTPUT = INPUT;
OUTPUT.data = [];
% Some Error Handling
try
    %%%%%%%%%%%%%%%% Routine for the analysis of this step
    EEG = INPUT.data.EEG;
    ECG = INPUT.ECG;
    
    % Info on ** Epochs **
    Event_Window = [-0.200 2];
    Event_WindowECG = [-0.5 5];
    Condition_Triggers =  {100, 110, 150; 101, 111, 151};
    Condition_Names = ["Loss", "Win"];
    NrConditions = length(Condition_Names);
    
    
    % ********************************************************************************************
    % **** Set Up Some Information for EEG *******************************************************
    % ********************************************************************************************
    % Get Info on ** Electrodes **
    Electrodes = strrep(upper(strsplit(INPUT.StepHistory.Electrodes , ",")), " ", "");
    NrElectrodes = length(Electrodes);
    ElectrodeIdx = findElectrodeIdx(EEG.chanlocs, Electrodes);
    
    % ****** Get Info on TimeWindow EEG ******
    TimeWindow_EEG = INPUT.StepHistory.TimeWindow;
    TimeWindow_EEG = str2double(strsplit(TimeWindow_EEG, ","));
    if ~contains(TimeWindow_EEG, "Relative")
        TimeWindow_EEG = str2double(strsplit(TimeWindow_EEG, ","));
    else
        % Time window needs to be longer since peak could be at edge
        % this part of the data will be exported later
        TimeWindow_EEG = [150 500];
    end
    
    % Get Index of TimeWindow  [in Sampling Points]
    TimeIdx_EEG = findTimeIdx(EEG.times, TimeWindow_EEG(1), TimeWindow_EEG(2));
    
    
    
    % ********************************************************************************************
    % **** Set Up Some Information ECG *************************************************************
    % ********************************************************************************************
    % ****** Get Info on TimeWindow ECG ******
    TimeWindow_ECG = INPUT.StepHistory.ECG_TimeWindow;
    TimeWindow_ECG = str2double(strsplit(TimeWindow_ECG, ","));
    if ~contains(TimeWindow_EEG, "Relative")
        TimeWindow_ECG = str2double(strsplit(TimeWindow_ECG, ","));
    else
        % Time window needs to be longer since peak could be at edge
        % this part of the data will be exported later
        TimeWindow_ECG = [1500 5500];
    end
    
    % Get Index of TimeWindow  [in Sampling Points]
    TimeIdx_ECG = findTimeIdx(ECG.times, TimeWindow_ECG(1), TimeWindow_ECG(2));
    
    % ********************************************************************************************
    % ****  Prepare EEG & ECG Data *************************************************************************
    % ********************************************************************************************
    for i_Cond = 1:NrConditions
        % * Epoch Data around predefined window and save each
        EEGData = pop_epoch( EEG, Condition_Triggers(i_Cond,:), Event_Window, 'epochinfo', 'yes');
        ECGData = pop_epoch( ECG, Condition_Triggers(i_Cond,:), Event_WindowECG, 'epochinfo', 'yes');
        
        % Extract only relevant TimeWindow
        EEG.(Condition_Names(i_Cond)) = EEGData.data(ElectrodeIdx, TimeIdx_EEG,:);
        ECG.(Condition_Names(i_Cond)) = ECGData.data(TimeIdx_ECG,:);
        
        % Update Nr on Electrodes for Final OutputTable if Clustered before calculating N300H
        if INPUT.StepHistory.Cluster_Electrodes == "cluster"
            NrElectrodes = 1;
            Electrodes = strcat('Cluster ', join(Electrodes));
            EEG.(Condition_Names(i_Cond)) = mean(EEG.(Condition_Names(i_Cond)),1);
        end
    end
    
    
    % ********************************************************************************************
    % **** Extract Data and prepare Output Table    **********************************************
    % ********************************************************************************************
    % if any Time window is dependent on group, do not continue but save
    % relevant data
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group") || contains(INPUT.StepHistory.ECG_TimeWindow, "Relative_Group"
        For_Relative.RecordingLab = EEG.Info_Lab.RecordingLab;
        For_Relative.Experimenter = EEG.Info_Lab.Experimenter;
        For_Relative.DataEEG = EEG;
        For_Relative.DataECG = ECG;
        For_Relative.Times = EEGData.times(TimeIdx_EEG);
        For_Relative.Electrodes = Electrodes;
        
        
    else
        % ****** Extract N300H ******
        
        % ****** Create BINS ******
        % EEG: ca. 10 ms (depending on sampling rate); ECG: ca. 500 ms (depending on sampling rate)
        
        % ****** Calculate Correlation ******
        % Fisher Z-transformed lagged Pcorrelation (Pearson’s r)
        % N300H = atanh(r)?????
        
        % ****** Export N300H ******
        if Choice == "Bins"
            NrBins = 2; % ???
            Bin_L = num2str(1:NrBins);
        else
            NrBins = 1;
            Bin_L = "one";
        end
        
        InitSize = [NrElectrodes,NrConditions, NrBins]; %
        EpochCount = NaN(InitSize);
        ERP =NaN(InitSize); SME=NaN(InitSize);
        
        
        for i_Cond = 1:NrConditions
            Data = ConditionData.(Condition_Names{i_Cond});
            
            % Count Epochs
            EpochCount(:,i_Cond,:) = size(Data,3);
            if size(Data,3) < str2double(INPUT.StepHistory.Trials_MinNumber)
                ERP(:,i_Cond,:) = NaN;
                SME(:,i_Cond,:) = NaN;
            else
                
                
                
                
                % Calculate Mean across Bins
                if strcmp(Choice, "Mean")
                    ERP(:,i_Cond,:) = mean(N300H,3);
                    % SME(:,i_Cond,1) = Mean_SME(N300H); ?? how to get SME?
                    
                    % Export each Bin
                elseif strcmp(Choice, "Bins")
                    ERP(:,i_Cond,:) = N300H;
                    % SME(:,i_Cond,1) = Mean_SME(N300H); ??
                    
                    % Take Maximum of Bin
                elseif strcmp(Choice, "Maximum")
                    ERP(:,i_Cond,:) = max(N300H,2);
                    % SME(:,i_Cond,1) = Mean_SME(N300H); ??
                end
            end
        end
    end
    
    % Update Nr on Electrodes for Final OutputTable if Clustered after N300H
    if INPUT.StepHistory.Cluster_Electrodes == "no_cluster_butAV"
        NrElectrodes = 1;
        Electrodes = strcat('AV_of', join(Electrodes));
        ERP = mean(ERP,1);
        %SME = mean(SME,1);
    end
    
    
    
    
    
    
    % ********************************************************************************************
    % **** Prepare Output Table    ***************************************************************
    % ********************************************************************************************
    
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group") || contains(INPUT.StepHistory.ECG_TimeWindow, "Relative_Group")
        % Add Relative Data and Relative Info
        OUTPUT.data.For_Relative = For_Relative;
    else
        % Prepare Final Export with all Values
        % ****** Prepare Labels ******
        % Subject, ComponentName, Lab, Experimenter is constant AAA
        Subject_L = repmat(INPUT.Subject, NrConditions*NrElectrodes*NrBins,1 );
        Lab_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodes*NrBins,1 );
        Experimenter_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodes*NrBins,1 );
        Component_L = repmat("N300H", NrConditions*NrElectrodes*NrBins,1 );
        
        % Electrodes: if multiple electrodes, they simply alternate ABABAB
        Electrodes_L = repmat(Electrodes', NrConditions*NrBins, 1);
        
        % Conditions are blocked across electrodes, but alternate across
        % time windows AABBAABB
        Conditions_L = repelem(Condition_Names', NrElectrodes*NrBins,1);
        Conditions_L = repmat(Conditions_L(:), 1);
        
        % Time Window are blocked across electrodes and conditions AAAAABBBB
        TimeWindow_L = repmat(num2str(TimeWindow_EEG), NrConditions*NrElectrodes*NrBins, 1);
        TimeWindowECG_L = repmat(num2str(TimeWindow_ECG), NrConditions*NrElectrodes*NrBins, 1);
        Bin_L = repmat(Bin_L, NrConditions*NrElectrodes, 1);
        
        
        % ****** Prepare Table ******
        OUTPUT.data.Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L, Electrodes_L, TimeWindow_L, TimeWindowECG_L]),...
            num2cell([ERP(:), SME(:), EpochCount(:)]), cellstr(Bin_L), cellstr(Component_L)];
        
    end
    
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
