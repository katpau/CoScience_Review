function  OUTPUT = Quantification_ERP(INPUT, Choice)
% This script does the following:
% Based on information of previous steps, and depending on the forking
% choice, ERPs are quantified based on Mean or ERPS.
% Script also extracts Measurement error and reshapes Output to be easily
% merged into a R-readable Dataframe for further analysis.

% To be added: LRP jack knife procedure
% To be added: MVPA
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
    Event_Window = [-0.500 0.800];
    
    % Condition Names and Triggers depend on analysisname
   if INPUT.AnalysisName == "Flanker_MVPA"
    Condition_Triggers = [ 106, 116, 126,  136, 107, 117, 127, 137; ...
         108, 118, 128, 138, 109, 119, 129, 139  ]; %Responses Experimenter Absent
    Condition_Names = ["Flanker_Correct", "Flanker_Error"];

    elseif INPUT.AnalysisName == "GoNoGo_MVPA"
        Condition_Triggers = [211; 220 ]; %Responses Speed/Acc emphasis
        Condition_Names = ["GoNoGo_Correct", "GoNoGo_Error"];
   end
    NrConditions = length(Condition_Names);
    
    
    
    for i_Cond = 1:NrConditions
        try
        % * Epoch Data around predefined window and save each
        Interim = pop_epoch( EEG_for_ERP, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
        ForRelative = pop_epoch( EEG, num2cell(Condition_Triggers(i_Cond,:)), Event_Window, 'epochinfo', 'yes');
        ConditionData.(Condition_Names(i_Cond)) = ForRelative.data;
        % Calculate ERP
        ERP_toExport.(Condition_Names(i_Cond)) = mean(Interim.data,3);
        end
    end
    ERP_toExport.times = Interim.times;
    ERP_toExport.chanlocs = Interim.chanlocs;
    
    % update Conditions based on where Epochs were found
    Condition_Names = fieldnames(ConditionData);
    NrConditions = length(Condition_Names);
    
    
    % ********************************************************************************************
    % **** Prepare Indexes of  Data to be exported ***********************************************
    % ********************************************************************************************
    % **** Get Info on Electrodes ******
    Electrodes = upper(strsplit(INPUT.StepHistory.Electrodes , ","));
    Electrodes = strrep(Electrodes, " ", "");
    NrElectrodes = length(Electrodes);
    
    % Get Index on Electrodes  ******
    ElectrodeIdx = zeros(1, length(Electrodes));
    for iel = 1:length(Electrodes)
        [~, ElectrodeIdx(iel)] = ismember(Electrodes(iel), upper({EEG.chanlocs.labels})); % Do it in this loop to maintain matching/order of Name and Index!
    end
    
    % **** Get Info on Electrodes other Component ******
    ElectrodesPE = upper(strsplit(INPUT.StepHistory.Electrodes_PE , ","));
    ElectrodesPE = strrep(ElectrodesPE, " ", "");
    NrElectrodesPE = length(ElectrodesPE);
    
    % Get Index on Electrodes other Component ******
    ElectrodeIdxPE = zeros(1, length(ElectrodesPE));
    for iel = 1:length(ElectrodesPE)
        [~, ElectrodeIdxPE(iel)] = ismember(ElectrodesPE(iel), {EEG.chanlocs.labels}); % Do it in this loop to maintain matching/order of Name and Index!
    end
    
    % Update Nr on Electrodes for Final OutputTable
       NrElectrodes = 1;
       NrElectrodesPE = 1;
       Electrodes = strcat('Cluster ', join(Electrodes));
       ElectrodesPE = strcat('Cluster ', join(ElectrodesPE));

    
    
    % ****** Get Info on TimeWindow ******
    TimeWindow = INPUT.StepHistory.TimeWindow;
    TimeWindowPE = INPUT.StepHistory.TimeWindow_PE;
    if ~contains(TimeWindow, "Relative")
        TimeWindow = str2double(strsplit(TimeWindow, ","));
        TimeWindowPE = str2double(strsplit(TimeWindowPE, ","));
        
    elseif strcmp(TimeWindow, "Relative_Subject")
        % Calculate Grand Average ERP
        ERP = mean(EEG.data(:,:,:),3);
        
        % find subset to find Peak for ERN
        TimeIdx = findTimeIdx(EEG.times, 0, 150);
        
        % find subset to find Peak for PE
        TimeIdxPE = findTimeIdx(EEG.times, 150, 500);
        
        % Find Peak in this Subset
        [~, Latency] = Peaks_Detection(mean(ERP(ElectrodeIdx,TimeIdx),1), "NEG");
        [~, LatencyPE] = Peaks_Detection(mean(ERP(ElectrodeIdxPE,TimeIdxPE),1), "POS");
        
        % Define Time Window Based on this
        TimeWindow = [EEG.times(Latency+(TimeIdx(1))) - 25, EEG.times(Latency+(TimeIdx(1))) + 25];
        TimeWindowPE = [EEG.times(LatencyPE+(TimeIdxPE(1))) - 50, EEG.times(LatencyPE+(TimeIdxPE(1))) + 50];
        
        
    elseif contains(TimeWindow, "Relative_Group")
        % Time window needs to be longer since peak could be at edge
        TimeWindow = [-25 175];
        TimeWindowPE = [125 525];
    end
    
    % Get Index of TimeWindow ERN
    TimeIdx = findTimeIdx(EEG.times, TimeWindow(1), TimeWindow(2));
    % Get Index of TimeWindow PE
    TimeIdxPE = findTimeIdx(EEG.times, TimeWindowPE(1), TimeWindowPE(2));
    
    
    
    
    
    % ********************************************************************************************
    % **** Loop Through each Condition and extract Data ******************************************
    % ********************************************************************************************
    % if depending on group, crop data and save data for now
    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        Export.Data = EEG.data(ElectrodeIdx,TimeIdx,:);
        Export.Times = EEG.times(TimeIdx);
        Export.Electrodes = {EEG.chanlocs(ElectrodeIdx).labels};
        
        Export.DataPE = EEG.data(ElectrodeIdxPE,TimeIdxPE,:);
        Export.TimesPE = EEG.times(TimeIdxPE);
        Export.ElectrodesPE = {EEG.chanlocs(ElectrodeIdxPE).labels};
        
    else
        % if not dependent on group,
        % ****** Extract Amplitude, SME, Epoch Count ******
        InitSize = [NrElectrodes,NrConditions];
        EpochCount = NaN(InitSize);
        ERP =NaN(InitSize); SME=NaN(InitSize);
        InitSizePE = [NrElectrodesPE,NrConditions];
        ERPPE =NaN(InitSizePE); ERPPE=NaN(InitSizePE);
        EpochCountPE = NaN(InitSizePE);
        Trials = NaN(NrConditions);
        
        for i_Cond = 1:NrConditions
            % Select relevant Data
            Data = ConditionData.(Condition_Names{i_Cond})(ElectrodeIdx,TimeIdx,:);
            DataPE = ConditionData.(Condition_Names{i_Cond})(ElectrodeIdxPE,TimeIdxPE,:);
            
            % average across Electrodes
                Data = mean(Data, 1); % first dimensions are Electrodes
                DataPE = mean(DataPE, 1); % first dimensions are Electrodes
            
            % Count Epochs
            EpochCount(:,i_Cond,:) = size(Data,3);
            EpochCountPE(:,i_Cond,:) = size(Data,3);
            if size(Data,3) < str2double(INPUT.StepHistory.Trials_MinNumber)
                ERP(:,i_Cond,:) = NaN;
                SME(:,i_Cond,:) = NaN;
                ERPPE(:,i_Cond,:) = NaN;
                ERPPE(:,i_Cond,:) = NaN;
                
            else
                % Calculate Mean if enough epochs there
                if strcmp(Choice, "Mean")
                    ERP(:,i_Cond,1) = mean(mean(Data,3),2);
                    SME(:,i_Cond,1) = Mean_SME(Data);
                    
                    ERPPE(:,i_Cond,1) = mean(mean(DataPE,3),2);
                    ERPPE(:,i_Cond,1) = Mean_SME(DataPE);
                elseif strcmp(Choice, "Peak")
                    [ERP(:,i_Cond,1), ~] = Peaks_Detection(mean(Data,3), "NEG");
                    SME(:,i_Cond,1) = Peaks_SME(Data, "NEG");
                    
                    [ERPPE(:,i_Cond,1), ~] = Peaks_Detection(mean(DataPE,3), "POS");
                    ERPPE(:,i_Cond,1) = Peaks_SME(DataPE, "POS");
                end
                
                
            end
        end
        
        % ********************************************************************************************
        % **** Prepare Output Table    ***************************************************************
        % ********************************************************************************************
        % ****** Prepare Labels ******
        % Subject is constant
        Subject_L = repmat(INPUT.Subject, NrConditions*NrElectrodes,1 );
        SubjectPE_L = repmat(INPUT.Subject, NrConditions*NrElectrodesPE,1 );

        Lab_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodes,1 );
        LabPE_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodesPE,1 );

        Experimenter_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodes,1 );
        ExperimenterPE_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodesPE,1 );

        
        % Electrodes: if multiple electrodes, they simply alternate
        Electrodes_L = repmat(Electrodes', NrConditions, 1);
        ElectrodesPE_L = repmat(ElectrodesPE', NrConditions, 1);
        
        % Conditions are blocked across electrodes, but alternate across time windows
        Conditions_L = repelem(Condition_Names', NrElectrodes,1);
        Conditions_L = repmat([Conditions_L(:)], 1);
        ConditionsPE_L = repelem(Condition_Names', NrElectrodesPE,1);
        ConditionsPE_L = repmat([ConditionsPE_L(:)], 1);
        
        % Time Window are blocked across electrodes and conditions
        TimeWindow_L = repmat(num2str(TimeWindow), NrConditions*NrElectrodes, 1);
        TimeWindowPE_L = repmat(num2str(TimeWindowPE), NrConditions*NrElectrodesPE, 1);
        
        % ****** Prepare Table ******
        Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L, Electrodes_L, TimeWindow_L]),...
            num2cell([ERP(:), SME(:), EpochCount(:)]);
            cellstr([SubjectPE_L,  LabPE_L, ExperimenterPE_L, ConditionsPE_L, ElectrodesPE_L, TimeWindowPE_L]),...
            num2cell([ERPPE(:), ERPPE(:), EpochCountPE(:)])];
         
    end
    
        % ********************************************************************************************
        % **** Prepare LRP jack knife   **************************************************************
        % ********************************************************************************************

        % ********************************************************************************************
        % **** Prepare MVPA            ***************************************************************
        % ********************************************************************************************
        % Remove interpolated channels => INPUT.AC.EEG.Bad_Channel_Names
        
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
