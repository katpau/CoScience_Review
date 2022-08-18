function  OUTPUT = Quantification_ERP(INPUT, Choice)
% This script does the following:
% Based on information of previous steps, and depending on the forking
% choice, ERPs are quantified based on Mean/Peak etc.
% Script also extracts Measurement error and reshapes Output to be easily
% merged into a R-readable Dataframe for further analysis.
%#####################################################################
%### Usage Information                                         #######
%#####################################################################
% This function requires the following inputs:
% INPUT = structure, containing at least the fields "Data" (containing the
%       EEGlab structure, "StephHistory" (for every forking decision). More
%       fields can be added through other preprocessing steps.
% Choice = string, naming the choice run at this fork (included in "Choices")
%
% This function gives the following output:
% OUTPUT = struct, similiar to the INPUT structure. StepHistory and Data is
%           updated based on the new calculations. Additional fields can be
%           added below


%#####################################################################
%### Summary from the DESIGN structure                         #######
%#####################################################################
% Gives the name of the Step, all possible Choices, as well as any possible
% Conditional statements related to them ("NaN" when none applicable).
% SaveInterim marks if the results of this preprocessing step should be
% saved on the harddrive (in order to be loaded and forked from there).
% Order determines when it should be run.
StepName = "Quantification_ERP";
Choices = ["Mean", "Peak", "Mean_around_Subject_Peak", "Peak_around_GAV_Peak", "Mean_around_GAV_Peak_wide", "Mean_around_GAV_Peak_narrow"];
Conditional = ["NaN", "NaN", "TimeWindow == ""200,500"" ", "TimeWindow == ""200,500""", "TimeWindow == ""200,500""", "TimeWindow == ""200,500"""];
SaveInterim = logical([1]);
Order = [22];

%%%%%%%%%%%%%%%% Updating the SubjectStructure. No changes should be made here.
INPUT.StepHistory.Quantification_ERP = Choice;
OUTPUT = INPUT;
% Some Error Handling
try
    %%%%%%%%%%%%%%%% Routine for the analysis of this step
    % This functions starts from using INPUT and returns OUTPUT
    % If this is the first step, make sure you use Subject Name to load corresponding files.
    % Information from previous steps can be saved to (and later retrieved from) INPUT.Miscellaneous ??????
    % INSERT YOUR ANALYSIS SCRIPT HERE: 
    EEG = INPUT.data;
    
    % **** Get Info on Peaks ******
    PeakValence = "POS"

    
    % **** Get Info on Conditions ******
    Conditions = EEG.Conditions;
    NrConditions = length(Conditions);
    
    % **** Get Info on Electrodes ******
    Electrodes = upper(strsplit(INPUT.StepHistory.Electrodes , ", "));
    NrElectrodes = length(Electrodes);
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        NrElectrodes = 1;
        Electrodes = strcat('Cluster  ', join(Electrodes));
    end
    
    % ****** Get Info on TimeWindow ******
    TimeWindow = INPUT.StepHistory.TimeWindow;
    TimeWindow = str2double(strsplit(TimeWindow, ","));
    
    
    % ****** Refine Time Window when relative to Peaks ******
    % Window can be dependent on Subject Peak or GAV peak
    if contains(Choice, "around") 
        % Window dependent on Single Subject ERP
        if strcmp(Choice, "Mean_around_Subject_Peak")
            Peak_EEG = INPUT.ERP;  
        % Window dependent on GAV ERP
        else
            Peak_EEG = INPUT.GAV;  
        end
        
        % Define new Time Window. Used to temporarily subset data 
        [~, TimeIdx(1)]=min(abs(Peak_EEG.times - TimeWindow(1)));
        [~, TimeIdx(2)]=min(abs(Peak_EEG.times - TimeWindow(2)));
        TimeIdx = TimeIdx(1):TimeIdx(2);
            
        % Subset Data from ERP to get peak in condition difference 
        % only during relevant time window
        Subset = zeros(size(Peak_EEG.data(:,length(TimeIdx),:,1), 1));
        % mean across conditions and electrodes; Difference Error - Correct
        Subset = squeeze(mean(mean(Peak_EEG.data(:,TimeIdx,:,[3,4]), 1), 4)) -  ...
            squeeze(mean(mean(Peak_EEG.data(:,TimeIdx,:,[1,2]), 1), 4));
        % Find Peak in this Subset
        [~, Latency] = Peaks_Detection(Subset, PeakValence);           
            
        % Redefine the Time Window based on the latency of the peak in the subset (in ms)
        if strcmp(Choice, "Mean_around_GAV_Peak_wide") % Wide GAV window
            WindowLength = 50;
        else % Narrower GAV window, single subject window
            WindowLength = 25;
        end
        % (TimeIdx must be added as Latency is counted within the Subset)
        TimeWindow = [Peak_EEG.times(Latency+(TimeIdx(1))) - WindowLength, Peak_EEG.times(Latency+(TimeIdx(1))) + WindowLength];  
    end
    
    
    if length(TimeWindow)== 2
        % Find Index of Timepoints
        NrTimeWindows = 1;
        [~,TimeIdx(1)] = min(abs(EEG.times - TimeWindow(1)));
        [~,TimeIdx(2)] = min(abs(EEG.times - TimeWindow(2)));
        TimeIdx = TimeIdx(1) : TimeIdx(2);
    else
        % Pe has one option with two time windows
        NrTimeWindows = 2;
        TwoTimeWindows = strsplit(INPUT.StepHistory.TimeWindow, ";");
        
        % First Time Window
        TimeWindow = str2double(strsplit(TwoTimeWindows(1), ","));
        % Find Index of Timepoints
        [~,TimeIdx(1)] = min(abs(EEG.times - TimeWindow(1)));
        [~,TimeIdx(2)] = min(abs(EEG.times - TimeWindow(2)));
        TimeIdx = TimeIdx(1) : TimeIdx(2);
        
        % Second Time Window
        TimeWindow2 = str2double(strsplit(TwoTimeWindows(2), ","));
        % Find Index of Timepoints
        [~,TimeIdx2(1)] = min(abs(EEG.times - TimeWindow2(1)));
        [~,TimeIdx2(2)] = min(abs(EEG.times - TimeWindow2(2)));
        TimeIdx2 = TimeIdx2(1) : TimeIdx2(2);
        
        % Merge Windows for Labels later
        TimeWindow = [TwoTimeWindows(1);TwoTimeWindows(2)];
    end
    
    
    
    
    % ****** Extract Amplitude, SME, Epoch Count ******
    InitSize = [NrElectrodes,NrConditions, NrTimeWindows];
    EpochCount = NaN(InitSize); ERP =NaN(InitSize); SME=NaN(InitSize);
        
    % Select only relevant data (during relevant time period)
    Data =  EEG.data(:, TimeIdx, :, :);
    % for the PE there might be a second subset for the second timewindow
    if NrTimeWindows == 2
        Data2 =  EEG.data(:, TimeIdx2, :, :);
    end
    
    % extract Information for every Condition
    for iCondition = 1:NrConditions
        % Count Epochs
        NrEpochs = max(find(~isnan(Data(1,1,:,iCondition)))); 
        % Check if Epochs are included otherwise set to 0
        if isempty(NrEpochs)
            NrEpochs = 0;
        end
        % Remove Nan Filled Trials!
        EpochCount(:, iCondition, :) = NrEpochs;
        
        % Select relevant data for this condition
        Subset = zeros(NrElectrodes, length(TimeIdx), NrEpochs, 1);
        Subset = Data(:, :, [1:NrEpochs], iCondition);
        % for the second PE window
        if  NrTimeWindows == 2
            Subset2 = zeros(NrElectrodes, length(TimeIdx2), NrEpochs, 1);
            Subset2 = Data2(:, :, [1:NrEpochs], iCondition);
        end
        
         % check if Electrodes should be averaged across, or kept separat
        if INPUT.StepHistory.Cluster_Electrodes == "cluster"
            Subset = mean(Subset, 1); % first dimensions are Electrodes
            if NrTimeWindows == 2
                Subset2 = mean(Subset2, 1);
            end
        end
        
        % Check if minimum number of trials are included, otherwise keep NAN
        if  NrEpochs >= str2double(INPUT.StepHistory.Trials_MinNumber)
            % extract Peak (using custom functions, see below)
            if strcmp(Choice, "Peak") || strcmp(Choice, "Peak_around_GAV_Peak")
                ERP(:,iCondition, 1) = Peaks_Detection(squeeze(mean(Subset,3)), PeakValence);
                SME(:,iCondition, 1) = Peaks_SME(Subset, PeakValence);
                
                if NrTimeWindows == 2
                    ERP(:,iCondition, 2) = Peaks_Detection(squeeze(mean(Subset2,3)), PeakValence);
                    SME(:,iCondition, 2) = Peaks_SME(Subset2, PeakValence);
                end
                
            % extract Mean & SME (custom function for SME, see below)
            else 
                ERP(:,iCondition,1) = mean(mean(Subset,3),2);
                SME(:,iCondition,1) = Mean_SME(Subset);
                
                if NrTimeWindows == 2
                    ERP(:,iCondition,2) = mean(mean(Subset2,3),2);
                    SME(:,iCondition,2) = Mean_SME(Subset2);
                end
            end
        end
    end
    
    % ****  Prepare Output Table **** 
    % in Format Subject - Condition - Electrode - TimeWindow - ERP - SME - Epoch Count - ACC
    % Prepare Labels  
    % Electrodes: if multiple electrodes, they simply alternate
    Electrodes_L = repmat(Electrodes', NrConditions*NrTimeWindows, 1); 
    % Conditions are blocked across electrodes, but alternate across time windows
    Conditions_L = repelem(Conditions', NrElectrodes,1); 
    Conditions_L = repmat([Conditions_L(:)], NrTimeWindows,1);
    % Time Window are blocked across electrodes and conditions
    TimeWindow_L = repmat(num2str(TimeWindow(1,:)), NrConditions*NrElectrodes, 1);
    if NrTimeWindows == 2
        TimeWindow_L = [TimeWindow_L; repmat(num2str(TimeWindow(2,:)), NrConditions*NrElectrodes, 1)];
    end
    % Subject is constant
    Subject_L = repmat(INPUT.SubjectName, NrConditions*NrElectrodes*NrTimeWindows,1 ); 
    
    % Prepare Table
    ERP_Table = cellstr([Subject_L, Conditions_L, Electrodes_L, TimeWindow_L]);
    % Add ERP, SME, Epoch Count
    ERP_Table = [ERP_Table, num2cell([ERP(:), SME(:), EpochCount(:)])];
    % Add ACC
    ERP_Table = [ERP_Table, num2cell(repmat(INPUT.ACC, size(ERP_Table,1), 1))];
    
    
    % ASSIGN what should be saved for the next step:
    % e.g. OUTPUT.data = EEG;
    OUTPUT.data = []; % remove old EEG data
    OUTPUT.data = ERP_Table; % save new structure
    
    
    % ****** Error Management ******
catch e
    % If error ocurrs, create ErrorMessage(concatenated for all nested
    % errors). This string is given to the OUTPUT struct.
    ErrorMessage = string(e.message);
    for ierrors = 1:length(e.stack)
        ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
    end
    
    if ~isfield(INPUT, 'GAV') & contains(Choice, "GAV")
        ErrorMessage = strcat( "Note: GAV has not been precomputed. //", ErrorMessage);
    end
    
    
    OUTPUT.Error = ErrorMessage;
end
end


%% house built functions to detect peaks (and bootstrap SME)
function [Peaks, Latency] = Peaks_Detection(Subset, PeakValence)
if PeakValence == "NEG"
    % Find possible Peak
    possiblePeaks = islocalmin(Subset,2);
    Subset(~possiblePeaks) = NaN;
    % Identify largest Peak
    [Peaks, Latency]  = min(Subset,[],2);
    
elseif PeakValence == "POS"
    % Find Possible Peak
    possiblePeaks = islocalmax(Subset,2);
    Subset(~possiblePeaks) = NaN;
    % Identify largest Peak
    [Peaks, Latency]  = max(Subset,[],2);
end
end

% SME of Peaks
function SME = Peaks_SME(Subset, Component)
% similiar to ERPlab toolbox
% Initate some variables
n_boots = 10000;
replacement = 1;
trials = size(Subset,3);
electrodes = size(Subset,1);
Peak_perTrial = NaN(electrodes,trials);
% Bootstrap and create different ERPS, pick peaks
for i_bs = 1:n_boots
    rng(i_bs, 'twister')
    bs_trialidx = sort(randsample(1:trials,trials,replacement));
    bs_ERP = squeeze(mean(Subset(:,:,bs_trialidx),3));
    Peak_perTrial(:,i_bs) = Peaks_Detection(bs_ERP, Component);
end
% use sd of this distribution for SME
SME = std(Peak_perTrial, [], 2);
end

% SME of Mean Values
function SME = Mean_SME(Subset)
% Calculate Mean per Trial
Mean_perTrial = squeeze(mean(Subset,2));
% Take SD of these means
if size(Mean_perTrial,2) == 1
    SME = std(Mean_perTrial,[],1)/sqrt(length(Mean_perTrial));
else
    SME = std(Mean_perTrial,[],2)/sqrt(length(Mean_perTrial));
end
end
