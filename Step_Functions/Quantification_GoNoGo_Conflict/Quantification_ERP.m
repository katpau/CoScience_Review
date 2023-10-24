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
    EEG = INPUT.data.EEG;
    
    % ********************************************************************************************
    % **** Set Up Some Information 1 ***************************************************************
    % ********************************************************************************************
    % Get Info on ** Electrodes **
    Electrodes = strrep(upper(strsplit(INPUT.StepHistory.Electrodes , ",")), " ", "");
    NrElectrodes = length(Electrodes);
    ElectrodeIdx = findElectrodeIdx(EEG.chanlocs, Electrodes);
    
    % Info on ** Time Window ** handled later as it can be relative
    
    % Info on ** Epochs **
    Event_Window = [-0.200 0.500];
    Condition_Triggers = {'101';  '201'; '102'; '202'}; % Target onset
    Condition_Names = ["Go_Relaxed",   "Go_Speed",   "NoGo_Relaxed",       "NoGo_Speed"];
    NrConditions = length(Condition_Names);
    
    Condition_NamesDiff = ["Diff_Relaxed", "Diff_Speed"];
    NrConditionsDiff = length(Condition_NamesDiff);
    
    % ********************************************************************************************
    % **** Prepare ERP  ***************************************************************
    % ********************************************************************************************
    % For saving ERP, select only relevant channels
    ElectrodesERP = {'FCZ', 'CZ', 'FZ'};
    EEG_for_ERP = pop_select(EEG, 'channel',ElectrodesERP);
    % For saving ERP, downsample!
    EEG_for_ERP =  pop_resample(EEG_for_ERP, 100);
    for i_Cond = 1:NrConditions
        try
            ERP = pop_epoch( EEG_for_ERP, Condition_Triggers(i_Cond,:), Event_Window, 'epochinfo', 'yes');
            ERP_forExport.(Condition_Names(i_Cond)) = mean(ERP.data,3);
        catch
            error("in at least one Condition not enough Trials")
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
    if contains(INPUT.StepHistory.TimeWindow, "Relative")
        % select all relevant epochs
        EEG_for_Relative = pop_epoch( EEG, Condition_Triggers', Event_Window, 'epochinfo', 'yes');
        if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
            % Due to different recording setup, Biosemi needs to be resampled
            EEG_for_Relative_Export =  pop_resample(EEG_for_Relative, fix(EEG_for_Relative.srate/100)*100);
            % Get index of Data that should be exported (= used to find peaks)
            TimeIdxRel = findTimeIdx(EEG_for_Relative_Export.times, 150, 400);
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
        % find subset to find Peak for N2
        TimeIdx = findTimeIdx(EEG_for_Relative.times, 150, 400);
        % Calculate Grand Average ERP
        ERP = mean(EEG_for_Relative.data,3);
        % Find Peak in this Subset
        [~, Latency] = Peaks_Detection(mean(ERP(ElectrodeIdx, TimeIdx,:),1), "NEG");
        % Define Time Window Based on this
        TimeWindow = [EEG_for_Relative.times(Latency+(TimeIdx(1))) - 25, EEG_for_Relative.times(Latency+(TimeIdx(1))) + 25];
        
    elseif contains(TimeWindow, "Relative_Group")
        % Time window needs to be longer since peak could be at edge
        % this part of the data will be exported later
        TimeWindow = [100 450];
    end
    
    % Get Index of TimeWindow N2 [in Sampling Points]
    TimeIdx = findTimeIdx(EEG.times, TimeWindow(1), TimeWindow(2));
    
    % ********************************************************************************************
    % ****  Prepare Data *************************************************************************
    % ********************************************************************************************
    for i_Cond = 1:NrConditions
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
    
    
    
    % ********************************************************************************************
    % **** Extract Data and prepare Output Table    **********************************************
    % ********************************************************************************************
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        For_Relative.RecordingLab = EEG.Info_Lab.RecordingLab;
        For_Relative.Experimenter = EEG.Info_Lab.Experimenter;
        For_Relative.DataN2 = ConditionData;
        For_Relative.TimesN2 = EEGData.times(TimeIdx);
        For_Relative.ElectrodesN2 = Electrodes;
        For_Relative.ACC = INPUT.data.EEG.ACC;
                
    else
        % ****** Extract Amplitude, SME, Epoch Count ******
        InitSize = [NrElectrodes,NrConditions];
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
                % Calculate ERP and SME if enough epochs
                if strcmp(Choice, "Mean")
                    ERP(:,i_Cond,1) = mean(mean(Data,3),2);
                    SME(:,i_Cond,1) = Mean_SME(Data);
                    
                elseif strcmp(Choice, "Peak")
                    [ERP(:,i_Cond,1), ~] = Peaks_Detection(mean(Data,3), "NEG");
                    SME(:,i_Cond,1) = Peaks_SME(Data, "NEG");
                end
            end
        end
        
        
        
        % ********************************************************************************************
        % **** Loop also through Difference Waves!          ******************************************
        % ********************************************************************************************
        % Create **** Difference Waves ****   on ERPs
        for i_Diff = 1:NrConditionsDiff
            i_Cond = i_Diff + 4;
            Go = ConditionData.(Condition_Names(i_Diff));
            NoGo=  ConditionData.(Condition_Names(i_Diff+2));
            
            % Count Epochs
            MinEpochs = min(min(size(Go,3), size(NoGo,3)));
            EpochCount(:,i_Cond,:) = MinEpochs;
            if MinEpochs < str2double(INPUT.StepHistory.Trials_MinNumber)
                ERP(:,i_Cond,:) = NaN;
                SME(:,i_Cond,:) = NaN;
            else
                % Calculate Mean if enough epochs there
                if strcmp(Choice, "Mean")
                    ERP(:,i_Cond,1) = mean(mean(NoGo,3) - mean(Go,3),2);
                    SME(:,i_Cond,1) = DifferenceWave_SME(NoGo, Go, "MEAN");
                    
                elseif strcmp(Choice, "Peak")
                    ERP(:,i_Cond,1) = Peaks_Detection(mean(NoGo,3) - mean(Go,3), "NEG");
                    SME(:,i_Cond,1) = DifferenceWave_SME(NoGo, Go, "NEG");
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
        % Subject, ComponentName, Lab, Experimenter is constant AAA
        Subject_L = repmat(INPUT.Subject, (NrConditions+NrConditionsDiff)*NrElectrodes,1 );
        Lab_L = repmat(EEG.Info_Lab.RecordingLab, (NrConditions+NrConditionsDiff)*NrElectrodes,1 );
        Experimenter_L = repmat(EEG.Info_Lab.Experimenter, (NrConditions+NrConditionsDiff)*NrElectrodes,1 );
        Component_L = repmat("N2", (NrConditions+NrConditionsDiff)*NrElectrodes,1 );
        
        % Electrodes: if multiple electrodes, they simply alternate ABABAB
        Electrodes_L = repmat(Electrodes', (NrConditions+NrConditionsDiff), 1);
        
        % Conditions are blocked across electrodes, but alternate across
        % time windows AABBAABB
        Conditions_L = repelem([Condition_Names Condition_NamesDiff]', NrElectrodes,1);
        Conditions_L = repmat(Conditions_L(:), 1);
        
        % Time Window are blocked across electrodes and conditions AAAAABBBB
        TimeWindow_L = repmat(num2str(TimeWindow), (NrConditions+NrConditionsDiff)*NrElectrodes, 1);
        
        % Also Add ACC constant AAA
        ACC = repmat(INPUT.data.EEG.ACC, (NrConditions+NrConditionsDiff)*NrElectrodes,1 );
        
        % ****** Prepare Table ******
        OUTPUT.data.Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L, Electrodes_L, TimeWindow_L]),...
            num2cell([ERP(:), SME(:), EpochCount(:)]), cellstr(Component_L), num2cell(ACC)];
        
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