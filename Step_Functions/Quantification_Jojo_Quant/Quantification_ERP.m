function  OUTPUT = Quantification_ERP(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by:

% This script does the following:
% Based on information of previous steps, and depending on the forking
% choice, ERPs are quantified based on Mean or ERPS.
% Script also extracts Measurement error and reshapes Output to be easily
% merged into a R-readable Dataframe for further analysis.


% Note: This script exports single trial data.


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


    % Info on Baseline FMT
    BLTimeWindow_FMT = str2double(strsplit(INPUT.StepHistory.Baseline_FMT, " "));



    % ********************************************************************************************
    % **** Prepare Relative Data   ***************************************************************
    % ********************************************************************************************
    % if Time window is Relative to Peak across all Subjects or within a
    % subject, an ERP Diff needs to be created across all Conditions.
    if contains(INPUT.StepHistory.TimeWindow, "Relative")
        EEG_for_Relative = EEG;

        if contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
            EEG_for_Relative =  pop_resample(EEG_for_Relative, fix(EEG_for_Relative.srate/100)*100);
        end
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
    try
        % * Epoch Data around predefined window and save each
        EEGData = EEG;
        ConditionData_FRN  =EEGData.data(:, TimeIdx_FRN,:);
        if INPUT.StepHistory.Cluster_Electrodes == "cluster"
            ConditionData_FRN= mean(ConditionData_FRN,1);
        end

        if contains(INPUT.StepHistory.TimeWindow, "Relative")
            FMT = 10*log10(extract_power_allChans(EEGData, [], [4 8], BLTimeWindow_FMT));
            ConditionData_FMT = FMT(:, TimeIdx_FMT,:);
            if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                ConditionData_FMT = mean(ConditionData_FMT,1);
            end
        end
    end


    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        NrElectrodes = 1;
        Electrodes = strcat('Cluster ', join(Electrodes));
    end


    % Get Condition Data from EEGtrial structure

    if contains(INPUT.AnalysisName, 'Gambling')
        Events = EEG.epoch([EEG.epoch.eventEvent] == "Feedback");   %  doesnt work if an Event is empty thats why the weird loop above?

        BehavHeader = ["Subject", "Lab", "Experimenter", "Task", "Trial",  "RT", "Response", "Feedback", "Magnitude"];
        Single_TrialData_Behav =    [cellstr(repmat(INPUT.Subject, size(Events,1), 1)), ...
            cellstr(repmat(EEG.Info_Lab.RecordingLab, size(Events,1), 1)), ...
            cellstr(repmat(EEG.Info_Lab.Experimenter, size(Events,1), 1)), ...
            cellstr(repmat('Gambling', size(Events,1), 1)), ...
            num2cell([[Events.eventTrial]', [Events.eventRT]', [Events.eventResponse]']), ...
            [Events.eventFeedback]', num2cell([Events.eventMoneyMagnitude]')];

    else

        Events = EEG.event([EEG.event.Event]== "Offer");   %  doesnt work if an Event is empty thats why the weird loop above?

        BehavHeader = ["Subject", "Lab", "Experimenter", "Task", "Trial",  "RT", "Response", "OfferSelf", "OfferOther"];
        Single_TrialData_Behav =    [cellstr(repmat(INPUT.Subject, size(Events,1), 1)), ...
            cellstr(repmat(EEG.Info_Lab.RecordingLab, size(Events,1), 1)), ...
            cellstr(repmat(EEG.Info_Lab.Experimenter, size(Events,1), 1)), ...
            cellstr(repmat('UltimatumGame', size(Events,1), 1)), ...
            num2cell([[Events.Trial]', [Events.RT]']), [Events.Response]', ...
            num2cell([[Events.OfferSelf]', 10-[Events.OfferSelf]'])];

    end

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
        For_Relative.Events = Single_TrialData_Behav;
        For_Relative.BehavHeader = BehavHeader;

    else
        % ****** Extract Amplitude, SME, Epoch Count ******
        InitSize_FRN = [NrElectrodes_FRN*EEG.trials,1];
        ERP_FRN =NaN(InitSize_FRN);

        Data_FRN = ConditionData_FRN;

        % Calculate ERP if enough epochs there
        if strcmp(Choice ,  "Mean")
            ERP_FRN = mean(Data_FRN,2);
        elseif strcmp(Choice ,  "Peak")
            ERP_FRN = Peaks_Detection(Data_FRN, "NEG");
        elseif strcmp(Choice ,  "Peak2Peak")
            TimesData = EEGData.times(TimeIdx_FRN);
            TimeindexP2 = findTimeIdx(TimesData, 150, 250);
            TimeindexFN = findTimeIdx(TimesData, 200, 400);
            DataP2 = Data_FRN(:,TimeindexP2,:);
            DataFN = Data_FRN(:,TimeindexFN,:);
            [~, P2] = Peaks_Detection(mean(mean(DataP2,3),1), "POS");
            [~, FN] = Peaks_Detection(mean(mean(DataFN,3),1), "NEG");
            ERP_FRN = DataP2(:,P2,:) - DataFN(:,FN,:);
        end
    end




    % ********************************************************************************************
    % **** Extract Data     FMT                         *******************************************
    % ********************************************************************************************
    if strcmp(INPUT.StepHistory.TimeWindow, "Relative_Subject")

        ERP_FMT = mean(ConditionData_FMT,2);


    end

    % ********************************************************************************************
    % **** Prepare Output Table    ***************************************************************
    % ********************************************************************************************

    if ~contains(INPUT.StepHistory.TimeWindow, "Relative_Group")
        % Prepare Final Export with all Values
        % ****** Prepare Labels ******
        % Electrodes: if multiple electrodes, they simply alternate ABABAB
        Electrodes_FRN_L = repmat(Electrodes_FRN', EEG.trials, 1);

        % Time Window are blocked across electrodes and conditions AAAAABBBB
        TimeWindow_FRN_L = repmat(num2str(TimeWindow_FRN), EEG.trials*NrElectrodes_FRN, 1);

        EpochCount_FRN = repmat(EEG.trials, size(Events,1)*NrElectrodes_FRN, 1);
        Component_FRN_L = repmat('FRN', size(Events,1)*NrElectrodes_FRN, 1);

        ConditionLabels = repelem(Single_TrialData_Behav, NrElectrodes_FRN, 1);
        Export =  [ConditionLabels, cellstr([Electrodes_FRN_L, TimeWindow_FRN_L]),...
            num2cell([ERP_FRN(:), EpochCount_FRN]), cellstr(Component_FRN_L)];


        % if Relative per Subject, add FMT
        if strcmp(INPUT.StepHistory.TimeWindow, "Relative_Subject")
            TimeWindow_FMT_L = repmat(num2str(TimeWindow_FMT), EEG.trials*NrElectrodes_FRN, 1);
            Component_FMT_L = repmat('FMT', size(Events,1)*NrElectrodes_FRN, 1);

            ExportFMT =  [ConditionLabels, cellstr([Electrodes_FRN_L, TimeWindow_FMT_L]),...
                num2cell([ERP_FMT(:), EpochCount_FRN]), cellstr(Component_FMT_L)];

            Export = [Export; ExportFMT];
        end

        % ****** Prepare Table ******
        Export = [[BehavHeader, 'Electrodes', 'TimeWindow', 'EEG_Signal', 'EpochsTotal', 'Component' ]; Export];
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
