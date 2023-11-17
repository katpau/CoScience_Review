function  OUTPUT = TimeWindow(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following:
% Gets previouses choices and current one (=Time Window of LRP)
% exports MVPA (since it is not forked how its done) and LRP onsets

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
StepName = "TimeWindow";
Choices = ["relative_peak", "absolute_criteria"];
Conditional = ["NaN", "NaN"];
SaveInterim = logical([1]);
Order = [21];

INPUT.StepHistory.TimeWindow = Choice;
OUTPUT = INPUT;
% Some Error Handling
try
    %%%%%%%%%%%%%%%% Routine for the analysis of this step
    % This functions starts from using INPUT and returns OUTPUT
    EEG = INPUT.data.EEG;
    LRP = INPUT.data.LRP;
    
    % Condition Names and Triggers depend on analysisname
    if INPUT.AnalysisName == "Flanker_MVPA"
        Condition_Triggers = { 106, 116, 126,  136, 107, 117, 127, 137; ...
            108, 118, 128, 138, 109, 119, 129, 139  }; %Responses Experimenter Absent
        Condition_Names = ["Flanker_Correct", "Flanker_Error"];
        
    elseif INPUT.AnalysisName == "GoNoGo_MVPA"
        Condition_Triggers = {211; 220}; %Responses Speed/Acc emphasis
        Condition_Names = ["GoNoGo_Correct", "GoNoGo_Error"];
    end
    
    Event_Window = [-0.300 0.300]; % Epoch length in seconds
    NrConditions = length(Condition_Names);
    
    % epoch data
    for i_Cond = 1:NrConditions
        (Condition_Names(i_Cond))
        pop_epoch(EEG, Condition_Triggers(i_Cond,:), Event_Window, 'epochinfo', 'yes');     
    end

   % epoch lrp data
   for i_Cond = 1:NrConditions
        (Condition_Names(i_Cond))
        pop_epoch(LRP, Condition_Triggers(i_Cond,:), Event_Window, 'epochinfo', 'yes');     
    end
    
    % run first-level lrp and mvpa analyses    
     addpath(genpath(strcat(pwd, "/Analysis_Functions/Error_MVPA/")))
    
    % Create vector containing the response types
    events = struct2table(EEG.event);
    
    if iscell(events.Event)
        empty = find(cellfun(@isempty,events.Event));
        for i = 1:length(empty)
            events.Event(empty(i)) = {"NaN"};
        end
        events.Event = string(events.Event);
    else 
         events.Event(cellfun(@isempty,events.Event)) = "NaN";
    end
    
    events_response = events(strcmp(events.Event, 'Response'),:);
    
    if iscell(events_response.ACC)
        events_response.ACC = str2double(string(events_response.ACC));
    end
    
    if INPUT.AnalysisName == "Flanker_MVPA"
        for i = 1:(height(events_response))
            if events_response.ACC(i) == 1
               events_response.responsetype(i) = 1;
            elseif events_response.ACC(i) == 0
               events_response.responsetype(i) = 2;
            else 
               events_response.responsetype(i) = 0;    
            end
        end
    elseif INPUT.AnalysisName == "GoNoGo_MVPA" 
        for i = 1:(height(events_response))
            if strcmp(events_response.Type(i), 'Go') && events_response.ACC(i) == 1
            events_response.responsetype(i) = 1;
            elseif strcmp(events_response.Type(i), 'NoGo') && events_response.ACC(i) == 0
            events_response.responsetype(i) = 2;
            else 
            events_response.responsetype(i) = 0;    
            end
        end
    end
    
    %% LRP
    % Preprocessing 
     ms_start = -300;
    ms_end = 299;
    
%     % Create EEG substructures from 3d EEGmatrix containing only trials from LRP electrodes (channels x dp x trials)
%     chanlocs = struct2table(LRP.chanlocs);
    Electrodes = upper(strsplit(OUTPUT.StepHistory.Electrodes, ", ")); 
%     lrp_chanlocs = [find(strcmp(chanlocs.labels, Electrodes(1))) find(strcmp(chanlocs.labels, Electrodes(2)))]; %only use LRP electrodes of interest
%     
%     EEG_lrp = pop_select(LRP, 'channel', lrp_chanlocs); %remove other channels from EEG structure
%     
%     clear chanlocs lrp_chanlocs
    
    EEG_lrp = LRP;    

    %select response types (correct and error)
    EEG_lrp.data = EEG_lrp.data(:,:,events_response.responsetype ~= 0);
    
    %find indices from left and right hemisphere electrodes to ensure that 
    %right hemisphere electrode acitivty is substracted from the left later on
    chanlocs_remain = struct2table(EEG_lrp.chanlocs);
    C3 = find(strcmp(chanlocs_remain.labels, Electrodes(1)));
    C4 = find(strcmp(chanlocs_remain.labels, Electrodes(2)));
    
    clear Electrodes chanlocs_remain
    
    %create matrix for LRP (dp x trials) 
    data_lrp = zeros(length(EEG_lrp.data(1,:,1)), length(EEG_lrp.data(1,1,:)));
    for i = 1:length(EEG_lrp.data(1,1,:)) % number of trials
        for ii = 1:length(EEG_lrp.data(1,:,1)) % number of data points
           data_lrp(ii,i) = EEG_lrp.data(C3,ii,i) - EEG_lrp.data(C4,ii,i); 
        end
    end
    
    clear i ii C3 C4
        
    %only continue if data set contains any error trials    
    if width(data_lrp(:, events_response.responsetype == 2)) < 10
        fprintf('There are less than ten error trials in the data set. Continuing with next participant.');
        e.message = 'Not enough error trials.';
        error(e.message);
    end
 
    %create participant average across trials (dp) 
    EEG_lrp.data_lrp_aver = zeros(length(data_lrp(:,1)),1);
    for i = 1:length(data_lrp(:,1))
        EEG_lrp.data_lrp_aver(i) = mean(data_lrp(i,:));
    end
    
    clear i
        
    % add vector with ms
    if EEG_lrp.srate == 512
        ms_down = [ms_start:1.95:ms_end]'; 
        ms_base =  [ms_start:2:ms_end]';
        ms_base = vertcat(ms_base, zeros(length(ms_down)-length(ms_base),1));
        ms = [ms_down, ms_base];
        ms = array2table(ms);
        ms.Properties.VariableNames = ["down","base"];
        ms.diff = ms.down-ms.base;
        ms.del = zeros(length(ms_base),1);
        for i = 1:length(ms.down)
            if ms.diff(i) >= 1 || ms.diff(i) <= -1
                ms.del(i) = 1;
                ms.down = vertcat(ms.down(1:i-1), ms.down(i+1:end), 0);
                ms.diff = ms.down-ms.base;
            end
        end
        EEG_lrp.data_lrp_aver = array2table(EEG_lrp.data_lrp_aver);
        EEG_lrp.data_lrp_aver(find(ms.del),:) = [];
        ms = table2array(ms);
        del_zeros = find(all(ms ==0, 2));
        ms(del_zeros,:) = [];
        ms = array2table(ms);
        ms.Properties.VariableNames = ["down","base", "diff", "del"];
        EEG_lrp.data_lrp_aver.ms = ms.base;
    
    else 
            ms = [ms_start:2:ms_end]'; %create ms vector with time steps of 2 ms
            EEG_lrp.data_lrp_aver = array2table(EEG_lrp.data_lrp_aver);
            EEG_lrp.data_lrp_aver.ms = ms;
    
    end
    
    clear ms_base ms_down ms
    
    %add column names
    colNames={'amplitude', 'ms'};
    EEG_lrp.data_lrp_aver.Properties.VariableNames = colNames;

    %% MPVA 
    
    % Only use common channels
    common_channels = {'FP1', 'FP2', 'AF7', 'AF8', 'AF3', 'AF4', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'FT7', 'FT8', ...
                       'FC5', 'FC6', 'FC3', 'FC4', 'FC1', 'FC2', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'T7', 'T8', 'TP7', 'TP8', ...
                       'CP5', 'CP6', 'CP3', 'CP4', 'CP1', 'CP2', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'PO7', 'PO8', ...
                       'PO3', 'PO4', 'O1', 'O2', 'OZ', 'POZ', 'PZ', 'CPZ', 'CZ', 'FCZ', 'FZ'}'; %from the 61 common electrodes, AFZ and FPZ were used as grounds, so they are not included here
    common_channels = cell2table(common_channels);
    chanlocs_part = struct2table(EEG.chanlocs); %chanlocs of participant
    rm_chan = ~ismember(lower(chanlocs_part.labels), lower(common_channels.common_channels)); %find which channels need to be removed
    rm_chan_names = chanlocs_part.labels(rm_chan); %get names of channels that need to be removed
    
    global EEG_mvpa

    EEG_mvpa = pop_select(EEG, 'nochannel', rm_chan_names); %remove channels from EEG structure
    EEG_mvpa.chaninfo.additional_chans_removed = rm_chan_names;

    if length(EEG_mvpa.data(:,1,1)) ~= size(common_channels)
        fprintf('The number of channels does not equal the requested number of common channels. Continuing with next participant.');
        e.message = "Wrong number of channels.";
        error(e.message);
    end

    clear common_channels chanlocs_part rm_chan rm_chan_names
    
    %for 512Hz sampling rate, remove additional measuring points to fit with
    %500Hz sampling rate
    window_start = -300;
    window_end = 300;
    window_length = window_end - window_start;
    dppt = window_length/2;

    if EEG_mvpa.srate == 512
        ms_down = [window_start:1.95:window_end-1]'; 
        ms_base =  [window_start:2:window_end-1]';
        ms_base = vertcat(ms_base, zeros(length(ms_down)-length(ms_base),1));
        ms = [ms_down, ms_base];
        ms = array2table(ms);
        ms.Properties.VariableNames = ["down","base"];
        ms.diff = ms.down-ms.base;
        ms.del = zeros(length(ms_base),1);
        for i = 1:length(ms.down)
            if ms.diff(i) >= 1 || ms.diff(i) <= -1
                ms.del(i) = 1;
                ms.down = vertcat(ms.down(1:i-1), ms.down(i+1:end), 0);
                ms.diff = ms.down-ms.base;
            end
        end
    EEG_mvpa.data(:,find(ms.del),:) = [];
    end
    
    clear ms_base ms_down ms 
    
    % Create EEG substructures from 3d EEGmatrix containing only trials from the respective responsetype (dp x channels x trials)
    EEG_mvpa.data_restruct = permute(EEG_mvpa.data, [2 1 3]); %change order of dimensions in EEG matrix from channelsxdpxtrials to dpxchannelsxtrials
    EEG_mvpa.data_correct = EEG_mvpa.data_restruct(:,:,events_response.responsetype == 1);
    EEG_mvpa.data_error = EEG_mvpa.data_restruct(:,:,events_response.responsetype == 2);
    
    %% sanity check: are there any empty rows in the EEG substructures?
    empty_rows_correct(1:length(EEG_mvpa.data_correct(1,1,:)),:) = zeros;
    for i = 1:length(EEG_mvpa.data_correct(1,1,:))
        if EEG_mvpa.data_correct(:,:,i) == 0
           empty_rows_correct(i) = 1;
        else 
            empty_rows_correct(i) = 0;
        end
     end
     empty_rows_error(1:length(EEG_mvpa.data_error(1,1,:)),:) = zeros;
     for i = 1:length(EEG_mvpa.data_error(1,1,:))
         if EEG_mvpa.data_error(:,:,i) == 0
            empty_rows_error(i) = 1;
         else 
             empty_rows_error(i) = 0;
         end
     end
     all_empty_correct = sum(empty_rows_correct);
     all_empty_error = sum(empty_rows_error);

     fprintf('Results of sanity check: \nThere is a total of %d case(s) in which EEG_correct is empty.\n Check for causes.', all_empty_correct);
     fprintf('Results of sanity check: \nThere is a total of %d case(s) in which EEG_error is empty.\n Check for causes.', all_empty_error);


    if all_empty_correct > 0
        fprintf('There are cases where EEG_correct is empty. Check for causes.');
        e.message = "Empty rows in EEG_correct.";
        error(e.message);
    end

    if all_empty_error > 0
        fprintf('There are cases where EEG_error is empty. Check for causes.');
        e.message = "Empty rows in EEG_error.";
        error(e.message);
    end
    
     % !!! remove empty trials from EEG matrices only after checking their validty!!!
     % EEG_correct(:,:, (find(empty_rows_correct == 1))) = [];
     % EEG_error(:,:, (find(empty_rows_error == 1))) = [];

    clear all_empty_correct all_empty_error empty_rows_correct empty_rows_error

    global eeg_sorted_cond

    eeg_sorted_cond(1).data = EEG_mvpa.data_correct;
    eeg_sorted_cond(2).data = EEG_mvpa.data_error;

    % run first-level MVPA
    global SLIST
    global STUDY
    global RESULTS

     group = 1;
     part = 1;
     DECODING_ERP('coscience', 1, 0, part, group, 0);

    %% Prepare output file

    %LRP
    OUTPUT.LRP.chanlocs = EEG_lrp.chanlocs;
    OUTPUT.LRP.data_lrp = data_lrp;    
    OUTPUT.LRP.data_lrp_aver = EEG_lrp.data_lrp_aver;
    OUTPUT.LRP.partcode = EEG_lrp.subject;

    %MVPA
    OUTPUT.MVPA.chanlocs = EEG_mvpa.chanlocs;
    OUTPUT.MVPA.event = EEG_mvpa.event;
    OUTPUT.MVPA.epoch = EEG_mvpa.epoch;
    OUTPUT.MVPA.SLIST = SLIST;
    OUTPUT.MVPA.STUDY = STUDY;
    OUTPUT.MVPA.RESULTS = RESULTS;
    OUTPUT.MVPA.eeg_sorted_cond = eeg_sorted_cond;

    info.participant = EEG_mvpa.subject;
    info.n_trial_dp = dppt;
    info.pre_event_baseline = abs(window_start);
    info.ConditionLables = {'1 = correct'; '2 = error'};
    info.sampling_rate = EEG_mvpa.srate;
    info.n_correct = length(EEG_mvpa.data_correct(1,1,:)); 
    info.n_error = length(EEG_mvpa.data_error(1,1,:)); 
    info.n_total = sum([length(EEG_mvpa.data_correct(1,1,:)),length(EEG_mvpa.data_error(1,1,:))]);
    OUTPUT.MVPA.info = info;

    OUTPUT.data = [];

    clear data EEG_mvpa EEG_lrp SLIST STUDY RESULTS eeg_sorted_cond

    % Export should have format like this:
    % Subject, Lab, Experimenter, Condition (Correct/Error), Task, Onset (?) or DV, Component (LRP, MVPA, etc.), EpochCount ...
    NrComponents = 2; % LRP and MVPA?
    Subject_L = repmat(INPUT.Subject, NrConditions*NrComponents,1 );
    Lab_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrComponents,1 );
    Experimenter_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrComponents,1 );
    Conditions_L = repelem(Condition_Names', NrComponents,1);
    ACC = repmat(INPUT.data.EEG.ACC, NrConditions*NrComponents,1 );
    
    Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L]), ...
        num2cell(ACC)]; % add other
    OUTPUT.Export = Export;
    
    rmpath(genpath(strcat(pwd, "/Analysis_Functions/Error_MVPA/")))
    
    % ****** Updating the OUTPUT structure ******
    % No changes should be made here.
    INPUT.StepHistory.(StepName) = Choice;
    
    % ****** Error Management ******
catch e
    % If error ocurrs, create ErrorMessage(concatenated for all nested
    % errors). This string is given to the OUTPUT struct.
    ErrorMessage = string(e.message);
    for ierrors = 1:length(e.stack)
        ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
    end
    
    OUTPUT.Error = ErrorMessage;
    
end