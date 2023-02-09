%% This script computes the LRP

%% Specifications
AnalysisName = "Flanker_MVPA";

%% Add relevant paths
bdir = pwd; % Base directory
addpath(genpath(strcat(bdir, "/Only_ForGit_to_TestRun/")))
addpath(genpath(strcat(bdir, "/Analysis_Functions/LRP/")))

%% directories
if AnalysisName == "Flanker_MVPA"
    input_dir = [bdir '\Only_ForGit_To_TestRun\Preproc_forked\Error_MVPA\task-Flanker\1.1_2.1_3.1_4.1_5.1_6.1_7.1_8.1_9.1_10.1_11.1_12.1_13.1_14.1_15.1/'];   %Folder containing the raw data
    output_dir = [bdir '\Analysis_Functions\LRP\01_Preprocessing\PreprocessedData\flanker\'];      %Folder where the preprocessed data is to be stored 
 elseif AnalysisName == "GoNoGo_MVPA" 
    input_dir = [bdir '\Only_ForGit_To_TestRun\Preproc_forked\Error_MVPA\task-GoNoGo\1.1_2.1_3.1_4.1_5.1_6.1_7.1_8.1_9.1_10.1_11.1_12.1_13.1_14.1_15.1/'];   %Folder containing the raw data
    output_dir = [bdir '\Analysis_Functions\LRP\01_Preprocessing\PreprocessedData\go_nogo\'];      %Folder where the preprocessed data is to be stored Preprocessed Data
end

%% extract participant code
files = struct2table(dir(fullfile(input_dir,'*.mat')));
participant_filenames = files.name;
participant_codes = cell(size(participant_filenames));

for i = 1:length(participant_filenames)
    
    id = participant_filenames{i};
    participant_codes{i} = id(1:(length(id)-4));
    
end

clear files participant_filenames
%% loop through participants
for part = 1:length(participant_codes)
    part_code = participant_codes(part) %Informing in the command window about which participant is being processed. 
    filename = [input_dir, char(part_code), '.mat'];
    EEG_data = load(filename);

    %% Create vector containing the response types
    events = struct2table(EEG_data.Data.data.EEG.event);
    events_response = events(strcmp(events.Event, 'Response'),:);
    
    if AnalysisName == "Flanker_MVPA"
        for i = 1:(height(events_response))
            if events_response.ACC(i) == 1
               events_response.responsetype(i) = 1;
            elseif events_response.ACC(i) == 0
               events_response.responsetype(i) = 2;
            else 
               events_response.responsetype(i) = 0;    
            end
        end
    elseif AnalysisName == "GoNoGo_MVPA" 
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


    %% Compute LRP 
    % Create EEG substructures from 3d EEGmatrix containing only trials from LRP electrodes (channels x dp x trials)
    chanlocs = struct2table(EEG_data.Data.data.EEG.chanlocs);
    Electrodes = upper(strsplit(EEG_data.Data.StepHistory.Electrodes, ", ")); 
    lrp_chanlocs=[find(strcmp(chanlocs.labels, Electrodes(1))) find(strcmp(chanlocs.labels, Electrodes(2)))]; %only use LRP electrodes of interest
    
    EEG_data.Data.data.EEG = pop_select(EEG_data.Data.data.EEG, 'channel', lrp_chanlocs); %remove other channels from EEG structure
    
    clear chanlocs lrp_chanlocs

    %find indices from left and righz hemisphere electrodes to ensure that 
    %right hemisphere electrode acitivty is substracted from the left later on
    chanlocs_remain = struct2table(EEG_data.Data.data.EEG.chanlocs);
    left_hemisphere = find(strcmp(chanlocs_remain.labels, Electrodes(1)));
    right_hemisphere = find(strcmp(chanlocs_remain.labels, Electrodes(2)));
    
    clear Electrodes chanlocs_remain

    %create matrix for LRP (dp x trials)
    EEG_data.Data.data.EEG.data_lrp = zeros(length(EEG_data.Data.data.EEG.data(1,:,1)), length(EEG_data.Data.data.EEG.data(1,1,:)));
    for i = 1:length(EEG_data.Data.data.EEG.data(1,1,:)) % number of trials
        for ii = 1:length(EEG_data.Data.data.EEG.data(1,:,1)) % number of data points
            EEG_data.Data.data.EEG.data_lrp(ii,i) = EEG_data.Data.data.EEG.data(left_hemisphere,ii,i) - EEG_data.Data.data.EEG.data(right_hemisphere,ii,i); 
        end
    end
    clear i ii left_hemisphere right_hemisphere

    % create substructures for responsetypes (dp x trials)
    EEG_data.Data.data.EEG.data_lrp_correct = EEG_data.Data.data.EEG.data_lrp(:, events_response.responsetype == 1);
    EEG_data.Data.data.EEG.data_lrp_error = EEG_data.Data.data.EEG.data_lrp(:, events_response.responsetype == 2);
    
    %only continue if data set contains any error trials
    if isempty(EEG_data.Data.data.EEG.data_lrp_error)
        fprintf('There are no error trials in the data set. Continuing with next participant.');
        ErrorMessage = "Zero error trials.";
        FileName = strcat(output_dir, 'logs/', "Error_", part_code, ".txt");
        fid = fopen(FileName, 'wt');
        fprintf(fid, ErrorMessage);
        fclose(fid);
    else
        %create participant average across trials (dp)
        %for correct responses
        EEG_data.Data.data.EEG.data_lrp_correct_aver = zeros(length(EEG_data.Data.data.EEG.data_lrp_correct(:,1)),1);
        for iii = 1:length(EEG_data.Data.data.EEG.data_lrp_correct(:,1))
            EEG_data.Data.data.EEG.data_lrp_correct_aver(iii)=mean(EEG_data.Data.data.EEG.data_lrp_correct(iii,:));
        end
        clear iii
        
        %for errors
        EEG_data.Data.data.EEG.data_lrp_error_aver = zeros(length(EEG_data.Data.data.EEG.data_lrp_error(:,1)),1);
        for iii = 1:length(EEG_data.Data.data.EEG.data_lrp_error(:,1))
            EEG_data.Data.data.EEG.data_lrp_error_aver(iii)=mean(EEG_data.Data.data.EEG.data_lrp_error(iii,:));
        end
        clear iii
        
        %add vector with ms
        ms_start = EEG_data.Data.data.EEG.xmin*1000; %start of epoch 
        ms_end = EEG_data.Data.data.EEG.xmax*1000;  %end of epoch
        ms= [ms_start:2:ms_end]'; %create ms vector with time steps of 2 ms
        
        EEG_data.Data.data.EEG.data_lrp_correct_aver(:,2)=ms;
        EEG_data.Data.data.EEG.data_lrp_error_aver(:,2)=ms;
        
        %add vector with id
        id = cell2table(part_code);
        id = repmat(id,length(ms),1);
        EEG_data.Data.data.EEG.data_lrp_correct_aver = array2table(EEG_data.Data.data.EEG.data_lrp_correct_aver);
        EEG_data.Data.data.EEG.data_lrp_correct_aver(:,3) = id;
        EEG_data.Data.data.EEG.data_lrp_error_aver = array2table(EEG_data.Data.data.EEG.data_lrp_error_aver);
        EEG_data.Data.data.EEG.data_lrp_error_aver(:,3) = id;
        
        clear id
    
        %add column names
        colNames={'amplitude', 'dp', 'id'};
        EEG_data.Data.data.EEG.data_lrp_correct_aver.Properties.VariableNames = colNames;
        EEG_data.Data.data.EEG.data_lrp_error_aver.Properties.VariableNames = colNames;
    
        %create one output file for all participants
        %for correct responses
        if exist('data_lrp_correct_aver', 'var') == 0
           data_lrp_correct_aver = EEG_data.Data.data.EEG.data_lrp_correct_aver; %create new if it doesn't exist
        else 
           if ismember(part_code, data_lrp_correct_aver.id) == 0 %only append when current part has not been appended 
           data_lrp_correct_aver = vertcat(data_lrp_correct_aver, EEG_data.Data.data.EEG.data_lrp_correct_aver); %append if it exists
           end
        end
    
        %for errors
        if exist('data_lrp_error_aver', 'var') == 0
           data_lrp_error_aver = EEG_data.Data.data.EEG.data_lrp_error_aver;
        else 
           if ismember(part_code, data_lrp_error_aver.id) == 0
            data_lrp_error_aver = vertcat(data_lrp_error_aver, EEG_data.Data.data.EEG.data_lrp_error_aver);
           end
        end
    
        clear EEG_data

    end
    
end

%Save output files
out_file_correct = [output_dir 'data_lrp_correct_aver.mat'];
save(out_file_correct, 'data_lrp_correct_aver');

out_file_error = [output_dir 'data_lrp_error_aver.mat'];
save(out_file_error, 'data_lrp_error_aver');
