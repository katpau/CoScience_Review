%% File to test Forking Path Analysis of the Statistics for Review only
% This script helps the user to run specific Steps for close following of what happens

% Necessary Input 1: Analysis Name to load correct Step_Functions
AnalysisName = "Error_MVPA" % <<<<============================================
% choice from: 
% * Alpha_Resting (Cassie)
% * Alpha_Context (Kat)
% * Error_MVPA (Elisa)
% * Flanker_Conflict (Corinna)
% * Gambling_RewP (Anja)
% * Gambling_N300H (Erik)
% * GoNoGo_Conflict (Andre)
% * Ultimatum_Offer (Jojo)


% Necessary Input 1: Path of current project
[RootFolder] = fileparts(matlab.desktop.editor.getActiveFilename); % use this function or adjust here
% source input Function and prepare data to get correct file structure
run([RootFolder, '/Troubleshooting_RDF_source.m'])




% Necessary Input 2: Which Forking Combination should be tested 
Test_Fork = 2; % <<<<============================================
% Necessary Input 3: Which Step and choice should be tested
Test_Step = "HP_Filter" % <<<<============================================
Choice = "0.05"         % <<<<============================================




% Prepare Data till that Step (or get it if prepared earlier)
MaxStep = find(Test_Step == fieldnames(DESIGN))-1;
INPUT = parfor_Forks_notParallel(IndexSubjectsSubset, ListFile,  DESIGN, OUTPUT(Test_Fork), OutputFolder, ...
    RawFolder, MatlabAnalysisName, MaxStep,    RetryError, LogFolder, ParPools, PrintLocation);




%%%%%%%%%%%%%%% 
% Run Test of Interest
open(Test_Step) %  go and open the Step function of interest and run each line seperatly




