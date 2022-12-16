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
[RootFolder] = fileparts(matlab.desktop.editor.getActiveFilename);
RootFolder = strcat(RootFolder,'/');
addpath(RootFolder)

% Following inputs are flexible (use example of Alpha in different Contexts)
SubjectToTest = "sub-AM04EN20"; % Name of Subject to run, is actually based on Subjects in Raw Data
% Alternative "sub-AU06EL20", "sub-AA06WI11"
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
addpath(genpath(strcat(RootFolder, "Analysis_Functions/")))
rmpath(genpath(strcat(RootFolder, "Analysis_Functions/eeglab2022.0")))
cd(strcat(RootFolder, "Analysis_Functions/eeglab2022.0"))
eeglab
% Add Paths relevant for the Preprocessing of this specific Analysis (some
% analyses differ in their choices and oiptions)
Step_Functions_To_Add = ["Preprocessing_All", Step_Functions_To_Add];
for iStepFunction = 1:length(Step_Functions_To_Add)
    addpath(strcat(RootFolder, "Step_Functions/",Step_Functions_To_Add(iStepFunction)));
end



% other inputs that forking function takes, to manage parallelisation
IndexSubjectsSubset = "1"; % if multiple Forking Files are listed in the csv file, index which one should be run (here always 1)
RetryError="0" ; % usually, if error ocurrs, stop step and all combinations that include that fork. if errors should be retried, change here to "1"
ParPools="3"; % how many parallel instances can be run
PrintLocation = "0"; % some lines can be printed to console to make it easier to navigate errors (change to "1" if desired)

%% copied already from parfor_Forks
% Load Design
Import = load(DesignFile);
DESIGN = Import.DESIGN;
clearvars Import;

% Correct Design if Steps are not in correct order
% Get all Steps and all Choices from the Design Structure (important for
% indexing the Combination)
Steps =fieldnames(DESIGN);
Order = zeros(length(Steps),2);
for iStep = 1:length(Steps)
    Order(iStep,:) =[iStep, DESIGN.(Steps{iStep}).Order];
end
Order = sortrows(Order,2);
Steps = Steps(Order(:,1));


% Load OUTPUT File with List of Forks
% Get Name of OUTPUT File that should be run
OUTPUT_List = table2cell(readtable( ListFile, 'ReadVariableNames', false, 'Delimiter', ' '));  % read csv file with subject Ids to be run
OUTPUT_File = OUTPUT_List{1};
[~, OUTPUT_Name] = fileparts(OUTPUT_File);
clearvars OUTPUT_List

% Load OUTPUT File (= File with Forking List)
Import = load(OUTPUT_File);
OUTPUT = Import.OUTPUT;

%%
disp("*********************")
disp("All Steps that can be tested (in order):")
disp(fieldnames(DESIGN))
disp("*********************")
