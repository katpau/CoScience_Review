function  parfor_Flanker_Error_Relative(IndexSubset, Parentfolder)
% List all Folders
Folders = [dir(fullfile(Parentfolder, '*21.4*')); ...
    dir(fullfile(Parentfolder, '*21.5*'))];

% Subset Folders
if strcmp(IndexSubset, "odd")
    Folders = Folders(1:2:length(Folders));
else
    Folders = Folders(2:2:length(Folders));
end

%% Show input to this function
disp("Info for Parfor Function")
disp(IndexSubset)
disp(Parentfolder)
fprintf('\nNumber of Paths to analyse: %i. \n  ', length(Folders))


% Get Condition Names
Condition_Triggers = [107, 117, 127, 137, 106, 116, 126, 136; ...
    207, 217, 227, 237, 206, 216, 226, 236; ...
    109, 119, 129, 139, 108, 118, 128, 138; ...
    209, 219, 229, 239, 208, 218,  228, 238];

Condition_Names = ["Correct_ExpAbsent",
    "Correct_ExpPresent",
    "Error_ExpAbsent",
    "Error_ExpPresent"];

NrConditions = length(Condition_Names);


% Prepare Matlabpool
delete(gcp('nocreate')); % make sure that previous pooling is closed
distcomp.feature( 'LocalUseMpiexec', false );
parpool(12);

% In parallel way, for every Forking Combination extract GAV and ERP Values
parfor iFolder = 1:length(Folders)
    fprintf('\n*Subset: %s, FolderNr: %i - Calculating GAV. \n  ', IndexSubset, iFolder)
    %% ********************************
    % CREATE GAV (load single files)
    % *********************************
    Folder = Folders(iFolder).name;
    % List all Files of this forking path
    Files_Fork = dir( fullfile( Parentfolder, Folder,  '*.mat' )  );
    Files_Fork = Files_Fork(~contains({Files_Fork.name}, "error" ));
    
    % Get first File to have a starting point (order, timepoints etc)
    INPUT = load(fullfile(Parentfolder, Folder, Files_Fork(1).name));
    INPUT = INPUT.Data;
    ERPTemplateERN = INPUT.data.For_Relative.Data_ERN;
    ERPTemplatePE = INPUT.data.For_Relative.Data_PE;
    
    % Nr Electrodes
    NrElectrodes_ERN = length(INPUT.data.For_Relative.Electrodes_ERN);
    NrElectrodes_PE = length(INPUT.data.For_Relative.Electrodes_PE);
    
    % Get correct DP for each Component
    if  strcmp(INPUT.StepHistory.Resampling, "500")
        DP = 104;
        DPPE = 232;
    elseif  strcmp(INPUT.StepHistory.Resampling, "250")
        DP = 52;
        DPPE = 116;
    elseif  strcmp(INPUT.StepHistory.Resampling, "125")
        DP = 26;
        DPPE = 58;
    end
    
    
    % Initiate the GAV relevant to extract the peak
    GAV_ERN = [];
    GAV_PE = [];
    for i_Cond = 1:NrConditions
        GAV_ERN.(Condition_Names{i_Cond}) = NaN(NrElectrodes_ERN, ...
            DP,...
            length(Files_Fork));
        GAV_PE.(Condition_Names{i_Cond}) = NaN(NrElectrodes_PE, ...
            DPPE,...
            length(Files_Fork));
    end
    
    
    % Go through each File, load and merge to AV
    for ifile = 1:length(Files_Fork)
        try
            Data = load(fullfile( Parentfolder, Folder,Files_Fork(ifile).name));
            Data = Data.Data;
            
            DataERN = Data.data.For_Relative.Data_ERN;
            DataPE = Data.data.For_Relative.Data_PE;
            for icond = 1:NrConditions
                % Take mean, as this was not done before
                DataERN.(Condition_Names{icond}) = mean(DataERN.(Condition_Names{icond}), 3);
                DataPE.(Condition_Names{icond}) = mean(DataPE.(Condition_Names{icond}), 3);
                
                % Downsample if necessary (only Biosemis)
                if length(DataERN.(Condition_Names{icond}))>DP % downsample
                    New = [];
                    NewPE = [];
                    for iel = 1:size(DataERN.(Condition_Names{icond}),1)
                        New = [New; interp1(1:length(DataERN.(Condition_Names{icond})), DataERN.(Condition_Names{icond})(iel,:), linspace(1, length(DataERN.(Condition_Names{icond})), DP), 'linear')];
                    end
                    for iel = 1:size(DataPE.(Condition_Names{icond}),1)
                        NewPE = [NewPE; interp1(1:length(DataPE.(Condition_Names{icond})), DataPE.(Condition_Names{icond})(iel,:), linspace(1, length(DataPE.(Condition_Names{icond})), DPPE), 'linear')];
                    end
                    DataERN.(Condition_Names{icond})= New;
                    DataPE.(Condition_Names{icond})= NewPE;
                end
                
                % Merge across Subjects
                GAV_ERN.(Condition_Names{icond})(:,:,ifile) = DataERN.(Condition_Names{icond});
                GAV_PE.(Condition_Names{icond})(:,:,ifile) = DataPE.(Condition_Names{icond});
            end
        catch e
            fprintf('\n*ERROR GAV Subset: %s, FolderNr: %i: %s \n  ', IndexSubset, iFolder, string(e.message))
        end
    end
    
    %% ********************************
    % CREATE GAV AND GET TIME WINDOW BASED ON PEAKS
    % *********************************
    GAV_ERN = mean(cat(3,GAV_ERN.(Condition_Names{1}), ...
        GAV_ERN.(Condition_Names{2}),...
        GAV_ERN.(Condition_Names{3}),...
        GAV_ERN.(Condition_Names{4})),3);
    GAV_PE = mean(cat(3,GAV_PE.(Condition_Names{1}), ...
        GAV_PE.(Condition_Names{2}),...
        GAV_PE.(Condition_Names{3}),...
        GAV_PE.(Condition_Names{4})),3);
    
    % Extract Peaks and Determine new Time Window
    iFF = 0;
    while length(INPUT.data.For_Relative.Times_ERN)>DP
        iFF = iFF +1;
        INPUT = load(fullfile( Parentfolder, Folder,Files_Fork(iFF).name))
        INPUT = INPUT.Data;
    end
    
    % Extract new Latencies
    Times_ERN = INPUT.data.For_Relative.Times_ERN;
    Times_PE = INPUT.data.For_Relative.Times_PE;
    TimeIdx_ERN = findTimeIdx(Times_ERN,0, 150);
    TimeIdx_PE = findTimeIdx(Times_PE, 250, 500);
    [~, Latency_ERN] = Peaks_Detection(mean(GAV_ERN(:,TimeIdx_ERN,:),1), "NEG");
    [~, Latency_PE] = Peaks_Detection(mean(GAV_PE(:,TimeIdx_PE,:),1), "POS");
    if  contains(INPUT.StepHistory.TimeWindow, "wide")
        TimeWindow_ERN = [Times_ERN(Latency_ERN+(TimeIdx_ERN(1))) - 50, Times_ERN(Latency_ERN+(TimeIdx_ERN(1))) + 50];
        TimeWindow_PE = [Times_PE(Latency_PE+(TimeIdx_PE(1))) - 50, Times_PE(Latency_PE+(TimeIdx_PE(1))) + 100];
    else
        TimeWindow_ERN = [Times_ERN(Latency_ERN+(TimeIdx_ERN(1))) - 25, Times_ERN(Latency_ERN+(TimeIdx_ERN(1))) + 25];
        TimeWindow_PE = [Times_PE(Latency_PE+(TimeIdx_PE(1))) - 25, Times_PE(Latency_PE+(TimeIdx_PE(1))) + 25];
    end
    
    
    fprintf('\n*Subset: %s, FolderNr: %i - Time Window ERN: %i - %i. Time Window PE: %i - %i.  \n ', IndexSubset, iFolder, TimeWindow_ERN, TimeWindow_PE)
    
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
            Electrodes_ERN = INPUT.data.For_Relative.Electrodes_ERN;
            Electrodes_PE = INPUT.data.For_Relative.Electrodes_PE;
            
            TimeIdx_ERN = findTimeIdx(INPUT.data.For_Relative.Times_ERN,  TimeWindow_ERN(1), TimeWindow_ERN(2));
            TimeIdx_PE = findTimeIdx(INPUT.data.For_Relative.Times_PE, TimeWindow_PE(1), TimeWindow_PE(2));
            
            NrElectrodes_ERN = length(Electrodes_ERN);
            NrElectrodes_PE = length(Electrodes_PE);
            %             % update Label
            %             if INPUT.StepHistory.Cluster_Electrodes == "cluster"
            %                 NrElectrodes_ERN = 1;
            %                 Electrodes_ERN = strcat('Cluster ', join(Electrodes_ERN));
            %                 NrElectrodes_PE = 1;
            %                 Electrodes_PE = strcat('Cluster ', join(Electrodes_PE));
            %             end
            
            % ********************************************************************************************
            % ****  Extract Data *************************************************************************
            % ********************************************************************************************
            ConditionData_ERN = INPUT.data.For_Relative.Data_ERN;
            ConditionData_PE = INPUT.data.For_Relative.Data_PE;
            
            % ****** Extract Amplitude, SME, Epoch Count ******
            InitSize_ERN = [NrElectrodes_ERN,NrConditions];
            EpochCount_ERN = NaN(InitSize_ERN);
            ERP_ERN =NaN(InitSize_ERN); SME_ERN=NaN(InitSize_ERN);
            
            InitSize_PE = [NrElectrodes_PE,NrConditions];
            EpochCount_PE = NaN(InitSize_PE);
            ERP_PE =NaN(InitSize_PE); SME_PE=NaN(InitSize_PE);
            
            for i_Cond = 1:NrConditions
                Data_ERN = ConditionData_ERN.(Condition_Names{i_Cond});
                Data_PE = ConditionData_PE.(Condition_Names{i_Cond});
                
                
                %                 if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                %                     ConditionData_ERN.(Condition_Names(i_Cond)) = mean(ConditionData_ERN.(Condition_Names(i_Cond)),1);
                %                     ConditionData_PE.(Condition_Names(i_Cond)) = mean(ConditionData_PE.(Condition_Names(i_Cond)),1);
                %                 end
                
                % Count Epochs
                EpochCount_ERN(:,i_Cond,:) = size(Data_ERN,3);
                EpochCount_PE(:,i_Cond,:) = size(Data_PE,3);
                if size(Data_ERN,3) < str2double(INPUT.StepHistory.Trials_MinNumber)
                    ERP_ERN(:,i_Cond,:) = NaN;
                    SME_ERN(:,i_Cond,:) = NaN;
                    ERP_PE(:,i_Cond,:) = NaN;
                    SME_PE(:,i_Cond,:) = NaN;
                else
                    % Calculate ERP if enough epochs there
                    if strcmp(Choice, "Mean")
                        ERP_ERN(:,i_Cond,1) = mean(mean(Data_ERN,3),2);
                        SME_ERN(:,i_Cond,1) = Mean_SME(Data_ERN);
                        
                        ERP_PE(:,i_Cond,1) = mean(mean(Data_PE,3),2);
                        SME_PE(:,i_Cond,1) = Mean_SME(Data_PE);
                        
                    elseif strcmp(Choice, "Peak")
                        [ERP_ERN(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_ERN,3), "NEG");
                        SME_ERN(:,i_Cond,1) = Peaks_SME(Data_ERN, "NEG");
                        
                        [ERP_PE(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_PE,3), "POS");
                        SME_PE(:,i_Cond,1) = Peaks_SME(Data_PE, "POS");
                        
                        
                    end
                end
            end
            
            % ********************************************************************************************
            % **** Prepare Output Table    ***************************************************************
            % ********************************************************************************************
            
            
            % Prepare Final Export with all Values
            % ****** Prepare Labels ******
            % important PE and ERN do not always have same number of electrodes!
            
            % Subject, ComponentName, Lab, Experimenter is constant AAA
            Subject_ERN_L = repmat(INPUT.Subject, NrConditions*NrElectrodes_ERN,1 );
            Lab_ERN_L = repmat(INPUT.data.For_Relative.RecordingLab, NrConditions*NrElectrodes_ERN,1 );
            Experimenter_ERN_L = repmat(INPUT.data.For_Relative.Experimenter, NrConditions*NrElectrodes_ERN,1 );
            Component_ERN_L = repmat("ERN", NrConditions*NrElectrodes_ERN,1 );
            
            Subject_PE_L = repmat(INPUT.Subject, NrConditions*NrElectrodes_PE,1 );
            Lab_PE_L = repmat(INPUT.data.For_Relative.RecordingLab, NrConditions*NrElectrodes_PE,1 );
            Experimenter_PE_L = repmat(INPUT.data.For_Relative.Experimenter, NrConditions*NrElectrodes_PE,1 );
            Component_PE_L = repmat("PE", NrConditions*NrElectrodes_PE,1 );
            
            % Electrodes: if multiple electrodes, they simply alternate ABABAB
            Electrodes_ERN_L = repmat(Electrodes_ERN', NrConditions, 1);
            Electrodes_PE_L = repmat(Electrodes_PE', NrConditions, 1);
            
            
            % Conditions are blocked across electrodes, but alternate across
            % time windows AABBAABB
            Conditions_ERN_L = repelem(Condition_Names, NrElectrodes_ERN,1);
            Conditions_PE_L = repelem(Condition_Names, NrElectrodes_PE,1);
            
            
            % Time Window are blocked across electrodes and conditions AAAAABBBB
            TimeWindow_ERN_L = repmat(num2str(TimeWindow_ERN), NrConditions*NrElectrodes_ERN, 1);
            TimeWindow_PE_L = repmat(num2str(TimeWindow_PE), NrConditions*NrElectrodes_PE, 1);
            
            % ****** Prepare Table ******
            Export = [ [cellstr([Subject_ERN_L, Lab_ERN_L, Experimenter_ERN_L, Conditions_ERN_L, Electrodes_ERN_L, TimeWindow_ERN_L]),...
                num2cell([ERP_ERN(:), SME_ERN(:), EpochCount_ERN(:)]), cellstr(Component_ERN_L)]; ...
                [cellstr([Subject_PE_L, Lab_PE_L, Experimenter_PE_L, Conditions_PE_L, Electrodes_PE_L, TimeWindow_PE_L]),...
                num2cell([ERP_PE(:), SME_PE(:), EpochCount_PE(:)]), cellstr(Component_PE_L)]];
            
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