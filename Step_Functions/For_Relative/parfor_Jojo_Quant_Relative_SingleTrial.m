function  parfor_Jojo_Quant_Relative(IndexSubset, Parentfolder)
% List all Folders
Folders = [dir(fullfile(Parentfolder, '*21.2*'));...
    dir(fullfile(Parentfolder, '*21.3*')) ];

Folders = Folders(~contains({Folders.name}, "ERP"));
Folders = Folders(contains({Folders.name}, "22"));
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
        DP = 151;
        DPFRN = 101;
    elseif  strcmp(INPUT.StepHistory.Resampling, "250")
        DP = 38;
        DPFRN = 50;
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
            Electrodes_FMT = INPUT.data.For_Relative.Electrodes;
            TimeIdx_FMT = findTimeIdx(INPUT.data.For_Relative.Times_FMT, TimeWindow_FMT(1), TimeWindow_FMT(2));
            NrElectrodes = length(Electrodes_FMT);
            Electrodes_FRN = INPUT.data.For_Relative.Electrodes;
            TimeIdx_FRN = findTimeIdx(INPUT.data.For_Relative.Times_FRN,  TimeWindow_FRN(1), TimeWindow_FRN(2));


            % ********************************************************************************************
            % **** Extract Data     FRN  & FMT                 *******************************************
            % ********************************************************************************************
            % ****** Extract Amplitude, SME, Epoch Count ******
            Data_FMT = INPUT.data.For_Relative.Data_FMT(:,TimeIdx_FMT,:);
            ERP_FMT = mean(Data_FMT,2);

            Data_FRN = INPUT.data.For_Relative.Data_FRN(:,TimeIdx_FRN,:);
            ERP_FRN = mean(Data_FRN,2);



            % ****** Prepare Labels ******
            Events = INPUT.data.For_Relative.Events;
            % Electrodes: if multiple electrodes, they simply alternate ABABAB
            Electrodes_FRN_L = repmat(Electrodes_FRN', size(Events,1), 1);
            NrElectrodes_FRN = length(Electrodes_FRN);

            % Time Window are blocked across electrodes and conditions AAAAABBBB
            TimeWindow_FRN_L = repmat(num2str(TimeWindow_FRN), size(Events,1)*NrElectrodes_FRN, 1);

            EpochCount_FRN = repmat(size(Events,1), size(Events,1)*NrElectrodes_FRN, 1);
            Component_FRN_L = repmat('FRN', size(Events,1)*NrElectrodes_FRN, 1);

            ConditionLabels = repelem(Events, NrElectrodes_FRN, 1);
            Export =  [ConditionLabels, cellstr([Electrodes_FRN_L, TimeWindow_FRN_L]),...
                num2cell([ERP_FRN(:), EpochCount_FRN]), cellstr(Component_FRN_L)];


            % Add FMT
            TimeWindow_FMT_L = repmat(num2str(TimeWindow_FMT), size(Events,1)*NrElectrodes_FRN, 1);
            Component_FMT_L = repmat('FMT', size(Events,1)*NrElectrodes_FRN, 1);

            ExportFMT =  [ConditionLabels, cellstr([Electrodes_FRN_L, TimeWindow_FMT_L]),...
                num2cell([ERP_FMT(:), EpochCount_FRN]), cellstr(Component_FMT_L)];

            Export = [Export; ExportFMT];

            % ****** Prepare Table ******
            Export = [[INPUT.data.For_Relative.BehavHeader, 'Electrodes', 'TimeWindow', 'EEG_Signal', 'EpochsTotal', 'Component' ]; Export];
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
