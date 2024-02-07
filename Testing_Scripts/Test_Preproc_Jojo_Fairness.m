%% File to test Forking Path Analysis for Review only
% (1) prepares and adds all necessary files - no changes here
% (2) allows to run each step separately - check steps there!!
% How to?? 1) Run Section (1), then line by line, run Section (2)


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (1) Preparation to run preprocessing Steps - No Changes Here (only
% possible change is line 17, different subject)
% Set Up Analysis Specific Information
AnalysisName = "Ultimatum_Fairness";
% name of Task that should be analysed, used to import right files and structure outputs
ImportedTask = "UltimatumGame";
%besides the common preprocessing, additional functions to be run
Step_Functions_To_Add = ["Epoching_Tasks", "Quantification_Ultimatum_Fairness"]; 
% Name of Subject to run, Alternatives are "sub-AU06EL20", "sub-AA06WI11", "sub-AM04EN20"
SubjectName = "sub-AM04EN20"; % <===== only possible change!


% Setup some Folders and Name of Files based on where the current script is
% located
[RootFolder] = fileparts(matlab.desktop.editor.getActiveFilename);
RootFolder = strrep(RootFolder,'Testing_Scripts', '');
RawFolder=strcat(RootFolder, "Only_ForGit_To_TestRun/RawData/task-", ImportedTask, "/" );
DesignFile=strcat(RootFolder, "Only_ForGit_To_TestRun/ForkingFiles/", AnalysisName, "/DESIGN.mat");
File_to_Import = strcat(SubjectName, "\eeg\", SubjectName, "_task-", ImportedTask, "_eeg.set");

% Add Relevant Paths including predefined functions and eeglab functions
addpath(genpath(strcat(RootFolder, "Analysis_Functions/")))
rmpath(genpath(strcat(RootFolder, "Analysis_Functions/eeglab2022.0")))
addpath(strcat(RootFolder, "Analysis_Functions/eeglab2022.0"))
eeglab
% Add Paths relevant for the Preprocessing of this specific Analysis 
Step_Functions_To_Add = ["Preprocessing_All", Step_Functions_To_Add];
for iStepFunction = 1:length(Step_Functions_To_Add)
    addpath(strcat(RootFolder, "Step_Functions/",Step_Functions_To_Add(iStepFunction)));
end

% load Design to check Steps, loaded as Variable DESIGN
load(DesignFile)

% Prepare INPUT structure
INPUT_init = [];
f = fieldnames(DESIGN)';
f{2,1} = {NaN};
INPUT_init = struct('Subject',{SubjectName},'StepHistory',{struct(f{:})},...
    'Inputfile',{NaN}, 'AnalysisName', {AnalysisName});



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (2) Section to run all Preprocessing Steps, step-by step
% The comments list all possible alternatives, with the first option being
%              the main path
% Each line represents one preprocessing step and can be run separately
% Each line calls the respective "Step Function". These can be viewed by
%              entering >> open("Resampling") etc., 
% To test, Breakpoints can be added in these files to run the steps
%              till then(clicking on the hyphen next to the line number 
%              on the left side places a red dot). This can be used to run
%              each line separately. 
% Instead of Breakpoints, the code can also be run from the source editor.
%             The Step Functions use 2 inputs: the variable INPUT (that
%             includes Data and Info on the Analysis) and Choice. INPUT
%             will be updated below, however you need to assign a value to
%             the variable Choice if you want to run it like that
%             Choice = "500" (the choice that should be run from below)
% Important: The Variable INPUT is constantly overwritten in this example.
%            If you want to compare before and after, you need to rename
%            the variables or create a copy.
% The Data (EEG structures, or Exported Values) are in field INPUT.data


INPUT = Resampling(INPUT_init, "500", SubjectName, RawFolder, File_to_Import);  %   "500"    "250"    "125"
INPUT = Reference_AC(INPUT, "Cz");  %   "Cz"    "CAV"    "Mastoids" 
INPUT = Bad_Channels(INPUT, "EPOS"); % "EPOS"    "Makoto"    "HAPPE"    "PREP"    "FASTER"    "APPLE"    "CTAP"    "No_BadChannels"
INPUT = Bad_ChannelsMax(INPUT, "Applied"); %   "Applied"    "No_MaxBadChannels"
INPUT = LP_Filter_Early(INPUT, "No_LP_Early"); %    "No_LP_Early"    "30"    "40"    "60"
INPUT = HP_Filter(INPUT, "0.05"); %"0.05"    "0.1"    "0.5"    "No_HP"
INPUT = LineNoise_Filter(INPUT, "PREP"); %    "PREP"    "No_LineNoiseFilter"
INPUT = Epoching_AC(INPUT, "no_continous"); %  "no_continous"    "epoched"
INPUT = Detrending(INPUT, "Applied"); %    "Applied"    "No_Detrending"
INPUT = Bad_Segments(INPUT, "ASR"); %  "ASR", "Threshold_500", "Threshold_300", "Probability+Kurtosis+Frequency", "EPOS", "No_BadSegments"
INPUT = Run_ICA(INPUT, "ICA"); %  "ICA"    "No_ICA"
INPUT = OccularCorrection(INPUT, "ICLabel"); % "ICLabel"    "EPOS"    "ADJUST"    "MARA"    "FASTER"    "APPLE"    "Gratton_Coles"    "No_OccularCorrect…"
INPUT = LP_Filter_Later(INPUT, "30"); %  "30"    "40"    "60"    "No_LP_Later"
INPUTBU = INPUT;
INPUT = Bad_Epochs(INPUT, "FASTER"); %  "FASTER", "Threshold_100", "Threshold_120", "Threshold_150", "Threshold_200", "Probability+Kurtosis+Frequency_3.29SD", "No_BadEpochs"

INPUT = Reference(INPUT, "CAV"); %  "CAV"      "Mastoids"  "CSD" 
INPUT = Baseline(INPUT, "-200 0"); %  "-200 0"    "-500 0"    "-100 0"

INPUT = Cluster_Electrodes(INPUT, "no_cluster"); %    "no_cluster"    "cluster"
INPUT = Electrodes(INPUT, "Fz,Fcz,Cz"); % "Fz,Fcz,Cz"    "Fz, FCz, Cz, FC1, FC2"    "Fcz,Cz"    "Fcz"    "Cz"    "Fz"
INPUT = TimeWindow(INPUT, "200,400"); %  ["Relative_Group_wide", "Relative_Group_narrow", "Relative_Subject", "200,400", "250,350"];
INPUT1 = Quantification_ERP(INPUT, "Mean"); %  "250,500"    "200,400"    "300,350"    "Relative_Group"
