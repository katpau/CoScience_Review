function  OUTPUT = TimeWindow(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by:

% This script does the following:
% Script only marks which Times are used for quantification.
% Also determines the time Window for P3 and FMT.
% Nothing is done here as this will be used in a later
% Step (Quantificiation ERP).

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
StepName = "TimeWindow";
Choices = ["200,400", "240,340", "150,350", "Relative_Group_wide", "Relative_Group_narrow", "Relative_Subject"];
Conditional = ["NaN", "NaN", "NaN", "NaN", "NaN", "NaN"];
SaveInterim = logical([0]);
Order = [21];

%% Make Note on Time Window
% For P3 save other time window
if strcmp(Choice , "200,400")
    ChoiceP3 = "300,600";
elseif strcmp(Choice ,  "240,340" )
    ChoiceP3 = "250,500";
elseif strcmp(Choice ,"150,350")
    ChoiceP3 = "300,600";
elseif strcmp(Choice ,  "Relative_Group_wide")
    ChoiceP3 = "Relative_Group_wide";
elseif strcmp(Choice ,  "Relative_Group_narrow")
    ChoiceP3 = "Relative_Group_narrow";
elseif strcmp(Choice ,  "Relative_Subject")
    ChoiceP3 = "Relative_Subject";
end


% For FMT save other time window
if strcmp(Choice , "200,400")
    ChoiceFMT = "Relative_Group_wide";
elseif strcmp(Choice ,  "240,340" )
    ChoiceFMT = "200,350";
elseif strcmp(Choice ,"150,350")
    ChoiceFMT = "200,350";
elseif strcmp(Choice ,  "Relative_Group_wide")
    ChoiceFMT = "Relative_Group_wide";
elseif strcmp(Choice ,  "Relative_Group_narrow")
    ChoiceFMT = "Relative_Group_narrow";
elseif strcmp(Choice ,  "Relative_Subject")
    ChoiceFMT = "Relative_Subject";
end

INPUT.StepHistory.TimeWindow_P3 = ChoiceP3;
INPUT.StepHistory.TimeWindow_FMT = ChoiceFMT;


% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
OUTPUT.data = []; % Remove EEG structure


%% Extract EEG Data (Single Trial Data)
% Some Error Handling
try
    %%%%%%%%%%%%%%%% Routine for the analysis of this step
    EEG = INPUT.data.EEG;
    
    
    % ********************************************************************************************
    % **** Set Up Some Information 1 ***************************************************************
    % ********************************************************************************************
    % Get Info on ** Electrodes **
    Electrodes_N2 = strrep(upper(strsplit(INPUT.StepHistory.Electrodes , ",")), " ", "");
    NrElectrodes_N2 = length(Electrodes_N2);
    ElectrodeIdx_N2 = findElectrodeIdx(EEG.chanlocs, Electrodes_N2);
    
    Electrodes_P3 = upper(strsplit(INPUT.StepHistory.Electrodes_P3 , ","));
    NrElectrodes_P3 = length(Electrodes_P3);
    ElectrodeIdx_P3 = findElectrodeIdx(EEG.chanlocs, Electrodes_P3);
    
    % Info on ** Time Window ** handled later as it can be relative
    
    % Info on ** Epochs **
    Event_Window = [-0.200 0.500];
    Condition_Triggers = {'104';  '114'; '124'; '134'}; % Target onset
    Condition_Names = ["Cong_000",        "Cong_033",        "Cong_066",        "Cong_100"];
    NrConditions = length(Condition_Names);
    
    EEG_epoched = pop_epoch(EEG, Condition_Triggers', Event_Window, 'epochinfo', 'yes');
    
    % ********************************************************************************************
    % **** Prepare ERP  ***************************************************************
    % ********************************************************************************************
    % For saving ERP, select only relevant channels
    Electrodes_ERP = {'FCZ', 'CZ', 'FZ', 'PZ', 'CPZ'}; % includes N2 and P3 channels
    EEG_for_ERP = pop_select(EEG_epoched, 'channel',Electrodes_ERP);
    % For saving ERP, downsample!
    % EEG_for_ERP =  pop_resample(EEG_for_ERP, 100);
    EEG_for_ERP =  pop_resample(EEG_for_ERP, fix(EEG_for_ERP.srate/100)*100);
    
    
    for i_Cond = 1:NrConditions
        try
            ERP_N2 = pop_epoch( EEG_for_ERP, Condition_Triggers(i_Cond,:), Event_Window, 'epochinfo', 'yes');
            ERP_forExport.(Condition_Names(i_Cond)) = mean(ERP_N2.data,3);
        end
    end
    
    % Add Info on Exported ERP
    ERP_forExport.times = ERP_N2.times;
    ERP_forExport.chanlocs = ERP_N2.chanlocs;
    
    
    
    % ********************************************************************************************
    % **** Prepare Relative Data   ***************************************************************
    % ********************************************************************************************
    % if Time window is Relative to Peak across all Subjects or within a
    % subject, an ERP needs to be created across all Conditions.
    if contains(INPUT.StepHistory.TimeWindow, "Relative")
        % select all relevant epochs
        EEG_for_Relative = pop_epoch(EEG, Condition_Triggers', Event_Window, 'epochinfo', 'yes');
        if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
            % Due to different recording setup, Biosemi needs to be resampled
            EEG_for_Relative_Export =  pop_resample(EEG_for_Relative, fix(EEG_for_Relative.srate/100)*100);
            % Get index of Data that should be exported (= used to find peaks)
            ElectrodeIdxRel = [ElectrodeIdx_N2, ElectrodeIdx_P3];
            TimeIdxRel = findTimeIdx(EEG_for_Relative_Export.times, 150, 600);
            % Get only relevant Data
            For_Relative.ERP.AV = mean(EEG_for_Relative_Export.data(ElectrodeIdxRel,TimeIdxRel,:),3) ;
            For_Relative.ERP.times = EEG_for_Relative_Export.times(TimeIdxRel);
            For_Relative.ERP.chanlocs = EEG_for_Relative_Export.chanlocs(ElectrodeIdxRel);
        end
    end
    
    % ********************************************************************************************
    % **** Set Up Some Information 2 *************************************************************
    % ********************************************************************************************
    % ****** Get Info on TimeWindow ******
    TimeWindow_N2 = INPUT.StepHistory.TimeWindow;
    TimeWindow_P3 = INPUT.StepHistory.TimeWindow_P3;
    if ~contains(TimeWindow_N2, "Relative")
        TimeWindow_N2 = str2double(strsplit(TimeWindow_N2, ","));
        TimeWindow_P3 = str2double(strsplit(TimeWindow_P3, ","));
        
    elseif strcmp(TimeWindow_N2, "Relative_Subject")
        % find subset to find Peak
        TimeIdx_N2 = findTimeIdx(EEG_epoched.times, 150, 400);
        TimeIdx_P3 = findTimeIdx(EEG_epoched.times, 250, 600);
        % Calculate Grand Average ERP
        ERP_N2 = mean(EEG_epoched.data,3);
        % Find Peak in this Subset
        [~, Latency_N2] = Peaks_Detection(mean(ERP_N2(ElectrodeIdx_N2,TimeIdx_N2,:),1), "NEG");
        [~, Latency_P3] = Peaks_Detection(mean(ERP_N2(ElectrodeIdx_P3,TimeIdx_P3,:),1), "POS");
        % Define Time Window Based on this
        TimeWindow_N2 = [EEG_epoched.times(Latency_N2+(TimeIdx_N2(1))) - 25, EEG_epoched.times(Latency_N2+(TimeIdx_N2(1))) + 25];
        TimeWindow_P3 = [EEG_epoched.times(Latency_P3+(TimeIdx_P3(1))) - 25, EEG_epoched.times(Latency_P3+(TimeIdx_P3(1))) + 25];
        
    elseif contains(TimeWindow_N2, "Relative_Group")
        % Time window needs to be longer since peak could be at edge
        % this part of the data will be exported an, based on the peak in the
        % group, the ERPs will be determined.
        TimeWindow_N2 = [100 450];
        TimeWindow_P3 = [200 650];
    end
    
    % Get Index of TimeWindow N2 [in Sampling Points]
    TimeIdx_N2 = findTimeIdx(EEG_epoched.times, TimeWindow_N2(1), TimeWindow_N2(2));
    TimeIdx_P3 = findTimeIdx(EEG_epoched.times, TimeWindow_P3(1), TimeWindow_P3(2));
    
    % ********************************************************************************************
    % ****  Prepare Data *************************************************************************
    % ********************************************************************************************
    % Prepare Behav Data(one per Trial, Targetlocked)
    if length(EEG_epoched.event) > length([EEG_epoched.event.Event])
        for ievent = 1:length(EEG_epoched.event)
            if isempty(EEG_epoched.event(ievent).Event)
                EEG_epoched.event(ievent).Event = NaN;
            end
        end
    end
    Targets = EEG_epoched.event([EEG_epoched.event.Event] == "Target");   %  doesnt work if an Event is empty thats why the weird loop above?
    
    % Merge Data
    colNames_Behav =["Trial",  "Congruency", "ACC", "RT", "Subject", "Lab", "Experimenter"];
    Single_TrialData_Behav = [num2cell([[Targets.Trial]', [Targets.Congruency]', [Targets.ACC]', [Targets.RT]']), ...
        cellstr(repmat(INPUT.Subject, length(Targets), 1)), ...
        cellstr(repmat(EEG.Info_Lab.RecordingLab, length(Targets), 1)), ...
        cellstr(repmat(EEG.Info_Lab.Experimenter, length(Targets), 1))];
    Single_TrialData_Behav = [colNames_Behav;Single_TrialData_Behav];
    
    
    % Prepare Data for each Component (not averaged across time window)
    %N2_SingleTrial = squeeze(EEG_epoched.data(ElectrodeIdx_N2, TimeIdx_N2,:));
    %P3_SingleTrial = squeeze(EEG_epoched.data(ElectrodeIdx_P3, TimeIdx_P3,:));
    
    N2_SingleTrial = EEG_epoched.data(ElectrodeIdx_N2, TimeIdx_N2,:);
    P3_SingleTrial = EEG_epoched.data(ElectrodeIdx_P3, TimeIdx_P3,:);
    
    % Merge across electrodes if clustered
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        N2_SingleTrial = mean(N2_SingleTrial,1);
        P3_SingleTrial = mean(P3_SingleTrial,1);
        Electrodes_N2 = strcat('Cluster ', join(Electrodes_N2));
        Electrodes_P3 = strcat('Cluster ', join(Electrodes_P3));
    end
    
    
    
    
    % ********************************************************************************************
    % **** Extract Data and prepare Output Table    **********************************************
    % ********************************************************************************************
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        % no ERP detection, only export relevant part of data used to
        % determine ERP based on Group Peak
        For_Relative.Data_N2 = N2_SingleTrial;
        For_Relative.Times_N2 = EEG_epoched.times(TimeIdx_N2);
        For_Relative.Electrodes_N2 = Electrodes_N2;
        
        For_Relative.Data_P3 = P3_SingleTrial;
        For_Relative.Times_P3 = EEG_epoched.times(TimeIdx_P3);
        For_Relative.Electrodes_P3 = Electrodes_P3;
        
        For_Relative.Behav = Single_TrialData_Behav;
        
    else
        % ****** Extract Amplitude, SME, Epoch Count ******
        % Average across time window
        %N2_SingleTrial = squeeze(mean(N2_SingleTrial,2));
        %P3_SingleTrial = squeeze(mean(P3_SingleTrial,2));
        N2_SingleTrial = mean(N2_SingleTrial,2);
        P3_SingleTrial = mean(P3_SingleTrial,2);
        % Prepare Export
        colNames_ERP =[strcat("N2_", Electrodes_N2')', strcat("P3_", Electrodes_P3')'];
        % Reshape to drop Time and make electrodes first
        N2_SingleTrial = reshape(N2_SingleTrial,[size(N2_SingleTrial,3),size(N2_SingleTrial,1)]);
        P3_SingleTrial = reshape(P3_SingleTrial,[size(P3_SingleTrial,3),size(P3_SingleTrial,1)]);
        Single_TrialData_ERP = num2cell([N2_SingleTrial,P3_SingleTrial]);
        Single_TrialData_ERP = [colNames_ERP;Single_TrialData_ERP];
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
        % ****** Prepare Table ******
        OUTPUT.data.Export = [Single_TrialData_Behav, Single_TrialData_ERP];
    end
    
    
    
    
    % ********************************************************************************************
    % **** CALCULATE FMT AND PREPARE EXPORT *****************************************************
    % ********************************************************************************************
    
    % Get Info on ** Electrodes ** and ** Baseline **
    Electrodes_MFT = strrep(upper(strsplit(INPUT.StepHistory.Electrodes , ",")), " ", "");
    TimeWindowBL =  [str2num( INPUT.StepHistory.Baseline_FMT)];
    
    % **** Calculate Power and correct BL *****
    Power_DB =  extract_power(EEG,cellstr(Electrodes_MFT),[4, 8], [TimeWindowBL(1), TimeWindowBL(2)] );
    
    % **** Calculate Power AV across Conditions *****
    Power_GAV = 10*log10(mean(Power_DB, 3));
    
    % **** Get Time Window *****
    TimeWindow_FMT = INPUT.StepHistory.TimeWindow_FMT;
    if ~contains(TimeWindow_FMT, "Relative")
        TimeWindow_FMT = str2double(strsplit(TimeWindow_FMT, ","));
        
    elseif strcmp(TimeWindow_FMT, "Relative_Subject")
        % Calculate Grand Average across Electrodes
        FMT = mean(Power_GAV,1);
        % find subset to find Peak
        TimeIdx_FMT = findTimeIdx(EEG.times, 200, 500);
        % Find Peak in this Subset
        [~, Latency_FMT] = Peaks_Detection(mean(FMT(:,TimeIdx_FMT),1), "POS");
        % Define Time Window Based on this
        TimeWindow_FMT = [EEG.times(Latency_FMT+(TimeIdx_FMT(1))) - 25, EEG.times(Latency_FMT+(TimeIdx_FMT(1))) + 25];
        
    elseif contains(TimeWindow_FMT, "Relative_Group")
        % Time window needs to be longer since peak could be at edge
        % this part of the data will be exported later
        TimeWindow_FMT = [150 550];
    end
    % Get Index of TimeWindow  [in Sampling Points]
    TimeIdx_FMT = findTimeIdx(EEG.times, TimeWindow_FMT(1), TimeWindow_FMT(2));
    
    % **** Prepare Data (extract only relevant Data)
    Power_DB = Power_DB(:,TimeIdx_FMT,:);
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        Power_DB = mean(Power_DB,1);
    end
    
    
    % ********************************************************************************************
    % ****  PREPARE EXPORT OF FMT ****************************************************************
    % ********************************************************************************************
    if contains(INPUT.StepHistory.TimeWindow_FMT, "Relative_Group")
        For_Relative_FMT.Data_FMT = Power_DB;
        For_Relative_FMT.Times_FMT = EEG.times(TimeIdx_FMT);
        For_Relative_FMT.Electrodes_FMT = cellstr(Electrodes_MFT);
        
    else
        % ***** Extract Power per Trial across Time Window ******
        % Single_TrialData_Theta = squeeze(mean(Power_DB,2));
        Single_TrialData_Theta = 10*log10(mean(Power_DB,2)); % LOG10??
        
        colNames_Theta =[strcat("N2_", Electrodes_N2')'];
        % Reshape to drop Time and make electrodes first
        Single_TrialData_Theta = reshape(Single_TrialData_Theta,[size(Single_TrialData_Theta,3),size(Single_TrialData_Theta,1)]);
        
        Single_TrialData_Theta = [num2cell([squeeze(Single_TrialData_Theta)])];
        Single_TrialData_Theta = [colNames_Theta;Single_TrialData_Theta];
    end
    
    % ********************************************************************************************
    % **** Prepare Output Table FMT   ***************************************************************
    % ********************************************************************************************
    if contains(INPUT.StepHistory.TimeWindow_FMT, "Relative_Group")
        if isfield(OUTPUT.data, 'For_Relative')
            % if ERP is also Relative, then combine Structure
            namesfields = [fieldnames(OUTPUT.data.For_Relative); fieldnames(For_Relative_FMT)];
            OUTPUT.data.For_Relative = cell2struct([struct2cell(OUTPUT.data.For_Relative); struct2cell(For_Relative_FMT)], namesfields, 1);
        else
            OUTPUT.data.For_Relative = For_Relative_FMT;
        end
        
        
    else
        % ****** Prepare Table ******
        if isfield(OUTPUT.data, 'Export')
            OUTPUT.data.Export = [OUTPUT.data.Export, Single_TrialData_Theta];
            % Add to File
        else
            OUTPUT.data.Export = [Single_TrialData_Behav,Single_TrialData_Theta];
        end
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
