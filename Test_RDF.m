%% File to test Forking Path Analysis for Review only 
% this is only for testing, since the analysis is done on HUMMEL (UHH
% server) and SLURM (Job scheduler parallelizing across subjects)


% Get path of this master file and add it to current directory. 
% Allows easy running of this script
[RootFolder] = fileparts(matlab.desktop.editor.getActiveFilename); 
RootFolder = strcat(RootFolder,'/');
addpath(RootFolder)

% Following inputs are flexible (use example of Alpha in different Contexts)
AnalysisName = "Alpha_Context"; % name of Analysis, used to structure outputs
ImportedTask = "Resting"; % name of Task that should be analysed, used to import right files and structure outputs
% Alternative : "Stroop"
MatlabAnalysisName = "Resting_Context"; % is used in the step functions for specific choices. Usually the same as Analysis Name unless multiple Tasks are included in the Analysis
% Alternative: "Stroop_Alpha"
SubjectToTest = "sub-AM04EN20"; % Name of Subject to run, is actually based on Subjects in Raw Data
% Alternative "sub-AU06EL20", "sub-AA06WI11"
MaxStep = "20"; % On server analyses are junked and interim files are deleted. This is the highest step that should be analysed. For this test it can be the maximum (for Alpha Context the 20. Step is the Quantification)
DesignFile = "DESIGN"; % Name of .mat file including overview of all Steps (in correct order) and their choices and conditional Statements
ForkingFile = "FORKS"; % name of .mat file including List of Forks to be run in verbose format (name of choices separated by %)


% Setup Folders and Name of Files based on Input
RawFolder=strcat(RootFolder, "Only_ForGit_To_TestRun/RawData/task-", ImportedTask, "/" );
OutputFolder=strcat(RootFolder, "Only_ForGit_To_TestRun/", AnalysisName, "/task-",  ImportedTask, "/" );
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
addpath(genpath(strcat(RootFolder, "Analysis_Functions/")))
rmpath(genpath(strcat(RootFolder, "Analysis_Functions/eeglab2022.0")))
cd(strcat(RootFolder, "Analysis_Functions/eeglab2022.0"))
eeglab
% Add Paths relevant for the Preprocessing of this specific Analysis (some
% analyses differ in their choices and oiptions)
addpath(strcat(RootFolder, "Step_Functions/Preprocessing_All"))
addpath(strcat(RootFolder, "Step_Functions/Epoching_Tasks"))
addpath(strcat(RootFolder, "Step_Functions/Quantification_Alpha"))


% other inputs that forking function takes, to manage parallelisation
IndexSubjectsSubset = "1"; % if multiple Forking Files are listed in the csv file, index which one should be run (here always 1)
RetryError="0" ; % usually, if error ocurrs, stop step and all combinations that include that fork. if errors should be retried, change here to "1"
ParPools="3"; % how many parallel instances can be run
PrintLocation = "0"; % some lines can be printed to console to make it easier to navigate errors (change to "1" if desired)

parfor_Forks(IndexSubjectsSubset,      ListFile,  DesignFile, ForkingFile, OutputFolder, ...
    RawFolder, MatlabAnalysisName, MaxStep,    RetryError, LogFolder, ParPools, PrintLocation)

