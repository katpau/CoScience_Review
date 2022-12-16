function  OUTPUT = Quantification_ERP(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following:
% Based on information of previous steps, and depending on the forking
% choice, ERPs are quantified based on Mean or ERPS.
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
OUTPUT.data = [];
% Some Error Handling
try
    %%%%%%%%%%%%%%%% Routine for the analysis of this step
    EEG = INPUT.data.EEG;
    
    % ********************************************************************************************
    % **** Set Up Some Information 1 ***************************************************************
    % ********************************************************************************************
    % Get Info on ** Electrodes **
    if strcmp(INPUT.StepHistory.Electrodes, "Relative")
        Electrodes = upper(["AFz", "Fz", "Fcz", "Cz", "Cpz", "Pz", "Poz", "Oz", ...
            "AF3", "F1", "FC1", "C1", "CP1", "P1", "PO3", "O1", ...
            "AF4", "F2", "FC2", "C2", "CP2", "P2", "PO4", "O2"]);
    else
        Electrodes = strrep(upper(strsplit(INPUT.StepHistory.Electrodes , ",")), " ", "");
    end
    NrElectrodes = length(Electrodes);
    ElectrodeIdx = findElectrodeIdx(EEG.chanlocs, Electrodes);
    
    % Info on ** Time Window ** handled later as it can be relative too
    
    % Info on ** Epochs **    
    Condition_Triggers = {'101';  '102'; '201'; '202'}; % Target onset
    Event_Window = [-0.300 1.000];
    Condition_Triggers =  {'11', '12', '13', '14', '15', '16', '17', '18'; '21', '22', '23', '24', '25', '26', '27', '28'; ...
        '31', '32', '33', '34', '35', '36', '37', '38';  '41', '42', '43', '44', '45', '46', '47', '48'; ...
        '51', '52', '53', '54', '55', '56', '57', '58'; '61', '62', '63', '64', '65', '66', '67', '68';...
        '71', '72', '73', '74', '75', '76', '77', '78'}; % Picture Onset
    Condition_Names = ["Tree", "Erotic_Couple", "Erotic_Man", "Neutral_ManWoman", "Neutral_Couple", "Positive_ManWoman", "Erotic_Woman"];
    NrConditions = length(Condition_Names);
    
    
    % ********************************************************************************************
    % **** Prepare ERP  ***************************************************************
    % ********************************************************************************************
    % For saving ERP, select only relevant channels
    ElectrodesERP = {'CZ','CPZ','CP1','CP2','PZ'};
    EEG_for_ERP = pop_select(EEG, 'channel',ElectrodesERP);
    % For saving ERP, downsample!
    EEG_for_ERP =  pop_resample(EEG_for_ERP, 100);
    for i_Cond = 1:NrConditions
        try
            ERP = pop_epoch( EEG_for_ERP, Condition_Triggers(i_Cond,:), Event_Window, 'epochinfo', 'yes');
            ERP_forExport.(Condition_Names(i_Cond)) = mean(ERP.data,3);
        end
    end
    % Add Info on Exported ERP
    ERP_forExport.times = ERP.times;
    ERP_forExport.chanlocs = ERP.chanlocs;
    
    
    % ********************************************************************************************
    % **** Prepare Relative Data   ***************************************************************
    % ********************************************************************************************
    % if Time window is Relative to Peak across all Subjects or within a
    % subject, an ERP needs to be created across all Conditions.
    if contains(INPUT.StepHistory.TimeWindow, "Relative") ||  strcmp(INPUT.StepHistory.Electrodes, "Relative")
        % select all relevant epochs
        EEG_for_Relative = pop_epoch( EEG, Condition_Triggers', Event_Window, 'epochinfo', 'yes');
        if contains(INPUT.StepHistory.TimeWindow, "Relative_Group") ||  strcmp(INPUT.StepHistory.Electrodes, "Relative")
            % Due to different recording setup, Biosemi needs to be resampled
            EEG_for_Relative_Export =  pop_resample(EEG_for_Relative, fix(EEG_for_Relative.srate/100)*100);
            % Get index of Data that should be exported (= used to find peaks)
            TimeIdxRel = findTimeIdx(EEG_for_Relative_Export.times, 300, 1000);
            % Get only relevant Data
            For_Relative.ERP.AV = mean(EEG_for_Relative_Export.data(ElectrodeIdx,TimeIdxRel,:),3) ;
            For_Relative.ERP.times = EEG_for_Relative_Export.times(TimeIdxRel);
            For_Relative.ERP.chanlocs = EEG_for_Relative_Export.chanlocs(ElectrodeIdx);
        end
    end
    
    % ********************************************************************************************
    % **** Set Up Some Information 2 *************************************************************
    % ********************************************************************************************
    % ****** Get Info on TimeWindow ******
    TimeWindow = INPUT.StepHistory.TimeWindow;
    if ~contains(TimeWindow, "Relative")
        TimeWindow = str2double(strsplit(TimeWindow, ","));
        
    elseif strcmp(TimeWindow, "Relative_Subject")
        % find subset to find Peak for LPP
        TimeIdx = findTimeIdx(EEG_for_Relative.times, 300, 1000);
        % Calculate Grand Average ERP
        ERP = mean(EEG_for_Relative.data,3);
        % Find Peak in this Subset
        [~, Latency] = Peaks_Detection(mean(ERP(ElectrodeIdx, TimeIdx,:),1), "POS");
        % Define Time Window Based on this
        TimeWindow = [EEG_for_Relative.times(Latency+(TimeIdx(1))) - 100, EEG_for_Relative.times(Latency+(TimeIdx(1))) + 100];
        
    elseif contains(TimeWindow, "Relative_Group")
        % Time window needs to be longer since peak could be at edge
        % this part of the data will be exported later
        TimeWindow = [200 1000];
    end
    
    % Get Index of TimeWindow LPP [in Sampling Points]
    TimeIdx = findTimeIdx(EEG.times, TimeWindow(1), TimeWindow(2));
    
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
    % ****  Prepare Data *************************************************************************
    % ********************************************************************************************
    for i_Cond = 1:NrConditions
        try
            % * Epoch Data around predefined window and save each
            EEGData = pop_epoch( EEG, Condition_Triggers(i_Cond,:), Event_Window, 'epochinfo', 'yes');
            ConditionData.(Condition_Names(i_Cond)) = EEGData.data(ElectrodeIdx, TimeIdx,:);
            
            % Update Nr on Electrodes for Final OutputTable
            if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                NrElectrodes = 1;
                Electrodes = strcat('Cluster ', join(Electrodes));
                ConditionData.(Condition_Names(i_Cond)) = mean(ConditionData.(Condition_Names(i_Cond)),1);
            end
        end
    end
    
    % update Conditions based on on which epochs were found
    Condition_Names = fieldnames(ConditionData);
    NrConditions = length(Condition_Names);
    
    % ********************************************************************************************
    % **** Extract Data and prepare Output Table    **********************************************
    % ********************************************************************************************
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group") ||  strcmp(INPUT.StepHistory.Electrodes, "Relative")
        For_Relative.RecordingLab = EEG.Info_Lab.RecordingLab;
        For_Relative.Experimenter = EEG.Info_Lab.Experimenter;
        For_Relative.Data = ConditionData;
        For_Relative.Times = EEGData.times(TimeIdx);
        For_Relative.Electrodes = Electrodes;
        
    else
        % ****** Extract Amplitude, SME, Epoch Count ******
        InitSize = [NrElectrodes*NrTimeWindows,NrConditions];
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
                % Calculate Mean if enough epochs there
                if ~strcmp(Choice, "Mean_Binned")
                    ERP(:,i_Cond) = mean(mean(Data,3),2);
                    SME(:,i_Cond) = Mean_SME(Data);
                else
                    ERP(:,i_Cond) = [mean(mean(Data(:, 1:HalfWindowIdx,:),3),2); ...
                        mean(mean(Data(:, HalfWindowIdx+1:length(TimeIdx),:),3),2)];
                    SME(:,i_Cond) = [Mean_SME(Data(:, 1:HalfWindowIdx,:)); ...
                        Mean_SME(Data(:, HalfWindowIdx+1:length(TimeIdx),:))];
                end
                
                
            end
        end
    end
    
    
    % ********************************************************************************************
    % **** Prepare Output Table    ***************************************************************
    % ********************************************************************************************
    % Add ERP for Plotting
    OUTPUT.data.ERP = ERP_forExport;
    
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group") ||  strcmp(INPUT.StepHistory.Electrodes, "Relative")
        % Add Relative Data and Relative Info
        OUTPUT.data.For_Relative = For_Relative;
    else
        % Prepare Final Export with all Values
        % ****** Prepare Labels ******
        % Subject, ComponentName, Lab, Experimenter is constant AAA
        Subject_L = repmat(INPUT.Subject, NrConditions*NrElectrodes*NrTimeWindows,1 );
        Lab_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodes*NrTimeWindows,1 );
        Experimenter_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodes*NrTimeWindows,1 );
        Component_L = repmat("LPP", NrConditions*NrElectrodes*NrTimeWindows,1 );
        
        % Electrodes: if multiple electrodes, they simply alternate ABABAB
        Electrodes_L = repmat(Electrodes', NrConditions*NrTimeWindows, 1);
        
        % Conditions are blocked across electrodes and timewindows AABBAABB
        Conditions_L = repelem(Condition_Names', NrElectrodes*NrTimeWindows,1);
        
        % Time Window are blocked across electrodes and conditions
        if NrTimeWindows == 2
            TimeWindow_L = [convertCharsToStrings(num2str(TimeWindow(1,:))); ...
                convertCharsToStrings(num2str(TimeWindow(2,:)))]
        else
            TimeWindow_L = convertCharsToStrings(num2str(TimeWindow(1,:)));
        end
        TimeWindow_L = repmat(repelem(TimeWindow_L, NrElectrodes, 1),NrConditions,1) ;
        
        
        % ****** Prepare Table ******
        OUTPUT.data.Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L, Electrodes_L, TimeWindow_L]),...
            num2cell([ERP(:), SME(:), EpochCount(:)]), cellstr(Component_L)];
        
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
