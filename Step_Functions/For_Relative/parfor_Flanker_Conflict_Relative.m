function  parfor_Flanker_Conflict_Relative(IndexSubset, Parentfolder)
% List all Folders
Folders = [dir(fullfile(Parentfolder, '*20.4'));...
    dir(fullfile(Parentfolder, '*20.5')) ];

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
    fprintf('\n*Subset: %s, FoldN2r: %i - Calculating GAV. \n  ', IndexSubset, iFolder)
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
    
    % Nr Electrodes
    NrElectrodes_N2 = length(INPUT.data.For_Relative.Electrodes_N2);
    NrElectrodes_P3 = length(INPUT.data.For_Relative.Electrodes_P3);
    NrElectrodes_FMT = length(INPUT.data.For_Relative.Electrodes_FMT);
    
    % Get correct DP for each Component
    if  strcmp(INPUT.StepHistory.Resampling, "500")
        DP = 176;
        DPP3 = 150;
        DPFMT = 201;
    elseif  strcmp(INPUT.StepHistory.Resampling, "250")
        DP = 88;
        DPP3 = 75;
        DPFMT = 101;
    elseif  strcmp(INPUT.StepHistory.Resampling, "125")
        DP = 45;
        DPP3 = 38;
        DPFMT = 51;
    end
    
    
    % Initiate the GAV relevant to extract the P3ak
    GAV_N2 = NaN(NrElectrodes_N2, ...
        DP,...
        length(Files_Fork));
    GAV_P3 = NaN(NrElectrodes_P3, ...
        DPP3,...
        length(Files_Fork));
    GAV_FMT = NaN(NrElectrodes_FMT, ...
        DPFMT,...
        length(Files_Fork));
    
    
    % Go through each File, load and merge to AV
    for ifile = 1:length(Files_Fork)
        try
            
            Data = load(fullfile( Parentfolder, Folder,Files_Fork(ifile).name));
            Data = Data.Data;
            
            DataN2 = Data.data.For_Relative.Data_N2;
            DataP3 = Data.data.For_Relative.Data_P3;
            DataFMT = Data.data.For_Relative.Data_FMT;
            % Take mean across Trials, as this was not done before
            DataN2 =  mean(DataN2,3);
            DataP3 =  mean(DataP3,3);
            DataFMT =  mean(DataFMT,3);
            
            % Downsample if necessary (only Biosemis)
            if size(DataN2,2)>DP % downsample
                New = [];
                NewP3 = [];
                NewFMT = [];
                for iel = 1:size(DataN2,1)
                    for it = 1:size(DataN2,3)
                        New = [New; interp1(1:size(DataN2,2), DataN2(iel,:,it), linspace(1, size(DataN2,2), DP), 'linear')];
                    end
                end
                for iel = 1:size(DataP3,1)
                    for it = 1:size(DataP3,3)
                        NewP3 = [NewP3; interp1(1:size(DataP3,2), DataP3(iel,:,it), linspace(1, size(DataP3,2), DPP3), 'linear')];
                    end
                end
                for iel = 1:size(DataFMT,1)
                    for it = 1:size(DataFMT,3)
                        NewFMT = [NewFMT; interp1(1:size(DataFMT,2), DataFMT(iel,:,it), linspace(1, size(DataFMT,2), DPFMT), 'linear')];
                    end
                end
                DataN2 = New;
                DataP3 = NewP3;
                DataFMT = NewFMT;
            end
            
            % Merge across Subjects
            GAV_N2(:,:,ifile) = DataN2;
            GAV_P3(:,:,ifile) = DataP3;
            GAV_FMT(:,:,ifile) = DataFMT;
            
            
        catch e
            fprintf('\n*ERROR GAV Subset: %s, FoldN2r: %i: Subject %s. %s \n  ', IndexSubset, iFolder, Files_Fork(ifile).name, string(e.message))
        end
    end
    
    %% ********************************
    % CREATE GAV AND GET TIME WINDOW BASED ON PEAKS ACROSS CONDITIONS
    % *********************************
    GAV_N2 = mean(GAV_N2,3);
    GAV_P3 = mean(GAV_P3,3);
    GAV_FMT = mean(GAV_FMT,3);
    
    
    % Extract Peaks and Determine new Time Window
    iFF = 1;
    while length(INPUT.data.For_Relative.Times_N2)>DP
        iFF = iFF +1;
        INPUT = load(fullfile( Parentfolder, Folder,Files_Fork(iFF).name))
        INPUT = INPUT.Data;
    end
    
    % Extract new Latencies
    Times_N2 = INPUT.data.For_Relative.Times_N2;
    Times_P3 = INPUT.data.For_Relative.Times_P3;
    Times_FMT = INPUT.data.For_Relative.Times_FMT;
    TimeIdx_N2 = findTimeIdx(Times_N2,150, 400);
    TimeIdx_P3 = findTimeIdx(Times_P3, 250, 600);
    TimeIdx_FMT = findTimeIdx(Times_FMT, 200, 500);
    [~, Latency_N2] = Peaks_Detection(mean(GAV_N2(:,TimeIdx_N2,:),1), "NEG");
    [~, Latency_P3] = Peaks_Detection(mean(GAV_P3(:,TimeIdx_P3,:),1), "POS");
    [~, Latency_FMT] = Peaks_Detection(10*log10(mean(GAV_FMT(:,TimeIdx_FMT,:),1)), "POS");
    if  contains(INPUT.StepHistory.TimeWindow, "wide")
        TimeWindow_N2 = [Times_N2(Latency_N2+(TimeIdx_N2(1))) - 50, Times_N2(Latency_N2+(TimeIdx_N2(1))) + 50];
        TimeWindow_P3 = [Times_P3(Latency_P3+(TimeIdx_P3(1))) - 50, Times_P3(Latency_P3+(TimeIdx_P3(1))) + 50];
        TimeWindow_FMT = [Times_N2(Latency_FMT+(TimeIdx_FMT(1))) - 50, Times_FMT(Latency_FMT+(TimeIdx_FMT(1))) + 50];
    else
        TimeWindow_N2 = [Times_N2(Latency_N2+(TimeIdx_N2(1))) - 25, Times_N2(Latency_N2+(TimeIdx_N2(1))) + 25];
        TimeWindow_P3 = [Times_P3(Latency_P3+(TimeIdx_P3(1))) - 25, Times_P3(Latency_P3+(TimeIdx_P3(1))) + 25];
        TimeWindow_FMT = [Times_N2(Latency_FMT+(TimeIdx_FMT(1))) - 25, Times_FMT(Latency_FMT+(TimeIdx_FMT(1))) + 25];
    end
    
    
    fprintf('\n*Subset: %s, Foldernr: %i - Time Window N2: %i - %i. Time Window P3: %i - %i.  \n ', IndexSubset, iFolder, TimeWindow_N2, TimeWindow_P3)
    fprintf('\n*Subset: %s, Foldernr: %i - Time Window FMT: %i - %i.  \n ', IndexSubset, iFolder, TimeWindow_FMT)
    
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
            Electrodes_N2 = INPUT.data.For_Relative.Electrodes_N2;
            Electrodes_P3 = INPUT.data.For_Relative.Electrodes_P3;
            Electrodes_FMT = INPUT.data.For_Relative.Electrodes_FMT;
            
            TimeIdx_N2 = findTimeIdx(INPUT.data.For_Relative.Times_N2,  TimeWindow_N2(1), TimeWindow_N2(2));
            TimeIdx_P3 = findTimeIdx(INPUT.data.For_Relative.Times_P3, TimeWindow_P3(1), TimeWindow_P3(2));
            TimeIdx_FMT = findTimeIdx(INPUT.data.For_Relative.Times_FMT, TimeWindow_FMT(1), TimeWindow_FMT(2));
            
            
            % ********************************************************************************************
            % ****  Extract Data *************************************************************************
            % ********************************************************************************************
            N2_SingleTrial = INPUT.data.For_Relative.Data_N2;
            P3_SingleTrial = INPUT.data.For_Relative.Data_P3;
            FMT_SingleTrial = INPUT.data.For_Relative.Data_FMT;
            
            N2_SingleTrial = mean(N2_SingleTrial(:, TimeIdx_N2,:),2);
            P3_SingleTrial = mean(P3_SingleTrial(:, TimeIdx_P3,:),2);
            FMT_SingleTrial = 10*log10(mean(FMT_SingleTrial(:, TimeIdx_FMT,:),2));
            
            
            
            
            % ********************************************************************************************
            % **** Prepare Output Table    ***************************************************************
            % ********************************************************************************************
            
            % Prepare Export
            colNames_ERP =[strcat("N2_", Electrodes_N2')', ...
                strcat("P3_", Electrodes_P3')', ...
                strcat("FMT_", Electrodes_FMT')'];
            % Reshape to drop Time
            N2_SingleTrial = reshape(N2_SingleTrial,[size(N2_SingleTrial,3),size(N2_SingleTrial,1)]);
            P3_SingleTrial = reshape(P3_SingleTrial,[size(P3_SingleTrial,3),size(P3_SingleTrial,1)]);
            FMT_SingleTrial = reshape(FMT_SingleTrial,[size(FMT_SingleTrial,3),size(FMT_SingleTrial,1)]);
            Single_TrialData_ERP = num2cell([N2_SingleTrial,P3_SingleTrial, FMT_SingleTrial]);
            Single_TrialData_ERP = [colNames_ERP;Single_TrialData_ERP];
            
            OUTPUT.data.Export = [INPUT.data.For_Relative.Behav, Single_TrialData_ERP];
            
            OUTPUT.data.ExportInfo = struct('TimeWindowN2', TimeWindow_N2, ...
                'TimeWindowP3', TimeWindow_P3, ...
                'TimeWindowFMT', TimeWindow_FMT );
            
            
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
            fprintf('\n*Subset: %s, FoldN2r: %i, Subject: %s - Error Extracting ERPs. \n ', IndexSubset, iFolder, INPUT.Subject)

        end
        parfor_save(fullfile(Parentfolder, Folder, Files_Fork(i_Files).name), OUTPUT)
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% DO WHEN ONLY FMT IS RELATIVE, BUT ERPS ARE NOT %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List all Folders
Folders = dir(fullfile(Parentfolder, '*20.1'));

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
fprintf('\nNumber of Paths to analyse for FMT only: %i. \n  ', length(Folders))


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
    
    % Get first File to have a starting point (order, timepoints etc)
    INPUT = load(fullfile(Parentfolder, Folder, Files_Fork(1).name));
    INPUT = INPUT.Data;
    
    % Nr Electrodes
    NrElectrodes_FMT = length(INPUT.data.For_Relative.Electrodes_FMT);
    
    DPFMT =[];
    % Get correct DP for each Component
    if  strcmp(INPUT.StepHistory.Resampling, "500")
        DPFMT = 201;
    elseif  strcmp(INPUT.StepHistory.Resampling, "250")
        DPFMT = 101;
    elseif  strcmp(INPUT.StepHistory.Resampling, "125")
        DPFMT = 51;
    end
    
    
    % Initiate the GAV relevant to extract the P3ak
    GAV_FMT = NaN(NrElectrodes_FMT, ...
        DPFMT,...
        length(Files_Fork));
    
    
    % Go through each File, load and merge to AV
    for ifile = 1:length(Files_Fork)
        try
            Data = load(fullfile( Parentfolder, Folder,Files_Fork(ifile).name));
            Data = Data.Data;
            DataFMT = Data.data.For_Relative.Data_FMT;
            % Take mean across Trials, as this was not done before
            DataFMT =  mean(DataFMT,3);
            
            % Downsample if necessary (only Biosemis)
            if size(DataFMT,2)>DPFMT % downsample
                NewFMT = [];
                for iel = 1:size(DataFMT,1)
                    for it = 1:size(DataFMT,3)
                        NewFMT = [NewFMT; interp1(1:size(DataFMT,2), DataFMT(iel,:,it), linspace(1, size(DataFMT,2), DPFMT), 'linear')];
                    end
                end
                DataFMT = NewFMT;
            end
            
            % Merge across Subjects
            GAV_FMT(:,:,ifile) = DataFMT;
            
            
        catch e
            fprintf('\n*ERROR GAV Subset: %s, FoldN2r: %i: %s \n  ', IndexSubset, iFolder, string(e.message))
        end
    end
    
    %% ********************************
    % CREATE GAV AND GET TIME WINDOW BASED ON PEAKS ACROSS CONDITIONS
    % *********************************
    GAV_FMT = mean(GAV_FMT,3);
    
    
    % Extract Peaks and Determine new Time Window
    iFF = 1;
    while length(INPUT.data.For_Relative.Times_FMT)>DPFMT
        iFF = iFF +1;
        INPUT = load(fullfile( Parentfolder, Folder,Files_Fork(iFF).name));
        INPUT = INPUT.Data;
    end
    
    % Extract new Latencies
    Times_FMT = INPUT.data.For_Relative.Times_FMT;
    TimeIdx_FMT = findTimeIdx(Times_FMT, 200, 500);
    [~, Latency_FMT] = Peaks_Detection(10*log10(mean(GAV_FMT(:,TimeIdx_FMT,:),1)), "POS");
    TimeWindow_FMT = [Times_FMT(Latency_FMT+(TimeIdx_FMT(1))) - 50, Times_FMT(Latency_FMT+(TimeIdx_FMT(1))) + 50];
    fprintf('\n*Subset: %s, Foldernr: %i - Time Window FMT: %i - %i.  \n ', IndexSubset, iFolder, TimeWindow_FMT)
    
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
            Electrodes_FMT = INPUT.data.For_Relative.Electrodes_FMT;
            TimeIdx_FMT = findTimeIdx(INPUT.data.For_Relative.Times_FMT, TimeWindow_FMT(1), TimeWindow_FMT(2));
            
            
            % ********************************************************************************************
            % ****  Extract Data *************************************************************************
            % ********************************************************************************************
            FMT_SingleTrial = INPUT.data.For_Relative.Data_FMT;
            FMT_SingleTrial = 10*log10(mean(FMT_SingleTrial(:, TimeIdx_FMT,:),2));
            
            
            % ********************************************************************************************
            % **** Prepare Output Table    ***************************************************************
            % ********************************************************************************************
            
            % Prepare Export
            colNames_ERP =strcat("FMT_", Electrodes_FMT')';
            % Reshape to drop Time
            FMT_SingleTrial = reshape(FMT_SingleTrial,[size(FMT_SingleTrial,3),size(FMT_SingleTrial,1)]);
            Single_TrialData_ERP = num2cell([FMT_SingleTrial]);
            Single_TrialData_ERP = [colNames_ERP;Single_TrialData_ERP];
            
            OUTPUT.data.Export = [OUTPUT.data.Export, Single_TrialData_ERP];
            OUTPUT.data.ExportInfo = struct('TimeWindowFMT', TimeWindow_FMT );
            
            
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
        parfor_save(fullfile(Parentfolder, Folder, Files_Fork(i_Files).name), OUTPUT)
    end
end


end