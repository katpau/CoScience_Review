function  parfor_Flanker_Conflict_Relative(IndexSubset, Parentfolder)
% List all Folders
Folders = [dir(fullfile(Parentfolder, '*21.4*'));...
    dir(fullfile(Parentfolder, '*21.5*')) ];

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


% Prepare Matlabpool
delete(gcp('nocreate')); % make sure that previous pooling is closed
distcomp.feature( 'LocalUseMpiexec', false );
parpool(12);

% In parallel way, for every Forking Combination extract GAV and ERP Values
parfor iFolder = 1:length(Folders)
    fprintf('\n*Subset: %s, Folder: %i - Calculating GAV. \n  ', IndexSubset, iFolder)
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
    

   
    % Get correct DP for each Component
    if  strcmp(INPUT.StepHistory.Resampling, "500")
        DP = 76;
        DPPE = 176;
    elseif  strcmp(INPUT.StepHistory.Resampling, "250")
        DP = 31;
        DPPE = 71;
    elseif  strcmp(INPUT.StepHistory.Resampling, "125")
        DP = 16;
        DPPE = 36;
    end
    
    
    % Initiate the GAV relevant to extract the PEak
    GAV_ERN = NaN(1, ...
        DP,...
        length(Files_Fork));
    GAV_PE = NaN(1, ...
        DPPE,...
        length(Files_Fork));

    
    
    % Go through each File, load and merge to AV
    for ifile = 1:length(Files_Fork)
        try
            Data = load(fullfile( Parentfolder, Folder,Files_Fork(ifile).name));
            Data = Data.Data;
            
            % Merge across Subjects
            GAV_ERN(:,:,ifile) = Data.data.For_Relative.ERP.ERN;
            GAV_PE(:,:,ifile) = Data.data.For_Relative.ERP.PE;
            
            
        catch e
            fprintf('\n*ERROR GAV Subset: %s, Folderr: %i: %s \n  ', IndexSubset, iFolder, string(e.message))
        end
    end
    
    %% ********************************
    % CREATE GAV AND GET TIME WINDOW BASED ON PEAKS ACROSS CONDITIONS
    % *********************************
    GAV_ERN = mean(GAV_ERN,3);
    GAV_PE = mean(GAV_PE,3);
   
    % Extract Peaks and Determine new Time Window
      % Extract new Latencies
          % Nr Electrodes
    NrElectrodes_ERN = length(INPUT.data.For_Relative.Data.ERN_Electrodes);
    NrElectrodes_PE = length(INPUT.data.For_Relative.Data.PE_Electrodes);
    
    Times_ERN = INPUT.data.For_Relative.ERP.ERN_times;
    Times_PE = INPUT.data.For_Relative.ERP.PE_times;

    [~, Latency_ERN] = Peaks_Detection(mean(GAV_ERN,1), "NEG");
    [~, Latency_PE] = Peaks_Detection(mean(GAV_PE,1), "POS");
    if  contains(INPUT.StepHistory.TimeWindow, "wide")
        TimeWindow_ERN = [Times_ERN(Latency_ERN) - 50, Times_ERN(Latency_ERN) + 50];
        TimeWindow_PE = [Times_PE(Latency_PE) - 50, Times_PE(Latency_PE) + 50];
    else
        TimeWindow_ERN = [Times_ERN(Latency_ERN) - 25, Times_ERN(Latency_ERN) + 25];
        TimeWindow_PE = [Times_PE(Latency_PE) - 25, Times_PE(Latency_PE) + 25];
    end
    
    
    fprintf('\n*Subset: %s, Folder: %i - Time Window ERN: %i - %i. Time Window PE: %i - %i.  \n ', IndexSubset, iFolder, TimeWindow_ERN, TimeWindow_PE)
    
    %% ********************************
    % LOAD EACH FILE AND EXPORT PEAK/MEAN IN TIME WINDOW
    % *********************************
    
    for i_Files = 1 : length(Files_Fork)
        try
            INPUT = load(fullfile(Parentfolder, Folder,Files_Fork(i_Files).name));
            INPUT = INPUT.Data;
            OUTPUT = INPUT;
            
            
            % ********************************************************************************************
            % **** Set Up Some Information *************************************************************
            % ********************************************************************************************
            
            % Get Index of Electrodes
            Electrodes_ERN = INPUT.data.For_Relative.Data.ERN_Electrodes;
            Electrodes_PE = INPUT.data.For_Relative.Data.PE_Electrodes;
            
            TimeIdx_ERN = findTimeIdx(INPUT.data.For_Relative.Data.ERN_Times,  TimeWindow_ERN(1), TimeWindow_ERN(2));
            TimeIdx_PE = findTimeIdx(INPUT.data.For_Relative.Data.PE_Times, TimeWindow_PE(1), TimeWindow_PE(2));
            
        
            
            
            % ********************************************************************************************
            % **** Prepare Output Table    ***************************************************************
            % ********************************************************************************************
       Condition_Names = fieldnames( INPUT.data.For_Relative.Data.ERN);
        NrConditions = length(Condition_Names);
        
        
        InitSize_ERN = [NrElectrodes_ERN,NrConditions];
        ERP_ERN =NaN(InitSize_ERN); SME_ERN=NaN(InitSize_ERN);
        EpochCount_ERN=NaN(InitSize_ERN);
        
          InitSize_PE = [NrElectrodes_PE,NrConditions];
        ERP_PE =NaN(InitSize_PE); SME_PE=NaN(InitSize_PE);
	EpochCount_PE=NaN(InitSize_PE);
        
        
        
        % ****** Extract Amplitude, SME, Epoch Count ******
        for i_Cond = 1:NrConditions
                 
            Data_ERN = INPUT.data.For_Relative.Data.ERN.(Condition_Names{i_Cond})(:,TimeIdx_ERN,:);
            Data_PE = INPUT.data.For_Relative.Data.PE.(Condition_Names{i_Cond})(:,TimeIdx_PE,:);
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
                    if strcmp(INPUT.StepHistory.Quantification_ERP, "Mean")
                        ERP_ERN(:,i_Cond,1) = mean(mean(Data_ERN,3),2);
                        SME_ERN(:,i_Cond,1) = Mean_SME(Data_ERN);
                        
                        ERP_PE(:,i_Cond,1) = mean(mean(Data_PE,3),2);
                        SME_PE(:,i_Cond,1) = Mean_SME(Data_PE);
                        
                    elseif strcmp(INPUT.StepHistory.Quantification_ERP, "Peak")
                        [ERP_ERN(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_ERN,3), "NEG");
                        SME_ERN(:,i_Cond,1) = Peaks_SME(Data_ERN, "NEG");
                        
                        [ERP_PE(:,i_Cond,1), ~] = Peaks_Detection(mean(Data_PE,3), "POS");
                        SME_PE(:,i_Cond,1) = Peaks_SME(Data_PE, "POS");
                        
                        
                    end
                    
            
            
            
                end
        end
        
        
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
            Conditions_ERN_L = repelem(Condition_Names', NrElectrodes_ERN,1)';
            Conditions_PE_L = repelem(Condition_Names', NrElectrodes_PE,1)';
            
            
            % Time Window are blocked across electrodes and conditions AAAAABBBB
            TimeWindow_ERN_L = repmat(num2str(TimeWindow_ERN), NrConditions*NrElectrodes_ERN, 1);
            TimeWindow_PE_L = repmat(num2str(TimeWindow_PE), NrConditions*NrElectrodes_PE, 1);

            % Task Label
            TaskLabel = INPUT.data.For_Relative.Task;
            Task_PE_L =  repmat(TaskLabel, NrConditions*NrElectrodes_PE,1 );
            Task_ERN_L =  repmat(TaskLabel, NrConditions*NrElectrodes_ERN,1 );
            
            % ****** Prepare Table ******
            Export = [[cellstr([Subject_ERN_L, Lab_ERN_L, Experimenter_ERN_L, Task_ERN_L, Conditions_ERN_L(:), Electrodes_ERN_L, TimeWindow_ERN_L]),...
            num2cell([ERP_ERN(:), SME_ERN(:), EpochCount_ERN(:)]), cellstr(Component_ERN_L)]; ...
            [cellstr([Subject_PE_L, Lab_PE_L, Experimenter_PE_L, Task_PE_L, Conditions_PE_L(:), Electrodes_PE_L, TimeWindow_PE_L]),...
            num2cell([ERP_PE(:), SME_PE(:), EpochCount_PE(:)]), cellstr(Component_PE_L)]];
            
            OUTPUT = INPUT;
            OUTPUT.data.Export = Export;
            
            parfor_save(fullfile(Parentfolder, Folder, Files_Fork(i_Files).name), OUTPUT)
            
            
            
            % ****** Error Management ******
        catch e
            % If error ocurrs, create ErrorMessage(concatenated for all nested
            % errors). This string is given to the OUTPUT struct.
            ErrorMessage = string(e.message);
            for ierrors = 1:length(e.stack)
                ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
            end

            OUTPUT = INPUT;
            OUTPUT.Error = ErrorMessage;
            fprintf('\n*Subset: %s, Folder: %i, Subject: %s - Error Extracting ERPs. \n ', IndexSubset, iFolder, INPUT.Subject)
            
            parfor_save(fullfile(Parentfolder, Folder, strrep(Files_Fork(i_Files).name, '.mat', '_error.mat')), OUTPUT)
            
        end
        
    end
end

end