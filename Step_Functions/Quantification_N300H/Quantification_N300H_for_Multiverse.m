function  OUTPUT = Quantification_N300H(INPUT, Choice)
% Last Checked by
% Planned Reviewer:
% Reviewed by:

% This script does the following:
% Based on information of previous steps, and depending on the forking
% choice, N300H is calculated and Exported.
% Script also reshapes Output to be easily
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
StepName = "Quantification_N300H";
Choices = ["Mean", "Bins", "Maximum"];
Conditional = ["NaN", "NaN", "NaN"];
SaveInterim = logical([1]);
Order = [24];



%%%%%%%%%%%%%%%% Updating the SubjectStructure. No changes should be made here.
INPUT.StepHistory.Quantification_ERP = Choice;
OUTPUT = INPUT;
OUTPUT.data = [];

% Some Error Handling
try
    %%%%%%%%%%%%%%%% Routine for the analysis of this step

    EEG = INPUT.data.EEG;
    ECG = INPUT.ECG;

    % Get Info on ** Electrodes **
    Electrodes = strrep(upper(strsplit(INPUT.StepHistory.Electrodes , ",")), " ", "");
    NrElectrodes = length(Electrodes);
    ElectrodeIdx = findElectrodeIdx(EEG.chanlocs, Electrodes);

    % Discard non-relevant EEG electrodes
    EEG = pop_select(EEG, 'channel', ElectrodeIdx);



    % Check if electrodes are averaged before extracting the N300H,
    % i.e. before calculating intra-individual correlations:
    if strcmp(INPUT.StepHistory.Cluster_Electrodes,"cluster")

        % Calculate average of electrodecluster and save it as channel 1 in
        % EEG.data matrix
        EEG.data(1,:,:) = squeeze(mean(EEG.data,1));
        % change value of relevant channel containing the average of the
        % elctrode cluster
        ElectrodeIdx = 1;
        NrElectrodes = 1;
        Electrodes = append('cluster: ', join(Electrodes));
    end

    %% Calculate CECTs


    % ****** Get Info on TimeWindow of EEG and IBI data ******
    % Get choices for the time window of interest in which the N300H is defined

    % For the IBI and EEG data

    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group") || ...
            contains(INPUT.StepHistory.ECG_TimeWindow, "Relative_Group")
        For_Relative.RecordingLab = EEG.Info_Lab.RecordingLab;
        For_Relative.Experimenter = EEG.Info_Lab.Experimenter;
        For_Relative.DataEEG = EEG;
        For_Relative.DataECG = ECG;
        For_Relative.Electrodes = Electrodes;
    else

        % Define settings for CECT analysis
        cfg.segsizeIBI = [-0.5, 5];
        cfg.segsizeEEG = [-0.2, 2];
        cfg.ibibins = [0, 5];
        cfg.eegbins = [0, 1];
        cfg.srateEEG = EEG.srate;
        cfg.srateIBI = ECG.srate;
        cfg.ibibinsize = 500;
        cfg.eegbinsize = 10;

        % ***********************************************************************************
        % calculate CECTs for each condition ************************************************
        % ***********************************************************************************

        % prepare markers and triggers
        Condition_Names = {'loss', 'win' };
        Condition_Triggers = {'100' '110' '150';...
            '101'  '111' '151'}';
        NrConditions = length(Condition_Names);

        for i = 1:size(Condition_Triggers,2)

            % find index of relevant condition triggers within the EEG.event structure
            idx = []; idx=find(contains({EEG.event.type}, Condition_Triggers(:,i)));

            % get number of epochs
            Epochs(i,1) = length(idx);

            % calculate CECTS via CECT.m and save results for each condition in
            % a "cect results" structure
            cect.results.(Condition_Names{i}) = ...
                CECT(EEG.data(:,:,idx), squeeze(ECG.data(2,:,idx)), cfg);

        end
        % save the employed CECT settings into the cect results structure
        cect.settings = cfg;


        % IBI
        IBI_window = [str2num(INPUT.StepHistory.ECG_TimeWindow)];
        % Translate given time windows from ms into CECT bins
        % IBI_window as well as the ibi- and eegbin size are given in ms
        BinsIBI = IBI_window/cfg.ibibinsize; BinsIBI(1) = BinsIBI(1)+1;
        % EEG
        EEG_window = [str2num(INPUT.StepHistory.TimeWindow)];
        % Translate given time windows from ms into CECT bins
        % IBI_window as well as the ibi- and eegbin size are given in ms
        BinsEEG = EEG_window/cfg.eegbinsize; BinsEEG(1) = BinsEEG(1)+1;



        % ********************************************************************************************
        % **** Extract N300H Data and prepare Output Table    ****************************************
        % ********************************************************************************************

        % ****** Get Info on N300H extraction method of EEG and IBI data ******
        % Get choices for the time window of interest in which the N300H is defined

        % if any Time window is dependent on group, do not continue but save
        % relevant data


        % Extract N300H
        N300H = []; % electrodes x conditions x bins
        for c = 1:NrConditions

            % initialize CECT data matrix
            tmp_data = NaN(1,BinsEEG(2)-BinsEEG(1)+1,BinsIBI(2)-BinsIBI(1)+1);
            tmp_data = (cect.results. ...
                (Condition_Names{1,c})...
                (:, BinsEEG(1):BinsEEG(2), BinsIBI(1):BinsIBI(2)));

            % Fisher-Z transform CECTs
            tmp_data = atanh(tmp_data);

            % Calculate mean across bins of interest
            if  strcmpi(Choice,"Mean")
                N300H(:,c,:) = mean(tmp_data,[2,3]);

                % Export each bin
            elseif strcmp(Choice, "Bins")
                N300H(:,c,:) = squeeze(mean(tmp_data,3));

                % detect maximal N300H within bins of interest
            elseif strcmp(Choice, "Maximum")
                % detecting the maximal N300H [negative correlation, therfore
                % min()]
                N300H(:,c,:) = min(tmp_data,[],[2,3]);

            end
        end
    

    % Update Nr on Electrodes for Final OutputTable if Clustered after N300H
    if INPUT.StepHistory.Cluster_Electrodes == "no_cluster_butAV"
        NrElectrodes = 1;
        Electrodes = append('AV_of: ', join(Electrodes));
        N300H = mean(N300H,1);
    end

    % ****** Export N300H ******
    if Choice == "Bins"
        NrBins = size(N300H,3);
        Bin_L = num2cell(1:NrBins)';
    else
        NrBins = 1;
        Bin_L = "one";
    end

    InitSize = [NrElectrodes,NrConditions, NrBins];
    EpochCount = NaN(InitSize);
    EpochCount =  repmat(Epochs', NrElectrodes, NrBins);
    end
    % ********************************************************************************************
    % **** Prepare Output Table    ***************************************************************
    % ********************************************************************************************
    

    if contains(INPUT.StepHistory.TimeWindow, "Relative_Group") || ...
            contains(INPUT.StepHistory.ECG_TimeWindow, "Relative_Group")
        % Add Relative Data and Relative Info
        OUTPUT.data.For_Relative = For_Relative;
        OUTPUT = rmfield(OUTPUT,'ECG');
    else
        % Prepare Final Export with all Values
        % ****** Prepare Labels ******
        % Subject, ComponentName, Lab, Experimenter, Scoring is constant AAA
        Subject_L = repmat(INPUT.Subject, NrConditions*NrElectrodes*NrBins,1 );
        Lab_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrElectrodes*NrBins,1 );
        Experimenter_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrElectrodes*NrBins,1 );
        Component_L = repmat("N300H", NrConditions*NrElectrodes*NrBins,1 );
        Scoring_L = repmat(Choice, NrConditions*NrElectrodes*NrBins,1 );
        TimeWindow_L = repmat(num2str(EEG_window), NrConditions*NrElectrodes*NrBins, 1);
        TimeWindowECG_L = repmat(num2str(IBI_window), NrConditions*NrElectrodes*NrBins, 1);


        % Electrodes: if multiple electrodes, they simply alternate ABABAB
        Electrodes_L = repmat(Electrodes', NrConditions*NrBins, 1);

        % Conditions are blocked across electrodes, but alternate across
        % time windows AABBAABB
        Conditions_L = repelem(Condition_Names', NrElectrodes,1);
        Conditions_L = repmat(Conditions_L(:), NrBins,1);

        % Bins are blocked across electrodes and conditions AAAAABBBB
        Bin_L = repelem(Bin_L, NrConditions*NrElectrodes, 1);

        %******************************************************************
        % check if number of positive and negative feedback segments
        % drop below the minimum number of segments. If segment number is
        % smaller -> mark condition as outlier by setting it to NaN
        %******************************************************************
        if sum(EpochCount(contains(Conditions_L, 'loss'))) < ...
                str2num(INPUT.StepHistory.Trials_MinNumber)

            N300H(contains(Conditions_L, 'loss')) = NaN;
        else
        end

        if  sum(EpochCount(contains(Conditions_L, 'win'))) < ...
                str2num(INPUT.StepHistory.Trials_MinNumber)

            N300H(contains(Conditions_L, 'win')) = NaN;
        else
        end

        % ****** Prepare Table ******
        if Choice ~= "Bins"
            NrBins = size(N300H,3);

            OUTPUT.data.Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L, ...
                Electrodes_L, TimeWindow_L, TimeWindowECG_L, Scoring_L]),...
                num2cell([N300H(:),  EpochCount(:)]), cellstr(Bin_L), cellstr(Component_L)];
        else

            OUTPUT.data.Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L, ...
                Electrodes_L, TimeWindow_L, TimeWindowECG_L, Scoring_L]),...
                num2cell([N300H(:),  EpochCount(:)]), Bin_L(:), cellstr(Component_L)];
        end

        % save cect analsis for all conditions and electrodes
        % (for plotting the temporal and spatial dynamics of the N300H)
        OUTPUT.data.cect = cect;
        OUTPUT = rmfield(OUTPUT,'ECG');
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