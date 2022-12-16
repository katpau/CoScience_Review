function  OUTPUT = Quantification_ERP(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following:
% Based on information of previous steps, and depending on the forking
% choice, ERPs are quantified based on Mean, peaks or peak-to-peak
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
Choices = ["Mean", "Peak", "Peak-to-Peak"];
Conditional = ["NaN", "TimeWindow ~= ""Relative_Group_narrow"" & TimeWindow ~= ""Relative_Subject"" ",  "TimeWindow ~= ""Relative_Group_narrow"" & ""TimeWindow ~= ""Relative_Group_wide"" & TimeWindow ~= ""Relative_Subject"" "];
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
    Electrodes_RewP = strrep(upper(strsplit(INPUT.StepHistory.Electrodes , ",")), " ", "");
    NrElectrodes_RewP = length(Electrodes_RewP);
    ElectrodeIdx_RewP = findElectrodeIdx(EEG.chanlocs, Electrodes_RewP);
    
    Electrodes_P3 = strrep(upper(strsplit(INPUT.StepHistory.Electrodes_P3 , ",")), " ", "");
    NrElectrodes_P3 = length(Electrodes_P3);
    ElectrodeIdx_P3 = findElectrodeIdx(EEG.chanlocs, Electrodes_P3);
    
    % Info on ** Time Window ** handled later as it can be relative
    
    % Info on ** Epochs **
    Event_Window = [-0.300 1.000];
    Condition_Triggers =  [100; 110; 150 ; 101; 111; 151];
    Condition_Names = ["P0_Loss", "P10_Loss", "P50_Loss", "P0_Win", "P10_Win", "P50_Win" ];
    NrConditions = length(Condition_Names);
    Condition_NamesDiff = ["P0_Diff", "P10_Diff", "P50_Diff", "PXX_Diff"];
    NrConditionsDiff = length(Condition_NamesDiff);
    % For Relative Data Difference Wave is needed
    Neg_Triggers =  {100, 110, 150};
    Pos_Triggers =  {101, 111, 151};
    
    % ********************************************************************************************
    % **** Prepare ERP  ***************************************************************
    % ********************************************************************************************
    % For saving ERP, select only relevant channels
    Electrodes_ERP = {'FCZ', 'CZ', 'FZ', 'PZ', 'CPZ'};
    EEG_for_ERP = pop_select(EEG, 'channel',Electrodes_ERP);
    % For saving ERP, downsample!
    EEG_for_ERP =  pop_resample(EEG_for_ERP, 100);
    for i_Cond = 1:NrConditions
        try
            ERP_forExport = pop_epoch( EEG_for_ERP, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
            ERP_forExport.(Condition_Names(i_Cond)) = mean(ERP_forExport.data,3);
        end
    end
    
    % Add Info on Exported ERP
    ERP_forExport.times = ERP_forExport.times;
    ERP_forExport.chanlocs = ERP_forExport.chanlocs;
    
    
    % ********************************************************************************************
    % **** Prepare Relative Data   ***************************************************************
    % ********************************************************************************************
    % if Time window is Relative to Peak across all Subjects or within a
    % subject, an ERP Diff needs to be created across all Conditions.
    
    
    if contains(INPUT.StepHistory.TimeWindow, "Relative")
        % select all relevant epochs
        EEG_for_Relative_Pos = pop_epoch(EEG,  Pos_Triggers, Event_Window, 'epochinfo', 'yes');
        EEG_for_Relative_Neg = pop_epoch(EEG,  Neg_Triggers, Event_Window, 'epochinfo', 'yes');
        if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
            % Due to different recording setup, Biosemi needs to be resampled
            EEG_for_Relative_Export_Pos =  pop_resample(EEG_for_Relative_Pos, fix(EEG_for_Relative_Pos.srate/100)*100);
            EEG_for_Relative_Export_Neg =  pop_resample(EEG_for_Relative_Neg, fix(EEG_for_Relative_Neg.srate/100)*100);
            AV_RewP = mean(EEG_for_Relative_Export_Pos.data,3) - mean(EEG_for_Relative_Export_Neg.data,3);
            % Get index of Data that should be exported (= used to find peaks)
            ElectrodeIdxRel = [ElectrodeIdx_RewP, ElectrodeIdx_P3];
            TimeIdxRel = findTimeIdx(EEG_for_Relative_Export_Pos.times, 200, 600);
            % Get only relevant Data
            For_Relative.ERP.AV = AV_RewP(ElectrodeIdxRel,TimeIdxRel,:);
            For_Relative.ERP.times = EEG_for_Relative_Export_Pos.times(TimeIdxRel);
            For_Relative.ERP.chanlocs = EEG_for_Relative_Export_Pos.chanlocs(ElectrodeIdxRel);
        end
    end
    
    % ********************************************************************************************
    % **** Set Up Some Information 2 *************************************************************
    % ********************************************************************************************
    % ****** Get Info on TimeWindow ******
    TimeWindow_RewP = INPUT.StepHistory.TimeWindow;
    TimeWindow_P3 = INPUT.StepHistory.TimeWindow_P3;
    if ~contains(TimeWindow_RewP, "Relative")
        if ~strcmp(Choice, "Peak-to-Peak")
            TimeWindow_RewP = str2double(strsplit(TimeWindow_RewP, ","));
        else
            TimeWindow_RewP = str2double(strsplit(TimeWindow_RewP, ","));
            TimeWindow_RewP = [150, TimeWindow_RewP(2)];
        end
        TimeWindow_P3 = str2double(strsplit(TimeWindow_P3, ","));
        
        
    elseif strcmp(TimeWindow_RewP, "Relative_Subject")
        % find subset to find Peak
        TimeIdx_RewP = findTimeIdx(EEG_for_Relative_Pos.times, 150, 400);
        TimeIdx_P3 = findTimeIdx(EEG_for_Relative_Pos.times, 250, 600);
        AV_RewP = mean(EEG_for_Relative_Pos.data, 3) - mean(EEG_for_Relative_Neg.data, 3);
        % Find Peak in this Subset
        [~, Latency_RewP] = Peaks_Detection(mean(AV_RewP(ElectrodeIdx_RewP,TimeIdx_RewP,:),1), "POS");
        [~, Latency_P3] = Peaks_Detection(mean(AV_RewP(ElectrodeIdx_P3,TimeIdx_P3,:),1), "POS");
        % Define Time Window Based on this
        TimeWindow_RewP = [EEG_for_Relative_Pos.times(Latency_RewP+(TimeIdx_RewP(1))) - 25, EEG_for_Relative_Pos.times(Latency_RewP+(TimeIdx_RewP(1))) + 25];
        TimeWindow_P3 = [EEG_for_Relative_Pos.times(Latency_P3+(TimeIdx_P3(1))) - 25, EEG_for_Relative_Pos.times(Latency_P3+(TimeIdx_P3(1))) + 25];
        
    elseif contains(TimeWindow_RewP, "Relative_Group")
        % Time window needs to be longer since peak could be at edge
        % this part of the data will be exported later.
        TimeWindow_RewP = [150 450];
        TimeWindow_P3 = [200 650];
    end
    
    % Get Index of TimeWindow N2 [in Sampling Points]
    TimeIdx_RewP = findTimeIdx(EEG.times, TimeWindow_RewP(1), TimeWindow_RewP(2));
    TimeIdx_P3 = findTimeIdx(EEG.times, TimeWindow_P3(1), TimeWindow_P3(2));
    
    % ********************************************************************************************
    % ****  Prepare Data *************************************************************************
    % ********************************************************************************************
    for i_Cond = 1:NrConditions
        % * Epoch Data around predefined window and save each
        EEGData = pop_epoch( EEG, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
        ConditionData_RewP.(Condition_Names(i_Cond)) = EEGData.data(ElectrodeIdx_RewP, TimeIdx_RewP,:);
        ConditionData_P3.(Condition_Names(i_Cond)) = EEGData.data(ElectrodeIdx_P3, TimeIdx_P3,:);
        
        % Update Nr on Electrodes for Final OutputTable
        if INPUT.StepHistory.Cluster_Electrodes == "cluster"
            ConditionData_RewP.(Condition_Names(i_Cond)) = mean(ConditionData_RewP.(Condition_Names(i_Cond)),1);
            ConditionData_P3.(Condition_Names(i_Cond)) = mean(ConditionData_P3.(Condition_Names(i_Cond)),1);
        end
    end
    
    % update Label
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        NrElectrodes_RewP = 1;
        Electrodes_RewP = strcat('Cluster ', join(Electrodes_RewP));
        NrElectrodes_P3 = 1;
        Electrodes_P3 = strcat('Cluster ', join(Electrodes_P3));
    end
    
    % ********************************************************************************************
    % **** Extract Data and prepare Output Table    **********************************************
    % ********************************************************************************************
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        For_Relative.RecordingLab = EEG.Info_Lab.RecordingLab;
        For_Relative.Experimenter = EEG.Info_Lab.Experimenter;
        
        For_Relative.Data_RewP = ConditionData_RewP;
        For_Relative.Times_RewP = EEGData.times(TimeIdx_RewP);
        For_Relative.Electrodes_RewP = Electrodes_RewP;
        
        For_Relative.Data_P3 = ConditionData_P3;
        For_Relative.Times_NP3 = EEGData.times(TimeIdx_P3);
        For_Relative.Electrodes_P3 = Electrodes_P3;
        
    else
        % ****** Extract Amplitude, SME, Epoch Count ******
        InitSize_RewP = [NrElectrodes_RewP,NrConditions+NrConditionsDiff];
        EpochCount_RewP = NaN(InitSize_RewP);
        ERP_RewP =NaN(InitSize_RewP); SME_RewP=NaN(InitSize_RewP);
        
        InitSize_P3 = [NrElectrodes_P3,NrConditions+NrConditionsDiff];
        EpochCount_P3 = NaN(InitSize_P3);
        ERP_P3 =NaN(InitSize_P3); SME_P3=NaN(InitSize_P3);
        
        for i_Cond = 1:NrConditions
            Data_RewP = ConditionData_RewP.(Condition_Names(i_Cond));
            Data_P3 = ConditionData_P3.(Condition_Names(i_Cond));
            
            % Count Epochs
            EpochCount_RewP(:,i_Cond,:) = size(Data_RewP,3);
            EpochCount_P3(:,i_Cond,:) = size(Data_P3,3);
            if size(Data_RewP,3) < str2double(INPUT.StepHistory.Trials_MinNumber)
                ERP_RewP(:,i_Cond,:) = NaN;
                SME_RewP(:,i_Cond,:) = NaN;
                ERP_P3(:,i_Cond,:) = NaN;
                SME_P3(:,i_Cond,:) = NaN;
            else
                % Calculate ERP if enough epochs there
                if strcmp(Choice, "Mean")
                    ERP_RewP(:,i_Cond,1) = mean(mean(Data_RewP,3),2);
                    SME_RewP(:,i_Cond,1) = Mean_SME(Data_RewP);
                    
                    ERP_P3(:,i_Cond,1) = mean(mean(Data_P3,3),2);
                    SME_P3(:,i_Cond,1) = Mean_SME(Data_P3);
                    
                elseif strcmp(Choice, "Peak")
                    [ERP_RewP(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_RewP,3), "NEG");
                    SME_RewP(:,i_Cond,1) = Peaks_SME(Data_RewP, "NEG");
                    
                    [ERP_P3(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_P3,3), "POS");
                    SME_P3(:,i_Cond,1) = Peaks_SME(Data_P3, "POS");
                    
                elseif strcmp(Choice, "Peak-to-Peak")
                    % Peak to Peak for RewP (P2 - FRN)
                    % Get Time Window for P2 and FRN
                    TimeIdx_P2 = findTimeIdx(EEG.times(TimeIdx_RewP), 150, 250);
                    if isstring(TimeWindow_RewP)
                        TimeWindow_RewP = str2double(strsplit(TimeWindow_RewP, ","));
                    end
                    TimeIdx_RewP_P2P = findTimeIdx(EEG.times(TimeIdx_RewP), TimeWindow_RewP(1),TimeWindow_RewP(2) );
                    
                    % Get data in which peaks should be found
                    DataP2 = Data_RewP(:,TimeIdx_P2,:);
                    DataRewP = Data_RewP(:,TimeIdx_RewP_P2P,:);
                    
                    % Get peaks
                    P2 = Peaks_Detection(mean(DataP2,3), "POS");
                    FRN = Peaks_Detection(mean(DataRewP,3), "NEG");
                    
                    % Substract peaks
                    ERP_RewP(:,i_Cond,1) = P2 - FRN;
                    
                    % Get SME
                    SME_RewP(:,i_Cond,1) = Peaks_to_Peak_SME(DataRewP, "NEG", DataP2, "POS");
                    
                    % For P3 take only Peak
                    [ERP_P3(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_P3,3), "POS");
                    SME_P3(:,i_Cond,1) = Peaks_SME(Data_P3, "POS");
                end
            end
        end
        
        % ********************************************************************************************
        % **** Loop also through Difference Waves!          ******************************************
        % ********************************************************************************************
        % Create **** Difference Waves ****   on ERPs
        for i_Diff = 1:NrConditionsDiff
            i_Cond = i_Diff + 6;
            if i_Diff < 4 % Diff Per Condition
                Pos_RewP = ConditionData_RewP.(Condition_Names(i_Diff+3));
                Neg_RewP =  ConditionData_RewP.(Condition_Names(i_Diff));
                
                Pos_P3 = ConditionData_P3.(Condition_Names(i_Diff+3));
                Neg_P3 =  ConditionData_P3.(Condition_Names(i_Diff));
                
            else % Diff across all Magnitude Conditions
                Pos_RewP = cat(3, ConditionData_RewP.(Condition_Names(1)), ...
                    ConditionData_RewP.(Condition_Names(2)), ...
                    ConditionData_RewP.(Condition_Names(3)));
                Neg_RewP =  cat(3, ConditionData_RewP.(Condition_Names(4)), ...
                    ConditionData_RewP.(Condition_Names(5)), ...
                    ConditionData_RewP.(Condition_Names(6)));
                
                Pos_P3 = cat(3, ConditionData_P3.(Condition_Names(1)), ...
                    ConditionData_P3.(Condition_Names(2)), ...
                    ConditionData_P3.(Condition_Names(3)));
                Neg_P3 =  cat(3, ConditionData_P3.(Condition_Names(4)), ...
                    ConditionData_P3.(Condition_Names(5)), ...
                    ConditionData_P3.(Condition_Names(6)));
            end
            
            % Count Epochs
            MinEpochs = min(min(size(Pos_RewP,3), size(Neg_RewP,3)));
            EpochCount_RewP(:,i_Cond,:) = MinEpochs;
            EpochCount_P3(:,i_Cond,:) = MinEpochs;
            
            if MinEpochs < str2double(INPUT.StepHistory.Trials_MinNumber)
                ERP_RewP(:,i_Cond,:) = NaN;
                SME_RewP(:,i_Cond,:) = NaN;
                ERP_P3(:,i_Cond,:) = NaN;
                SME_P3(:,i_Cond,:) = NaN;
            else
                
                % Calculate if enough epochs there
                if strcmp(Choice, "Mean")
                    ERP_RewP(:,i_Cond,1) = mean(mean(Pos_RewP,3) - mean(Neg_RewP,3),2);
                    SME_RewP(:,i_Cond,1) = DifferenceWave_SME(Pos_RewP, Neg_RewP, "MEAN");
                    
                    ERP_P3(:,i_Cond,1) = mean(mean(Pos_P3,3) - mean(Neg_P3,3), 2);
                    SME_P3(:,i_Cond,1) = DifferenceWave_SME(Pos_P3, Neg_P3, "MEAN");
                    
                elseif strcmp(Choice, "Peak")
                    ERP_RewP(:,i_Cond,1) = Peaks_Detection(mean(Pos_RewP,3) - mean(Neg_RewP,3), "POS");
                    SME_RewP(:,i_Cond,1) = DifferenceWave_SME(Pos_RewP, Neg_RewP, "POS");
                    
                    ERP_P3(:,i_Cond,1) = Peaks_Detection(mean(Pos_P3,3) - mean(Neg_P3,3), "POS");
                    SME_P3(:,i_Cond,1) = DifferenceWave_SME(Pos_P3, Neg_P3, "POS");
                    
                elseif strcmp(Choice, "Peak-to-Peak")
                    % doesn't make sense in DIFF waves! NaN or just take peak?
                    ERP_RewP(:,i_Cond,1) = NaN;
                    SME_RewP(:,i_Cond,1) = NaN;
                    
                    ERP_P3(:,i_Cond,1) = Peaks_Detection(mean(Pos_P3,3) - mean(Neg_P3,3), "POS");
                    SME_P3(:,i_Cond,1) = DifferenceWave_SME(Pos_P3, Neg_P3, "POS");
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
        % important P3 and RewP do not always have same number of electrodes!
        
        % Subject, ComponentName, Lab, Experimenter is constant AAA
        NrConditions = NrConditions + NrConditionsDiff;
        
        Subject_RewP_L = repmat(INPUT.Subject, NrConditions*NrElectrodes_RewP,1 );
        Lab_RewP_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodes_RewP,1 );
        Experimenter_RewP_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodes_RewP,1 );
        Component_RewP_L = repmat("RewP", NrConditions*NrElectrodes_RewP,1 );
        
        Subject_P3_L = repmat(INPUT.Subject, NrConditions*NrElectrodes_P3,1 );
        Lab_P3_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodes_P3,1 );
        Experimenter_P3_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodes_P3,1 );
        Component_P3_L = repmat("P3", NrConditions*NrElectrodes_P3,1 );
        
        % Electrodes: if multiple electrodes, they simply alternate ABABAB
        Electrodes_RewP_L = repmat(Electrodes_RewP', NrConditions, 1);
        Electrodes_P3_L = repmat(Electrodes_P3', NrConditions, 1);
        
        
        % Conditions are blocked across electrodes, but alternate across
        % time windows AABBAABB
        Condition_Names = [Condition_Names, Condition_NamesDiff];
        Conditions_RewP_L = repelem(Condition_Names', NrElectrodes_RewP,1);
        Conditions_RewP_L = repmat(Conditions_RewP_L(:), 1);
        Conditions_P3_L = repelem(Condition_Names', NrElectrodes_P3,1);
        Conditions_P3_L = repmat(Conditions_P3_L(:), 1);
        
        % Time Window are blocked across electrodes and conditions AAAAABBBB
        TimeWindow_RewP_L = repmat(num2str(TimeWindow_RewP), NrConditions*NrElectrodes_RewP, 1);
        TimeWindow_P3_L = repmat(num2str(TimeWindow_P3), NrConditions*NrElectrodes_P3, 1);
        
        % ****** Prepare Table ******
        OUTPUT.data.Export = [[cellstr([Subject_RewP_L, Lab_RewP_L, Experimenter_RewP_L, Conditions_RewP_L, Electrodes_RewP_L, TimeWindow_RewP_L]),...
            num2cell([ERP_RewP(:), SME_RewP(:), EpochCount_RewP(:)]), cellstr(Component_RewP_L)]; ...
            [cellstr([Subject_P3_L, Lab_P3_L, Experimenter_P3_L, Conditions_P3_L, Electrodes_P3_L, TimeWindow_P3_L]),...
            num2cell([ERP_P3(:), SME_P3(:), EpochCount_P3(:)]), cellstr(Component_P3_L)]];
        
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