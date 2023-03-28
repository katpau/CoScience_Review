%% This scripts runs all lrp analyses

%% Specifications
global AnalysisName;
AnalysisName = "Flanker_MVPA"; %or "GoNoGo_MVPA" 

%% Add Relevant Paths 
global bdir;
bdir = pwd; % Base directory

addpath(genpath(strcat(bdir, "/Only_ForGit_to_TestRun/")))
addpath(genpath(strcat(bdir, "/Analysis_Functions/MVPA/")))


%% Preprocessing
prep_lrp

%% Jackknifing
jackknifing_lrp