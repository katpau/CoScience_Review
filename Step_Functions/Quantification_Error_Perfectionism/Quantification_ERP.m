function  OUTPUT = Quantification_ERP(INPUT, Choice)
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
Choices = ["Mean", "Peak"];
Conditional = ["NaN", "TimeWindow ~= ""Relative_Group_narrow"" & TimeWindow ~= ""Relative_Subject"" "];
SaveInterim = logical([1]);
Order = [22];


%%%%%%%%%%%%%%%% Updating the SubjectStructure. No changes should be made here.
INPUT.StepHistory.Quantification_ERP = Choice;
OUTPUT = INPUT;
OUTPUT.data = [];
% Some Error Handling
try
    %%%%%%%%%%%%%%%% Routine for the analysis of this step
    % This functions starts from using INPUT and returns OUTPUT
    EEG = INPUT.data.EEG;
    
    
    % ********************************************************************************************
    % **** Set Up Some Information 1 ***************************************************************
    % ********************************************************************************************
    % Get Info on ** Electrodes **
    Electrodes_ERN = strrep(upper(strsplit(INPUT.StepHistory.Electrodes , ",")), " ", "");
    NrElectrodes_ERN = length(Electrodes_ERN);
    ElectrodeIdx_ERN = findElectrodeIdx(EEG.chanlocs, Electrodes_ERN);
    
    Electrodes_PE = strrep(upper(strsplit(INPUT.StepHistory.Electrodes_PE , ",")), " ", "");
    NrElectrodes_PE = length(Electrodes_PE);
    ElectrodeIdx_PE = findElectrodeIdx(EEG.chanlocs, Electrodes_PE);
    
    % Info on ** Time Window ** handled later as it can be relative
    
    % Info on ** Epochs **
     if strcmp(INPUT.AnalysisName , "Flanker_Perfectionism")
        Condition_Triggers =  [106, 116, 126, 136, 107, 117, 127, 137; ...
        108, 118, 128, 138, 109, 119, 129, 139];
        Condition_Names = ["Correct", "Error"];
        TaskLabel = "Flanker";
    else
        Condition_Triggers =  [211; ...
        220];
        Condition_Names = ["Correct", "Error"];
        TaskLabel = "GoNoGo";
     end
    Event_Window = [-0.500 0.800];
   
    NrConditions = length(Condition_Names);
    
    
    
    % ********************************************************************************************
    % **** Prepare ERP  ***************************************************************
    % ********************************************************************************************
    % For saving ERP, select only relevant channels
    Electrodes_ERP = {'Fz', 'FCz', 'Cz', 'FC1', 'FC2'};
    EEG_for_ERP = pop_select(EEG, 'channel',Electrodes_ERP);
    % For saving ERP, downsample!
    EEG_for_ERP =  pop_resample(EEG_for_ERP, 100);
    Empty_Conditions = repmat(0, 1,NrConditions);
    for i_Cond = 1:NrConditions
        try
            ERP = pop_epoch( EEG_for_ERP, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
            ERP_forExport.(Condition_Names(i_Cond)) = mean(ERP.data,3);
        end
    end
    % Add Info on Exported ERP
    ERP_forExport.times = ERP.times;
    ERP_forExport.chanlocs = ERP.chanlocs;
    
     
    % ********************************************************************************************
    % **** Prepare Relative Data     *************************************************************
    % ********************************************************************************************
    if contains(INPUT.StepHistory.TimeWindow, "Relative")
        % select all relevant epochs and split them up between Accept and Reject
        % as their difference is used to detect time window
        EEG_for_Relative = pop_epoch(EEG,  num2cell(Condition_Triggers(:)), Event_Window, 'epochinfo', 'yes');
        
        if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
            EEG_for_Relative =  pop_resample(EEG_for_Relative, fix(EEG_for_Relative.srate/100)*100);
            % Get ERP
            ERP_Relative = mean(EEG_for_Relative.data,3) ;
            
            % Get only relevant Data for ERN
            TimeIdxRel = findTimeIdx(EEG_for_Relative.times, 0, 150);
            For_Relative.ERP.ERN = mean(ERP_Relative(ElectrodeIdx_ERN,TimeIdxRel,:),1);
            For_Relative.ERP.ERN_times = EEG_for_Relative.times(TimeIdxRel);
            
            % Get only relevant Data for ERN
            TimeIdxRel = findTimeIdx(EEG_for_Relative.times, 150, 500);
            For_Relative.ERP.PE = mean(ERP_Relative(ElectrodeIdx_PE,TimeIdxRel,:),1);
            For_Relative.ERP.PE_times = EEG_for_Relative.times(TimeIdxRel);
        end
        

    end

    
    
    % ********************************************************************************************
    % **** Set Up Some Information 2 *************************************************************
    % ********************************************************************************************
    % ****** Get Info on TimeWindow ******
    TimeWindow_ERN = INPUT.StepHistory.TimeWindow;
    if ~contains(TimeWindow_ERN, "Relative")
        TimeWindow_ERN = str2double(strsplit(TimeWindow_ERN, ","));
        TimeWindow_PE = str2double(strsplit(INPUT.StepHistory.TimeWindow_PE, ","));
    elseif strcmp(TimeWindow_ERN, "Relative_Subject")
        %create ERP
        AV_ERP = mean(EEG_for_Relative.data,3);
        % find subset to find Peak
        TimeIdx_ERN = findTimeIdx(EEG_for_Relative.times, 0, 150);
        TimeIdx_PE = findTimeIdx(EEG_for_Relative.times, 150, 500);
        % Find Peak in this Subset
        [~, Latency_ERN] = Peaks_Detection(mean(AV_ERP(ElectrodeIdx_ERN,TimeIdx_ERN,:),1), "NEG");
        [~, Latency_PE] = Peaks_Detection(mean(AV_ERP(ElectrodeIdx_PE,TimeIdx_PE,:),1), "POS");
        % Define Time Window Based on this
        TimeWindow_ERN = [EEG_for_Relative.times(Latency_ERN+(TimeIdx_ERN(1))-1) - 25, EEG_for_Relative.times(Latency_ERN+(TimeIdx_ERN(1))-1) + 25];
        TimeWindow_PE = [EEG_for_Relative.times(Latency_PE+(TimeIdx_PE(1))-1) - 25, EEG_for_Relative.times(Latency_PE+(TimeIdx_PE(1))-1) + 25];
     
    elseif contains(TimeWindow_ERN, "Relative_Group")
        % Time window needs to be longer since peak could be at edge
        % this part of the data will be exported later.
        TimeWindow_ERN = [-50 200];
        TimeWindow_PE = [100 550];
    end
    
    % Get Index of TimeWindow  [in Sampling Points]
    TimeIdx_ERN = findTimeIdx(EEG.times, TimeWindow_ERN(1), TimeWindow_ERN(2));
    TimeIdx_PE = findTimeIdx(EEG.times, TimeWindow_PE(1), TimeWindow_PE(2));
    
   
    % ********************************************************************************************
    % ****  Prepare Data *************************************************************************
    % ********************************************************************************************
    
    % * Epoch Data around predefined window and save each
        for i_Cond = 1:NrConditions
        % * Epoch Data around predefined window and save each
        EEGData = pop_epoch( EEG, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
        ConditionData_ERN.(Condition_Names(i_Cond)) = EEGData.data(ElectrodeIdx_ERN, TimeIdx_ERN,:);
        ConditionData_PE.(Condition_Names(i_Cond)) = EEGData.data(ElectrodeIdx_PE, TimeIdx_PE,:);
        
        % Update Nr on Electrodes for Final OutputTable
        if INPUT.StepHistory.Cluster_Electrodes == "cluster"
            ConditionData_ERN.(Condition_Names(i_Cond)) = mean(ConditionData_ERN.(Condition_Names(i_Cond)),1);
            ConditionData_PE.(Condition_Names(i_Cond)) = mean(ConditionData_PE.(Condition_Names(i_Cond)),1);
        end
        end
        
            % update Label
    if  INPUT.StepHistory.Cluster_Electrodes == "cluster"
        NrElectrodes_ERN = 1;
        Electrodes_ERN = strcat('Cluster ', join(Electrodes_ERN));
        NrElectrodes_PE = 1;
        Electrodes_PE = strcat('Cluster ', join(Electrodes_PE));
    end
    
        
    
    % ********************************************************************************************
    % **** Extract Data and prepare Output Table    **********************************************
    % ********************************************************************************************
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        For_Relative.Data.ERN = ConditionData_ERN;
        For_Relative.Data.ERN_Times= EEG.times(TimeIdx_ERN);
        For_Relative.Data.ERN_Electrodes = Electrodes_ERN;
        For_Relative.Data.PE = ConditionData_PE;
        For_Relative.Data.PE_Times= EEG.times(TimeIdx_PE);
        For_Relative.Data.PE_Electrodes = Electrodes_PE;
        For_Relative.RecordingLab = EEG.Info_Lab.RecordingLab;
        For_Relative.Experimenter = EEG.Info_Lab.Experimenter;
        For_Relative.Task = TaskLabel;
         
    else
        % ****** Extract Amplitude, SME, Epoch Count ******
        InitSize_ERN = [NrElectrodes_ERN,NrConditions];
        EpochCount_ERN = NaN(InitSize_ERN);
        ERP_ERN =NaN(InitSize_ERN); SME_ERN=NaN(InitSize_ERN);
        
        InitSize_PE = [NrElectrodes_PE,NrConditions];
        EpochCount_PE = NaN(InitSize_PE);
        ERP_PE =NaN(InitSize_PE); SME_PE=NaN(InitSize_PE);
        for i_Cond = 1:NrConditions
            Data_ERN = ConditionData_ERN.(Condition_Names(i_Cond));
            Data_PE = ConditionData_PE.(Condition_Names(i_Cond));
            
            % Count Epochs
            EpochCount_ERN(:,i_Cond,:) = size(Data_ERN,3);
            EpochCount_PE(:,i_Cond,:) = size(Data_PE,3);
            if size(Data_ERN,3) < str2double(INPUT.StepHistory.Trials_MinNumber)
                ERP_ERN(:,i_Cond,:) = NaN;
                SME_ERN(:,i_Cond,:) = NaN;
                ERP_PE(:,i_Cond,:) = NaN;
                SME_PE(:,i_Cond,:) = NaN;
            else
                % Calculate ERP if enough epochs there
                if strcmp(Choice, "Mean")
                    ERP_ERN(:,i_Cond,1) = mean(mean(Data_ERN,3),2);
                    SME_ERN(:,i_Cond,1) = Mean_SME(Data_ERN);
                    
                    ERP_PE(:,i_Cond,1) = mean(mean(Data_PE,3),2);
                    SME_PE(:,i_Cond,1) = Mean_SME(Data_PE);
                    
                elseif strcmp(Choice, "Peak")
                    [ERP_ERN(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_ERN,3), "NEG");
                    SME_ERN(:,i_Cond,1) = Peaks_SME(Data_ERN, "NEG");
                    
                    [ERP_PE(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_PE,3), "POS");
                    SME_PE(:,i_Cond,1) = Peaks_SME(Data_PE, "POS");
                    
                end
            end
        end
        
    end
    
        
    
    % ********************************************************************************************
    % **** Prepare Output Table    ***************************************************************
    % ********************************************************************************************
    % Add ERP for Plotting
    OUTPUT.data.ERP = ERP_forExport;
    
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        % Add Relative Data and Relative Info
        OUTPUT.data.For_Relative = For_Relative;
        
    else
        % Prepare Final Export with all Values
        % ****** Prepare Labels ******
        % important PE and ERN do not always have same number of electrodes!
        
        % Subject, ComponentName, Lab, Experimenter is constant AAA
        Subject_ERN_L = repmat(INPUT.Subject, NrConditions*NrElectrodes_ERN,1 );
        Lab_ERN_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodes_ERN,1 );
        Experimenter_ERN_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodes_ERN,1 );
        Component_ERN_L = repmat("ERN", NrConditions*NrElectrodes_ERN,1 );
        Task_ERN_L =  repmat(TaskLabel, NrConditions*NrElectrodes_ERN,1 );
        
        Subject_PE_L = repmat(INPUT.Subject, NrConditions*NrElectrodes_PE,1 );
        Lab_PE_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodes_PE,1 );
        Experimenter_PE_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodes_PE,1 );
        Component_PE_L = repmat("PE", NrConditions*NrElectrodes_PE,1 );
        Task_PE_L =  repmat(TaskLabel, NrConditions*NrElectrodes_PE,1 );
        
        % Electrodes: if multiple electrodes, they simply alternate ABABAB
        Electrodes_ERN_L = repmat(Electrodes_ERN', NrConditions, 1);
        Electrodes_PE_L = repmat(Electrodes_PE', NrConditions, 1);
        
        
        % Conditions are blocked across electrodes, but alternate across
        % time windows AABBAABB
        Conditions_ERN_L = repelem(Condition_Names', NrElectrodes_ERN,1);
        Conditions_ERN_L = repmat(Conditions_ERN_L(:), 1);
        Conditions_PE_L = repelem(Condition_Names', NrElectrodes_PE,1);
        Conditions_PE_L = repmat(Conditions_PE_L(:), 1);
        
        % Time Window are blocked across electrodes and conditions AAAAABBBB
        TimeWindow_ERN_L = repmat(num2str(TimeWindow_ERN), NrConditions*NrElectrodes_ERN, 1);
        TimeWindow_PE_L = repmat(num2str(TimeWindow_PE), NrConditions*NrElectrodes_PE, 1);
        
        % ****** Prepare Table ******
        OUTPUT.data.Export = [[cellstr([Subject_ERN_L, Lab_ERN_L, Experimenter_ERN_L, Task_ERN_L, Conditions_ERN_L, Electrodes_ERN_L, TimeWindow_ERN_L]),...
            num2cell([ERP_ERN(:), SME_ERN(:), EpochCount_ERN(:)]), cellstr(Component_ERN_L)]; ...
            [cellstr([Subject_PE_L, Lab_PE_L, Experimenter_PE_L, Task_PE_L, Conditions_PE_L, Electrodes_PE_L, TimeWindow_PE_L]),...
            num2cell([ERP_PE(:), SME_PE(:), EpochCount_PE(:)]), cellstr(Component_PE_L)]];
        
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
