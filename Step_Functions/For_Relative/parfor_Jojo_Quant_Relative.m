function  parfor_Jojo_Quant_Relative(IndexSubset, Parentfolder)
% List all Folders
Folders = [dir(fullfile(Parentfolder, '*21.2*'));...
    dir(fullfile(Parentfolder, '*21.3*')) ];

%% Show input to this function
disp("Info for Parfor Function")
disp(IndexSubset)
disp(Parentfolder)
fprintf('\nNumber of Paths to analyse: %i. \n  ', length(Folders))


% Prepare Matlabpool
%delete(gcp('nocreate')); % make sure that previous pooling is closed
%distcomp.feature( 'LocalUseMpiexec', false );
%parpool(12);

% In parallel way, for every Forking Combination extract GAV and ERP Values
parfor iFolder = 1:length(Folders)
    fprintf('\n*Subset: %s, FoldN2r: %i - Calculating GAV. \n  ', IndexSubset, iFolder)
    %% ********************************
    % CREATE GAV (load single files)
    % *********************************
    Folder = Folders(iFolder).name;
    % List all Files of this forking path
    Files_Fork = dir( fullfile( Parentfolder, Folder,  '*.mat' )  );
    Files_Fork = Files_Fork(~contains({Files_Fork.name}, "error" ));
    Files_Fork = Files_Fork(~contains({Files_Fork.name}, "running" ));
    
    % Get first File to have a starting point (order, timepoints etc)
    INPUT = load(fullfile(Parentfolder, Folder, Files_Fork(1).name));
    INPUT = INPUT.Data;
    
    
    % Get correct DP for each Component
    if  strcmp(INPUT.StepHistory.Resampling, "500")
        DP = 201;
        DPFRN = 151;
    elseif  strcmp(INPUT.StepHistory.Resampling, "250")
        DP = 100;
        DPFRN = 125;
    elseif  strcmp(INPUT.StepHistory.Resampling, "125")
        DP = 50;
        DPFRN = 25;
    end
    
    
    % Initiate the GAV relevant to extract the Peak
    GAV_FRN = NaN(1, ...
        DPFRN,...
        length(Files_Fork));
    GAV_FMT = NaN(1, ...
        DP,...
        length(Files_Fork));
    
    
    % Go through each File, load and merge to AV
    for ifile = 1:length(Files_Fork)
        try
            Data = load(fullfile( Parentfolder, Folder,Files_Fork(ifile).name));
            Data = Data.Data;
            
            DataFMT = Data.data.For_Relative.FMT.FMT;
            DataFRN = Data.data.For_Relative.ERP.ERP;
            
                        
            % Merge across Subjects
            GAV_FMT(:,:,ifile) = DataFMT;
            GAV_FRN(:,:,ifile) = DataFRN;
            
            
        catch e
            fprintf('\n*ERROR GAV Subset: %s, FoldN2r: %i:, File: %i %s \n  ', IndexSubset, iFolder,ifile, string(e.message))
        end
    end
    
    %% ********************************
    % CREATE GAV AND GET TIME WINDOW BASED ON PEAKS ACROSS CONDITIONS AND
    % ELECTRODES
    % *********************************
    GAV_FRN = mean(mean(GAV_FRN,3, 'omitnan'),1);
    GAV_FMT = mean(mean(GAV_FMT,3, 'omitnan'),1);
    
    
 
    
    
    % Extract new Latencies
    Times_FMT = INPUT.data.For_Relative.FMT.times;
    [~, Latency_FMT] = Peaks_Detection(GAV_FMT, "POS");   
    if  contains(INPUT.StepHistory.TimeWindow, "wide")
        TimeWindow_FMT = [Times_FMT(Latency_FMT) - 50, Times_FMT(Latency_FMT) + 50];
    else
        TimeWindow_FMT = [Times_FMT(Latency_FMT) - 25, Times_FMT(Latency_FMT) + 25];
    end
    fprintf('\n*Subset: %s, Foldernr: %i - Time Window FMT: %i - %i.  \n ', IndexSubset, iFolder, TimeWindow_FMT)
    
    
    
    
    Times_FRN = INPUT.data.For_Relative.ERP.times;
    [~, Latency_FRN] = Peaks_Detection(GAV_FRN, "NEG");
    if  contains(INPUT.StepHistory.TimeWindow, "wide")
        TimeWindow_FRN = [Times_FRN(Latency_FRN) - 50, Times_FRN(Latency_FRN) + 50];
    else
        TimeWindow_FRN = [Times_FRN(Latency_FRN) - 25, Times_FRN(Latency_FRN) + 25];
    end
    fprintf('\n*Subset: %s, Foldernr: %i - Time Window FRN: %i - %i.  \n ', IndexSubset, iFolder, TimeWindow_FRN)



    Trials_MinNumber =1;

%% ********************************
% LOAD EACH FILE AND EXPORT P3AK/MEAN IN TIME WINDOW
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
        Electrodes_FMT = INPUT.data.For_Relative.Electrodes;
        TimeIdx_FMT = findTimeIdx(INPUT.data.For_Relative.Times_FMT, TimeWindow_FMT(1), TimeWindow_FMT(2));
        NrElectrodes = length(Electrodes_FMT);
        Electrodes_FRN = INPUT.data.For_Relative.Electrodes;
        TimeIdx_FRN = findTimeIdx(INPUT.data.For_Relative.Times_FRN,  TimeWindow_FRN(1), TimeWindow_FRN(2));
        
        
        % ********************************************************************************************
        % **** Extract Data     FRN  & FMT                 *******************************************
        % ********************************************************************************************
        Condition_Names = fieldnames( INPUT.data.For_Relative.Data_FMT);
        NrConditions = length(Condition_Names);
        
        InitSize_FMT = [NrElectrodes,NrConditions];
        EpochCount = NaN(InitSize_FMT);
        ERP_FMT =NaN(InitSize_FMT); SME_FMT =NaN(InitSize_FMT);
        
        InitSize_FRN = [NrElectrodes,NrConditions];
        ERP_FRN =NaN(InitSize_FRN); SME_FRN=NaN(InitSize_FRN);
        
        
        % ****** Extract Amplitude, SME, Epoch Count ******
        for i_Cond = 1:NrConditions
            Data_FMT = INPUT.data.For_Relative.Data_FMT.(Condition_Names{i_Cond})(:,TimeIdx_FMT,:);
            % Count Epochs
            EpochCount(:,i_Cond) = size(Data_FMT,3);
            if size(Data_FMT,3) < (Trials_MinNumber)
                ERP_FMT(:,i_Cond) = NaN;
                SME_FMT(:,i_Cond) = NaN;
            else
                % Calculate ERP if enough epochs there
                ERP_FMT(:,i_Cond) = mean(mean(Data_FMT,3),2);
                SME_FMT(:,i_Cond) = Mean_SME(Data_FMT);
            end
            
            Data_FRN = INPUT.data.For_Relative.Data_FRN.(Condition_Names{i_Cond})(:,TimeIdx_FRN,:);
            if size(Data_FRN,3) < (Trials_MinNumber)
                ERP_FRN(:,i_Cond) = NaN;
                SME_FRN(:,i_Cond) = NaN;
            else
                % Calculate ERP if enough epochs there
                ERP_FRN(:,i_Cond) = mean(mean(Data_FRN,3),2);
                SME_FRN(:,i_Cond) = Mean_SME(Data_FRN);
            end
            
            
            
        end
        
        % ****** Prepare Labels ******
        % Subject, ComponentName, Lab, Experimenter is constant AAA
        Subject_L = repmat(INPUT.Subject, NrConditions*NrElectrodes,1 );
        if strcmp(INPUT.AnalysisName , "Ultimatum_Quant")
            Task_L = repmat('Ultimatum', NrConditions*NrElectrodes,1 );
        else
            Task_L = repmat('Gambling', NrConditions*NrElectrodes,1 );
        end
        Lab_L = repmat(INPUT.data.For_Relative.RecordingLab, NrConditions*NrElectrodes,1 );
        Experimenter_L = repmat(INPUT.data.For_Relative.Experimenter, NrConditions*NrElectrodes,1 );
        Component_FRN_L = repmat("FRN", NrConditions*NrElectrodes,1 );
        Component_FMT_L = repmat("FMT", NrConditions*NrElectrodes,1 );
        
        % Electrodes: if multiple electrodes, they simply alternate ABABAB
        Electrodes_L = repmat(Electrodes_FMT', NrConditions, 1);
        
        % Conditions are blocked across electrodes, but alternate across
        % time windows AABBAABB
        Conditions_L = repelem(Condition_Names', NrElectrodes,1);
        Conditions_L = repmat(Conditions_L(:), 1);
        
        % Time Window are blocked across electrodes and conditions AAAAABBBB
        TimeWindow_FMT_L = repmat(num2str(TimeWindow_FMT), NrConditions*NrElectrodes, 1);
        Export =  [cellstr([Subject_L, Lab_L, Experimenter_L, Task_L, Conditions_L, Electrodes_L, TimeWindow_FMT_L]),...
            num2cell([ERP_FMT(:), SME_FMT(:), EpochCount(:)]), cellstr(Component_FMT_L) ];
        
        TimeWindow_FRN_L = repmat(num2str(TimeWindow_FRN), NrConditions*NrElectrodes, 1);
        Export_FRN =  [cellstr([Subject_L, Lab_L, Experimenter_L, Task_L, Conditions_L, Electrodes_L, TimeWindow_FRN_L]),...
            num2cell([ERP_FRN(:), SME_FRN(:), EpochCount(:)]), cellstr(Component_FRN_L)];
        Export = [Export; Export_FRN];
        
        
        OUTPUT.data.Export = Export;
        parfor_save(fullfile(Parentfolder, Folder,Files_Fork(i_Files).name), OUTPUT)
        
        
        % ****** Error Management ******
    catch e
        % If error ocurrs, create ErrorMessage(concatenated for all nested
        % errors). This string is given to the OUTPUT struct.
        ErrorMessage = string(e.message);
        for ierrors = 1:length(e.stack)
            ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
        end
        
        OUTPUT.Error = ErrorMessage;
        fprintf('\n*Subset: %s, FoldN2r: %i, Subject: %s - Error Extracting ERPs. \n ', IndexSubset, iFolder, INPUT.Subject)
        OUTPUT = INPUT;
    end
end
end
