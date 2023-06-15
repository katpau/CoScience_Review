%% This script computes the LRP

global AnalysisName;
global bdir;

%% specifications

ms_start = -300;
ms_end = 299;

%% directories
if AnalysisName == "Flanker_MVPA"
    input_dir = [bdir '\Only_ForGit_To_TestRun\Preproc_forked\Error_MVPA\task-Flanker\1.1_2.1_3.1_4.1_5.1_6.1_7.1_8.1_9.1_10.1_11.1_12.1_13.1_14.1_15.1/'];   %Folder containing the raw data
    output_dir = [bdir '\Analysis_Functions\Error_MVPA\LRP\preprocessed_data\flanker\'];      %Folder where the preprocessed data is to be stored 
 elseif AnalysisName == "GoNoGo_MVPA" 
    input_dir = [bdir '\Only_ForGit_To_TestRun\Preproc_forked\Error_MVPA\task-GoNoGo\1.1_2.1_3.1_4.1_5.1_6.1_7.1_8.1_9.1_10.1_11.1_12.1_13.1_14.1_15.1/'];   %Folder containing the raw data
    output_dir = [bdir '\Analysis_Functions\Error_MVPA\LRP\preprocessed_data\go_nogo\'];      %Folder where the preprocessed data is to be stored Preprocessed Data
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
    C3 = find(strcmp(chanlocs_remain.labels, Electrodes(1)));
    C4 = find(strcmp(chanlocs_remain.labels, Electrodes(2)));
    
    clear Electrodes chanlocs_remain

    % Create vector containing the response types
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

%     %create matrix for LRP (dp x trials) separately for both response types
%     EEG_data.Data.data.EEG.data_lrp = zeros(length(EEG_data.Data.data.EEG.data(1,:,1)), length(EEG_data.Data.data.EEG.data(1,1,:)));
%     for i = 1:length(EEG_data.Data.data.EEG.data(1,1,:)) % number of trials
%         for ii = 1:length(EEG_data.Data.data.EEG.data(1,:,1)) % number of data points
%             EEG_data.Data.data.EEG.data_lrp_correct(ii,i) = EEG_data.Data.data.EEG.data(C3,ii,i) - EEG_data.Data.data.EEG.data(C4,ii,i); 
%             EEG_data.Data.data.EEG.data_lrp_error(ii,i) = EEG_data.Data.data.EEG.data(C4,ii,i) - EEG_data.Data.data.EEG.data(C3,ii,i); %substract C3 from C4 for error trials
%         end
%     end

    %create matrix for LRP (dp x trials) 
    data_lrp = zeros(length(EEG_data.Data.data.EEG.data(1,:,1)), length(EEG_data.Data.data.EEG.data(1,1,:)));
    for i = 1:length(EEG_data.Data.data.EEG.data(1,1,:)) % number of trials
        for ii = 1:length(EEG_data.Data.data.EEG.data(1,:,1)) % number of data points
           data_lrp(ii,i) = EEG_data.Data.data.EEG.data(C3,ii,i) - EEG_data.Data.data.EEG.data(C4,ii,i); 
        end
    end

    clear i ii C3 C4
 
%     EEG_data.Data.data.EEG.data_lrp_correct = EEG_data.Data.data.EEG.data_lrp_correct(:, events_response.responsetype == 1); %correct trials only
%     EEG_data.Data.data.EEG.data_lrp_error = EEG_data.Data.data.EEG.data_lrp_error(:, events_response.responsetype == 2); %error trials only
%     data_lrp = [EEG_data.Data.data.EEG.data_lrp_correct EEG_data.Data.data.EEG.data_lrp_error]; %merge correct and error trials 
    
    %only continue if data set contains any error trials
    data_lrp_error = data_lrp(:, events_response.responsetype == 2); %error trials only
    if isempty(data_lrp_error)
        fprintf('There are no error trials in the data set. Continuing with next participant.');
        ErrorMessage = "Zero error trials.";
        FileName = strcat(output_dir, 'logs/', "Error_", part_code, ".txt");
        fid = fopen(FileName, 'wt');
        fprintf(fid, ErrorMessage);
        fclose(fid);
    else
        %create participant average across trials (dp) 
        EEG_data.Data.data.EEG.data_lrp_aver = zeros(length(data_lrp(:,1)),1);
        for i = 1:length(data_lrp(:,1))
            EEG_data.Data.data.EEG.data_lrp_aver(i) = mean(data_lrp(i,:));
        end

        clear i
    
%         %add vector with ms (only works for 500 Hz srate)
%         ms_start = EEG_data.Data.data.EEG.xmin*1000; %start of epoch 
%         ms_end = EEG_data.Data.data.EEG.xmax*1000;  %end of epoch
    
        % add vector with ms
        if EEG_data.Data.data.EEG.srate == 512
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
        EEG_data.Data.data.EEG.data_lrp_aver = array2table(EEG_data.Data.data.EEG.data_lrp_aver);
        EEG_data.Data.data.EEG.data_lrp_aver(find(ms.del),:) = [];
        ms = table2array(ms);
        del_zeros = find(all(ms ==0, 2));
        ms(del_zeros,:) = [];
        ms = array2table(ms);
        ms.Properties.VariableNames = ["down","base", "diff", "del"];
        EEG_data.Data.data.EEG.data_lrp_aver.ms = ms.base;

        else 
            ms = [ms_start:2:ms_end]'; %create ms vector with time steps of 2 ms
            EEG_data.Data.data.EEG.data_lrp_aver = array2table(EEG_data.Data.data.EEG.data_lrp_aver);
            EEG_data.Data.data.EEG.data_lrp_aver.ms = ms;

        end
    
        clear ms_base ms_down ms

        
        %add vector with id
        id = cell2table(part_code);
        id = repmat(id,length(EEG_data.Data.data.EEG.data_lrp_aver.ms),1);
        EEG_data.Data.data.EEG.data_lrp_aver.id = id.part_code;

        clear id
        
        %add column names
        colNames={'amplitude', 'ms', 'id'};
        EEG_data.Data.data.EEG.data_lrp_aver.Properties.VariableNames = colNames;
    
        %create one output file for all participants
%         part_code = cell2table(part_code);
        if exist('data_lrp_aver', 'var') == 0
           data_lrp_aver = EEG_data.Data.data.EEG.data_lrp_aver; %create new if it doesn't exist
        else 
           if ismember(part_code, data_lrp_aver.id) == 0 %only append when current part has not been appended 
           data_lrp_aver = vertcat(data_lrp_aver, EEG_data.Data.data.EEG.data_lrp_aver); %append if it exists
           end
        end
        
        clear EEG_data
    end
end

%Save output files
out_file = [output_dir 'data_lrp_aver.mat'];
save(out_file, 'data_lrp_aver');
