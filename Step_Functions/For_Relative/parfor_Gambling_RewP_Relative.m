function  parfor_Gambling_RewP_Relative(IndexSubset, Parentfolder)
% List all Folders
Folders = dir(fullfile(Parentfolder, '1.*'));

% Subset Folders
if strcmp(IndexSubset, "odd")
    Folders = Folders(1:2:length(Folders));
else
    Folders = Folders(2:2:length(Folders));
end

% Get Condition Names
Condition_Names = ["P0_Loss", "P10_Loss", "P50_Loss", "P0_Win", "P10_Win", "P50_Win" ];
NrConditions=length(Condition_Names);

Condition_NamesDiff = ["P0_Diff", "P10_Diff", "P50_Diff", "PXX_Diff"];
NrConditionsDiff = length(Condition_NamesDiff);


% Prepare Matlabpool
delete(gcp('nocreate')); % make sure that previous pooling is closed
distcomp.feature( 'LocalUseMpiexec', false );
parpool(12);

% In parallel way, for every Forking Combination extract GAV and ERP Values
parfor iFolder = 1:length(Folders)
    fprintf('\n*Subset: %s, FolderNr: %i - Caclulating GAV. \n  ', IndexSubset, iFolder)
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
    
    % Get Relevant Time Windows to extract Peak
    TimeWindow_P3 = INPUT.StepHistory.TimeWindow_P3;
    TimeWindow_RewP = INPUT.StepHistory.TimeWindow;
    
    % Nr Electrodes
    NrElectrodes_RewP = length(INPUT.data.For_Relative.Electrodes_RewP);
    NrElectrodes_P3 = length(INPUT.data.For_Relative.Electrodes_P3);
    
    % Get correct DP for each Component
    if  strcmp(INPUT.StepHistory.Resampling, "500")
        DP = 151;
        DPP3 = 226;
    elseif  strcmp(INPUT.StepHistory.Resampling, "250")
        DP = 76;
        DPP3 = 113;
    elseif  strcmp(INPUT.StepHistory.Resampling, "125")
        DP = 38;
        DPP3 = 57;
    end
    
    
    % Initiate the GAV relevant to extract the peak
    GAV = [];
    GAV_P3 = [];
    for i_Cond = 1:NrConditions
        GAV.(Condition_Names{i_Cond}) = NaN(NrElectrodes_RewP, ...
            DP,...
            length(Files_Fork));
        GAV_P3.(Condition_Names{i_Cond}) = NaN(NrElectrodes_P3, ...
            DPP3,...
            length(Files_Fork));
    end
    
    
    % Go through each File, load and merge to AV
    for ifile = 1:length(Files_Fork)
        Data = load(fullfile( Parentfolder, Folder,Files_Fork(ifile).name));
        Data = Data.Data;
        
        DataRewP = Data.data.For_Relative.Data_RewP;
        DataP3 = Data.data.For_Relative.Data_P3;
        for icond = 1:NrConditions
            % Take mean, as this was not done before
            DataRewP.(Condition_Names{icond}) = mean(DataRewP.(Condition_Names{icond}), 3);
            DataP3.(Condition_Names{icond}) = mean(DataP3.(Condition_Names{icond}), 3);
            
            % Downsample if necessary (only Biosemis)
            if length(DataRewP.(Condition_Names{icond}))>DP % downsample
                New = [];
                NewP3 = [];
                for iel = 1:size(DataRewP.(Condition_Names{icond}),1)
                    New = [New; interp1(1:length(DataRewP.(Condition_Names{icond})), DataRewP.(Condition_Names{icond})(iel,:), linspace(1, length(DataRewP.(Condition_Names{icond})), DP), 'linear')];
                end
                for iel = 1:size(DataP3.(Condition_Names{icond}),1)
                    NewP3 = [NewP3; interp1(1:length(DataP3.(Condition_Names{icond})), DataP3.(Condition_Names{icond})(iel,:), linspace(1, length(DataP3.(Condition_Names{icond})), DPP3), 'linear')];
                end
                DataRewP.(Condition_Names{icond})= New;
                DataP3.(Condition_Names{icond})= NewP3;
            end
            
            % Merge across Subjects
            GAV.(Condition_Names{icond})(:,:,ifile) = DataRewP.(Condition_Names{icond});
            GAV_P3.(Condition_Names{icond})(:,:,ifile) = DataP3.(Condition_Names{icond});
        end
    end
    
    %% ********************************
    % CREATE GAV AND GET TIME WINDOW BASED ON PEAKS
    % *********************************
    GAV = mean(cat(3,GAV.(Condition_Names{4}), ...
        GAV.(Condition_Names{5}),...
        GAV.(Condition_Names{6})),3) - ...
        mean(cat(3,GAV.(Condition_Names{1}), ...
        GAV.(Condition_Names{2}),...
        GAV.(Condition_Names{3})),3);
    % Create GAVs - for P3 Across
    GAV_P3 = mean(cat(3,GAV_P3.(Condition_Names{4}), ...
        GAV_P3.(Condition_Names{5}),...
        GAV_P3.(Condition_Names{6}),...
        GAV_P3.(Condition_Names{1}), ...
        GAV_P3.(Condition_Names{2}),...
        GAV_P3.(Condition_Names{3})),3);
    
    % Extract Peaks and Determine new Time Window
    iFF = 1;
    while length(INPUT.data.For_Relative.Times_RewP)>DP
        iFF = iFF +1;
        INPUT = load(Files_Fork(iFF).name);
        INPUT = INPUT.Data;
    end
    
    % Extract new Latencies
    Times = INPUT.data.For_Relative.Times_RewP;
    Times_P3 = INPUT.data.For_Relative.Times_P3;
    TimeIdx = findTimeIdx(Times,200, 400);
    TimeIdx_P3 = findTimeIdx(Times_P3, 250, 600);
    [~, Latency] = Peaks_Detection(mean(GAV(:,TimeIdx,:),1), "POS");
    [~, Latency_P3] = Peaks_Detection(mean(GAV_P3(:,TimeIdx_P3,:),1), "POS");
    if  contains(INPUT.StepHistory.TimeWindow, "wide")
        TimeWindow_RewP = [Times(Latency+(TimeIdx(1))) - 50, Times(Latency+(TimeIdx(1))) + 50];
        TimeWindow_P3 = [Times_P3(Latency_P3+(TimeIdx_P3(1))) - 100, Times_P3(Latency_P3+(TimeIdx_P3(1))) + 100];
    else
        TimeWindow_RewP = [Times(Latency+(TimeIdx(1))) - 25, Times(Latency+(TimeIdx(1))) + 25];
        TimeWindow_P3 = [Times_P3(Latency_P3+(TimeIdx_P3(1))) - 25, Times_P3(Latency_P3+(TimeIdx_P3(1))) + 25];
    end
    
    
    fprintf('\n*Subset: %s, FolderNr: %i - Time Window RewP: %i - %i. Time Window P3: %i - %i.  \n ', IndexSubset, iFolder, TimeWindow_RewP, TimeWindow_P3)
    
    %% ********************************
    % LOAD EACH FILE AND EXPORT PEAK/MEAN IN TIME WINDOW
    % *********************************
    
    for i_Files = 1 : length(Files_Fork)
        INPUT = load(fullfile(Parentfolder, Folder,Files_Fork(i_Files).name));
        INPUT = INPUT.Data;
        OUTPUT = INPUT;
        % Some Error Handling
        try
            Choice = INPUT.StepHistory.Quantification_ERP;
            Relative = INPUT.data.For_Relative;
            
            
            % ********************************************************************************************
            % **** Set Up Some Information *************************************************************
            % ********************************************************************************************
            
            % Get Index of Electrodes
            Electrodes_RewP = INPUT.data.For_Relative.Electrodes_RewP;
            Electrodes_P3 = INPUT.data.For_Relative.Electrodes_P3;
            
            TimeIdx_RewP = findTimeIdx(INPUT.data.For_Relative.Times_RewP,  TimeWindow_RewP(1), TimeWindow_RewP(2));
            TimeIdx_P3 = findTimeIdx(INPUT.data.For_Relative.Times_P3, TimeWindow_P3(1), TimeWindow_P3(2));
            
            NrElectrodes_RewP = length(Electrodes_RewP);
            NrElectrodes_P3 = length(Electrodes_P3);
            %             % update Label
%             if INPUT.StepHistory.Cluster_Electrodes == "cluster"
%                 NrElectrodes_RewP = 1;
%                 Electrodes_RewP = strcat('Cluster ', join(Electrodes_RewP));
%                 NrElectrodes_P3 = 1;
%                 Electrodes_P3 = strcat('Cluster ', join(Electrodes_P3));
%             end
            
            % ********************************************************************************************
            % ****  Extract Data *************************************************************************
            % ********************************************************************************************
            ConditionData_RewP = INPUT.data.For_Relative.Data_RewP;
            ConditionData_P3 = INPUT.data.For_Relative.Data_P3;
            
            % ****** Extract Amplitude, SME, Epoch Count ******
            InitSize_RewP = [NrElectrodes_RewP,NrConditions+NrConditionsDiff];
            EpochCount_RewP = NaN(InitSize_RewP);
            ERP_RewP =NaN(InitSize_RewP); SME_RewP=NaN(InitSize_RewP);
            
            InitSize_P3 = [NrElectrodes_P3,NrConditions+NrConditionsDiff];
            EpochCount_P3 = NaN(InitSize_P3);
            ERP_P3 =NaN(InitSize_P3); SME_P3=NaN(InitSize_P3);
            
            for i_Cond = 1:NrConditions
                Data_RewP = ConditionData_RewP.(Condition_Names{i_Cond});
                Data_P3 = ConditionData_P3.(Condition_Names{i_Cond});
                
                
%                 if INPUT.StepHistory.Cluster_Electrodes == "cluster"
%                     ConditionData_RewP.(Condition_Names(i_Cond)) = mean(ConditionData_RewP.(Condition_Names(i_Cond)),1);
%                     ConditionData_P3.(Condition_Names(i_Cond)) = mean(ConditionData_P3.(Condition_Names(i_Cond)),1);
%                 end
                
                % Count Epochs
                EpochCount_RewP(:,i_Cond,:) = size(Data_RewP,3);
                EpochCount_P3(:,i_Cond,:) = size(Data_P3,3);
                if size(Data_RewP,3) < str2double(INPUT.StepHistory.Trials_MinNumber)
                    ERP_RewP(:,i_Cond,:) = NaN;
                    SME_RewP(:,i_Cond,:) = NaN;
                    ERP_P3(:,i_Cond,:) = NaN;
                    SME_P3(:,i_Cond,:) = NaN;
                else
                    % Calculate ERP if enough epochs there
                    if strcmp(Choice, "Mean")
                        ERP_RewP(:,i_Cond,1) = mean(mean(Data_RewP,3),2);
                        SME_RewP(:,i_Cond,1) = Mean_SME(Data_RewP);
                        
                        ERP_P3(:,i_Cond,1) = mean(mean(Data_P3,3),2);
                        SME_P3(:,i_Cond,1) = Mean_SME(Data_P3);
                        
                    elseif strcmp(Choice, "Peak")
                        [ERP_RewP(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_RewP,3), "NEG");
                        SME_RewP(:,i_Cond,1) = Peaks_SME(Data_RewP, "NEG");
                        
                        [ERP_P3(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_P3,3), "POS");
                        SME_P3(:,i_Cond,1) = Peaks_SME(Data_P3, "POS");
                        
                    elseif strcmp(Choice, "Peak-to-Peak")
                        % Peak to Peak for RewP (P2 - FRN)
                        % Get Time Window for P2 and FRN
                        TimeIdx_P2 = findTimeIdx(INPUT.data.For_Relative.Times_RewP, 150, 250);
                        
                        % Get data in which peaks should be found
                        DataP2 = Data_RewP(:,TimeIdx_P2,:);
                        DataRewP = Data_RewP(:,TimeIdx_RewP,:);
                        
                        % Get peaks
                        P2 = Peaks_Detection(mean(DataP2,3), "POS");
                        FRN = Peaks_Detection(mean(DataRewP,3), "NEG");
                        
                        % Substract peaks
                        ERP_RewP(:,i_Cond,1) = P2 - FRN;
                        
                        % Get SME
                        SME_RewP(:,i_Cond,1) = Peaks_to_Peak_SME(DataRewP, "NEG", DataP2, "POS");
                        
                        % For P3 take only Peak
                        [ERP_P3(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_P3,3), "POS");
                        SME_P3(:,i_Cond,1) = Peaks_SME(Data_P3, "POS");
                    end
                end
                
            end
            
            % ********************************************************************************************
            % **** Loop also through Difference Waves!          ******************************************
            % ********************************************************************************************
            % Create **** Difference Waves ****   on ERPs
            for i_Diff = 1:NrConditionsDiff
                i_CondDiff = i_Diff + 6;
                if i_Diff < 4 % Diff Per Condition
                    Pos_RewP = ConditionData_RewP.(Condition_Names{i_Diff+3});
                    Neg_RewP =  ConditionData_RewP.(Condition_Names{i_Diff});
                    
                    Pos_P3 = ConditionData_P3.(Condition_Names{i_Diff+3});
                    Neg_P3 =  ConditionData_P3.(Condition_Names{i_Diff});
                    
                else % Diff across all Magnitude Conditions
                    Pos_RewP = cat(3, ConditionData_RewP.(Condition_Names{1}), ...
                        ConditionData_RewP.(Condition_Names{2}), ...
                        ConditionData_RewP.(Condition_Names{3}));
                    Neg_RewP =  cat(3, ConditionData_RewP.(Condition_Names{4}), ...
                        ConditionData_RewP.(Condition_Names{5}), ...
                        ConditionData_RewP.(Condition_Names{6}));
                    
                    Pos_P3 = cat(3, ConditionData_P3.(Condition_Names{1}), ...
                        ConditionData_P3.(Condition_Names{2}), ...
                        ConditionData_P3.(Condition_Names{3}));
                    Neg_P3 =  cat(3, ConditionData_P3.(Condition_Names{4}), ...
                        ConditionData_P3.(Condition_Names{5}), ...
                        ConditionData_P3.(Condition_Names{6}));
                end
                
                % Count Epochs
                MinEpochs = min(min(size(Pos_RewP,3), size(Neg_RewP,3)));
                EpochCount_RewP(:,i_CondDiff,:) = MinEpochs;
                EpochCount_P3(:,i_CondDiff,:) = MinEpochs;
                
                % if MinEpochs < str2double(INPUT.StepHistory.Trials_MinNumber)
                if MinEpochs < 2
                    ERP_RewP(:,i_CondDiff,:) = NaN;
                    SME_RewP(:,i_CondDiff,:) = NaN;
                    ERP_P3(:,i_CondDiff,:) = NaN;
                    SME_P3(:,i_CondDiff,:) = NaN;
                else
                    
                    % Calculate if enough epochs there
                    if strcmp(Choice, "Mean")
                        ERP_RewP(:,i_CondDiff,1) = mean(mean(Pos_RewP,3) - mean(Neg_RewP,3),2);
                        SME_RewP(:,i_CondDiff,1) = DifferenceWave_SME(Pos_RewP, Neg_RewP, "MEAN");
                        
                        ERP_P3(:,i_CondDiff,1) = mean(mean(Pos_P3,3) - mean(Neg_P3,3), 2);
                        SME_P3(:,i_CondDiff,1) = DifferenceWave_SME(Pos_P3, Neg_P3, "MEAN");
                        
                    elseif strcmp(Choice, "Peak")
                        ERP_RewP(:,i_CondDiff,1) = Peaks_Detection(mean(Pos_RewP,3) - mean(Neg_RewP,3), "POS");
                        SME_RewP(:,i_CondDiff,1) = DifferenceWave_SME(Pos_RewP, Neg_RewP, "POS");
                        
                        ERP_P3(:,i_CondDiff,1) = Peaks_Detection(mean(Pos_P3,3) - mean(Neg_P3,3), "POS");
                        SME_P3(:,i_CondDiff,1) = DifferenceWave_SME(Pos_P3, Neg_P3, "POS");
                        
                    elseif strcmp(Choice, "Peak-to-Peak")
                        % doesn't make sense in DIFF waves! NaN or just take peak?
                        ERP_RewP(:,i_CondDiff,1) = NaN;
                        SME_RewP(:,i_CondDiff,1) = NaN;
                        
                        ERP_P3(:,i_CondDiff,1) = Peaks_Detection(mean(Pos_P3,3) - mean(Neg_P3,3), "POS");
                        SME_P3(:,i_CondDiff,1) = DifferenceWave_SME(Pos_P3, Neg_P3, "POS");
                    end
                end
            end
            
            % ********************************************************************************************
            % **** Prepare Output Table    ***************************************************************
            % ********************************************************************************************
            
            
            % Prepare Final Export with all Values
            % ****** Prepare Labels ******
            % important P3 and RewP do not always have same number of electrodes!
            
            % Subject, ComponentName, Lab, Experimenter is constant AAA
            NrConditionsL = NrConditions + NrConditionsDiff;
            
            Subject_RewP_L = repmat(INPUT.Subject, NrConditionsL*NrElectrodes_RewP,1 );
            Lab_RewP_L = repmat(INPUT.data.For_Relative.RecordingLab, NrConditionsL*NrElectrodes_RewP,1 );
            Experimenter_RewP_L = repmat(INPUT.data.For_Relative.Experimenter, NrConditionsL*NrElectrodes_RewP,1 );
            Component_RewP_L = repmat("RewP", NrConditionsL*NrElectrodes_RewP,1 );
            
            Subject_P3_L = repmat(INPUT.Subject, NrConditionsL*NrElectrodes_P3,1 );
            Lab_P3_L = repmat(INPUT.data.For_Relative.RecordingLab, NrConditionsL*NrElectrodes_P3,1 );
            Experimenter_P3_L = repmat(INPUT.data.For_Relative.Experimenter, NrConditionsL*NrElectrodes_P3,1 );
            Component_P3_L = repmat("P3", NrConditionsL*NrElectrodes_P3,1 );
            
            % Electrodes: if multiple electrodes, they simply alternate ABABAB
            Electrodes_RewP_L = repmat(Electrodes_RewP', NrConditionsL, 1);
            Electrodes_P3_L = repmat(Electrodes_P3', NrConditionsL, 1);
            
            
            % Conditions are blocked across electrodes, but alternate across
            % time windows AABBAABB
            Condition_NamesL = [Condition_Names, Condition_NamesDiff];
            Conditions_RewP_L = repelem(Condition_NamesL', NrElectrodes_RewP,1);
            Conditions_P3_L = repelem(Condition_NamesL', NrElectrodes_P3,1);
            
            
            % Time Window are blocked across electrodes and conditions AAAAABBBB
            TimeWindow_RewP_L = repmat(num2str(TimeWindow_RewP), NrConditionsL*NrElectrodes_RewP, 1);
            TimeWindow_P3_L = repmat(num2str(TimeWindow_P3), NrConditionsL*NrElectrodes_P3, 1);
            
            % ****** Prepare Table ******
            Export = [ [cellstr([Subject_RewP_L, Lab_RewP_L, Experimenter_RewP_L, Conditions_RewP_L, Electrodes_RewP_L, TimeWindow_RewP_L]),...
                num2cell([ERP_RewP(:), SME_RewP(:), EpochCount_RewP(:)]), cellstr(Component_RewP_L)]; ...
                [cellstr([Subject_P3_L, Lab_P3_L, Experimenter_P3_L, Conditions_P3_L, Electrodes_P3_L, TimeWindow_P3_L]),...
                num2cell([ERP_P3(:), SME_P3(:), EpochCount_P3(:)]), cellstr(Component_P3_L)]];
            
            if isfield(INPUT.data, 'Export')
                OUTPUT.data.Export = [INPUT.data.Export; Export];
            else
                OUTPUT.data.Export = Export;
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
            fprintf('\n*Subset: %s, FolderNr: %i, Subject: %s - Error Extracting ERPs. \n ', IndexSubset, iFolder, INPUT.Subject)
            OUTPUT = INPUT;
        end
        parfor_save(fullfile(Parentfolder, Folder, Files_Fork(i_Files).name), OUTPUT)
    end
end
end