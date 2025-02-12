%function  parfor_Stroop_LPP_Relative(IndexSubset, Parentfolder)
IndexSubset = "all"
Parentfolder = "/work/bay2875/Stroop_LPP/task-Stroop/Data/"

% List all Folders
Folders = [dir(fullfile(Parentfolder, '*20.4*'));...
    dir(fullfile(Parentfolder, '*21.5*')) ];

% Subset Folders
if strcmp(IndexSubset, "odd")
    Folders = Folders(1:2:length(Folders));
elseif strcmp(IndexSubset, "even")
    Folders = Folders(2:2:length(Folders));
end

% Get Condition Names
Condition_Names = ["Tree", "Erotic_Couple", "Erotic_Man", "Neutral_ManWoman", "Neutral_Couple", "Positive_ManWoman", "Erotic_Woman"];
NrConditions=length(Condition_Names);

% ACC Info missing 
ACC = readtable("/work/bay2875/BehaviouralData/task_Stroop_beh.csv");
ACC.ACC = str2double(ACC.ACC);
ACC = groupsummary(ACC, 'ID', 'mean', 'ACC');
ACC.mean_ACC = round(ACC.mean_ACC*100,2);

Files_Fork = [];
% Prepare Matlabpool
delete(gcp('nocreate')); % make sure that previous pooling is closed
distcomp.feature( 'LocalUseMpiexec', false );
parpool(12);

% In parallel way, for every Forking Combination extract GAV and ERP Values
parfor iFolder = 1:length(Folders)
    %fprintf('\n*Subset: %s, FolderNr: %i - Caclulating GAV. \n  ', IndexSubset, iFolder)
    %% ********************************
    % CREATE GAV (load single files)
    % *********************************
    Folder = Folders(iFolder).name;
    % List all Files of this forking path
    Files_Fork = dir( fullfile( Parentfolder, Folder,  '*mat' )  );
    Files_Fork = Files_Fork(~contains({Files_Fork.name}, "error" ));

    % Get first File to have a starting point (order, timepoints etc)
    INPUT = load(fullfile(Parentfolder, Folder, Files_Fork(1).name));
    INPUT = INPUT.Data;
    ERPTemplate = INPUT.data.For_Relative;

    % Get Relevant Infos to extract Peak
    TimeWindow_LPP = INPUT.StepHistory.TimeWindow;
    Electrode_LPP = INPUT.StepHistory.Electrodes;



    % Initiate the GAV relevant to extract the peak
    GAV_LPP =[];
    if Electrode_LPP == "Relative"
        for i_Cond = 1:NrConditions
            GAV_LPP = NaN(7, 1, length(Files_Fork));
        end
    else
        for i_Cond = 1:NrConditions
            GAV_LPP = NaN(1, size(INPUT.data.For_Relative.ERP.AV, 2), length(Files_Fork));
        end
    end


    % Go through each File, load and merge to AV
    for ifile = 1:length(Files_Fork)
        try
            Data = load(fullfile( Parentfolder, Folder,Files_Fork(ifile).name));
            Data = Data.Data;

            DataLPP = Data.data.For_Relative;
            for icond = 1:NrConditions
                % Take mean across electrodes or time window
                if Electrode_LPP == "Relative"
                    GAV_LPP(:,:,ifile) = squeeze(mean(DataLPP.ERP.AV(1:7, :), 2));
                else
                    if size(DataLPP.ERP.AV(:, :),2)<size(GAV_LPP,2)
                        GAV_LPP(:,:,ifile) = [squeeze(mean(DataLPP.ERP.AV(:, :), 1)),0];
                    elseif size(DataLPP.ERP.AV(:, :),2)>size(GAV_LPP,2)
                        GAV_LPP(:,:,ifile) = squeeze(mean(DataLPP.ERP.AV(:, 1:size(GAV_LPP,2)), 1));
                    else
                        GAV_LPP(:,:,ifile) = squeeze(mean(DataLPP.ERP.AV(:, :), 1));
                    end
                end
            end
        catch e
            fprintf('\n*ERROR Import File. Subject: %s, Folder: %i: %s \n  ', Files_Fork(ifile).name, Folder, string(e.message));
        end
    end

    %% ********************************
    % CREATE GAV AND GET TIME WINDOW BASED ON PEAKS
    % *********************************
    try
        GAV_LPP = mean(GAV_LPP, 3);


        % Find peak in Electrode or in Time Window
        if Electrode_LPP == "Relative"
            [~, idx_Electrode] =  max(GAV_LPP);
            Electrode_LPP = INPUT.data.For_Relative.ERP.chanlocs(idx_Electrode).labels;
            if strcmp(Electrode_LPP, "FZ")
                Electrode_LPP = "FZ,FCZ,F1,F2";
            elseif strcmp(Electrode_LPP, "FCZ")
                Electrode_LPP = "FZ,FCZ,CZ,FC1,FC2";
            elseif strcmp(Electrode_LPP, "CZ")
                Electrode_LPP = "CZ,FCZ,CPZ,C1,C2";
            elseif strcmp(Electrode_LPP, "CPZ")
                Electrode_LPP = "CPZ,CZ,PZ,CP1,CP2";
            elseif strcmp(Electrode_LPP, "PZ")
                Electrode_LPP = "PZ,CPZ,POZ,P1,P2";
            elseif strcmp(Electrode_LPP, "POZ")
                Electrode_LPP = "POZ,OZ,PZ,PO3,PO4";
            elseif strcmp(Electrode_LPP, "OZ")
                Electrode_LPP = "OZ,POZ,O1,O2";
            end
            TimeWindow_LPPName = TimeWindow_LPP;
            TimeWindow_LPP = strsplit(TimeWindow_LPPName, ",");
            TimeWindow_LPP = [str2num(TimeWindow_LPP(1)), str2num(TimeWindow_LPP(2))] ;

        else
            [~, Latency_LPP] = Peaks_Detection(GAV_LPP, "POS");
            Latency_LPP = INPUT.data.For_Relative.ERP.times(Latency_LPP);

            TimeWindow_LPP = round([Latency_LPP-100, Latency_LPP+100]);
            TimeWindow_LPPName=strrep(num2str(TimeWindow_LPP), "  ", ",");
        end

        Electrode_LPP = cellstr(strsplit(Electrode_LPP, ","));
        Electrode_LPPName = Electrode_LPP;

        fprintf('\n*Subset: %s, FolderNr: %i - Time Window LPP: %s.  \n ', IndexSubset, iFolder,  TimeWindow_LPPName)

    catch e
        fprintf('\n*ERROR GAV Subset: %s, Folder: %s: %s \n  ', IndexSubset, Folder, string(e.message))
        continue
    end

    %% ********************************
    % LOAD EACH FILE AND EXPORT PEAK/MEAN IN TIME WINDOW
    % *********************************

    for i_Files = 1 : length(Files_Fork)
        try
            INPUT = load(fullfile(Parentfolder, Folder,Files_Fork(i_Files).name));
            INPUT = INPUT.Data;
            OUTPUT = INPUT;

            Choice = INPUT.StepHistory.Quantification_ERP;



            % ********************************************************************************************
            % **** Set Up Some Information *************************************************************
            % ********************************************************************************************

            % Get Indices
            TimeIdx_LPP = findTimeIdx(INPUT.data.For_Relative.Times, TimeWindow_LPP(1), TimeWindow_LPP(2));
            if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                ElecIdx_LPP = 1;
                Electrode_LPP = strcat('cluster_', Electrode_LPPName);
                Electrode_LPPName = Electrode_LPP;
            else

                ElecIdx_LPP = findElectrodeIdx(INPUT.data.For_Relative.Electrodes, Electrode_LPP );
            end

            NrElectrodes = length(Electrode_LPP);

            % If Window is binned into early and later, then Adjust here
            if strcmp(Choice, "Mean_Binned")
                HalfWindow = (TimeWindow_LPP(2)-TimeWindow_LPP(1))/2;
                TimeWindow_LPP(2,1) = TimeWindow_LPP(1)+HalfWindow;
                TimeWindow_LPP(2,2) = TimeWindow_LPP(1,2);
                TimeWindow_LPP(1,2) = TimeWindow_LPP(2,1);
                HalfWindowIdx = ceil(length(TimeIdx_LPP)/2);
                NrTimeWindows = 2;
            else
                NrTimeWindows = 1;
            end


            % ********************************************************************************************
            % ****  Extract Data *************************************************************************
            % ********************************************************************************************
            ConditionData_LPP = INPUT.data.For_Relative.Data;

            % ****** Extract Amplitude, SME, Epoch Count ******
            InitSize_LPP = [NrElectrodes*NrTimeWindows,NrConditions];
            EpochCount = NaN(InitSize_LPP);
            ERP_LPP =NaN(InitSize_LPP); SME_LPP=NaN(InitSize_LPP);

            for i_Cond = 1:NrConditions
                try
                    Data_LPP = ConditionData_LPP.(Condition_Names{i_Cond});

                    % Count Epochs
                    EpochCount(:,i_Cond,:) = size(Data_LPP,3);
                    if size(Data_LPP,3) < str2double(INPUT.StepHistory.Trials_MinNumber)
                        ERP_LPP(:,i_Cond,:) = NaN;
                        SME_LPP(:,i_Cond,:) = NaN;
                    else
                        % Calculate ERP if enough epochs there
                        if strcmp(Choice, "Mean")
                            ERP_LPP(:,i_Cond,1) = mean(mean(Data_LPP(ElecIdx_LPP, TimeIdx_LPP, :),3),2);
                            SME_LPP(:,i_Cond,1) = Mean_SME(Data_LPP(ElecIdx_LPP, TimeIdx_LPP, :));

                        elseif strcmp(Choice, "Mean_Binned")
                            ERP_LPP(:,i_Cond) = [mean(mean(Data_LPP(:, 1:HalfWindowIdx,:),3),2); ...
                                mean(mean(Data_LPP(:, HalfWindowIdx+1:length(TimeIdx_LPP),:),3),2)];
                            SME_LPP(:,i_Cond) = [Mean_SME(Data_LPP(:, 1:HalfWindowIdx,:)); ...
                                Mean_SME(Data_LPP(:, HalfWindowIdx+1:length(TimeIdx_LPP),:))];
                        end

                    end
                end
            end

            % ********************************************************************************************
            % **** Prepare Output Table    ***************************************************************
            % ********************************************************************************************




            Subject_L = repmat(INPUT.Subject, NrConditions*NrElectrodes*NrTimeWindows,1 );
            Lab_L = repmat(INPUT.data.For_Relative.RecordingLab, NrConditions*NrElectrodes*NrTimeWindows,1 );
            Experimenter_L = repmat(INPUT.data.For_Relative.Experimenter, NrConditions*NrElectrodes*NrTimeWindows,1 );
            Component_L = repmat("LPP", NrConditions*NrElectrodes*NrTimeWindows,1 );
            ACC_V = ACC.mean_ACC(strcmp(ACC.ID, INPUT.Subject));
            ACC_L = repmat(ACC_V, NrConditions*NrElectrodes*NrTimeWindows,1 );
            % Electrodes: if multiple electrodes, they simply alternate ABABAB
            Electrodes_L = repmat(Electrode_LPPName', NrConditions*NrTimeWindows, 1);

            % Conditions are blocked across electrodes and timewindows AABBAABB
            Conditions_L = repelem(Condition_Names', NrElectrodes*NrTimeWindows,1);

            % Time Window are blocked across electrodes and conditions
            if NrTimeWindows == 2
                TimeWindow_L = [convertCharsToStrings(num2str(TimeWindow_LPP(1,:))); ...
                    convertCharsToStrings(num2str(TimeWindow_LPP(2,:)))];
            else
                TimeWindow_L = convertCharsToStrings(num2str(TimeWindow_LPP(1,:)));
            end
            TimeWindow_L = repmat(repelem(TimeWindow_L, NrElectrodes, 1),NrConditions,1) ;


            % ****** Prepare Table ******
            OUTPUT.data.Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L(:), Electrodes_L, TimeWindow_L]),...
                num2cell([ERP_LPP(:), SME_LPP(:), EpochCount(:)]), cellstr(Component_L), num2cell(ACC_L)];
	    OUTPUT.data = rmfield(OUTPUT.data, 'For_Relative')


            % ****** Error Management ******
        catch e
            % If error ocurrs, create ErrorMessage(concatenated for all nested
            % errors). This string is given to the OUTPUT struct.
            ErrorMessage = string(e.message);
            for ierrors = 1:length(e.stack)
                ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
            end


            fprintf('\n*Subset: %s, FolderNr: %s, Subject: %s - Error Extracting ERPs. \n ', IndexSubset, Folder, INPUT.Subject)
            OUTPUT = INPUT;
            OUTPUT.Error = ErrorMessage;
	    OUTPUT.data = rmfield(OUTPUT.data, 'For_Relative')
        end
        parfor_save(fullfile(Parentfolder, Folder, Files_Fork(i_Files).name), OUTPUT)
    end
end
%end