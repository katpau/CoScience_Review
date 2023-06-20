%% File to test Forking Path Analysis for Review only
% this is only for testing, since the analysis is done on HUMMEL (UHH
% server) and SLURM (Job scheduler parallelizing across subjects)

AnalysisName = "Error_GMA";
% choice from: 
% * Alpha_Resting (Cassie)
% * Alpha_Context (Kat)
% * Error_MVPA (Elisa)
% * Error_GMA (Olaf)
% * Flanker_Conflict (Corinna)
% * Gambling_RewP (Anja)
% * Gambling_N300H (Erik)
% * GoNoGo_Conflict (Andre)
% * Ultimatum_Offer (Jojo)

% Depending on analysis that should be tested, adjust inputs
switch AnalysisName
    case "Alpha_Context" 
        AnalysisName = "Alpha_Context";
        ImportedTask = "Resting";
        MatlabAnalysisName = "Resting_Context";
        MaxStep = "20";
        Step_Functions_To_Add = ["Epoching_Tasks", "Quantification_Alpha"];
        
    case "Alpha_Resting" 
        ImportedTask = "Resting";
        MatlabAnalysisName = "Alpha_Resting";
        MaxStep = "21";
        Step_Functions_To_Add = ["Epoching_Resting", "Quantification_Alpha"];
        
    case "Error_MVPA" 
        ImportedTask = "Flanker"; % Or GoNoGo
        MatlabAnalysisName = "Flanker_MVPA";
        MaxStep = "16";
        Step_Functions_To_Add = ["Epoching_Tasks", "Quantification_MVPA"];

    case "Error_GMA" 
        ImportedTask = "GoNoGo"; % Flanker or GoNoGo
        MatlabAnalysisName = "GoNoGo_GMA"; % Flanker_GMA or GoNoGo_GMA
        MaxStep = "19";
        Step_Functions_To_Add = ["Epoching_Tasks", "Quantification_GMA"];
        
    case "Flanker_Conflict" 
        ImportedTask = "Flanker";
        MatlabAnalysisName = "Flanker_Conflict";
        MaxStep = "22";
        Step_Functions_To_Add = ["Epoching_Tasks", "Quantification_Flanker_Conflict"];
        
    case "Gambling_RewP" 
        ImportedTask = "Gambling";
        MatlabAnalysisName = "Gambling_RewP";
        MaxStep = "21";
        Step_Functions_To_Add = ["Epoching_Tasks", "Quantification_Gambling_RewP"];
        
    case "Gambling_N300H" 
        ImportedTask = "Gambling"; %
        MatlabAnalysisName = "Gambling_N300H";
        MaxStep = "23";
        Step_Functions_To_Add = ["Epoching_Tasks", "Quantification_N300H"];
        
    case "GoNoGo_Conflict"
        ImportedTask = "GoNoGo"; % name of Task that should be analysed, used to import right files and structure outputs
        MatlabAnalysisName = "GoNoGo_Conflict"; % is used in the step functions for specific choices. Usually the same as Analysis Name unless multiple Tasks are included in the Analysis
        MaxStep = "22"; % On server analyses are junked and interim files are deleted. This is the highest step that should be analysed. For this test it can be the maximum (for Alpha Context the 20. Step is the Quantification). Must correspond to the existing List_Subsets
        Step_Functions_To_Add = ["Epoching_Tasks", "Quantification_GoNoGo_Conflict"];
        
    case "Stroop_LPP" 
        ImportedTask = "Stroop";
        MatlabAnalysisName = "Stroop_LPP";
        MaxStep = "20";
        Step_Functions_To_Add = ["Epoching_Tasks", "Quantification_Stroop_LPP"];
        
    case "Ultimatum_Offer"
        ImportedTask = "UltimatumGame";
        MatlabAnalysisName = "Ultimatum_Offer";
        MaxStep = "21";
        Step_Functions_To_Add = ["Epoching_Tasks", "Quantification_Ultimatum_Offer"];
        
        %     case "Flanker_Error" % Roman
        %         ImportedTask = "Flanker";
        %         MatlabAnalysisName = "Flanker_Error";
        %         MaxStep = "22";
        %         Step_Functions_To_Add = ["Epoching_Tasks", "Quantification_Flanker_Error"];
end

% Get path of this master file and add it to current directory.
% Allows easy running of this script

% [ocs] Using 'matlab.desktop.editor.getActiveFilename' could be confusing, as
% another file might be open in the editor. Instead, we use the file name of the
% script currently running.
RootFolder = fileparts(mfilename('fullpath'));
RootFolder = strcat(RootFolder, '/');
addpath(RootFolder)

% Following inputs are flexible (use example of Alpha in different Contexts)
SubjectToTest = "sub-AA06WI11"; % Name of Subject to run, is actually based on Subjects in Raw Data
% Alternative "sub-AU06EL20", "sub-AA06WI11"
% All: sub-AA06WI11	sub-AG04EN28	sub-AG05AS29	sub-AH17AR05	sub-AHSAER12	sub-AM04EN20	sub-AU06EL20	sub-CH05ER25	sub-ER05EL09
DesignFile = "DESIGN"; % Name of .mat file including overview of all Steps (in correct order) and their choices and conditional Statements
ForkingFile = "FORKS"; % name of .mat file including List of Forks to be run in verbose format (name of choices separated by %)


% Setup Folders and Name of Files based on Input
RawFolder=strcat(RootFolder, "Only_ForGit_To_TestRun/RawData/task-", ImportedTask, "/" );
OutputFolder=strcat(RootFolder, "Only_ForGit_To_TestRun/Preproc_forked/", AnalysisName, "/task-",  ImportedTask, "/" );
LogFolder=strcat(RootFolder, "Only_ForGit_To_TestRun/Logs/",AnalysisName, "/task-",  ImportedTask, "/" );
ListFolder= strcat(RootFolder, "Only_ForGit_To_TestRun/ForkingFiles/", AnalysisName, "/List_Subsets/", ImportedTask, "/",MaxStep, "/");

ForkingFile=strcat(RootFolder, "Only_ForGit_To_TestRun/ForkingFiles/", AnalysisName, "/", ForkingFile, ".mat");
DesignFile=strcat(RootFolder, "Only_ForGit_To_TestRun/ForkingFiles/", AnalysisName, "/", DesignFile, ".mat");

% in final analysis there are more than one Forking File (to junk analysis
% better), therefore there is also a file for each Subject listing which
% ForkingList Files should be done. This file is created separately by checking
% if any combinations were completed before (completed ones create a note)
% For this test here just create one that includes the Full File Name to the
% ForkingFile (needs to be created because it includes the full file name)
ListFile = strcat(ListFolder,  SubjectToTest, ".csv");
writetable(table(ForkingFile),ListFile, 'WriteVariableNames',0);

% Add Relevant Paths including predefined functions and eeglab functions
addpath(strcat(RootFolder, "Parfor_Functions/"))

% Add Analysis Functions
% [ocs] Remove EEGLAB paths and let it handle its paths
afPaths = genpath(strcat(RootFolder, "Analysis_Functions/"));
afSplit = strsplit(afPaths, ':');
% Remove all subfolders of eeglab2022
afSplit = afSplit(cellfun(@(x) ~contains(x, ['eeglab2022.0', filesep]), afSplit));
addpath(strjoin(afSplit, ':'));
eeglab('nogui');

% Add Paths relevant for the Preprocessing of this specific Analysis (some
% analyses differ in their choices and oiptions)
Step_Functions_To_Add = ["Preprocessing_All", Step_Functions_To_Add];
for iStepFunction = 1:length(Step_Functions_To_Add)
    addpath(strcat(RootFolder, "Step_Functions/",Step_Functions_To_Add(iStepFunction)));
end



% other inputs that forking function takes, to manage parallelisation
IndexSubjectsSubset = "1"; % if multiple Forking Files are listed in the csv file, index which one should be run (here always 1)
RetryError="0" ; % usually, if error ocurrs, stop step and all combinations that include that fork. if errors should be retried, change here to "1"
ParPools="6"; % how many parallel instances can be run
PrintLocation = "0"; % some lines can be printed to console to make it easier to navigate errors (change to "1" if desired)


% parfor_Forks(IndexSubjectsSubset,      ListFile,  DesignFile, ForkingFile, OutputFolder, ...
%     RawFolder, MatlabAnalysisName, MaxStep,    RetryError, LogFolder, ParPools, PrintLocation)


% if only Main Path needs to be run comment out call parfor_Forks above and
% use this instead

SubjectListFile=strcat(RootFolder, "Only_ForGit_To_TestRun/ForkingFiles/", AnalysisName, "/List_Subjects-Main.csv");
parfor_MainPath(IndexSubjectsSubset, SubjectListFile, DesignFile, ForkingFile, OutputFolder, ...
   RawFolder, MatlabAnalysisName, "10", RetryError, LogFolder, ParPools, PrintLocation)


% CS: comment for testing commits
