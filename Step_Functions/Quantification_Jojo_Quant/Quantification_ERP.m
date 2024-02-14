function  OUTPUT = Quantification_ERP(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by:

% This script does the following:
% Based on information of previous steps, and depending on the forking
% choice, ERPs are quantified based on Mean or ERPS.
% Script also extracts Measurement error and reshapes Output to be easily
% merged into a R-readable Dataframe for further analysis.


% Important: The forking and Main Path have different Components (FMT is only s
% used in the multivariate analysis, not the GLM, Single Trial Analysis in
% main path only...) Hence, there will be two scripts, one with only ERP for forking
% and one with ERP + FMT + Single Trial Data for Main Path. Here Below
% is the Main Path for the ERP.
% At the bottom a rough Example of how Theta could be exported


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
Choices = ["Mean", "Peak", "Peak2Peak"];
Conditional = ["NaN", "~contains(TimeWindow, ""Relative"") ", "~contains(TimeWindow, ""Relative"") "];
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
    Electrodes_FRN = strrep(upper(strsplit(INPUT.StepHistory.Electrodes , ",")), " ", "");
    NrElectrodes_FRN = length(Electrodes_FRN);
    ElectrodeIdx_FRN = findElectrodeIdx(EEG.chanlocs, Electrodes_FRN);
    
    % Drop irrelevant channels
    EEG = pop_select(EEG, 'channel', cellstr(Electrodes_FRN));
    
    % Info on ** Time Window ** handled later as it can be relative
    
    % Info on ** Epochs **
    if strcmp(INPUT.AnalysisName , "Ultimatum_Quant")
        Condition_Triggers =  [1;2;3;];
        Condition_Names = ["Offer1", "Offer5", "Offer3" ];
    else
        Condition_Triggers =  [100; 101;  110; 111; 150; 151];
        Condition_Names = ["Loss_0";"Win_0";"Loss_10";"Win_10";"Loss_50"; "Win_50" ];
    end
    Event_Window = [-0.500 1.000];
    NrConditions = length(Condition_Names);
    
    
    BLTimeWindow_FMT = str2double(strsplit(INPUT.StepHistory.Baseline_FMT, " "));
    
    
    
    % ********************************************************************************************
    % **** Prepare Relative Data   ***************************************************************
    % ********************************************************************************************
    % if Time window is Relative to Peak across all Subjects or within a
    % subject, an ERP Diff needs to be created across all Conditions.
    if contains(INPUT.StepHistory.TimeWindow, "Relative")
        EEG_for_Relative = pop_epoch(EEG,  num2cell(Condition_Triggers(:)), Event_Window, 'epochinfo', 'yes');
        
            EEG_for_Relative =  pop_resample(EEG_for_Relative, fix(EEG_for_Relative.srate/100)*100);
            % Get ERP
            ERP_Relative = mean(EEG_for_Relative.data,3) ;
            % Get index of Data that should be exported (= used to find peaks)
            TimeIdxRel = findTimeIdx(EEG_for_Relative.times, 200, 400);
            % Get only relevant Data
            For_Relative.ERP.ERP = mean(ERP_Relative(:,TimeIdxRel,:),1);
            For_Relative.ERP.times = EEG_for_Relative.times(TimeIdxRel);
       
        
        % Get FMT
        FMT_Relative = 10*log10(mean(extract_power_allChans(EEG_for_Relative, [], [4 8], BLTimeWindow_FMT ),3));
        TimeIdxRel_FMT = findTimeIdx(EEG_for_Relative.times, 200, 500);
        
        For_Relative.FMT.FMT = mean(FMT_Relative(:,TimeIdxRel_FMT,:),1);
        For_Relative.FMT.times = EEG_for_Relative.times(TimeIdxRel_FMT);

        
    end
    
    
    
    % ********************************************************************************************
    % **** Set Up Some Information 2 *************************************************************
    % ********************************************************************************************
    % ****** Get Info on TimeWindow FRN ******
    TimeWindow_FRN = INPUT.StepHistory.TimeWindow;
    TimeWindow_FMT = [0 1]; % not needed for first three options
    if ~contains(TimeWindow_FRN, "Relative")
        TimeWindow_FRN = str2double(strsplit(TimeWindow_FRN, ","));
    elseif strcmp(Choice, "Peak2Peak")
        TimeWindow_FRN = [150 400];
    elseif strcmp(TimeWindow_FRN, "Relative_Subject")
        % Find Peak in Relative ERPs
        [~, Latency_FRN] = Peaks_Detection(For_Relative.ERP.ERP, "NEG");
        [~, Latency_FMT] = Peaks_Detection( For_Relative.FMT.FMT, "POS");
        % Define Time Window Based on this
        TimeWindow_FRN = [For_Relative.ERP.times(Latency_FRN) - 25, For_Relative.ERP.times(Latency_FRN) + 25];
        TimeWindow_FMT = [For_Relative.FMT.times(Latency_FMT) - 25, For_Relative.FMT.times(Latency_FMT) + 25];
        
    elseif contains(TimeWindow_FRN, "Relative_Group")
        % Time window needs to be longer since peak could be at edge
        % this part of the data will be exported later.
        TimeWindow_FRN = [150 450];
        TimeWindow_FMT = [150 550];
    end
    
    
    % Get Index of TimeWindow  [in Sampling Points]
    TimeIdx_FRN = findTimeIdx(EEG.times, TimeWindow_FRN(1), TimeWindow_FRN(2));
    TimeIdx_FMT = findTimeIdx(EEG.times, TimeWindow_FMT(1), TimeWindow_FMT(2));
    
    % ********************************************************************************************
    % ****  Prepare Data *************************************************************************
    % ********************************************************************************************
    ConditionData_FRN = [];
    ConditionData_FMT = [];
    for i_Cond = 1:NrConditions
        try
            % * Epoch Data around predefined window and save each
            EEGData = pop_epoch( EEG, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
            ConditionData_FRN.(Condition_Names(i_Cond)) =EEGData.data(:, TimeIdx_FRN,:);
            if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                ConditionData_FRN.(Condition_Names(i_Cond)) = mean(ConditionData_FRN.(Condition_Names(i_Cond)),1);
            end
            
            if contains(INPUT.StepHistory.TimeWindow, "Relative")
                FMT = 10*log10(extract_power_allChans(EEGData, [], [4 8], BLTimeWindow_FMT));
                ConditionData_FMT.(Condition_Names(i_Cond)) = FMT(:, TimeIdx_FMT,:);                
                if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                    ConditionData_FMT.(Condition_Names(i_Cond)) = mean(ConditionData_FMT.(Condition_Names(i_Cond)),1);
                end
            end
        end
    end
    
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        NrElectrodes = 1;
        Electrodes = strcat('Cluster ', join(Electrodes));
    end
    
    % update Conditions to include only the ones where epochs were found
    Condition_Names = fieldnames(ConditionData_FRN);
    NrConditions = length(Condition_Names);
    
    
    
    
    % ********************************************************************************************
    % **** Extract Data and prepare Output Table                    *******************************************
    % ********************************************************************************************
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        For_Relative.Data_FRN = ConditionData_FRN;
        For_Relative.Times_FRN= EEGData.times(TimeIdx_FRN);
        For_Relative.Data_FMT = ConditionData_FMT;
        For_Relative.Times_FMT = EEGData.times(TimeIdx_FMT);
        For_Relative.RecordingLab = EEG.Info_Lab.RecordingLab;
        For_Relative.Experimenter = EEG.Info_Lab.Experimenter;
        For_Relative.Electrodes = Electrodes_FRN; 
        
    else
        % ****** Extract Amplitude, SME, Epoch Count ******
        InitSize_FRN = [NrElectrodes_FRN,NrConditions];
        EpochCount_FRN = NaN(InitSize_FRN);
        ERP_FRN =NaN(InitSize_FRN); SME_FRN=NaN(InitSize_FRN);
        
        for i_Cond = 1:NrConditions
            Data_FRN = ConditionData_FRN.(Condition_Names{i_Cond})(:,:,:);
            
            % Count Epochs
            EpochCount_FRN(:,i_Cond) = size(Data_FRN,3);
            if size(Data_FRN,3) < 1 %  str2double(INPUT.StepHistory.Trials_MinNumber)
                ERP_FRN(:,i_Cond) = NaN;
                SME_FRN(:,i_Cond) = NaN;
            else
                % Calculate ERP if enough epochs there
                if strcmp(Choice ,  "Mean")
                    ERP_FRN(:,i_Cond) = mean(mean(Data_FRN,3),2);
                    SME_FRN(:,i_Cond) = Mean_SME(Data_FRN);
                elseif strcmp(Choice ,  "Peak")
                    ERP_FRN(:,i_Cond) = Peaks_Detection(mean(Data_FRN,3), "NEG");
                    SME_FRN(:,i_Cond) = Peaks_SME(Data_FRN, "NEG");
                elseif strcmp(Choice ,  "Peak2Peak")
                    TimesData = EEGData.times(TimeIdx_FRN);
                    TimeindexP2 = findTimeIdx(TimesData, 150, 250);
                    TimeindexFN = findTimeIdx(TimesData, 200, 400);
                    DataP2 = Data_FRN(:,TimeindexP2,:);
                    DataFN = Data_FRN(:,TimeindexFN,:);
                    P2 = Peaks_Detection(mean(DataP2,3), "POS");
                    FN = Peaks_Detection(mean(DataFN,3), "NEG");
                    ERP_FRN(:,i_Cond) = P2 - FN;
                    SME_FRN(:,i_Cond) = Peaks_to_Peak_SME(DataP2, "NEG", DataFN, "POS");
                end
            end
        end
    end
    
    
    
    % ********************************************************************************************
    % **** Extract Data     FMT                         *******************************************
    % ********************************************************************************************
    if strcmp(INPUT.StepHistory.TimeWindow, "Relative_Subject")
        
        InitSize_FMT = [NrElectrodes_FRN,NrConditions];
        EpochCount_FMT = NaN(InitSize_FMT);
        ERP_FMT =NaN(InitSize_FMT); SME_FMT =NaN(InitSize_FMT);
        
        for i_Cond = 1:NrConditions
            Data_FMT = ConditionData_FMT.(Condition_Names{i_Cond})(:,:,:);
            
            % Count Epochs
            EpochCount_FMT(:,i_Cond) = size(Data_FMT,3);
            if size(Data_FMT,3) < 1 % str2double(INPUT.StepHistory.Trials_MinNumber)
                ERP_FMT(:,i_Cond) = NaN;
                SME_FMT(:,i_Cond) = NaN;
            else
                ERP_FMT(:,i_Cond) = mean(mean(Data_FMT,3),2);
                SME_FMT(:,i_Cond) = Mean_SME(Data_FMT);
            end
        end
        

    end
    
    % ********************************************************************************************
    % **** Prepare Output Table    ***************************************************************
    % ********************************************************************************************
    
    if ~contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        % Prepare Final Export with all Values
        % ****** Prepare Labels ******
        % important P3 and N2 do not always have same number of electrodes!
        % Subject, ComponentName, Lab, Experimenter is constant AAA
        Subject_FRN_L = repmat(INPUT.Subject, NrConditions*NrElectrodes_FRN,1 );
        if strcmp(INPUT.AnalysisName , "Ultimatum_Quant")
            Task_FRN_L = repmat('Ultimatum', NrConditions*NrElectrodes_FRN,1 );
        else
            Task_FRN_L = repmat('Gambling', NrConditions*NrElectrodes_FRN,1 );
        end
        Lab_FRN_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodes_FRN,1 );
        Experimenter_FRN_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodes_FRN,1 );
        Component_FRN_L = repmat("FRN", NrConditions*NrElectrodes_FRN,1 );
        
        % Electrodes: if multiple electrodes, they simply alternate ABABAB
        Electrodes_FRN_L = repmat(Electrodes_FRN', NrConditions, 1);
        
        % Conditions are blocked across electrodes, but alternate across
        % time windows AABBAABB
        Conditions_FRN_L = repelem(Condition_Names', NrElectrodes_FRN,1);
        Conditions_FRN_L = repmat(Conditions_FRN_L(:), 1);
        
        % Time Window are blocked across electrodes and conditions AAAAABBBB
        TimeWindow_FRN_L = repmat(num2str(TimeWindow_FRN), NrConditions*NrElectrodes_FRN, 1);
        
        Export =  [cellstr([Subject_FRN_L, Lab_FRN_L, Experimenter_FRN_L, Task_FRN_L, Conditions_FRN_L, Electrodes_FRN_L, TimeWindow_FRN_L]),...
            num2cell([ERP_FRN(:), SME_FRN(:), EpochCount_FRN(:)]), cellstr(Component_FRN_L)];
        
        
        % if Relative per Subject, add FMT
        if strcmp(INPUT.StepHistory.TimeWindow, "Relative_Subject")
            TimeWindow_FMT_L = repmat(num2str(TimeWindow_FMT), NrConditions*NrElectrodes_FRN, 1);
            Component_FMT_L = repmat("FMT", NrConditions*NrElectrodes_FRN,1 );
            
            ExportFMT =  [cellstr([Subject_FRN_L, Lab_FRN_L, Experimenter_FRN_L, Task_FRN_L, Conditions_FRN_L, Electrodes_FRN_L, TimeWindow_FMT_L]),...
                num2cell([ERP_FMT(:), SME_FMT(:), EpochCount_FMT(:)]), cellstr(Component_FMT_L)];
            Export = [Export; ExportFMT];
        end
        
        % ****** Prepare Table ******
        OUTPUT.data.Export = Export ;
    else
        OUTPUT.data.For_Relative = For_Relative;
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
