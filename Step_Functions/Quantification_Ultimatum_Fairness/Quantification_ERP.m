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
Choices = ["Mean"];
Conditional = ["NaN"];
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
    Event_Window = [-0.500 1.000];
    Condition_Triggers =  [1;2;3;];
    Condition_Names = ["Offer1", "Offer5", "Offer3" ];
    NrConditions = length(Condition_Names);
    
    BLTimeWindow_FMT = str2double(strsplit(INPUT.StepHistory.Baseline_FMT, " "));
    
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
            AV_FRN = pop_epoch( EEG_for_ERP, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
            ERP_forExport.(Condition_Names(i_Cond)) = mean(AV_FRN.data,3);
            ERP_forExport.(strcat(Condition_Names(i_Cond), '_FMT')) = mean(extract_power_allChans(AV_FRN, [], [4 8], BLTimeWindow_FMT ),3);
        end
    end
    % Add Info on Exported ERP
    ERP_forExport.times = AV_FRN.times;
    ERP_forExport.chanlocs = AV_FRN.chanlocs;
    
    % Drop irrelevant channels
    EEG = pop_select(EEG, 'channel', cellstr(Electrodes));
    
    % ********************************************************************************************
    % **** Prepare Relative Data   ***************************************************************
    % ********************************************************************************************
    % if Time window is Relative to Peak across all Subjects or within a
    % subject, an ERP Diff needs to be created across all Conditions.
    if contains(INPUT.StepHistory.TimeWindow, "Relative")
        % select all relevant epochs and split them up between Accept and Reject
        % as their difference is used to detect time window
        EEG_for_Relative = pop_epoch(EEG,  num2cell(Condition_Triggers(:)), Event_Window, 'epochinfo', 'yes');
        
        if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
            EEG_for_Relative =  pop_resample(EEG_for_Relative, fix(EEG_for_Relative.srate/100)*100);
            % Get ERP
            ERP_Relative = mean(EEG_for_Relative.data,3) ;
            % Get index of Data that should be exported (= used to find peaks)
            TimeIdxRel = findTimeIdx(EEG_for_Relative.times, 150, 450);
            % Get only relevant Data
            For_Relative.ERP.ERP = mean(ERP_Relative(:,TimeIdxRel,:),1);
            For_Relative.ERP.times = EEG_for_Relative.times(TimeIdxRel);
        end
        
        % Get FMT
        FMT_Relative = 10*log10(mean(extract_power_allChans(EEG_for_Relative, [], [4 8], BLTimeWindow_FMT ),3));
        TimeIdxRel_FMT = findTimeIdx(EEG_for_Relative.times, 150, 550);
        
        if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
            For_Relative.FMT.FMT = mean(FMT_Relative(:,TimeIdxRel_FMT,:),1);
            For_Relative.FMT.times = EEG_for_Relative.times(TimeIdxRel_FMT);
        end
    end
    
    % ********************************************************************************************
    % **** Set Up Some Information 2 *************************************************************
    % ********************************************************************************************
    % ****** Get Info on TimeWindow ******
    TimeWindow_FRN = INPUT.StepHistory.TimeWindow;
    if ~contains(TimeWindow_FRN, "Relative")
        TimeWindow_FRN = str2double(strsplit(TimeWindow_FRN, ","));
        TimeWindow_FMT = str2double(strsplit(INPUT.StepHistory.TimeWindow_FMT, ","));
    elseif strcmp(TimeWindow_FRN, "Relative_Subject")
        %create ERP
        AV_FRN = mean(mean(EEG_for_Relative.data,3),1);
        AV_FMT = mean(FMT_Relative, 1);
        % find subset to find Peak
        TimeIdx_FRN = findTimeIdx(EEG_for_Relative.times, 200, 400);
        TimeIdx_FMT = findTimeIdx(EEG_for_Relative.times, 200, 500);
        % Find Peak in this Subset
        [~, Latency_FRN] = Peaks_Detection(AV_FRN(:,TimeIdx_FRN,:), "NEG");
        [~, Latency_FMT] = Peaks_Detection(AV_FMT(:,TimeIdx_FMT,:), "POS");
        % Define Time Window Based on this
        TimeWindow_FRN = [EEG_for_Relative.times(Latency_FRN+(TimeIdx_FRN(1))-1) - 25, EEG_for_Relative.times(Latency_FRN+(TimeIdx_FRN(1))-1) + 25];
        TimeWindow_FMT = [EEG_for_Relative.times(Latency_FMT+(TimeIdx_FMT(1))-1) - 25, EEG_for_Relative.times(Latency_FMT+(TimeIdx_FMT(1))-1) + 25];
        
        
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
    
    % * Epoch Data around predefined window and save each
    ConditionData_FRN = EEG.data(:, TimeIdx_FRN,:);
    FMT = 10*log10(extract_power_allChans(EEG, [], [4 8], BLTimeWindow_FMT ));
    ConditionData_FMT = FMT(:, TimeIdx_FMT,:);
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        ConditionData_FRN = mean(ConditionData_FRN,1);
        ConditionData_FMT = mean(ConditionData_FMT,1);
        NrElectrodes = 1;
        Electrodes = strcat('Cluster ', join(Electrodes));
    end
        
    
    % ********************************************************************************************
    % **** Extract Data and prepare Output Table    **********************************************
    % ********************************************************************************************
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        For_Relative.Data_FRN = ConditionData_FRN;
        For_Relative.Times_FRN= EEG.times(TimeIdx_FRN);
        For_Relative.Data_FMT = ConditionData_FMT;
        For_Relative.Times_FMT = EEG.times(TimeIdx_FMT);
        For_Relative.RecordingLab = EEG.Info_Lab.RecordingLab;
        For_Relative.Experimenter = EEG.Info_Lab.Experimenter;
        For_Relative.Electrodes = Electrodes;
        
        TrialInfo = cell(size(EEG.epoch,2), 4);
        for iep = 1:length(TrialInfo)
            TrialInfo(iep,:) = [ EEG.epoch(iep).eventTrial{1,1}, ...
                EEG.epoch(iep).eventOfferSelf{1,1}, ...
                EEG.epoch(iep).eventResponse{1,1}, ...
                EEG.epoch(iep).eventRT{1,1}];
        end
        For_Relative.TrialInfo = TrialInfo;
        % Add to Export
        OUTPUT.data.For_Relative = For_Relative;
    
    else
        % ****** Extract Amplitude per Trial ******
        Export_Header = {'ID', 'Lab', 'Experimenter', 'Trial', 'Offer', 'Choice', 'RT', 'Component',  'Electrode', 'EEG_Signal'};
        ConditionData_FRN = mean(ConditionData_FRN, 2);
        ConditionData_FRN = reshape(ConditionData_FRN, size(ConditionData_FRN, 1), size(ConditionData_FRN, 3));
        ConditionData_FRN = ConditionData_FRN';
        ConditionData_FMT = mean(ConditionData_FMT, 2);
        ConditionData_FMT = reshape(ConditionData_FMT, size(ConditionData_FMT, 1), size(ConditionData_FMT, 3));
        ConditionData_FMT = ConditionData_FMT';

        Electrode_Labels = repmat(Electrodes, size(ConditionData_FRN,1), 1);
        Constants = repmat({INPUT.Subject, EEG.Info_Lab.RecordingLab, EEG.Info_Lab.Experimenter}, ...
            size(ConditionData_FRN,1)*size(ConditionData_FRN,2),1);
        
        TrialInfo = cell(size(ConditionData_FRN,1), 4);
        for iep = 1:length(TrialInfo)
            TrialInfo(iep,:) = [ EEG.epoch(iep).eventTrial{1,1}, ...
                EEG.epoch(iep).eventOfferSelf{1,1}, ...
                EEG.epoch(iep).eventResponse{1,1}, ...
                EEG.epoch(iep).eventRT{1,1}];
        end
        
        Export = [Export_Header; ...
            [Constants,  ...
            repmat(TrialInfo, NrElectrodes, 1), ...
            repmat("FRN", size(ConditionData_FRN,1)*NrElectrodes, 1), ...
            Electrode_Labels(:), ConditionData_FRN(:)];
            [Constants,  ...
            repmat(TrialInfo, NrElectrodes, 1), ...
            repmat("FMT", size(ConditionData_FRN,1)*NrElectrodes, 1), ...
            Electrode_Labels(:), ConditionData_FMT(:)]];
        
        % Add to Export
        OUTPUT.data.Export = Export ;
    end
    
    % Add ERP for Plotting
    OUTPUT.data.ERP = ERP_forExport;  
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
