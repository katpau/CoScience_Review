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
Choices = ["Mean", "Peak", "Peak-to-Peak"];
Conditional = ["NaN", "TimeWindow ~= ""Relative_Group_narrow"" & TimeWindow ~= ""Relative_Subject"" ", "TimeWindow ~= ""Relative_Group_narrow"" & TimeWindow ~= ""Relative_Subject"" "];
SaveInterim = logical([1]);
Order = [22];


% For P300 save other Quantification Method
if strcmp(Choice , "Mean")
    ChoiceP3 = "Mean";
elseif strcmp(Choice, "Peak")
    ChoiceP3 = "Peak";
elseif strcmp(Choice, "Peak-to-Peak")
    ChoiceP3 = "Peak";
end

INPUT.StepHistory.Quantification_P3 = ChoiceP3;


%%%%%%%%%%%%%%%% Updating the SubjectStructure. No changes should be made here.
INPUT.StepHistory.Quantification_ERP = Choice;
OUTPUT = INPUT;
% Some Error Handling
try
    %%%%%%%%%%%%%%%% Routine for the analysis of this step
    % This functions starts from using INPUT and returns OUTPUT
    
    
    
    EEG = INPUT.data.EEG;
    
    % ********************************************************************************************
    % **** Epoch Data into different Conditions **************************************************
    % ********************************************************************************************
     % For saving ERP, select only relevant channels
      EEG_for_ERP = EEG;
      Electrodes_ERP = {'FCZ', 'CZ', 'FZ', 'PZ', 'CPZ'};
      EEG_for_ERP = pop_select(EEG_for_ERP, 'channel',Electrodes_ERP);
      %For saving ERP,  downsample!
      EEG_for_ERP =  pop_resample(EEG_for_ERP, 100);
    
    % Info on Epochs
    Event_Window = [-0.300 1.000];
    Condition_Triggers =  [100; 110; 150 ; 101; 111; 151]; % Feedback Onset
    Condition_Names = ["P0_Loss", "P10_Loss", "P50_Loss", "P0_Win", "P10_Win", "P50_Win" ];
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
    % **** Prepare Indexes of  Data to be exported ***********************************************
    % ********************************************************************************************
    
    
    % **** Get Info on Electrodes RewP******
    Electrodes = upper(strsplit(INPUT.StepHistory.Electrodes , ","));
    NrElectrodes = length(Electrodes);
    
    % Get Index on Electrodes RewP ******
    Electrodes = strrep(Electrodes, " ", "");
    ElectrodeIdx = zeros(1, length(Electrodes));
    for iel = 1:length(Electrodes)
        [~, ElectrodeIdx(iel)] = ismember(Electrodes(iel), upper({EEG.chanlocs.labels})); % Do it in this loop to maintain matching/order of Name and Index!
    end
    
    % **** Get Info on Electrodes P3 ******
    ElectrodesP3 = upper(strsplit(INPUT.StepHistory.Electrodes_P3 , ","));
    NrElectrodesP3 = length(ElectrodesP3);
    
    % Get Index on Electrodes P3 ******
    ElectrodesP3 = strrep(ElectrodesP3, " ", "");
    ElectrodeIdxP3 = zeros(1, length(ElectrodesP3));
    for iel = 1:length(ElectrodesP3)
        [~, ElectrodeIdxP3(iel)] = ismember(ElectrodesP3(iel), {EEG.chanlocs.labels}); % Do it in this loop to maintain matching/order of Name and Index!
    end
    
    % Update Nr on Electrodes for Final OutputTable
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        NrElectrodes = 1;
        NrElectrodesP3 = 1;
        Electrodes = strcat('Cluster ', join(Electrodes));
        ElectrodesP3 = strcat('Cluster ', join(ElectrodesP3));
    end
    
    
    % ****** Get Info on TimeWindow ******
    TimeWindow = INPUT.StepHistory.TimeWindow;
    TimeWindowP3 = INPUT.StepHistory.TimeWindow_P3;
    if ~contains(TimeWindow, "Relative")
        TimeWindow = str2double(strsplit(TimeWindow, ","));
        TimeWindowP3 = str2double(strsplit(TimeWindowP3, ","));
        
    elseif strcmp(TimeWindow, "Relative_Subject")
        % Calculate Difference Wave ERP
        Positive_FB = ismember({EEG.event.type }, {'101', '111', '151'});
        Negative_FB = ismember({EEG.event.type }, {'100', '110', '150'});
        Positive_FB = [EEG.event(Positive_FB).epoch];
        Negative_FB = [EEG.event(Negative_FB).epoch];
        Positive_FB = mean(EEG.data(:,:,Positive_FB),3);
        Negative_FB = mean(EEG.data(:,:,Negative_FB),3);
        ERP = Positive_FB - Negative_FB;
        
        
        % find subset to find Peak for RewP
        TimeIdx = findTimeIdx(EEG.times, 200, 400);
        
        % find subset to find Peak for P3
        TimeIdxP3 = findTimeIdx(EEG.times, 250, 600);
        
        % Find Peak in this Subset
        [~, Latency] = Peaks_Detection(mean(ERP(ElectrodeIdx,TimeIdx),1), "POS");
        [~, LatencyP3] = Peaks_Detection(mean(ERP(ElectrodeIdxP3,TimeIdxP3),1), "POS");
        
        % Define Time Window Based on this
        TimeWindow = [EEG.times(Latency+(TimeIdx(1))) - 25, EEG.times(Latency+(TimeIdx(1))) + 25];
        TimeWindowP3 = [EEG.times(LatencyP3+(TimeIdxP3(1))) - 50, EEG.times(LatencyP3+(TimeIdxP3(1))) + 50];
        
        
    elseif contains(TimeWindow, "Relative_Group")
        TimeWindow = [200 400];
        TimeWindowP3 = [250 600];
    end
    
    % Get Index of TimeWindow RewP
    TimeIdx = findTimeIdx(EEG.times, TimeWindow(1), TimeWindow(2));
    % Get Index of TimeWindow P3
    TimeIdxP3 = findTimeIdx(EEG.times, TimeWindowP3(1), TimeWindowP3(2));
    
    
    
    
    
    % ********************************************************************************************
    % **** Loop Through each Condition and extract Data ******************************************
    % ********************************************************************************************
    % if depending on group, crop data and save data for now
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        Export.Data = EEG.data(ElectrodeIdx,TimeIdx,:);
        Export.Times = EEG.times(TimeIdx);
        Export.Electrodes = {EEG.chanlocs(ElectrodeIdx).labels};
        
        Export.DataP3 = EEG.data(ElectrodeIdxP3,TimeIdxP3,:);
        Export.TimesP3 = EEG.times(TimeIdxP3);
        Export.ElectrodesP3 = {EEG.chanlocs(ElectrodeIdxP3).labels};
        
    else
        % if not dependent on group,
        % ****** Extract Amplitude, SME, Epoch Count ******
        InitSize = [NrElectrodes,NrConditions];
        EpochCount = NaN(InitSize);
        ERP =NaN(InitSize); SME=NaN(InitSize);
        InitSizeP3 = [NrElectrodesP3,NrConditions];
        ERPP3 =NaN(InitSizeP3); SMEP3=NaN(InitSizeP3);
        EpochCountP3 = NaN(InitSizeP3);
        Trials = NaN(NrConditions);
        
        for i_Cond = 1:NrConditions
            % Select relevant Data
            Data = ConditionData.(Condition_Names(i_Cond))(ElectrodeIdx,TimeIdx,:);
            DataP3 = ConditionData.(Condition_Names(i_Cond))(ElectrodeIdxP3,TimeIdxP3,:);
            
            % check if Electrodes should be averaged across, or kept
            % separate
            if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                Data = mean(Data, 1); % first dimensions are Electrodes
                DataP3 = mean(DataP3, 1); % first dimensions are Electrodes
            end
            
            % Count Epochs
            EpochCount(:,i_Cond,:) = size(Data,3);
            EpochCountP3(:,i_Cond,:) = size(Data,3);
            if Trials(i_Cond) < str2double(INPUT.StepHistory.Trials_MinNumber)
                ERP(:,i_Cond,:) = NaN;
                SME(:,i_Cond,:) = NaN;
                ERPP3(:,i_Cond,:) = NaN;
                SMEP3(:,i_Cond,:) = NaN;
            else
                % Calculate Mean if enough epochs there
                if strcmp(Choice, "Mean")
                    ERP(:,i_Cond,1) = mean(mean(Data,3),2);
                    SME(:,i_Cond,1) = Mean_SME(Data);
                elseif strcmp(Choice, "Peak")
                    [ERP(:,i_Cond,1), ~] = Peaks_Detection(mean(Data,3), "NEG");
                    SME(:,i_Cond,1) = Peaks_SME(Data, "NEG");
                elseif strcmp(Choice, "Peak-to-Peak")
                    [~, TimeIdxP2(1)]=min(abs(EEG.times - 150));
                    [~, TimeIdxP2(2)]=min(abs(EEG.times - 250));
                    TimeIdxP2 = TimeIdxP2(1):TimeIdxP2(2);
                    DataP2 = ConditionData.(Condition_Names(i_Cond))(ElectrodeIdx,TimeIdxP2,:);
                    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                        DataP2 = mean(DataP2, 1);
                    end
                    P2 = Peaks_Detection(mean(DataP2,3), "POS");
                    FRN = Peaks_Detection(mean(Data,3), "NEG");
                    ERP(:,i_Cond,1) = P2 - FRN;
                    SME(:,i_Cond,1) = Peaks_to_Peak_SME(Data, "NEG", DataP2, "POS");
                end
                if strcmp(ChoiceP3, "Mean")
                    ERPP3(:,i_Cond,1) = mean(mean(DataP3,3),2);
                    SMEP3(:,i_Cond,1) = Mean_SME(DataP3);
                elseif strcmp(ChoiceP3, "Peak")
                    [ERPP3(:,i_Cond,1), ~] = Peaks_Detection(mean(DataP3,3), "NEG");
                    SMEP3(:,i_Cond,1) = Peaks_SME(DataP3, "NEG");
                end
                
            end
        end
        
        % ********************************************************************************************
        % **** Prepare Output Table    ***************************************************************
        % ********************************************************************************************
        % ****** Prepare Labels ******
        % Subject is constant
        if isfield(INPUT, "Subject"); INPUT.SubjectName = INPUT.Subject; end
        Subject_L = repmat(INPUT.SubjectName, NrConditions*NrElectrodes,1 );
        SubjectP3_L = repmat(INPUT.SubjectName, NrConditions*NrElectrodesP3,1 );

        Lab_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodes,1 );
        LabP3_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodesP3,1 );

        Experimenter_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodes,1 );
        ExperimenterP3_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodesP3,1 );
        
        % Electrodes: if multiple electrodes, they simply alternate
        Electrodes_L = repmat(Electrodes', NrConditions, 1);
        ElectrodesP3_L = repmat(ElectrodesP3', NrConditions, 1);
        
        % Conditions are blocked across electrodes, but alternate across time windows
        Conditions_L = repelem(Condition_Names', NrElectrodes,1);
        Conditions_L = repmat([Conditions_L(:)], 1);
        ConditionsP3_L = repelem(Condition_Names', NrElectrodesP3,1);
        ConditionsP3_L = repmat([ConditionsP3_L(:)], 1);
        
        % Time Window are blocked across electrodes and conditions
        TimeWindow_L = repmat(num2str(TimeWindow), NrConditions*NrElectrodes, 1);
        TimeWindowP3_L = repmat(num2str(TimeWindowP3), NrConditions*NrElectrodesP3, 1);
        
        % ****** Prepare Table ******
        Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L, Electrodes_L, TimeWindow_L]),...
            num2cell([ERP(:), SME(:), EpochCount(:)]);
            cellstr([SubjectP3_L, LabP3_L, ExperimenterP3_L, ConditionsP3_L, ElectrodesP3_L, TimeWindowP3_L]),...
            num2cell([ERPP3(:), SMEP3(:), EpochCountP3(:)])];
        
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

%% house built functions
% Find Time Index (range)
    function [TimeIndexRange] = findTimeIdx(times, Start, End)
        [~, TimeIndexRange(1)]=min(abs(times - Start));
        [~, TimeIndexRange(2)]=min(abs(times - End));
        TimeIndexRange = TimeIndexRange(1):TimeIndexRange(2);
    end

% detect peaks (and latencies)
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

% SME of Peaks
    function SME = Peaks_SME(Subset, Component)
        % similiar to ERPlab toolbox
        % Initate some variables
        n_boots = 10000;
        replacement = 1;
        trials = size(Subset,3);
        electrodes = size(Subset,1);
        Peak_perTrial = NaN(electrodes,trials);
        % Bootstrap and create different ERPS, pick peaks
        for i_bs = 1:n_boots
            rng(i_bs, 'twister')
            bs_trialidx = sort(randsample(1:trials,trials,replacement));
            bs_ERP = squeeze(mean(Subset(:,:,bs_trialidx),3));
            Peak_perTrial(:,i_bs) = Peaks_Detection(bs_ERP, Component);
        end
        % use sd of this distribution for SME
        SME = std(Peak_perTrial, [], 2);
    end


% SME of PeakDifference
    function SME = Peaks_to_Peak_SME(Subset, Component, Subset2, Component2)
        % similiar to ERPlab toolbox
        % Initate some variables
        n_boots = 10000;
        replacement = 1;
        trials = size(Subset,3);
        electrodes = size(Subset,1);
        Peak_perTrial = NaN(electrodes,trials);
        % Bootstrap and create different ERPS, pick peaks
        for i_bs = 1:n_boots
            rng(i_bs, 'twister')
            bs_trialidx = sort(randsample(1:trials,trials,replacement));
            bs_ERP = squeeze(mean(Subset(:,:,bs_trialidx),3));
            bs_ERP2 = squeeze(mean(Subset2(:,:,bs_trialidx),3));
            Peak_perTrial1 = Peaks_Detection(bs_ERP, Component);
            Peak_perTrial2 = Peaks_Detection(bs_ERP2, Component2);
            Peak_perTrial(:,i_bs)=Peak_perTrial1-Peak_perTrial2;
        end
        % use sd of this distribution for SME
        SME = std(Peak_perTrial, [], 2);
    end
end

