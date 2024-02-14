function  parfor_Ultimatum_Fairness(IndexSubset, Parentfolder)
% List all Folders
Folders = [dir(fullfile(Parentfolder, '*19.1*'));...
    dir(fullfile(Parentfolder, '*19.2*')) ];

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
for iFolder = 1:length(Folders)
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
        Electrodes = INPUT.data.For_Relative.Electrodes;
        TimeIdx_FMT = findTimeIdx(INPUT.data.For_Relative.Times_FMT, TimeWindow_FMT(1), TimeWindow_FMT(2));
        TimeIdx_FRN = findTimeIdx(INPUT.data.For_Relative.Times_FRN,  TimeWindow_FRN(1), TimeWindow_FRN(2));
        
        
        % ********************************************************************************************
        % **** Extract Data     FRN  & FMT                 *******************************************
        % ********************************************************************************************
        
        ConditionData_FRN = INPUT.data.For_Relative.Data_FRN(:, TimeIdx_FRN, :);
        ConditionData_FMT = INPUT.data.For_Relative.Data_FMT(:, TimeIdx_FMT, :);
        % ****** Extract Amplitude per Trial ******
        Export_Header = {'ID', 'Lab', 'Experimenter', 'Trial', 'Offer', 'Choice', 'RT', 'Component',  'Electrode', 'EEG_Signal'};
  
        
        ConditionData_FRN = squeeze(mean(ConditionData_FRN, 2))';
        ConditionData_FMT = squeeze(mean(ConditionData_FMT, 2))';
        Electrode_Labels = repmat(INPUT.data.For_Relative.Electrodes, size(ConditionData_FRN,1), 1);
        Constants = repmat({INPUT.Subject, INPUT.data.For_Relative.RecordingLab, ...
            INPUT.data.For_Relative.Experimenter}, ...
            size(ConditionData_FRN,1)*size(ConditionData_FRN,2),1);
  
        
        
        TrialInfo = INPUT.data.For_Relative.TrialInfo;
        NrElectrodes = length(Electrodes)
        Export = [Export_Header; ...
            [Constants,  ...
            repmat(TrialInfo, NrElectrodes, 1), ...
            repmat("FRN", size(ConditionData_FRN,1)*NrElectrodes, 1), ...
            Electrode_Labels(:), ConditionData_FRN(:)];
            [Constants,  ...
            repmat(TrialInfo, NrElectrodes, 1), ...
            repmat("FMT", size(ConditionData_FRN,1)*NrElectrodes, 1), ...
            Electrode_Labels(:), ConditionData_FMT(:)]];
        
        
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
	fprintf(ErrorMessage )
        OUTPUT = INPUT;
    end
end
end
