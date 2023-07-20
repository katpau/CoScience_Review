%% This script computes the LRP onsets by jackknifing

global AnalysisName

%% directories
if AnalysisName == "Flanker_MVPA"
    input_dir = [pwd '\Only_ForGit_To_TestRun\Preproc_forked\Error_MVPA\task-Flanker\1.1_2.1_3.1_4.1_5.1_6.1_7.1_8.1_9.1_10.1_11.1_12.1_13.1_14.1_15.1_16.1\'];   %Folder containing the raw data
    output_dir = [pwd '\Analysis_Functions\Error_MVPA\LRP\lrp_onsets\flanker\'];      %Folder where the preprocessed data is to be stored 
 elseif AnalysisName == "GoNoGo_MVPA" 
    input_dir = [pwd '\Only_ForGit_To_TestRun\Preproc_forked\Error_MVPA\task-GoNogo\1.1_2.1_3.1_4.1_5.1_6.1_7.1_8.1_9.1_10.1_11.1_12.1_13.1_14.1_15.1_16.1\'];   %Folder containing the raw data
    output_dir = [pwd '\Analysis_Functions\Error_MVPA\LRP\lrp_onsets\go_nogo\'];      %Folder where the preprocessed data is to be stored Preprocessed Data
end

%% load preprocessed data
files = struct2table(dir(fullfile(input_dir,'*.mat')));
participant_filenames = files.name;
participant_codes = cell(size(participant_filenames));

for i = 1:length(participant_filenames)
    
    id = participant_filenames{i};
    participant_codes{i} = id(1:(length(id)-4));
    
end

clear files participant_filenames

for part = 1:length(participant_codes)
    part_code = participant_codes(part) %Informing in the command window about which participant is being processed. 
    filename = [input_dir, char(part_code), '.mat'];
    data = load(filename);

    %add vector with id
    id = cell2table(part_code);
    id = repmat(id,length(data.Data.LRP.data_lrp_aver.ms),1);
        data.Data.LRP.data_lrp_aver.id = id.part_code;

    clear id
     
    %create one output file for all participants
%         part_code = cell2table(part_code);
     if exist('data_lrp_all', 'var') == 0
           data_lrp_all = data.Data.LRP.data_lrp_aver; %create new if it doesn't exist
     else 
        if ismember(part_code, data_lrp_all.id) == 0 %only append when current part has not been appended 
           data_lrp_all = vertcat(data_lrp_all, data.Data.LRP.data_lrp_aver); %append if it exists
        end
     end
end

%% compute lrp onsets
% compute mean amplitude for every time step when id = i is left out
part = unique(data_lrp_all.id);

for i = 1:length(part)
    remove_part = ismember(data_lrp_all.id, part(i)); % define participant to leave out
    data_subset = data_lrp_all(~remove_part,:); % leave participant out
    data_new = groupsummary(data_subset, "ms", "mean", "amplitude"); %compute average of amplitudes across remaining ids for each time step (ms)
    id = repmat(part(i),length(data_new.ms),1);
    data_new =  [data_new, id]; % append participant code that has been leftout
    colNames = {'ms', 'groupcount', 'amplitude', 'id'};
    data_new.Properties.VariableNames = colNames;
    if exist('jack_lrp', 'var') == 0
       jack_lrp = data_new;
    else 
         if ismember(part(i), jack_lrp.id) == 0
            jack_lrp = vertcat(jack_lrp, data_new); %append to existing data frame
         end
    end
    clear remove_part data_subset data_new id 
end

clear part i 

% determine amplitude threshold for lrp onset (50% of max amplitude) 
max_amp = groupsummary(jack_lrp, "id", "min", "amplitude"); % min because lrp peak is negative
max_amp.criterion = max_amp.min_amplitude*0.5; % 50% of max amplitude as criterion

for i = 1:length(jack_lrp.ms)
    for ii = 1:length(max_amp.id)
        if ismember(jack_lrp.id(i), max_amp.id(ii)) 
            if jack_lrp.amplitude(i) <= max_amp.criterion(ii)
               jack_lrp.threshold(i) = 1;
            else 
                jack_lrp.threshold(i) = 0;
            end
        end
    end
end

clear i ii
    
% determine lrp onset as first time step where amplitude exceeds threshold
max_amp.lrp_onset = NaN([length(max_amp.id), 1]);
for i = 1:length(max_amp.id)
    part_code = max_amp.id(i);
    part_onset = jack_lrp(ismember(jack_lrp.id, part_code),:);  
    max_amp.lrp_onset(i) =  part_onset.ms(find(part_onset.threshold, 1, 'first'));

    clear part_code part_onset
end

clear i

% smulders transformation to obtain individual latencies
max_amp.lrp_smulders = NaN([length(max_amp.id), 1]);
for i = 1:length(max_amp.id)
    max_amp.lrp_smulders(i) = length(max_amp.lrp_onset)*mean(max_amp.lrp_onset)-(length(max_amp.lrp_onset)-1)*max_amp.lrp_onset(i);
end


%Save output file
out_file = [output_dir 'lrp_onsets.mat'];
save(out_file, 'max_amp');
