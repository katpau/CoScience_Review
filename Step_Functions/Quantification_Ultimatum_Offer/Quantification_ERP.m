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
    Electrodes_FRN = strrep(upper(strsplit(INPUT.StepHistory.Electrodes , ",")), " ", "");
    NrElectrodes_FRN = length(Electrodes_FRN);
    ElectrodeIdx_FRN = findElectrodeIdx(EEG.chanlocs, Electrodes_FRN);
    
    % Info on ** Time Window ** handled later as it can be relative
    
    % Info on ** Epochs **
    Event_Window = [-0.300 1.000];
    Condition_Triggers =  [1;2;3;];
    Condition_Names = ["Offer1_BothChoices", "Offer5_BothChoices", "Offer3_BothChoices" ];
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
            AV_FRN = pop_epoch( EEG_for_ERP, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
            ERP_forExport.(Condition_Names(i_Cond)) = mean(AV_FRN.data,3);
        end
    end
    % Add Info on Exported ERP
    ERP_forExport.times = AV_FRN.times;
    ERP_forExport.chanlocs = AV_FRN.chanlocs;
    
    
    % ********************************************************************************************
    % **** Prepare Relative Data   ***************************************************************
    % ********************************************************************************************
    % if Time window is Relative to Peak across all Subjects or within a
    % subject, an ERP Diff needs to be created across all Conditions.
    if contains(INPUT.StepHistory.TimeWindow, "Relative")
        % select all relevant epochs and split them up between Accept and Reject
        % as their difference is used to detect time window
        EEG_for_Relative = pop_epoch(EEG,  num2cell(Condition_Triggers(1:3)), Event_Window, 'epochinfo', 'yes');
        CorrectChoice = unique([EEG_for_Relative.event(strcmp([EEG_for_Relative.event.Response] , "Reject")).epoch]);
        EEG_for_Relative_Reject = pop_selectevent( EEG_for_Relative, 'epoch',CorrectChoice ,'deleteevents','off','deleteepochs','on','invertepochs','off');
        
        CorrectChoice = unique([EEG_for_Relative.event(strcmp([EEG_for_Relative.event.Response] , "Accept")).epoch]);
        EEG_for_Relative_Accept = pop_selectevent( EEG_for_Relative, 'epoch',CorrectChoice ,'deleteevents','off','deleteepochs','on','invertepochs','off');
        
        if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
            % Due to different recording setup, Biosemi needs to be resampled
            EEG_for_Relative_Export_Reject =  pop_resample(EEG_for_Relative_Reject, fix(EEG_for_Relative_Reject.srate/100)*100);
            EEG_for_Relative_Export_Accept =  pop_resample(EEG_for_Relative_Accept, fix(EEG_for_Relative_Accept.srate/100)*100);
            AV_FRN = mean(EEG_for_Relative_Export_Reject.data,3) - mean(EEG_for_Relative_Export_Accept.data,3);
            % Get index of Data that should be exported (= used to find peaks)
            ElectrodeIdxRel = [ElectrodeIdx_FRN];
            TimeIdxRel = findTimeIdx(EEG_for_Relative_Export_Reject.times, 150, 450);
            % Get only relevant Data
            For_Relative.ERP.AV = AV_FRN(ElectrodeIdxRel,TimeIdxRel,:);
            For_Relative.ERP.times = EEG_for_Relative_Export_Reject.times(TimeIdxRel);
            For_Relative.ERP.chanlocs = EEG_for_Relative_Export_Reject.chanlocs(ElectrodeIdxRel);
        end
    end
    
    % ********************************************************************************************
    % **** Set Up Some Information 2 *************************************************************
    % ********************************************************************************************
    % ****** Get Info on TimeWindow ******
    TimeWindow_FRN = INPUT.StepHistory.TimeWindow;
    if ~contains(TimeWindow_FRN, "Relative")
        TimeWindow_FRN = str2double(strsplit(TimeWindow_FRN, ","));
    elseif strcmp(TimeWindow_FRN, "Relative_Subject")
        %create ERP
        AV_FRN = mean(EEG_for_Relative_Reject.data,3) - mean(EEG_for_Relative_Accept.data,3);
        % find subset to find Peak
        TimeIdx_FRN = findTimeIdx(EEG_for_Relative.times, 200, 400);
        % Find Peak in this Subset
        [~, Latency_FRN] = Peaks_Detection(mean(AV_FRN(ElectrodeIdx_FRN,TimeIdx_FRN,:),1), "NEG");
        % Define Time Window Based on this
        TimeWindow_FRN = [EEG_for_Relative.times(Latency_FRN+(TimeIdx_FRN(1))) - 25, EEG_for_Relative.times(Latency_FRN+(TimeIdx_FRN(1))) + 25];
        
    elseif contains(TimeWindow_FRN, "Relative_Group")
        % Time window needs to be longer since peak could be at edge
        % this part of the data will be exported later.
        TimeWindow_FRN = [150 450];
    end
    
    % Get Index of TimeWindow N2 [in Sampling Points]
    TimeIdx_FRN = findTimeIdx(EEG.times, TimeWindow_FRN(1), TimeWindow_FRN(2));
    
    % ********************************************************************************************
    % ****  Prepare Data *************************************************************************
    % ********************************************************************************************
    for i_Cond = 1:NrConditions
        try
            % * Epoch Data around predefined window and save each
            EEGData = pop_epoch( EEG, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
            ConditionData_FRN.(Condition_Names(i_Cond)) = EEGData.data(ElectrodeIdx_FRN, TimeIdx_FRN,:);
            
            % Update Nr on Electrodes for Final OutputTable
            if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                ConditionData_FRN.(Condition_Names(i_Cond)) = mean(ConditionData_FRN.(Condition_Names(i_Cond)),1);
            end
        end
    end
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        NrElectrodes_FRN = 1;
        Electrodes_FRN = strcat('Cluster ', join(Electrodes_FRN));
    end
    
    % update Conditions to include only the ones where epochs were found
    Condition_Names = fieldnames(ConditionData_FRN);
    NrConditions = length(Condition_Names);
    
    % ********************************************************************************************
    % **** Extract Data and prepare Output Table    **********************************************
    % ********************************************************************************************
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        For_Relative.RecordingLab = EEG.Info_Lab.RecordingLab;
        For_Relative.Experimenter = EEG.Info_Lab.Experimenter;
        For_Relative.Data_FRN = ConditionData_FRN;
        For_Relative.Times_FRN= EEGData.times(TimeIdx_FRN);
        For_Relative.Electrodes_FRN = Electrodes_FRN;
        
    else
        % ****** Extract Amplitude, SME, Epoch Count ******
        InitSize_FRN = [NrElectrodes_FRN,NrConditions];
        EpochCount_FRN = NaN(InitSize_FRN);
        ERP_FRN =NaN(InitSize_FRN); SME_FRN=NaN(InitSize_FRN);
        
        for i_Cond = 1:NrConditions
            Data_FRN = ConditionData_FRN.(Condition_Names{i_Cond});
            
            % Count Epochs
            EpochCount_FRN(:,i_Cond,:) = size(Data_FRN,3);
            if size(Data_FRN,3) < str2double(INPUT.StepHistory.Trials_MinNumber)
                ERP_FRN(:,i_Cond,:) = NaN;
                SME_FRN(:,i_Cond,:) = NaN;
            else
                % Calculate Mean if enough epochs there
                ERP_FRN(:,i_Cond,1) = mean(mean(Data_FRN,3),2);
                SME_FRN(:,i_Cond,1) = Mean_SME(Data_FRN);
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
        % important P3 and N2 do not always have same number of electrodes!
        % Subject, ComponentName, Lab, Experimenter is constant AAA
        Subject_FRN_L = repmat(INPUT.Subject, NrConditions*NrElectrodes_FRN,1 );
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
        
        Export =  [cellstr([Subject_FRN_L, Lab_FRN_L, Experimenter_FRN_L, Conditions_FRN_L, Electrodes_FRN_L, TimeWindow_FRN_L]),...
            num2cell([ERP_FRN(:), SME_FRN(:), EpochCount_FRN(:)]), cellstr(Component_FRN_L)];
        
        % ****** Prepare Table ******
        OUTPUT.data.Export = Export ;
    end
    
    
    
%     % ********************************************************************************************
%     % **** CALCULATE MFT AND PREPARE EXPORT on FMT ***********************************************
%     % ********************************************************************************************
%     % only for Main Path - Remove from here! 
%     % initate arrays
%     % Get Info on ** Electrodes **
%     Electrodes_MFT = strrep(upper(strsplit(INPUT.StepHistory.Electrodes , ",")), " ", "");
%   
%     EEG_FMT = pop_epoch(EEG,  num2cell(Condition_Triggers(1:3)), Event_Window, 'epochinfo', 'yes');
%     EEG_FMT = pop_select(EEG_FMT, 'channel', cellstr(Electrodes_MFT));
%     TimeWindowBL =  [str2num( INPUT.StepHistory.Baseline_FMT)];
%     TimeIdxBL = findTimeIdx(EEG_FMT.times, TimeWindowBL(1), TimeWindowBL(2));
%     PowerData = [];
%     
%     Condition_Triggers =  [1;2;3;1;2;3];
%     Condition_Names = ["Offer1_Accept", "Offer5_Accept", "Offer2_Accept", "Offer1_Reject", "Offer5_Reject", "Offer2_Reject" ];
%     Response = ["Accept", "Accept", "Accept", "Reject", "Reject", "Reject"];
%     NrConditions = length(Condition_Names);
%  
%     % **** Calculate Power *****
%     Trial_info = [];
%     for i_Cond = 1:NrConditions
%         % Epoch Data
%         EEGData = pop_epoch( EEG_FMT, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
%         CorrectChoice = unique([EEGData.event(strcmp([EEGData.event.Response] , Response(i_Cond))).epoch]);
%         if length(CorrectChoice) > 1
%             EEGData = pop_selectevent( EEGData, 'epoch',CorrectChoice ,'deleteevents','off','deleteepochs','on','invertepochs','off');
%             Trial_info = [Trial_info, [EEGData.event.Trial]];
%             % Initate Matrices
%             Power = NaN(size(EEGData.data));
%             Power_DB = NaN(size(EEGData.data));
%             Power_BL = NaN(EEGData.nbchan, 1, EEGData.trials);
% 
%             % Calculate Time Frequency
%             Power = wavelet_power_2(EEGData,'lowfreq', 4,...
%                 'highfreq', 8, ...
%                 'log_spacing', 1, ...
%                 'fixed_cycles', 3.5); 
%             % Baseline Correct Power
%             Power_BL = mean(Power(:,TimeIdxBL,:),2);
%             Power_BL = repmat(Power_BL, 1, size(Power,2)); % reshape for easier correction
%             Power_DB = Power ./ Power_BL; % add 10*log10() ???
%             PowerData.(Condition_Names{i_Cond}) = Power_DB; 
%         else
%             PowerData.(Condition_Names{i_Cond})  = NaN(EEGData.nbchan,EEGData.pnts,1);
%         end
%     end
%     
%     % **** Calculate Power AV across Conditions *****
%     Power_GAV = cat(3, PowerData.(Condition_Names{1}), ...
%         PowerData.(Condition_Names{2}), ...
%         PowerData.(Condition_Names{3}), ...
%         PowerData.(Condition_Names{4}), ...
%         PowerData.(Condition_Names{5}), ...
%         PowerData.(Condition_Names{6}) );
%     Power_GAV = nanmean(Power_GAV, 3);
%     
%     % Get Time Window
%     TimeWindow_FMT = INPUT.StepHistory.TimeWindow_FMT;
%     if ~contains(TimeWindow_FMT, "Relative")
%         TimeWindow_FMT = str2double(strsplit(TimeWindow_FMT, ","));
%     elseif strcmp(TimeWindow_FMT, "Relative_Subject")
%         % Calculate Grand Average
%         FMT = mean(Power_GAV,3);
%         % find subset to find Peak
%         TimeIdx_FMT = findTimeIdx(EEG_FMT.times, 200, 500);
%         % Find Peak in this Subset
%         [~, Latency_FMT] = Peaks_Detection(mean(mean(FMT(:,TimeIdx_FMT),1),3), "POS");
%         % Define Time Window Based on this
%         TimeWindow_FMT = [EEG_FMT.times(Latency_FMT+(TimeIdx_FMT(1))) - 25, EEG_FMT.times(Latency_FMT+(TimeIdx_FMT(1))) + 25];
%         
%     elseif contains(TimeWindow_FMT, "Relative_Group")
%         % Time window needs to be longer since peak could be at edge
%         % this part of the data will be exported later
%         TimeWindow_FMT = [150 550];
%     end
%     % Get Index of TimeWindow  [in Sampling Points]
%     TimeIdx_FMT = findTimeIdx(EEG_FMT.times, TimeWindow_FMT(1), TimeWindow_FMT(2));
%     
%     
%     
%     % **** Prepare Data (extract only relevant Data
%     for i_Cond = 1:NrConditions
%         PowerToKeep = PowerData.(Condition_Names{i_Cond});
%         if INPUT.StepHistory.Cluster_Electrodes == "cluster"
%             PowerToKeep = mean(PowerToKeep, 1); % first dimensions are Electrodes
%         end
%         PowerData.(Condition_Names{i_Cond}) = PowerToKeep(:, TimeIdx_FMT, :);
%     end
% 
%     % ********************************************************************************************
%     % ****  PREPARE EXPORT OF MFT ****************************************************************
%     % ********************************************************************************************
%       InitSize_MFT = [NrElectrodes_FRN,NrConditions];
%       
%     if contains(INPUT.StepHistory.TimeWindow_FMT, "Relative_Group")
%         For_Relative_MFT.Data_FMT = PowerData;
%         For_Relative_MFT.Times_FMT = EEG_FMT.times(TimeIdx_FMT);
%         For_Relative_MFT.Electrodes_FMT = {EEG_FMT.chanlocs.labels};
%         For_Relative_MFT.Trials = Trial_info;
%         
%     else
%         % ***** Extract Power per Condition and Trial ******
%         % Initate Matrices
%         EpochCountFMT =  NaN(InitSize_MFT);
%         Nr_El = length(Electrodes_FRN);
%         FMT = [];
%        % SME_FMT =  NaN(InitSize_FRN);
%         for i_Cond = 1:NrConditions
%             Data = PowerData.(Condition_Names{i_Cond});
%             % Count Epochs
%             NrEpochs = size(Data,3);
%             % if enough epochs, calculate mean per trials otherwise do
%             % nothing
%              if size(Data,3) >= str2double(INPUT.StepHistory.Trials_MinNumber)
%             Data = mean(Data,2);
%             FMT = [FMT; repmat(Condition_Names{i_Cond},NrEpochs*Nr_El),  ...
%                 repmat(Electrodes_FRN', NrEpochs, 1) , ...
%                 repmat(num2str(TimeWindow_FMT), NrEpochs*Nr_El, 1), ...
%                 Data(:), ... % NaN(length(Data(:)),1), ...% or add SME? but how for Single Trial Data?
%                 repmat(NrEpochs, length(Data(:)),1)];
%             end
%             
%         end
%     end
%     
%     % ********************************************************************************************
%     % **** Prepare Output Table MFT   ***************************************************************
%     % ********************************************************************************************
%     if contains(INPUT.StepHistory.TimeWindow_FMT, "Relative_Group")
%         if isfield(OUTPUT.data, 'For_Relative')
%             namesfields = [fieldnames(OUTPUT.data.For_Relative); fieldnames(For_Relative_MFT)];
%             OUTPUT.data.For_Relative = cell2struct([struct2cell(OUTPUT.data.For_Relative); struct2cell(For_Relative_MFT)], namesfields, 1);
%         else
%             OUTPUT.data.For_Relative = For_Relative_FMT;
%         end
%         OUTPUT.data.For_Relative.Experimenter = EEG.Info_Lab.Experimenter; % add like this in case field exists
%         OUTPUT.data.For_Relative.RecordingLab = EEG.Info_Lab.RecordingLab; % add like this in case field exists
%         
%         
%     else
%         % ****** Prepare Table ******
%         ComponentFMT_L = repmat("FMT", size(FMT,1),1 );
%         NrTrials = size(FMT,1);
%          
%         ExportMFTSingleTrial = [repmat(INPUT.Subject,NrTrials,1), ...
%             repmat(EEG.Info_Lab.RecordingLab,NrTrials,1), ...
%             repmat(EEG.Info_Lab.Experimenter,NrTrials,1), ...
%             FMT,...
%             repmat("FMT", NrTrials, 1), ...
%             Trial_info];
%         
%         % Add to File
%         OUTPUT.data.Export = Export;
%     end
    
    
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
