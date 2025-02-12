function  parfor_GoNoGo_Conflict_Relative(IndexSubset, Parentfolder)
% List all Folders
Folders = [dir(fullfile(Parentfolder, '*21.5*'));...
    dir(fullfile(Parentfolder, '*21.6*')) ];

% Subset Folders
if strcmp(IndexSubset, "odd")
    Folders = Folders(1:2:length(Folders));
else
    Folders = Folders(2:2:length(Folders));
end

% Get Condition Names
Condition_Names = ["Go_Relaxed",   "Go_Speed",   "NoGo_Relaxed",       "NoGo_Speed"];
NrConditions=length(Condition_Names);

Condition_NamesDiff = ["Diff_Relaxed", "Diff_Speed"];
NrConditionsDiff = length(Condition_NamesDiff);

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
    
    % Get Relevant Time Windows to extract Peak
    TimeWindow_N2 = INPUT.StepHistory.TimeWindow;
    
    % Nr Electrodes
    NrElectrodes_N2 = length(INPUT.data.For_Relative.ElectrodesN2);
    
    % Get correct DP for each Component
    if  strcmp(INPUT.StepHistory.Resampling, "500")
        DP = 176;
    elseif strcmp(INPUT.StepHistory.Resampling, "250")
        DP = 88;
    elseif strcmp(INPUT.StepHistory.Resampling, "125")
        DP = 45;
    end
    
    
    % Initiate the GAV relevant to extract the peak
    GAV_N2 =[];
    for i_Cond = 1:NrConditions
        GAV_N2.(Condition_Names{i_Cond}) = NaN(NrElectrodes_N2, ...
            DP,...
            length(Files_Fork));
    end
    
    
    % Go through each File, load and merge to AV
    for ifile = 1:length(Files_Fork)
        try
            Data = load(fullfile( Parentfolder, Folder,Files_Fork(ifile).name));
            Data = Data.Data;
            
            DataN2 = Data.data.For_Relative.DataN2;
            for icond = 1:NrConditions
                % Take mean, as this was not done before
                DataN2.(Condition_Names{icond}) = mean(DataN2.(Condition_Names{icond}), 3);
                
                % Downsample if necessary (only Biosemis)
                if length(DataN2.(Condition_Names{icond}))>DP % downsample
                    NewN2 = [];
                    for iel = 1:size(DataN2.(Condition_Names{icond}),1)
                        NewN2 = [NewN2; interp1(1:length(DataN2.(Condition_Names{icond})), DataN2.(Condition_Names{icond})(iel,:), linspace(1, length(DataN2.(Condition_Names{icond})), DP), 'linear')];
                    end
                    DataN2.(Condition_Names{icond})= NewN2;
                end
                
                % Merge across Subjects
                GAV_N2.(Condition_Names{icond})(:,:,ifile) = DataN2.(Condition_Names{icond});
            end
        catch e
            fprintf('\n*ERROR Import File. Subject: %s, Folder: %i: %s \n  ', Files_Fork(ifile).name, Folder, string(e.message));
        end
    end
    
    %% ********************************
    % CREATE GAV AND GET TIME WINDOW BASED ON PEAKS
    % *********************************
    try
        GAV_N2 = mean(cat(3,GAV_N2.(Condition_Names{4}), ...
            GAV_N2.(Condition_Names{1}), ...
            GAV_N2.(Condition_Names{2}),...
            GAV_N2.(Condition_Names{3})),3);
        
        % Extract Peaks and Determine new Time Window
        iFF = 0;
        while length(INPUT.data.For_Relative.TimesN2)>DP
            iFF = iFF +1;
            INPUT = load(fullfile(Parentfolder, Folder, Files_Fork(iFF).name));
            INPUT = INPUT.Data;
        end
        
        % Extract new Latencies
        Times_N2 = INPUT.data.For_Relative.TimesN2;
        TimeIdx_N2 = findTimeIdx(Times_N2, 150, 400);
        [~, Latency_N2] = Peaks_Detection(mean(GAV_N2(:,TimeIdx_N2,:),1), "NEG");
        TimeWindow_N2 = Times_N2(TimeIdx_N2); TimeWindow_N2 = TimeWindow_N2(Latency_N2);
        
        if  contains(INPUT.StepHistory.TimeWindow, "wide")
            TimeWindow_N2 = [TimeWindow_N2 - 50, TimeWindow_N2 + 50];
        else
            TimeWindow_N2 = [TimeWindow_N2 - 25, TimeWindow_N2 + 25];
        end
        
        fprintf('\n*Subset: %s, FolderNr: %i - Time Window N2: %i - %i.  \n ', IndexSubset, iFolder,  TimeWindow_N2)
        
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
            Relative = INPUT.data.For_Relative;
            
            
            % ********************************************************************************************
            % **** Set Up Some Information *************************************************************
            % ********************************************************************************************
            
            % Get Index of Electrodes
            Electrodes_N2 = INPUT.data.For_Relative.ElectrodesN2;
            
            TimeIdx_N2 = findTimeIdx(INPUT.data.For_Relative.TimesN2, TimeWindow_N2(1), TimeWindow_N2(2));
            
            NrElectrodes_N2 = length(Electrodes_N2);
            
            % ********************************************************************************************
            % ****  Extract Data *************************************************************************
            % ********************************************************************************************
            ConditionData_N2 = INPUT.data.For_Relative.DataN2;
            
            % ****** Extract Amplitude, SME, Epoch Count ******
            InitSize_N2 = [NrElectrodes_N2,NrConditions+NrConditionsDiff];
            EpochCount_N2 = NaN(InitSize_N2);
            ERP_N2 =NaN(InitSize_N2); SME_N2=NaN(InitSize_N2);
            
            for i_Cond = 1:NrConditions
                Data_N2 = ConditionData_N2.(Condition_Names{i_Cond});
                
                % Count Epochs
                EpochCount_N2(:,i_Cond,:) = size(Data_N2,3);
                if size(Data_N2,3) < str2double(INPUT.StepHistory.Trials_MinNumber)
                    ERP_N2(:,i_Cond,:) = NaN;
                    SME_N2(:,i_Cond,:) = NaN;
                else
                    % Calculate ERP if enough epochs there
                    if strcmp(Choice, "Mean")
                        ERP_N2(:,i_Cond,1) = mean(mean(Data_N2,3),2);
                        SME_N2(:,i_Cond,1) = Mean_SME(Data_N2);
                        
                    elseif strcmp(Choice, "Peak")
                        [ERP_N2(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_N2,3), "NEG");
                        SME_N2(:,i_Cond,1) = Peaks_SME(Data_N2, "NEG");
                    end
                    
                end
            end
            
            % ********************************************************************************************
            % **** Loop also through Difference Waves!          ******************************************
            % ********************************************************************************************
            % Create **** Difference Waves ****   on ERPs
            for i_Diff = 1:NrConditionsDiff
                i_CondDiff = i_Diff + 4;
                
                NoGo_N2 = ConditionData_N2.(Condition_Names{i_Diff+2});
                Go_N2 =  ConditionData_N2.(Condition_Names{i_Diff});
                
                % Count Epochs
                MinEpochs = min(min(size(NoGo_N2,3), size(Go_N2,3)));
                EpochCount_N2(:,i_CondDiff,:) = MinEpochs;
                
                % if MinEpochs < str2double(INPUT.StepHistory.Trials_MinNumber)
                if MinEpochs < 2
                    ERP_N2(:,i_CondDiff,:) = NaN;
                    SME_N2(:,i_CondDiff,:) = NaN;
                else
                    
                    % Calculate if enough epochs there
                    if strcmp(Choice, "Mean")
                        
                        
                        ERP_N2(:,i_CondDiff,1) = mean(mean(NoGo_N2,3) - mean(Go_N2,3), 2);
                        SME_N2(:,i_CondDiff,1) = DifferenceWave_SME(NoGo_N2, Go_N2, "MEAN");
                        
                    elseif strcmp(Choice, "Peak")
                        
                        
                        ERP_N2(:,i_CondDiff,1) = Peaks_Detection(mean(NoGo_N2,3) - mean(Go_N2,3), "NEG");
                        SME_N2(:,i_CondDiff,1) = DifferenceWave_SME(NoGo_N2, Go_N2, "NEG");
                        
                        
                    end
                end
            end
            
            % ********************************************************************************************
            % **** Prepare Output Table    ***************************************************************
            % ********************************************************************************************
            
            
            % Prepare Final Export with all Values
            % ****** Prepare Labels ******
            % important N2 and RewP do not always have same number of electrodes!
            
            % Subject, ComponentName, Lab, Experimenter is constant AAA
            NrConditionsL = NrConditions + NrConditionsDiff;
            
            
            Subject_N2_L = repmat(INPUT.Subject, NrConditionsL*NrElectrodes_N2,1 );
            Lab_N2_L = repmat(INPUT.data.For_Relative.RecordingLab, NrConditionsL*NrElectrodes_N2,1 );
            Experimenter_N2_L = repmat(INPUT.data.For_Relative.Experimenter, NrConditionsL*NrElectrodes_N2,1 );
            Component_N2_L = repmat("N2", NrConditionsL*NrElectrodes_N2,1 );
            ACC = repmat(INPUT.data.For_Relative.ACC, NrConditionsL*NrElectrodes_N2,1 );
            
            % Electrodes: if multiple electrodes, they simply alternate ABABAB
            Electrodes_N2_L = repmat(Electrodes_N2', NrConditionsL, 1);
            
            
            % Conditions are blocked across electrodes, but alternate across
            % time windows AABBAABB
            Condition_NamesL = [Condition_Names, Condition_NamesDiff];
            Conditions_N2_L = repelem(Condition_NamesL', NrElectrodes_N2,1);
            
            
            % Time Window are blocked across electrodes and conditions AAAAABBBB
            TimeWindow_N2_L = repmat(num2str(TimeWindow_N2), NrConditionsL*NrElectrodes_N2, 1);
            
            % ****** Prepare Table ******
            Export = [  [cellstr([Subject_N2_L, Lab_N2_L, Experimenter_N2_L, Conditions_N2_L, Electrodes_N2_L, TimeWindow_N2_L]),...
                num2cell([ERP_N2(:), SME_N2(:), EpochCount_N2(:)]),  cellstr(Component_N2_L), num2cell(ACC)]];
            
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
            
            
            fprintf('\n*Subset: %s, FolderNr: %s, Subject: %s - Error Extracting ERPs. \n ', IndexSubset, Folder, INPUT.Subject)
            OUTPUT = INPUT;
            OUTPUT.Error = ErrorMessage;
        end
        parfor_save(fullfile(Parentfolder, Folder, Files_Fork(i_Files).name), OUTPUT)
    end
end
end