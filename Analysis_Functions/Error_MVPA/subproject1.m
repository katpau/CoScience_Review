%% This scripts runs all lrp and mvpa analyses and compares the lrp and mvpa onsets

%% Specifications 
global AnalysisName;
AnalysisName = "GoNoGo_MVPA"; %or "Flanker_MVPA" 

%Preprocessing MVPA
first_part = 1; %index of first participant in folder to analyse
last_part = 2; %index of last participant in folder to analyse 

%Main analyses MVPA
participants = [1:2]; % index of participants in PreprocessedData to analyse

%% Add Relevant Paths 
global bdir;
bdir = pwd; % Base directory

addpath(genpath(strcat(bdir, "/Only_ForGit_to_TestRun/")))
addpath(genpath(strcat(bdir, "/Analysis_Functions/Error_MVPA/")))

% %% LRP
% % Preprocessing 
% prep_lrp
% 
% % Jackknifing
% jackknifing_lrp
% 
% %% MVPA
% % Preprocessing
% % run for all specified participants
% 
% for part = first_part:last_part   
%     try
%         prep_mvpa(part)      
%     catch 
%         fprintf('Participant %d does not exist \n', part)   
%     end    
% end
% 
% % First-level Analyses
% error = 1;
% for part = participants
%     for group = 1
%         try
%             DECODING_ERP('coscience', 1, 0, part, group, 0);
%         catch
%             protocol(error, 1) = part;
%             protocol(error, 2) = group;
%             error = error + 1;
%         end 
%     end 
% end 
% 
% % Second-level Analyses
% ANALYSE_DECODING_ERP('coscience',1,0,'all',1)

%% Compare lrp and mvpa onsets
%load lrp data
if strcmp(AnalysisName, "Flanker_MVPA")
      input_dir_lrp = [bdir '\Analysis_Functions\Error_MVPA\LRP\lrp_onsets\flanker\'];   
 elseif strcmp(AnalysisName, "GoNoGo_MVPA") 
    input_dir_lrp = [bdir '\Analysis_Functions\Error_MVPA\LRP\lrp_onsets\go_nogo\'];  
end

filename_lrp = [input_dir_lrp, 'lrp_onsets.mat'];
load(filename_lrp);

%load mvpa data
if strcmp(AnalysisName, "Flanker_MVPA")
      input_dir_mvpa = [bdir '\Analysis_Functions\Error_MVPA\MVPA\02_MVPA\DECODING_RESULTS\level_1\flanker\'];   
 elseif strcmp(AnalysisName, "GoNoGo_MVPA") 
    input_dir_mvpa = [bdir '\Analysis_Functions\Error_MVPA\MVPA\02_MVPA\DECODING_RESULTS\level_1\go_nogo\'];  
end

filename_mvpa = [input_dir_mvpa, 'all_part_acc.mat'];
load(filename_mvpa);

%jackknife mvpa onset
% compute mean decoding accuracy for every time step when id = i is left out
part = unique(all_part_accuracies.id);

for i = 1:length(part)
    remove_part = ismember(all_part_accuracies.id, part(i)); % define participant to leave out
    data_subset = all_part_accuracies(~remove_part,:); % leave participant out
    data_new = groupsummary(data_subset, "timestep", "mean", ["subj_acc", "subj_perm_acc"]); %compute average of amplitudes across remaining ids for each time step
    id = repmat(part(i),length(data_new.timestep),1);
    data_new =  [cell2table(id), data_new]; % append participant code that has been leftout
    colNames={'id', 'timestep', 'groupcount', 'subj_acc', 'subj_perm_acc'};
    data_new.Properties.VariableNames = colNames;
    if exist('jack_all_part_acc', 'var') == 0
       jack_all_part_acc = data_new;
    else 
         if ~ismember(part(i), jack_all_part_acc.id)
            jack_all_part_acc = vertcat(jack_all_part_acc, data_new); %append to existing data frame
         end
    end
    clear remove_part data_subset data_new id 
end

clear part i 

% determine decoding accuracy threshold for mvpa onset (mean perm_acc + 50% of difference between mean perm_acc and max subj_acc) 
max_subj_acc = groupsummary(jack_all_part_acc, "id", "max", "subj_acc"); 
mean_perm_acc = groupsummary(jack_all_part_acc, "id", "mean", "subj_perm_acc"); 
mean_acc = join(max_subj_acc, mean_perm_acc);
mean_acc.mvpa_criterion = mean_acc.mean_subj_perm_acc + (mean_acc.max_subj_acc - mean_acc.mean_subj_perm_acc)*0.5; 

for i = 1:length(jack_all_part_acc.timestep)
    for ii = 1:length(mean_acc.id)
        if ismember(jack_all_part_acc.id(i), mean_acc.id(ii)) 
            if jack_all_part_acc.subj_acc(i) >= mean_acc.mvpa_criterion(ii)
               jack_all_part_acc.threshold(i) = 1;
            else 
                jack_all_part_acc.threshold(i) = 0;
            end
        end
    end
end

clear i ii

% determine mvpa onset as first time step where decoding accuracy exceeds threshold
mean_acc.mvpa_onset = zeros([length(mean_acc.id), 1]);
for i = 1:length(mean_acc.id)
    part_code = mean_acc.id(i);
    part_onset = jack_all_part_acc(ismember(jack_all_part_acc.id, part_code),:);  
    mean_acc.mvpa_onset(i) =  jack_all_part_acc.timestep(find(part_onset.threshold, 1, 'first'));

    clear part_code part_onset
end

clear i

% smulders transformation to obtain individual latencies
mean_acc.mvpa_smulders = zeros([length(mean_acc.id), 1]);
for i = 1:length(mean_acc.id)
    mean_acc.mvpa_smulders(i) = length(mean_acc.mvpa_onset)*mean(mean_acc.mvpa_onset)-(length(mean_acc.mvpa_onset)-1)*mean_acc.mvpa_onset(i);
end

%merge datasets
mvpa_onsets = [mean_acc(:,1)  mean_acc(:,7)];
lrp_onsets = [max_amp(:,1) max_amp(:,6)];
onsets = join(mvpa_onsets, lrp_onsets);

%test lrp onsets against mvpa onsets
[h,p,~,stats] = ttest(onsets.mvpa_smulders, onsets.lrp_smulders, "Tail", "right");

%test mvpa onset against response onset
[h,p,~,stats] = ttest(onsets.mvpa_smulders);