function  parfor_Gambling_N300H_Relative(IndexSubset, Parentfolder)

%clear all
%Parentfolder = pwd
%Folder = pwd

%Parentfolder = 'C:\Users\Paul\Downloads\HummelDownloads\Gambling_relative\Test3'
%IndexSubset = 'even'
Parentfolder = "/work/bay2875/Gambling_N300H/task-Gambling/Data/"
IndexSubset = "all"
% List all Folders

Folders = [dir(fullfile(Parentfolder, '*20.4*'));...
    dir(fullfile(Parentfolder, '*19.3*')) ];

Folders = unique({Folders.name});


IndexSubset=strrep(IndexSubset, " ", "");
% Subset Folders
if strcmp(IndexSubset, "odd")
    Folders = Folders(1:2:length(Folders));
elseif strcmp(IndexSubset, "all")
    Folders = Folders;
else
    Folders = Folders(2:2:length(Folders));
end


%% Calculate CECTs

% ***********************************************************************************
% calculate CECTs for each condition ************************************************
% ***********************************************************************************

% prepare markers and triggers
Condition_Names = {'loss', 'win' };
Condition_Triggers = {'100' '110' '150';...
    '101'  '111' '151'}';
NrConditions = length(Condition_Names);

% In parallel way, for every Forking Combination extract GAV and ERP Values
cfg.segsizeIBI = [-0.5, 5];
cfg.segsizeEEG = [-0.2, 2];
cfg.ibibins = [0, 5];
cfg.eegbins = [0, 1];
cfg.ibibinsize = 100;
cfg.eegbinsize = 5;

cfg_search = cfg;


cfg.ibibinsize = 500;
cfg.eegbinsize = 10;
cfg_applied = cfg;

% Prepare Matlabpool
delete(gcp('nocreate')); % make sure that previous pooling is closed
distcomp.feature( 'LocalUseMpiexec', false );
parpool(12);
%%
parfor iFolder = 777 : 779% length(Folders)%:-1:1
try

    fprintf('\n*Subset: %s, FolderNr: %i - Caclulating GAV. \n  ', IndexSubset, iFolder)
    %% ********************************
    % CREATE GAV (load single files)
    % *********************************
    Folder = Folders{iFolder};
    % List all Files of this forking path
    Files_Fork = dir( fullfile( Parentfolder, Folder,  '*mat' )  );
    Files_Fork = Files_Fork(~contains({Files_Fork.name}, "error" ));
    IBI_window =[];
    EEG_window = [];

    INPUT = load(fullfile(Parentfolder, Folder, Files_Fork(1).name));


    % Get first File to have a starting point (order, timepoints etc)
    is500 = 0; ifile1 = 0;
    while is500 == 0
        ifile1 = ifile1+1;
        INPUT = load(fullfile(Parentfolder, Folder, Files_Fork(ifile1).name));
        INPUT = INPUT.Data;
        if ismember(INPUT.data.For_Relative.DataEEG.srate, [500, 250, 125])
            is500 = 1;
        end
    end

    EEG = INPUT.data.For_Relative.DataEEG;
    ECG = INPUT.data.For_Relative.DataECG;

    % Define settings for CECT analysis
    cfg = cfg_search;
    cfg.srateEEG = EEG.srate;
    cfg.srateIBI = ECG.srate;
    % just to initialize size
    cect = CECT(EEG.data, squeeze(ECG.data(1,:,:)), cfg);

    Electrodes = INPUT.data.For_Relative.Electrodes;
    if strcmp(INPUT.StepHistory.Cluster_Electrodes,"cluster")
        NrElectrodes = 1;
    else
        NrElectrodes = length(strsplit(INPUT.StepHistory.Electrodes, ','));
    end

    % initialize cect
    cect= nan([NrElectrodes, size(cect, [2,3]), length(Files_Fork)]);

    for ifile = 1: length(Files_Fork)
        try
            Data = load(fullfile( Parentfolder, Folder,Files_Fork(ifile).name));
            Data.srate = Data.Data.data.For_Relative.DataEEG.srate;
    	    Data.event = Data.Data.data.For_Relative.DataEEG.event;
            EEG = Data.Data.data.For_Relative.DataEEG.data;
       	    ECG = Data.Data.data.For_Relative.DataECG.data(1,:,:);

            % if Sampling Rate not 500 250 or 125, resample
            if Data.srate == 512
                EEG =  downsample_quick(EEG, 1100);
                ECG =  downsample_quick(ECG, 2750);
            elseif Data.srate== 256
                EEG =  downsample_quick(EEG, 550);
                ECG =  downsample_quick(ECG, 1375);
            elseif Data.srate == 128
                EEG =  downsample_quick(EEG, 275);
                ECG =  downsample_quick(ECG, 688);
            end


            % find index of relevant condition triggers within the EEG.event structure
            idx = []; idx=find(contains({Data.event.type}, Condition_Triggers(:)));

            if length(idx) < 2
                fprintf("Careful: File %s could not be added to GAV of Folder because less than two trials. %s \n", Files_Fork(ifile).name, Folder)
                continue
            end

            % if cluster electrodes but not AV yet
            if strcmp(INPUT.StepHistory.Cluster_Electrodes,"cluster") & size(EEG,1)>1
                EEG = mean(EEG, 1);
            end

            % calculate CECTS via CECT.m and save results for each condition in
            % a "cect results" structure
            cect(:,:,:,ifile) =  CECT(EEG(:,:,idx), squeeze(ECG(1,:,idx)), cfg);
        catch e

            fprintf("Careful: File %s could not be added to GAV of Folder %s , Error: %s\n", Files_Fork(ifile).name, Folder, e.message)
        end

    end


    %% ********************************
    % CREATE GAV AND GET TIME WINDOW BASED ON PEAKS
    % *********************************
    cect_GAV = mean(cect, [1,4], 'omitnan');
    cect = [];

    % get time points for each bin
    % IBI
    id_Time =  round((cfg.ibibins(1)  - cfg.segsizeIBI(1)) * cfg.srateIBI);
    id2_Time =     round((cfg.ibibins(1) - cfg.segsizeIBI(1) + cfg.ibibins(2)) * cfg.srateIBI);
    no_bins = round(length(id_Time : id2_Time)/(cfg.ibibinsize/1000*cfg.srateIBI));
    bin_range = round(linspace(1,length(id_Time : id2_Time),no_bins+1));
    BinStarts_IBI =  Data.Data.data.For_Relative.DataECG.times(bin_range(1:length(bin_range)-1) + id_Time);
    binWidth_IBI = round((BinStarts_IBI(2)-BinStarts_IBI(1))/2);
    % EEG
    id_Time =  round((cfg.eegbins(1)  - cfg.segsizeEEG(1)) * cfg.srateEEG);
    id2_Time =     round((cfg.eegbins(1) - cfg.segsizeEEG(1) + cfg.eegbins(2)) * cfg.srateEEG);
    no_bins = round(length(id_Time : id2_Time)/(cfg.eegbinsize/1000*cfg.srateEEG));
    bin_range = round(linspace(1,length(id_Time : id2_Time),no_bins+1));
    BinStarts_EEG = Data.Data.data.For_Relative.DataEEG.times(bin_range(1:length(bin_range)-1) + id_Time);
    binWidth_EEG = round((BinStarts_EEG(2)-BinStarts_EEG(1))/2);

    % if EEG window clear, only check that one
    if ~contains(INPUT.StepHistory.TimeWindow ,"Relative_Group")
        EEG_window = [str2num(INPUT.StepHistory.TimeWindow)];
        [~, EEG_bin] = min(abs(BinStarts_EEG - EEG_window')');
        cect_GAV = cect_GAV(:,EEG_bin, :);
    end

    % is ECG bin relative?
    if contains(INPUT.StepHistory.ECG_TimeWindow ,"Relative_Group")
        [~, IBI_idmin] =min(squeeze(mean(cect_GAV,2)));
        MinTime = BinStarts_IBI(IBI_idmin) + binWidth_IBI;
        IBI_window = [MinTime-500, MinTime+500];
        if any(IBI_window < 0 )
            IBI_window = IBI_window - min(IBI_window);
        end
    else
        IBI_window = [str2num(INPUT.StepHistory.ECG_TimeWindow)];
    end

    % if EEG window is relative, find it here
    if contains(INPUT.StepHistory.TimeWindow ,"Relative_Group")
        [~, EEG_idmin] =    min(squeeze(mean(cect_GAV,3)));
        MinTime = BinStarts_EEG(EEG_idmin) + binWidth_EEG;
        EEG_window = [MinTime-100, MinTime+100];
        if any(EEG_window < 0 )
            EEG_window = EEG_window - min(EEG_window);
        end
        if any(EEG_window > 1000 )
            EEG_window = EEG_window - (max(EEG_window) -1000);
        end
    end

    % make IBI to closest 500
    IBI_window = floor(IBI_window/500)*500;
    % make EEG to closest 10
    EEG_window = floor(EEG_window/10)*10;

    fprintf('\n*Subset: %s, FolderNr: %i - Time Window ECG: %i - %i. Time Window EEG: %i - %i.  \n ', IndexSubset, iFolder, IBI_window, EEG_window)


    %% ********************************
    % Loop through each file
    % *********************************

    for i_Files = 1 : length(Files_Fork)
        INPUT = load(fullfile(Parentfolder, Folder,Files_Fork(i_Files).name));
        INPUT = INPUT.Data;
        OUTPUT = INPUT;
        OUTPUT.data=[];


        % Some Error Handling
        try
            Choice = INPUT.StepHistory.Quantification_ERP;
            EEG = INPUT.data.For_Relative.DataEEG.data;
            ECG = INPUT.data.For_Relative.DataECG.data(1,:,:);
            cfg = cfg_applied;
            cfg.srateEEG = INPUT.data.For_Relative.DataEEG.srate;
            cfg.srateIBI = INPUT.data.For_Relative.DataEEG.srate;



            % Check if electrodes are averaged (!)before extracting the N300H,
            % i.e. before calculating intra-individual correlations:
            Electrodes = INPUT.data.For_Relative.Electrodes;
            % Check if electrodes are averaged (!)before extracting the N300H,
            % i.e. before calculating intra-individual correlations:
            if strcmp(INPUT.StepHistory.Cluster_Electrodes,"cluster")

                % Calculate average of electrodecluster and save it as channel 1 in
                % EEG.data matrix
                EEG = mean(EEG,1);
       	        NrElectrodes = 1;
            else
                NrElectrodes = length(strsplit(INPUT.StepHistory.Electrodes, ','));
            end




            Epochs = nan(size(Condition_Triggers,2),1);
            cect.results = [];

            for i = 1:size(Condition_Triggers,2)

                % find index of relevant condition triggers within the EEG.event structure
                idx = []; idx=find(contains({INPUT.data.For_Relative.DataEEG.event.type}, Condition_Triggers(:,i)));

                % get number of epochs
                Epochs(i,1) = length(idx);
                if length(idx)<=1
                    cect.results.(Condition_Names{i}) = nan(NrElectrodes, 100,10);
                    continue
                end

                % calculate CECTS via CECT.m and save results for each condition in
                % a "cect results" structure
                cect.results.(Condition_Names{i}) = ...
                    CECT(EEG(:,:,idx), squeeze(ECG(1,:,idx)), cfg);

            end
            % save the employed CECT settings into the cect results structure
            cect.settings = cfg;


            % IBI
            % Translate given time windows from ms into CECT bins
            % IBI_window as well as the ibi- and eegbin size are given in ms
            BinsIBI = IBI_window/cfg.ibibinsize; BinsIBI(1) = BinsIBI(1)+1;
            % EEG
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

            % Check if Electrodes are averaged (!) after CECT
            % Update Nr on Electrodes for Final OutputTable if Clustered after N300H
            if INPUT.StepHistory.Cluster_Electrodes == "no_cluster_butAV"
                NrElectrodes = 1;
                Electrodes = append('AV_of: ', join(Electrodes));
                Electrodes = strrep(Electrodes, 'AV_of: AV_of:', 'AV_of: ');
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


            % ********************************************************************************************
            % **** Prepare Output Table    ***************************************************************
            % ********************************************************************************************




            % Prepare Final Export with all Values
            % ****** Prepare Labels ******
            % Subject, ComponentName, Lab, Experimenter, Scoring is constant AAA
            Subject_L = repmat(INPUT.Subject, NrConditions*NrElectrodes*NrBins,1 );
            Lab_L = repmat(INPUT.data.For_Relative.RecordingLab, NrConditions*NrElectrodes*NrBins,1 );
            Experimenter_L = repmat(INPUT.data.For_Relative.Experimenter, NrConditions*NrElectrodes*NrBins,1 );
            Component_L = repmat("N300H", NrConditions*NrElectrodes*NrBins,1 );
            Scoring_L = repmat(Choice, NrConditions*NrElectrodes*NrBins,1 );
            TimeWindow_L = repmat(num2str(EEG_window), NrConditions*NrElectrodes*NrBins, 1);
            TimeWindowECG_L = repmat(num2str(IBI_window), NrConditions*NrElectrodes*NrBins, 1);


            % Electrodes: if multiple electrodes, they simply alternate ABABAB
            if any(contains(Electrodes, 'AV_'))
                Electrodes_L = repmat(Electrodes, NrConditions*NrBins, 1);
            else
                Electrodes_L = repmat(Electrodes', NrConditions*NrBins, 1);
            end

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
            if Choice == "Bins"
                OUTPUT.data.Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L, ...
                    Electrodes_L, TimeWindow_L, TimeWindowECG_L, Scoring_L]),...
                    num2cell([N300H(:),  EpochCount(:)]), Bin_L, cellstr(Component_L)];
            else

                OUTPUT.data.Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L, ...
                    Electrodes_L, TimeWindow_L, TimeWindowECG_L, Scoring_L]),...
                    num2cell([N300H(:),  EpochCount(:)]), Bin_L(:), cellstr(Component_L)];
            end

              parfor_save(fullfile(Parentfolder, Folder, Files_Fork(i_Files).name), OUTPUT)
            % ****** Error Management ******
       catch e
            %If error ocurrs, create ErrorMessage(concatenated for all nested
            %errors). This string is given to the OUTPUT struct.
           ErrorMessage = string(e.message);
           for ierrors = 1:length(e.stack)
               ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
           end

           OUTPUT.Error = ErrorMessage;
           fprintf('\n*Subset: %s, FolderNr: %i, Subject: %s - Error Extracting N300H. %s \n ', IndexSubset, iFolder, INPUT.Subject, Folder)
           % parfor_save(fullfile(Parentfolder, Folder, strrep(Files_Fork(i_Files).name, '.mat', '_error.mat')), OUTPUT)
           disp(ErrorMessage)
       end

    end
end

end

