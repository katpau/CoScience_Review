   %% This scripts runs all mvpa analyses

%% Specifications
%Preprocessing
first_part = 1; %index of first participant in folder to analyse
last_part = 5; %index of last participant in folder to analyse 

%Main analyses
participants = [1:5]; % index of participants in PreprocessedData to analyse

global AnalysisName;
AnalysisName = "Flanker_MVPA"; %or "GoNoGo_MVPA" 

%% Add Relevant Paths 
global bdir;
bdir = pwd; % Base directory

addpath(genpath(strcat(bdir, "/Only_ForGit_to_TestRun/")))
addpath(genpath(strcat(bdir, "/Analysis_Functions/MVPA/")))


%% Preprocessing
% run for all specified participants

for part = first_part:last_part   
    try
        prep_mvpa(part)      
    catch 
        fprintf('Participant %d does not exist \n', part)   
    end    
end

%% First-level Analyses
error = 1;
for part = participants
    for group = 1
        try
            DECODING_ERP('coscience', 1, 0, part, group, 0);
        catch
            protocol(error, 1) = part;
            protocol(error, 2) = group;
            error = error + 1;
        end 
    end 
end 

%% Second-level Analyses
ANALYSE_DECODING_ERP('coscience',1,0,'all',1)