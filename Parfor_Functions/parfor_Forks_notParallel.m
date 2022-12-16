function  Data = parfor_Forks_notParallel(IndexSubset, SubsetFile, DESIGN, OUTPUT, OutputFolder, ImportFolder, AnalysisName, MaxStep, RetryError, LogFolder, ParPools, PrintLocation)
% for each Subject, carries out all RDF combinatins as defined in
% OUTPUT(a .mat file)
% Output: For each Subject, creates a structure including EEG.Data,
%         Subjectname, StepHistory, InputFile and Miscellaneous
%         applies corresponding step_functions to the data
%         saves final file (or interims) as Subject.mat in a folder
%         with the corresponding step/choice combination, e.g. 1.1_2.3
%
% Inputs
%       IndexSubset: Integer, to manage parallelization on several nodes; points to subset of forkingList;
%		SubsetFile: String, pointing to list of Forks (OUTPUTS) to be
%		analyzed (completed ones are removed in separate function). Name of
%       this file includes Subject Info
%       DESIGN: string, Full FileName (incl. Path) to Structure including all possible Steps and Choices
%       OUTPUT: Kept for keeping function similar to parfor Main Path
%       ImportFolder: String pointing to the Folder that includes all raw files (in BIDS structure)
%       AnalysisName: string, used to decide which events should be
%                       extracted (see Step Function of Bad_Segments and Bad_Epochs
%                       for how this is used).
%       MaxStep: string, If not all Combinations should be calculated already, but
%               only to certain step (e.g. because data collection not finished and
%               Step requires all Subs, or because you want to delete interim data)
%       RetryError: string ("0"|"1"). When step was run before and resulted in an error, try
%               stepagain ("1"). Default is "0"
%       OutputFolder: String pointing to the Folder where Data should be saved
%       LogFolder: String pointing to the Folder where Logs should be saved
%       ParPools: String. how many parallel instances of matlab can be
%                    run, Default "16"
%       PrintLocation: string, "1" or "0", some indexes of currently ran
%                  lines can be printed to console if set to 1, Default is "0"
%       Note: All inputs are given as string as these are provided outside
%       Matlab and therefore always parsed as strings.

tic

% °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
% °°°°°°° Preparations °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
% °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
%% Parse Inputs Get SubjectID from List of Forks (named after subject)
[~, Subject] = fileparts(SubsetFile);
% Show input to this function
disp(Subject)
disp(OutputFolder)
disp(ImportFolder)
disp(AnalysisName)

% Set Up Export Folders if they do not exist yet
if ~contains(OutputFolder(end), filesep)
    OutputFolder = strcat(OutputFolder, filesep);
end


%% Complete all Inputs
% check if Max Step is specified, otherwise use all Steps
if nargin<8;    MaxStep = "0"; end
if nargin<9;   RetryError = "0"; end
if nargin<10;  LogFolder = OutputFolder; end
if nargin<11;   ParPools = "16"; end
if nargin<12;    PrintLocation = "0"; end

% make input numeric
RetryError = str2double(RetryError);
ParPools = str2double(ParPools);
PrintLocation = str2double(PrintLocation);

% Initate some Variables for Logkeeping
Dummy = [];

%% Set Up Folders for export and logging
OutputFolder = fullfile(OutputFolder);
if ~exist(OutputFolder, 'dir'); mkdir(OutputFolder); end
ErrorFolder = strcat(LogFolder, "ErrorMessages/");
if ~exist(ErrorFolder, 'dir'); mkdir(ErrorFolder); end
CompletionFolder =strcat(LogFolder, "/CompletionStatus/");
if ~exist(CompletionFolder, 'dir'); mkdir(CompletionFolder); end

if PrintLocation == 1; fprintf('Line 127\n'); end



% °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
% °°°°°°° Translate Choices into numeric ForkCombinations °°°°°°
% °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
%% PREPARE Step COMBINATION and test if to run
% Loop throgh each Step and get the Index of that Step/Choice
% combination. Concatenate all of them together to create the
% "FinalFolder" Name, which includes all Step/Choice Combinations
% Basically Translate the Verbal Description of Step/Choices into
% numeric indices (as Filepaths would be too long otherwise)

% Get Name of Choice for each Step from Forking List
OUTPUT_Choices = split(OUTPUT, '%')';


% Initate Name of Folder
Steps = fieldnames(DESIGN);
OUTPUT_FolderName = repmat("FF", size(OUTPUT_Choices));
for iStep = 1:length(Steps)
    Choices = DESIGN.(Steps{iStep}).Choices;
    for iChoice = 1:length(Choices)
        OUTPUT_FolderName(strcmp(OUTPUT_Choices(:, iStep), Choices{iChoice}),iStep) = iStep + "." + iChoice ;
    end
end

if PrintLocation == 1; fprintf('Line 158\n'); end


%%% Initate Summary Tables printed at the end
CountErrors = 0;
CountPreviouslyCompleted = 0;
CountCompleted = 0;
RetryFork =  ones(size(OUTPUT_Choices,1), 1);

% Prepare Matlabpool
% delete(gcp('nocreate')); % make sure that previous pooling is closed
% distcomp.feature( 'LocalUseMpiexec', false );
% parpool(ParPools);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
% °°°°°°° Run Forking Path Combination °°°°°°°°°°°°°°°°°°°°°°°°°
% °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
% This was put into a function to reduce the output text printed to the logfiles
% Since some combinations might in in progress at the first time of trying
% to run it, a note is created to retry it again (RetryFork). However, the
% Loop only attempts to retry this a limited time
% Retry if conflicts ocurred
Retry_Loop_Max = 0;


if PrintLocation == 1; fprintf('Line 216\n'); end

% Work only through the combinations that need to be retried (had to be
% done like this as parfor only accepts contionusly increasing
% parallelisation)
OUTPUT_Choices = OUTPUT_Choices(find(RetryFork)',:);
OUTPUT_FolderName = OUTPUT_FolderName(find(RetryFork)',:);
RetryForkOUT = zeros(size(OUTPUT_Choices,1),1);
CountErrorsOUT = zeros(size(RetryForkOUT));
CountCompletedOUT = zeros(size(RetryForkOUT));
CountPreviouslyCompletedOUT = zeros(size(RetryForkOUT));

% Loop through all Forking Combinations
% change to for (instead of parfor if checking manualy)
iPath = 1
RunningFileName = NaN;
ErrorFileName = strcat(LogFolder,  Subject, '_errorImport.mat');

%% if not Started at all, initate data
Data = [];
f = fieldnames(DESIGN)';
f{2,1} = {NaN};
Data = struct('Subject',{Subject},'StepHistory',{struct(f{:})},...
    'Inputfile',{NaN}, 'AnalysisName', {AnalysisName});


%% RUN REMAINING Steps
% Carry out remaining steps. Each Step is run after each other.
% File is kept in memory until new Combination is done (completed or error).

Choice = OUTPUT_Choices(iPath, iStep);

%% Find "Highest" Path that was already calculated
FileFound = 0;
steps_already_done = MaxStep+1;
StopPath = 0;
while FileFound == 0 & steps_already_done > 0
    steps_already_done = steps_already_done -1;
    Test_completed = strcat(OutputFolder, "/", join(OUTPUT_FolderName(iPath,1:steps_already_done), '_'), "/", Subject, '.mat');
    
    if isfile(Test_completed) % has this step been completed?
        FileFound = 1;
    end
end


%% if not Started at all, initate data
if steps_already_done == 0
    Data = [];
    f = fieldnames(DESIGN)';
    f{2,1} = {NaN};
    Data = struct('Subject',{Subject},'StepHistory',{struct(f{:})},...
        'Inputfile',{NaN}, 'AnalysisName', {AnalysisName});
    if PrintLocation == 1; fprintf('Line 275\n'); end
    
else
    %% if already previous Step found, load it
    % Problems when multiple instances are trying to read data
    Data = load(Test_completed, 'Data');
    Data = Data.Data;
    [~, Data.Inputfile] = fileparts(Test_completed);
    Data.AnalysisName = AnalysisName; % update Analysis Name as continous data might stem from different preproc!
    
    
end % End Load or Initate Data


for iStep = (steps_already_done+1): MaxStep
    %% Run Step
    % Run Step Function for this Step and Choice. Initate some
    % Variables
    % If First Step, Find Raw Data File relevant for this
    if iStep == 1
        RawEEGFile= dir(ImportFolder+"/"+Subject+"/eeg/*.set");
        % if no file there, stop loop
        if isempty(RawEEGFile)
            fprintf('Error: No Raw DataFileFound')
            break
        end
        RawEEGFolder = RawEEGFile(1).folder; %in case there are multiple Folders (e.g. Resting)
        RawEEGFile = RawEEGFile(1).name;
        Data=run_first_step(Steps{iStep}, Data, Choice, Subject, RawEEGFolder, RawEEGFile);
    else
        % if not first Step
        Data=run_step(Steps{iStep}, Data, Choice);
    end
    
    
    % After Step is done, check success of it
    if ~isfield (Data, 'Error')
        InterimFolder = strcat(OutputFolder, "/", join(OUTPUT_FolderName(iPath,1:iStep), '_'), "/");
        InterimFileName = strcat(InterimFolder,  Subject, '.mat');
        if ~exist(InterimFolder, 'dir'); mkdir(InterimFolder); end
        
        parfor_save(InterimFileName, Data);
        
    else
        %% Step gave Mistake
        % if an error occurrs when running the Step, make a log
        fprintf('Error ocurred with Step %s. \n The returned Error Message is \n %s \n', ...
            Steps{iStep}, Data.Error );
        break % out of Step loop
    end
end

