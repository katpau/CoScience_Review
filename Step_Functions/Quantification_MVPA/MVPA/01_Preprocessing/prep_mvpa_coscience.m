function prep_mvpa_coscience(part)

%% This function preprocessed the EEG and behavioural data and sorts them into the following conditions:

% flanker task:
% correct
% error

% gonogo task:
% Go - correct
% NoGo - errror


%% A trial starts at "window_start" ms before the response and ends at "window_end" ms after the response. So one trial
% takes "window_length" ms. That is "dppt" data points per trial (dppt). Since the window
% size may vary in future analyses, it is better to have a variable
% containing the dppt so it can be changed easily.
window_start = -300;
window_end = 300;
window_length = window_end - window_start;
dppt = window_length/2;

%% Specifications
AnalysisName = "Flanker_MVPA";

bdir = 'C:\Users\elisa\Documents\GitHub\CoScience_Review\'; % Base directory

if AnalysisName == "Flanker_MVPA"
    input_dir = [bdir 'Only_ForGit_To_TestRun\Preproc_forked\Error_MVPA\task-Flanker\1.1_2.1_3.1_4.1_5.1_6.1_7.1_8.1_9.1_10.1_11.1_12.1_13.1_14.1_15.1/'];   %Folder containing the raw data
    output_dir = [bdir 'Step_Functions\Quantification_MVPA\MVPA\01_Preprocessing\PreprocessedData\flanker\'];      %Folder where the preprocessed data is to be stored 
 elseif AnalysisName == "GoNoGo_MVPA" 
    input_dir = [bdir 'Only_ForGit_To_TestRun\Preproc_forked\Error_MVPA\task-GoNoGo\1.1_2.1_3.1_4.1_5.1_6.1_7.1_8.1_9.1_10.1_11.1_12.1_13.1_14.1_15.1/'];   %Folder containing the raw data
    output_dir = [bdir 'Step_Functions\Quantification_MVPA\MVPA\01_Preprocessing\PreprocessedData\go_nogo\'];      %Folder where the preprocessed data is to be stored Preprocessed Data
end

chan_dir = [bdir 'Step_Functions\Quantification_MVPA\MVPA\02_MVPA\locations\']; %Folder where channel locations are to be stored

%% extract participant code

participant_codes = get_participant_codes(bdir, input_dir);
part_code = participant_codes(part) %Informing in the command window about which participant is being processed. 
filename = [input_dir, char(part_code), '.mat'];
EEG_data = load(filename);

%% Create vector containing the response types

events = struct2table(EEG_data.Data.data.EEG.event);
events_response = events(strcmp(events.Event, 'Response'),:);

if AnalysisName == "Flanker_MVPA"
    for i = 1:(height(events_response));
        if events_response.ACC(i) == 1
           events_response.responsetype(i) = 1;
        elseif events_response.ACC(i) == 0
            events_response.responsetype(i) = 2;
        else 
            events_response.responsetype(i) = 0;    
        end
    end
elseif AnalysisName == "GoNoGo_MVPA" 
    for i = 1:(height(events_response));
        if strcmp(events_response.Type(i), 'Go') && events_response.ACC(i) == 1
        events_response.responsetype(i) = 1;
        elseif strcmp(events_response.Type(i), 'NoGo') && events_response.ACC(i) == 0
        events_response.responsetype(i) = 2;
        else 
        events_response.responsetype(i) = 0;    
        end
    end
end

%% Only use common channels
common_channels = {'FP1', 'FP2', 'AF7', 'AF8', 'AF3', 'AF4', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'FT7', 'FT8', ...
                   'FC5', 'FC6', 'FC3', 'FC4', 'FC1', 'FC2', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'T7', 'T8', 'TP7', 'TP8', ...
                   'CP5', 'CP6', 'CP3', 'CP4', 'CP1', 'CP2', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'PO7', 'PO8', ...
                   'PO3', 'PO4', 'O1', 'O2', 'OZ', 'POZ', 'PZ', 'CPZ', 'CZ', 'FCZ', 'FZ', 'AFZ', 'FPZ'}';
common_channels = cell2table(common_channels);
chanlocs_part = struct2table(EEG_data.Data.data.EEG.chanlocs); %chanlocs of participant
rm_chan = ~ismember(lower(chanlocs_part.labels), lower(common_channels.common_channels)); %find which channels need to be removed
rm_chan_names = chanlocs_part.labels(rm_chan); %get names of channels that need to be removed
EEG_data.Data.data.EEG.chaninfo.additional_chans_removed = rm_chan_names;

EEG_data.Data.data.EEG = pop_select(EEG_data.Data.data.EEG, 'nochannel', rm_chan_names); %remove channels from EEG structure

clear common_channels chanlocs_part rm_chan rm_chan_names

%% Create EEG substructures from 3d EEGmatrix containing only trials from the respective responsetype (dp x channels x trials)

EEG_data.Data.data.EEG.data_restruct = permute(EEG_data.Data.data.EEG.data, [2 1 3]); %change order of dimensions in EEG matrix from channelsxdpxtrials to dpxchannelsxtrials
EEG_data.Data.data.EEG.data_correct = EEG_data.Data.data.EEG.data_restruct(:,:,events_response.responsetype == 1);
EEG_data.Data.data.EEG.data_error = EEG_data.Data.data.EEG.data_restruct(:,:,events_response.responsetype == 2);

%% sanity check: are there any empty rows in the EEG substructures?

empty_rows_correct(1:length(EEG_data.Data.data.EEG.data_correct(1,1,:)),:) = zeros;
for i = 1:length(EEG_data.Data.data.EEG.data_correct(1,1,:))
    if EEG_data.Data.data.EEG.data_correct(:,:,i) == 0
       empty_rows_correct(i) = 1;
    else empty_rows_correct(i) = 0;
    end
 end
 empty_rows_error(1:length(EEG_data.Data.data.EEG.data_error(1,1,:)),:) = zeros;
 for i = 1:length(EEG_data.Data.data.EEG.data_error(1,1,:))
     if EEG_data.Data.data.EEG.data_error(:,:,i) == 0
        empty_rows_error(i) = 1;
     else empty_rows_error(i) = 0;
     end
 end
 all_empty_correct = sum(empty_rows_correct);
 all_empty_error = sum(empty_rows_error);
 fprintf('Results of sanity check: \nThere is a total of %d case(s) in which EEG_correct is empty.\n Check for causes.', all_empty_correct);
 fprintf('Results of sanity check: \nThere is a total of %d case(s) in which EEG_error is empty.\n Check for causes.', all_empty_error);
 % !!! remove empty trials from EEG matrices only after checking their validty!!!
 % EEG_correct(:,:, (find(empty_rows_correct == 1))) = [];
 % EEG_error(:,:, (find(empty_rows_error == 1))) = [];
 clear all_empty_correct all_empty_error empty_rows_correct empty_rows_error



%% Prepare output file.

%Information.
channels = struct2table(EEG_data.Data.data.EEG.chanlocs);
info.ChannelLabels = channels.labels;
info.participant = part_code;
info.n_trial_dp = dppt;
info.pre_event_baseline = abs(window_start);
info.ConditionLables = {'1 = correct'; '2 = error'};
info.n_correct = length(EEG_data.Data.data.EEG.data_correct(1,1,:)); 
info.n_error = length(EEG_data.Data.data.EEG.data_error(1,1,:)); 
info.n_total = sum([length(EEG_data.Data.data.EEG.data_correct(1,1,:)),length(EEG_data.Data.data.EEG.data_error(1,1,:))]);
eeg_sorted_cond(1).data = EEG_data.Data.data.EEG.data_correct;
eeg_sorted_cond(2).data = EEG_data.Data.data.EEG.data_error;

%Output directory and file name.
out_file = [output_dir char(part_code) '.mat'];
channel_outfile = [chan_dir 'channel_inf' '.mat'];

%Save the information on the data
save(out_file, 'info', 'eeg_sorted_cond');
save(channel_outfile, 'channels');








