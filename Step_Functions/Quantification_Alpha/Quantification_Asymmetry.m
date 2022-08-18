function  OUTPUT = Quantification_Asymmetry(INPUT, Choice)
% This script does the following:
% Depending on the forking choice, it uses the choices from the previous
% steps to quantify Alpha Asymmetry
% It is able to handle all options from "Choices" below (see Summary).


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
StepName = "Quantification_Asymmetry";
Choices = ["diff", "separate"];
Conditional = ["NaN", "NaN"];
SaveInterim = logical([0]);
Order = [22];

%****** Updating the OUTPUT structure ******
INPUT.StepHistory.Quantification_Asymmetry = Choice;
OUTPUT = INPUT;
tic
try
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    
    
    % ****** Epoch the Data into seperate Conditions if necessary ******
    Conditions = fieldnames(INPUT.data);
    
    if any(contains(Conditions, 'Gambling_Anticipation'))
        Relevant_Triggers = [100,  101;      110,   111;        150,   151];
        Condition_Names = "Gambling_Anticipation_" +["0";    "10";   "50"];
        try
            for i_cond = 1:length(Condition_Names)
                EEG = pop_selectevent(INPUT.data.Gambling_Anticipation, 'type',Relevant_Triggers(i_cond,:),'deleteevents','off','deleteepochs','on','invertepochs','off');
                INPUT.data.(Condition_Names(i_cond)) = EEG;
            end
        end
        INPUT.data = rmfield(INPUT.data,'Gambling_Anticipation');
    end
    
    if any(contains(Conditions, 'Gambling_Consumption'))
        Relevant_Triggers = [100; 101;  110; 111; 150; 151];
        Condition_Names = "Gambling_Consumption_" + ["0_Loss";"10_Loss";"50_Loss"; "0_Win";"10_Win";"50_Win" ];
        try
            for i_cond = 1:length(Condition_Names)
                EEG = pop_selectevent(INPUT.data.Gambling_Consumption, 'type',Relevant_Triggers(i_cond,:),'deleteevents','off','deleteepochs','on','invertepochs','off');
                INPUT.data.(Condition_Names(i_cond)) = EEG;
            end
        end
        INPUT.data = rmfield(INPUT.data,'Gambling_Consumption');
    end
    
    if any(contains(Conditions, 'Stroop_Anticipation'))
        Condition_Names = "Stroop_Anticipation_" + ["Tree"; "EroticCouple"; "EroticMan"; ...
            "NeutralManWoman"; "NeutralCouple"; "PositiveManWoman"; "EroticWoman"];
        Event_Names = ["post_tree"; "post_erotic_couple"; "post_erotic_man"; ...
            "post_neutral_man_woman"; "post_neutral_couple";  "post_positive_man_woman";  "post_erotic_woman"];
        
        try
            for i_cond = 1:length(Condition_Names)
                EEG = pop_selectevent( INPUT.data.Stroop_Anticipation, 'epoch',find([INPUT.data.Stroop_Anticipation.event.Post_TrialCondition] == Event_Names(i_cond)) ,'deleteevents','off','deleteepochs','on','invertepochs','off');
                INPUT.data.(Condition_Names(i_cond)) = EEG;
            end
        end
        INPUT.data = rmfield(INPUT.data,'Stroop_Anticipation');
    end
    
    if any(contains(Conditions, 'Stroop_Consumption'))
        Relevant_Triggers = [11, 12, 13, 14, 15, 16, 17, 18; ...
            21,  22, 23, 24, 25, 26, 27,  28;...
            31, 32, 33, 34,  35, 36, 37,  38;...
            41, 42, 43, 44,  45, 46, 47, 48;...
            51, 52, 53, 54, 55, 56, 57, 58;...
            61, 62,  63,  64, 65, 66, 67, 68;...
            71,  72, 73, 74, 75, 76, 77, 78];
        
        Condition_Names = "Stroop_Consumption_" + ["Tree"; "EroticCouple"; "EroticMan"; ...
            "NeutralManWoman"; "NeutralCouple"; "PositiveManWoman"; "EroticWoman"];
        try
            for i_cond = 1:length(Condition_Names)
                EEG = pop_selectevent(INPUT.data.Stroop_Consumption, 'type',Relevant_Triggers(i_cond,:),'deleteevents','off','deleteepochs','on','invertepochs','off');
                INPUT.data.(Condition_Names(i_cond)) = EEG;
            end
        end
        INPUT.data = rmfield(INPUT.data,'Stroop_Consumption');
    end
    
    if any(strcmp(fieldnames(INPUT.data), 'EEG')) && contains(INPUT.AnalysisName, 'Resting')
        INPUT.data.Resting = INPUT.data.EEG;
        INPUT.data = rmfield(INPUT.data,'EEG');
    end
    
    
    % ****** After Updating, get new Names of Conditions ******
    Conditions = fieldnames(INPUT.data);
    
    
    
    % ****** Define minimum number of data ******
    % Depends on Task/Condition/Choice of previous step
    MinData =[];
    for icond = 1:length(Conditions)
        if INPUT.StepHistory.MinimumData == "MoreStrict"
            if contains(Conditions{icond}, "Resting")
                MinData = [MinData, 120 * INPUT.data.Resting.pnts/INPUT.data.Resting.srate];
            elseif  contains(Conditions{icond}, "Gambling_Anticipation")
                MinData = [MinData, 40]; 
            elseif  contains(Conditions{icond}, "Gambling_Consumption")
                MinData = [MinData, 20];
            elseif  contains(Conditions{icond}, "Stroop_Anticipation")
                MinData = [MinData, 28];
            elseif  contains(Conditions{icond}, "Stroop_Consumption")
                MinData = [MinData, 28]; 
            end
        else % not strict
            if  contains(Conditions{icond},  "Resting")
                MinData = [MinData, 60 * INPUT.data.Resting.pnts/INPUT.data.Resting.srate];
            elseif  contains(Conditions{icond}, "Gambling_Anticipation")
                MinData = [MinData, 20];
            elseif  contains(Conditions{icond}, "Gambling_Consumption")
                MinData = [MinData, 14];
            elseif  contains(Conditions{icond}, "Stroop_Anticipation")
                MinData = [MinData, 14];
            elseif  contains(Conditions{icond},  "Stroop_Consumption")
                MinData = [MinData, 14];
            end
        end
    end
    
    
    
    
    %#####################################################################
    %### Prepare Output Labels                                     #######
    %#####################################################################
    Electrodes = strsplit(INPUT.StepHistory.Electrodes, ',');
    if INPUT.StepHistory.Quantification_Asymmetry == "diff"
        NrAlphas = 1;
        switch INPUT.StepHistory.Electrodes
            case "F3,F4"
                ElectrodeNames = ["F4-F3"];
                Localisation = "Frontal";
                
                
            case "F3,F4,F5,F6,AF3,AF4"
                if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                    ElectrodeNames = ["F4,F6,AF4-F3,F5,AF3"];
                    Localisation = "Frontal";
                    
                else
                    ElectrodeNames = ["F4-F3", "F6-F5", "AF4-AF3"];
                    Localisation = ["Frontal","Frontal","Frontal"];
                end
                
            case "F3,F4,P3,P4"
                ElectrodeNames = ["F4-F3", "P4-P3"];
                Localisation = ["Frontal", "Parietal"];
                
                
            case "F3,F4,F5,F6,AF3,AF4,P3,P4,P5,P6,PO3,PO4"
                if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                    ElectrodeNames = ["F4,F6,AF4-F3,F5,AF3", "P4,P6,PO4-P3,P5,PO3"];
                    Localisation = ["Frontal", "Parietal"];
                else
                    ElectrodeNames = ["F4-F3", "F6-F5", "AF4-AF3", "P4-P3", "P6-P5", "PO4-PO3"];
                    Localisation = ["Frontal", "Frontal", "Frontal", "Parietal", "Parietal", "Parietal"];
                end
        end
        AlphaType = repmat("diff", size(Localisation));
        
    elseif INPUT.StepHistory.Quantification_Asymmetry == "separate"
        switch  INPUT.StepHistory.Electrodes
            case "F3,F4"
                ElectrodeNames = Electrodes;
                Localisation = repmat("Frontal",1,length(Electrodes));
                AlphaType = ["left", "right"];
                
            case "F3,F4,F5,F6,AF3,AF4"
                if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                    ElectrodeNames = ["F3,F5,AF3", "F4,F6,AF4"];
                    Localisation = ["Frontal", "Frontal"];
                    AlphaType = ["left", "right"];                  
                else
                    ElectrodeNames = Electrodes;
                    Localisation = repmat("Frontal",1,length(Electrodes));
                    AlphaType = repmat(["left", "right"],1,length(Electrodes)/2);
                end
                
                
            case "F3,F4,P3,P4"
                ElectrodeNames = Electrodes;
                Localisation = ["Frontal", "Frontal", "Parietal" "Parietal"];
                AlphaType = ["left", "right", "left", "right"];
                
            case "F3,F4,F5,F6,AF3,AF4,P3,P4,P5,P6,PO3,PO4"
                if INPUT.StepHistory.Cluster_Electrodes == "cluster"
                    ElectrodeNames = ["F3,F5,AF3", "F4,F6,AF4", "P3,P5,PO3", "P4,P6,PO4"];
                    Localisation = ["Frontal","Frontal", "Parietal", "Parietal"];
                    AlphaType = ["left",  "right", "left", "right"];
                    
                else
                    ElectrodeNames = Electrodes;
                    Localisation = sort(repmat(["Frontal", "Parietal"],1,6));
                    AlphaType = repmat(["left", "right"],1,6);
                end
        end
        
    end
    
    
    %#####################################################################
    %### Start FFT                                                 #######
    %#####################################################################
    % ****** Electrodes the same for all Conditions ******
    EEG = INPUT.data.(Conditions{1}); % get one EEG file to index Electrodes
    
    % Get Info on Electrodes ******
    ElectrodeIdx = zeros(1, length(Electrodes));
    for iel = 1:length(Electrodes)
        [~, ElectrodeIdx(iel)] = ismember(Electrodes(iel), {EEG.chanlocs.labels}); % Do it in this loop to maintain matching/order of Name and Index!
    end
    
    NrElectrodes = length(Electrodes);   
    % ****** Run FFT ******
    % for each condition (they might vary in length and nr of trials, run fft and prepare output)
    % Iniate Output Array
    % Get max Points = Max Freqs across Conditions
    MaxPoints = [];
    for i_cond = 1:length(Conditions); MaxPoints = [MaxPoints,     INPUT.data.(Conditions{icond}).pnts]; end
    MaxPoints = max(MaxPoints);
    NrFreqs = 2^nextpow2(MaxPoints)/2+1;
    power_AllConditions = repmat(NaN, NrElectrodes, NrFreqs, EEG.trials, length(Conditions));
    frequencies = [];
    Trials = [];
    
    for i_cond = 1:length(Conditions)
        EEG = INPUT.data.(Conditions{i_cond});
        Trials(i_cond) = EEG.trials; % used for bookkeeping later
        % ****** Get Info on Frequency Band ******
        FrequencyChoice = INPUT.StepHistory.FrequencyBand;
        nfft = 2^nextpow2(EEG.pnts);    % Next power of 2 from length of epochs
        NrFreqs = nfft/2+1;
        frequencies.(Conditions{i_cond}) = EEG.srate/2*linspace(0,1,NrFreqs);
        
        % Initate Empty Arrays
        FreqIdx = [];
        FreqData = zeros(length(ElectrodeIdx), nfft, EEG.trials);
        
        % ****** Select Data for relevant Electrodes ******
        Data = EEG.data(ElectrodeIdx,:,:);
        
        % ****** Check Minimum Data ******
        % check if min number of trials included, otherwise replace by NaN
        if Trials(i_cond) < MinData(i_cond)
            Data = NaN(size(Data));
        end
        
        % ****** Apply Hanning Window ******
             Data = Data.*[hann(EEG.pnts)]';

        
        % ****** Calculate FFT ******
        for ielectrode = 1:length(ElectrodeIdx)
            for itrial = 1:EEG.trials
                FreqData(ielectrode, :, itrial) = fft(Data(ielectrode,:,itrial),nfft)/EEG.pnts;    % Calculate Frequency Spectrum
                % Array of Electrodes : Frequencies : Trials
            end
        end
        power_AllConditions(:,1:NrFreqs, 1:Trials(i_cond), i_cond) = abs(FreqData(:, 1:NrFreqs, :)); % take only frequencies of Nyquist plus DC
    end
    
    
    
    % ****Calculate Average across Electrodes ******
    if INPUT.StepHistory.Cluster_Electrodes == "cluster"
        if contains(INPUT.StepHistory.Electrodes, "F5")
            BU_power = power_AllConditions;
            power_AllConditions = NaN(2, size(BU_power,2), size(BU_power,3), size(BU_power,4));
            power_AllConditions(1,:,:,:) = mean(BU_power([1,3,5], :, :,:),1, 'omitnan' );
            power_AllConditions(2,:,:,:) = mean(BU_power([2,4,6], :, :,:),1, 'omitnan' );
            if contains(INPUT.StepHistory.Electrodes, "P3")
                power_AllConditions(3,:,:,:) = mean(BU_power([7,9,11], :, :,:),1, 'omitnan' );
                power_AllConditions(4,:,:,:) = mean(BU_power([8,10,12], :, :,:),1, 'omitnan' );
            end
        end
    end
    
    
    % **** Get Info on Frequency Window ******
    if ~contains(FrequencyChoice, "relative")
        % Window is set
        FreqChoice = strsplit(FrequencyChoice, "_");
        FreqChoice = FreqChoice(2);
        if  contains(FrequencyChoice, "single")
            FrequencyBand = strsplit(FreqChoice, "-");
            FrequencyBand = str2double(FrequencyBand);
            FrequencyBandLabel = "one";
        elseif contains(FrequencyChoice, "double")
            FreqChoice = strsplit(FreqChoice, ";");
            FrequencyBand = [strsplit(FreqChoice(1), "-"); strsplit(FreqChoice(2), "-")];
            FrequencyBand = str2double(FrequencyBand);
            FrequencyBandLabel = ["low", "high"];
        end
        
        
    elseif contains(FrequencyChoice, "relative")
        % Window is dependent on maximum of frontal electrodes
        % Take peak within alpha range across all Conditions!
        MaxFreq = [];
        for i_cond = 1:length(Conditions)
            % Find Broad time window
            [~, Broadwindow(1)]  = min(abs(frequencies.(Conditions{i_cond}) - 8));
            [~, Broadwindow(2)]  = min(abs(frequencies.(Conditions{i_cond}) - 13));
            % take only frontal electrodes
            if INPUT.StepHistory.Cluster_Electrodes ~= "cluster"
                Idx_Frontal = find(contains(Electrodes, 'F'));
            else
                Idx_Frontal = [1,2]; % if averaged across electrodes only first two correspond to left/right Alpha
            end
            % Calculate Frontal power only in relevant frequency window
            FrontalPower = mean(mean(mean(power_AllConditions(Idx_Frontal,[Broadwindow(1):Broadwindow(2)],:), 3,'omitnan' ) ,1,'omitnan' ),4,'omitnan' );
            
            % Identify Maximum Power within Range
            [~, MaxIdx] = max(FrontalPower);
            % add Index of this maximum alpha peak (! Important add the skipped
            % Frequencies Back from the "broad window"
            MaxFreq = [MaxFreq, frequencies.(Conditions{i_cond})(Broadwindow(1) + MaxIdx -1)];
        end
        
        % Get Max across conditions
        MaxFreq = max(MaxFreq);
        
        % Set individualised Frequency Ranges
        if  contains(FrequencyChoice, "single")
            FrequencyBand = [MaxFreq-4, MaxFreq+2];
            FrequencyBandLabel = "one";
        elseif contains(FrequencyChoice, "double")
            FrequencyBand = [MaxFreq-4, MaxFreq; MaxFreq, MaxFreq+2];
            FrequencyBandLabel = ["low", "high"];
        end
        
    end
    
    
    % For each condition, calculate Average in that frequency range
    Alpha_Export = zeros(length(ElectrodeNames), size(FrequencyBand,1), length(Conditions));
    SME_Export = zeros(length(ElectrodeNames), size(FrequencyBand,1), length(Conditions));
    for i_cond = 1:length(Conditions)
        % Get index of frequencies
        [~,FreqIdx(1,1)] = min(abs(frequencies.(Conditions{icond}) - FrequencyBand(1,1)));
        [~,FreqIdx(1,2)] = min(abs(frequencies.(Conditions{icond}) - FrequencyBand(1,2)));
        
        if contains(FrequencyChoice, "double")
            [~,FreqIdx(2,1)] = min(abs(frequencies.(Conditions{icond}) - FrequencyBand(2,1)));
            [~,FreqIdx(2,2)] = min(abs(frequencies.(Conditions{icond}) - FrequencyBand(2,2)));
        end
        
        
        % **** Calculate Average across frequency range ******
        Alpha_Trials = mean(power_AllConditions(:,FreqIdx(1,1):FreqIdx(1,2),:,i_cond), 2, 'omitnan' );
        
        if contains(FrequencyChoice, "double")
            Alpha_Trials(:,2,:) = mean(power_AllConditions(:,FreqIdx(2,1):FreqIdx(2,2),:,i_cond), 2, 'omitnan' ); % electrode x FreqRange x Trials
        end
        
        % Mean across Trials
        Alpha_AV = mean(Alpha_Trials, 3, 'omitnan' ); % electrode x FreqRange
        
        % Calculate Difference Score of logs and mean of SME
        if INPUT.StepHistory.Quantification_Asymmetry == "diff"
            LeftIdx = 1:2:size(Alpha_AV ,1);
            RightIdx = 2:2:size(Alpha_AV ,1);
            Alpha_Export(:,:, i_cond) = log(Alpha_AV (RightIdx,:)) - log(Alpha_AV (LeftIdx,:));
            SingleTrial = log(Alpha_Trials (RightIdx,:,:)) - log(Alpha_Trials (LeftIdx,:,:));
            SME_Export(:,:, i_cond) = std(SingleTrial, [], 3, 'omitnan')/sqrt(Trials(i_cond));
        else
            Alpha_Export(:,:, i_cond) = log(Alpha_AV);
            SME_Export(:,:, i_cond) = std(log(Alpha_Trials), [], 3, 'omitnan' )/sqrt(Trials(i_cond));
        end
    end
    
    % Unclear why, but rarely the exported Value is -Inf
    SME_Export(abs(Alpha_Export) == Inf) = NaN;
    Alpha_Export(abs(Alpha_Export) == Inf) = NaN;
    
    % Prepare Output Table
    % Alpha is of size: NrElectrodes*FreqWindow times Conditions
    NrConditions = length(Conditions);
    NrElectrodes = length(ElectrodeNames);
    NrFreqWindow = size(FreqIdx,1);
    % Repeat Labels
    % Electrodes, Alpha, Freq alternate
    Electrodes_L = repmat([AlphaType;ElectrodeNames;Localisation], 1, NrConditions*NrFreqWindow);
 
    % Conditions same for all electrodes
    Conditions_L = repmat(repelem(Conditions', 1, NrElectrodes)',NrFreqWindow,1);
    % EpochCount Bound to Conditions
    EpochCount = repmat(repelem(Trials, 1, NrElectrodes)',NrFreqWindow,1);
    % Frequencies same across electrodes
    Frequency_Labels = num2str(FrequencyBand);
    FrequencyBandLabel_L = repelem(string(FrequencyBandLabel), 1, NrElectrodes*NrConditions)';
    Freq_L = repelem(string(Frequency_Labels)', 1, NrElectrodes*NrConditions)';
    % Subject is constant
    Subject_L = repmat(INPUT.Subject, NrConditions*NrElectrodes*NrFreqWindow,1 );
    % Prepare Table
    % in Format AnalysisName - Subject - Condition - AlphaType - Electrode - Localisation - FreqWindow - Alpha - SME - Epoch Count
    
    Alpha_Table = cellstr([Subject_L, Conditions_L, Electrodes_L', FrequencyBandLabel_L, Freq_L, [Alpha_Export(:)], [SME_Export(:)], EpochCount]);
    
    %#####################################################################
    %### Wrapping up Preprocessing Routine                         #######
    %#####################################################################
    % ****** Export ******
    % Script creates an OUTPUT structure. Assign here what should be saved
    % and made available for next step. Always save the EEG structure in
    % the OUTPUT.data field, overwriting previous EEG information.
    
    OUTPUT.data = []; % remove old EEG data
    OUTPUT.data = Alpha_Table; % save new structure
    
    OUTPUT.StepDuration = [OUTPUT.StepDuration; toc];
    
    
    % ****** Error Management ******
catch e
    % If error ocurrs, create ErrorMessage(concatenated for all nested
    % errors). This string is given to the OUTPUT struct.
    ErrorMessage = string(e.message);
    for ierrors = 1:length(e.stack)
        ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
    end
    ErrorMessage = strcat(Conditions(:), ErrorMessage); %delete! just for checking
    OUTPUT.Error = ErrorMessage;
end
end
