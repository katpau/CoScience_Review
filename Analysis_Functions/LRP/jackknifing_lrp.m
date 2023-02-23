%% This script computes the LRP onsets by jackknifing

global AnalysisName;
global bdir;

%% directories
if AnalysisName == "Flanker_MVPA"
    input_dir = [bdir '\Analysis_Functions\LRP\preprocessed_data\flanker\'];   %Folder containing the raw data
    output_dir = [bdir '\Analysis_Functions\LRP\lrp_onsets\flanker\'];      %Folder where the preprocessed data is to be stored 
 elseif AnalysisName == "GoNoGo_MVPA" 
    input_dir = [bdir '\Analysis_Functions\LRP\preprocessed_data\go_nogo\'];   %Folder containing the raw data
    output_dir = [bdir '\Analysis_Functions\LRP\lrp_onsets\go_nogo\'];      %Folder where the preprocessed data is to be stored Preprocessed Data
end

%% load preprocessed data
filename_corrects = [input_dir, 'data_lrp_correct_aver.mat'];
load(filename_corrects);

filename_errors = [input_dir, 'data_lrp_error_aver.mat'];
load(filename_errors);


%% compute lrp onsets
% correct responses

% compute mean amplitude for every time step when id = i is left out
part = unique(data_lrp_correct_aver.id);

for i = 1:length(part)
    remove_part = ismember(data_lrp_correct_aver.id, part(i)); % define participant to leave out
    data_subset = data_lrp_correct_aver(~remove_part,:); % leave participant out
    data_new = groupsummary(data_subset, "ms", "mean", "amplitude"); %compute average of amplitudes across remaining ids for each time step (ms)
    id = repmat(part(i),length(data_new.ms),1);
    data_new =  [data_new, id]; % append participant code that has been leftout
    colNames={'ms', 'groupcount', 'amplitude', 'id'};
    data_new.Properties.VariableNames = colNames;
    if exist('jack_lrp_corrects', 'var') == 0
       jack_lrp_corrects = data_new;
    else 
         if ismember(part(i), jack_lrp_corrects.id) == 0
            jack_lrp_corrects = vertcat(jack_lrp_corrects, data_new); %append to existing data frame
         end
    end
    clear remove_part data_subset data_new id 
end

clear part i 

% determine amplitude threshold for lrp onset (50% of max amplitude) 
max_amp_corrects = groupsummary(jack_lrp_corrects, "id", "min", "amplitude"); % min because lrp peak is negative
max_amp_corrects.criterion = max_amp_corrects.min_amplitude*0.5; % 50% of max amplitude as criterion

for i = 1:length(jack_lrp_corrects.ms)
    for ii = 1:length(max_amp_corrects.id)
        if ismember(jack_lrp_corrects.id(i), max_amp_corrects.id(ii)) 
            if jack_lrp_corrects.amplitude(i) <= max_amp_corrects.criterion(ii)
               jack_lrp_corrects.threshold(i) = 1;
            else 
                jack_lrp_corrects.threshold(i) = 0;
            end
        end
    end
end

clear i ii
    
% determine lrp onset as first time step where amplitude exceeds threshold
max_amp_corrects.onset = NaN([length(max_amp_corrects.id), 1]);
for i = 1:length(max_amp_corrects.id)
    part_code = max_amp_corrects.id(i);
    part_onset = jack_lrp_corrects(ismember(jack_lrp_corrects.id, part_code),:);  
    max_amp_corrects.onset(i) =  find(part_onset.threshold, 1, 'first');

    clear part_code part_onset
end

clear i

% smulders transformation to obtain individual latencies
max_amp_corrects.smulders = NaN([length(max_amp_corrects.id), 1]);
for i = 1:length(max_amp_corrects.id)
    max_amp_corrects.smulders(i) = length(max_amp_corrects.onset)*mean(max_amp_corrects.onset)-(length(max_amp_corrects.onset)-1)*max_amp_corrects.onset(i);
end

%% compute lrp onsets
% errors

% compute mean amplitude for every time step when id = i is left out
part = unique(data_lrp_error_aver.id);

for i = 1:length(part)
    remove_part = ismember(data_lrp_error_aver.id, part(i)); % define participant to leave out
    data_subset = data_lrp_error_aver(~remove_part,:); % leave participant out
    data_new = groupsummary(data_subset, "ms", "mean", "amplitude"); %compute average of amplitudes across remaining ids for each time step (ms)
    id = repmat(part(i),length(data_new.ms),1);
    data_new =  [data_new, id]; % append participant code that has been leftout
    colNames={'ms', 'groupcount', 'amplitude', 'id'};
    data_new.Properties.VariableNames = colNames;
    if exist('jack_lrp_errors', 'var') == 0
       jack_lrp_errors = data_new;
    else 
         if ismember(part(i), jack_lrp_errors.id) == 0
            jack_lrp_errors = vertcat(jack_lrp_errors, data_new); %append to existing data frame
         end
    end
    clear remove_part data_subset data_new id 
end

clear part i 

% determine amplitude threshold for lrp onset (50% of max amplitude) 
max_amp_errors = groupsummary(jack_lrp_errors, "id", "min", "amplitude"); % min because lrp peak is negative
max_amp_errors.criterion = max_amp_errors.min_amplitude*0.5; % 50% of max amplitude as criterion

for i = 1:length(jack_lrp_errors.ms)
    for ii = 1:length(max_amp_errors.id)
        if ismember(jack_lrp_errors.id(i), max_amp_errors.id(ii)) 
            if jack_lrp_errors.amplitude(i) <= max_amp_errors.criterion(ii)
               jack_lrp_errors.threshold(i) = 1;
            else 
                jack_lrp_errors.threshold(i) = 0;
            end
        end
    end
end

clear i ii
    
% determine lrp onset as first time step where amplitude exceeds threshold
max_amp_errors.onset = NaN([length(max_amp_errors.id), 1]);
for i = 1:length(max_amp_errors.id)
    part_code = max_amp_errors.id(i);
    part_onset = jack_lrp_errors(ismember(jack_lrp_errors.id, part_code),:);  
    max_amp_errors.onset(i) =  find(part_onset.threshold, 1, 'first');

    clear part_code part_onset
end

clear i

% smulders transformation to obtain individual latencies
max_amp_errors.smulders = NaN([length(max_amp_errors.id), 1]);
for i = 1:length(max_amp_errors.id)
    max_amp_errors.smulders(i) = length(max_amp_errors.onset)*mean(max_amp_errors.onset)-(length(max_amp_errors.onset)-1)*max_amp_errors.onset(i);
end

%Save output files
out_file_correct = [output_dir 'lrp_onsets_correct.mat'];
save(out_file_correct, 'max_amp_corrects');

out_file_error = [output_dir 'lrp_onsets_error.mat'];
save(out_file_error, 'max_amp_errors');
