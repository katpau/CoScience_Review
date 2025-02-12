function  parfor_MainPath(IndexSubjects, SubjectListFile, DESIGN, OUTPUT, OutputFolder, ImportFolder, AnalysisName, SubsetSize, RetryError, LogFolder, ParPools, PrintLocation, StepsToSave)

% for each Subject, carries out all RDF combinatins as defined in
% OUTPUT(a .mat file)
% Output: For each Subject, creates a structure including EEG.Data,
%         Subjectname, StepHistory, InputFile and Miscellaneous
%         applies corresponding step_functions to the data
%         saves final file (or interims) as Subject.mat in a folder
%         with the corresponding step/choice combination, e.g. 1.1_2.3
%
% Inputs
%       IndexSubjects: Integer, to manage parallelization on several nodes; points to subset of data;
%	    SubjectListFile: String, pointing to list of Subjects to be analyzed (completed ones are removed)
%       DESIGN: string, Full FileName (incl. Path) to Structure including all possible Steps and Choices
%       OUTPUT: Kept for keeping function similar to parfor Main Path
%       ImportFolder: String pointing to the Folder that includes all raw files (in BIDS structure)
%       AnalysisName: string, used to decide which events should be
%                       extracted (see Step Function of Bad_Segments and Bad_Epochs
%                       for how this is used).
%       SubsetSize
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

% 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
% 같같같� Preparations 같같같같같같같같같같같같같같같같같같같같�
% 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
%% Load Design
RetryLoad = 0; SuccessfulLoad = 0;
while RetryLoad <200 & SuccessfulLoad == 0% Parfor sometimes has problems with loading
    RetryLoad = RetryLoad +1;
    try % during parallelisation load sometimes crashes (if File is trying to be read at same time multiple times, hence retry)
        Import = load(DESIGN);
        DESIGN = Import.(whos('-file',DESIGN).name);
        clearvars Import;
        SuccessfulLoad = 1;
    end
end


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


%% Load OUTPUT File with List of Forks
OUTPUT_Name = OUTPUT;
if isstring(OUTPUT) || ischar(OUTPUT)
    RetryLoad = 0; SuccessfulLoad = 0;
    while RetryLoad <200 & SuccessfulLoad == 0% Parfor sometimes has problems with loading
        RetryLoad = RetryLoad +1;
        try
            Import = load(OUTPUT);
            OUTPUT = Import.(whos('-file',OUTPUT).name);
            clearvars Import;
            SuccessfulLoad = 1;
        end
    end
end


% Initate some Variables for Logkeeping
Dummy = [];

%% Set Up Folders for export and logging
OutputFolder = fullfile(OutputFolder);
if ~exist(OutputFolder, 'dir'); mkdir(OutputFolder); end
ErrorFolder = strcat(LogFolder, "ErrorMessages/");
if ~exist(ErrorFolder, 'dir'); mkdir(ErrorFolder); end
CompletionFolder =strcat(LogFolder, "/CompletionStatus/");
if ~exist(CompletionFolder, 'dir'); mkdir(CompletionFolder); end


%% Show input to this function
disp(OutputFolder)
disp(ImportFolder)
disp(AnalysisName)

% Set Up Export Folders if they do not exist yet
if ~contains(OutputFolder(end), filesep)
    OutputFolder = strcat(OutputFolder, filesep);
end

%% Complete all Inputs
if nargin<9;   RetryError = "0"; end
if nargin<10;  LogFolder = OutputFolder; end
if nargin<11;   ParPools = "16"; end
if nargin<12;    PrintLocation = "0"; end
MaxStep = length(Steps);
if nargin<13;    StepsToSave = num2str(MaxStep); end


% make input numeric
RetryError = str2double(RetryError);
ParPools = str2double(ParPools);
PrintLocation = str2double(PrintLocation);
IndexSubjects = str2double(IndexSubjects);
SubsetSize = str2double(SubsetSize);
StepsToSave = str2double(StepsToSave);
MaxStep=StepsToSave;
%% Prepare List of Subjects to be Processed
Subjects = table2cell(readtable( SubjectListFile, 'ReadVariableNames', false));  % read csv file with subject Ids to be run
%% To parallelize across nodes, subsets of Subjects are created
IndexSubjectsIN = IndexSubjects;

IndexSubjects = ((IndexSubjects-1)*SubsetSize+1): IndexSubjects*SubsetSize;

if max(IndexSubjects) > length(Subjects)
    IndexSubjects = IndexSubjects(ismember(IndexSubjects, 1:length(Subjects)));
end

if length(IndexSubjects) == 0
    fprintf('Index for Subset %d does not contain any subjects.\n', IndexSubjects);
    return
end

% Finalize Information on Subjects
Subjects = Subjects(IndexSubjects);


% 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
% 같같같� Translate Choices into numeric ForkCombinations 같같같
% 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
%% PREPARE Step COMBINATION and test if to run
% Loop throgh each Step and get the Index of that Step/Choice
% combination. Concatenate all of them together to create the
% "FinalFolder" Name, which includes all Step/Choice Combinations
% Basically Translate the Verbal Description of Step/Choices into
% numeric indices (as Filepaths would be too long otherwise)

% Get Name of Choice for each Step from Forking List
OUTPUT_Choices = split(OUTPUT(1,1), '%')';

% Initate Name of Folder
OUTPUT_FolderName = repmat("FF", size(OUTPUT_Choices));
for iStep = 1:StepsToSave
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
RetryFork =  ones(length(Subjects), 1);

% Prepare Matlabpool
delete(gcp('nocreate')); % make sure that previous pooling is closed
distcomp.feature( 'LocalUseMpiexec', false );
parpool(ParPools);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
% 같같같� Run Forking Path Combination 같같같같같같같같같같같같�
% 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
% This was put into a function to reduce the output text printed to the logfiles
% Since some combinations might in in progress at the first time of trying
% to run it, a note is created to retry it again (RetryFork). However, the
% Loop only attempts to retry this a limited time
% Retry if conflicts ocurred


Retry_Loop_Max = 0;

while sum(RetryFork)>1 && Retry_Loop_Max < 50
    fprintf('Subset %d. Number of Combinations that need to be retried/calculated: %d. \n', IndexSubjectsIN, sum(RetryFork));
    [CountErrors, CountCompleted, CountPreviouslyCompleted, ...
        RetryFork, Subjects] = run_Steps(Subjects, AnalysisName, DESIGN, ...
        OUTPUT_Choices, OUTPUT_FolderName, OUTPUT_Name, ...
        ImportFolder, OutputFolder, LogFolder, ErrorFolder,   ...
        Steps, MaxStep, Dummy,  RetryError, PrintLocation, ParPools,  ...
        CountErrors, CountCompleted, CountPreviouslyCompleted, RetryFork);
    fprintf('Subset %d. Run_Steps Loop: %d finished after %d. \n', IndexSubjectsIN, Retry_Loop_Max, toc);
    Retry_Loop_Max = Retry_Loop_Max + 1;
    
end


% Make Note that this analysis was completed
CompletionFolderSave = strcat(CompletionFolder,  OUTPUT_Name, '_', num2str(MaxStep), "/");
if ~exist(CompletionFolderSave, 'dir'); mkdir(CompletionFolderSave); end
% Make Note how long it took to run this combination
ElapsedTime_Hours = round((toc/60/60), 2);
fprintf('\n ************************ \n Summary on Achievements. \n  Running took %0.3f hours. \n Newly Completed Paths: %d. \n Previously Completed Paths: %d. \n Encounted Errors: %d. \n \n ************************ \n ',  ...
   IndexSubjectsIN, ElapsedTime_Hours, CountCompleted,  CountPreviouslyCompleted, CountErrors)




end
function [CountErrorsOUT, CountCompletedOUT, CountPreviouslyCompletedOUT ...
    RetryForkOUT, Subjects]  = run_Steps(Subjects, AnalysisName, DESIGN, ...
    OUTPUT_Choices, OUTPUT_FolderName, OUTPUT_Name, ...
    ImportFolder, OutputFolder, LogFolder, ErrorFolder,   ...
    Steps, MaxStep, Dummy,  RetryError, PrintLocation, ParPools,  ...
    CountErrorsIN,  CountCompletedIN, CountPreviouslyCompletedIN, RetryFork)
if PrintLocation == 1; fprintf('Line 216\n'); end

% Work only through the combinations that need to be retried (had to be
% done like this as parfor only accepts contionusly increasing
% parallelisation)

Subjects = Subjects(find(RetryFork));
RetryForkOUT = zeros(size(Subjects,1),1);
CountErrorsOUT = zeros(size(RetryForkOUT));
CountCompletedOUT = zeros(size(RetryForkOUT));
CountPreviouslyCompletedOUT = zeros(size(RetryForkOUT));

% Loop through all Forking Combinations
% change to for (instead of parfor if checking manualy)
parfor iSubject = 1:length(Subjects)
    try
        Subject = Subjects{iSubject};
        iPath = 1;
        
        fprintf("Running Subject %s \n", Subject)
        
        try
            RunningFileName = NaN;
            ErrorFileName = strcat(LogFolder,  Subject, '_errorImport.mat');
            
            %% Find "Highest" Path that was already calculated
            FileFound = 0;
            steps_already_done = length(Steps)+1;
            StopPath = 0;
            while FileFound == 0 & steps_already_done > 0
                steps_already_done = steps_already_done -1;
                Test_completed = strcat(OutputFolder, "/", join(OUTPUT_FolderName(iPath,1:steps_already_done), '_'), "/", Subject, '.mat');
                Test_InProgress = strcat(OutputFolder, "/", join(OUTPUT_FolderName(iPath,1:steps_already_done), '_'), "/", Subject, '_running.mat');
                Test_Error = strcat(OutputFolder, "/", join(OUTPUT_FolderName(iPath,1:steps_already_done), '_'), "/", Subject, '_error.mat');
                
                if isfile(Test_completed) % has this step been completed?
                    fprintf("Completed File was found \n")
                    FileFound = 1;
                elseif isfile(Test_InProgress) % is this step currently been calculated?
                    RetryForkOUT(iSubject) = 1;
                    fprintf("Path in Progress, retry later \n")
                    StopPath = 1;
                    FileFound = 1;
                elseif isfile(Test_Error) & RetryError == 0; % did this step throw an error before and should not be redone?
                    fprintf("Path threw error, stop \n")
                    StopPath = 1;
                    FileFound = 1;
                    CountErrorsOUT(iSubject) = 1;
                elseif isfile(Test_Error) & RetryError == 1; % did this step throw an error before but should be redone?
                    fprintf("Path threw error, retried \n")
                    delete(ErrorFileName)
                end
            end
            
            
            %% Do not Start analysis
            % skip iteration if already completed, or error has occurred
            % before, or calculation is in progress
            if PrintLocation == 1; fprintf('Line 266\n'); end
            
            if StopPath == 1 || steps_already_done == MaxStep
                CountPreviouslyCompletedOUT(iSubject) = 1;
                continue % with next Parfor iteration
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
                RetryLoad = 0;
                DataLoaded = 0;
                while RetryLoad <20 && DataLoaded == 0% Parfor sometimes has problems with loading
                    RetryLoad = RetryLoad +1;
                    try
                        Data = load(Test_completed, 'Data');
                        Data = Data.Data;
                        [~, Data.Inputfile] = fileparts(Test_completed);
                        Data.AnalysisName = AnalysisName; % update Analysis Name as continous data might stem from different preproc!
                        DataLoaded = 1;
                    catch
                        pause(3)
                    end
                end
                
                % if Data could not be loaded, try again later
                if DataLoaded == 0
                    fprintf('\n InterimStep Cannot be loaded \n')
                    delete(Test_completed);
                    RetryForkOUT(iSubject) = 1;
                    fprintf("InterimStep cannot be loaded, retried later")
                    continue
                end
                
            end % End Load or Initate Data
            if PrintLocation == 1; fprintf('Line 302\n'); end
            
            %% RUN REMAINING Steps
            % Carry out remaining steps. Each Step is run after each other.
            % File is kept in memory until new Combination is done (completed or error).
           fprintf("running")
            for iStep = (steps_already_done+1): MaxStep
                Choice = OUTPUT_Choices(iPath, iStep);
                if PrintLocation == 1; fprintf('Line 309\n'); end
                
                %% Run Step
                % Run Step Function for this Step and Choice. Initate some
                % Variables
                InterimFolder = strcat(OutputFolder, "/", join(OUTPUT_FolderName(iPath,1:iStep), '_'), "/");
                RunningFileName = strcat(InterimFolder,  Subject, '_running.mat');
                InterimFileName = strcat(InterimFolder,  Subject, '.mat');
                ErrorFileName = strcat(InterimFolder,  Subject, '_error.mat');
                
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
                    Save_Interim = 0;
                else
                    % if not first Step
                    
                    % should interim be saved? If yes save also "running"
                    Save_Interim =  DESIGN.(Steps{iStep}).SaveInterim == 1 || iStep == MaxStep;
                    
                    % Save Running File
                    if Save_Interim == 1
                        if ~exist(InterimFolder, 'dir'); mkdir(InterimFolder); end
                        parfor_save(RunningFileName, Dummy);
                    end
                    
                    Data=run_step(Steps{iStep}, Data, Choice);
                end
                
                
                % After Step is done, check success of it
                if ~isfield (Data, 'Error')
                    %% Step run correctly
                    % save Interim Step
                    if Save_Interim == 1
                        if ~exist(InterimFolder, 'dir'); mkdir(InterimFolder); end
                        parfor_save(InterimFileName, Data);
                        if isfile(RunningFileName)
                            delete(RunningFileName);
                        end
                    end
                    % if final step is completed make a note
                    if iStep == MaxStep
                        CountCompletedOUT(iSubject) = 1;
                    end
                    if PrintLocation == 1; fprintf('Line 372\n'); end
                else
                    
                    %% Step gave Mistake
                    % if an error occurrs when running the Step, make a log
                    fprintf('Error ocurred with Step %s. \n The returned Error Message is \n %s \n', ...
                        Steps{iStep}, Data.Error );
                    if ~exist(InterimFolder, 'dir'); mkdir(InterimFolder); end
                    parfor_save(ErrorFileName, Dummy);
                    
                    FileName = strcat(ErrorFolder, "Error_",  Steps{iStep}, "_", Choice, "_", Subject, "_", join(OUTPUT_FolderName(iPath,1:iStep), "_"), ".txt");
                    fid3 = fopen( FileName, 'wt' );
                    fprintf(fid3,'The returned Error Message is: \n  %s \n', ...
                        Data.Error);
                    fclose(fid3);
                    if isfile(RunningFileName)
                        delete(RunningFileName); end
                    % do not continue with next Step Combination, mark Combination as error
                    CountErrorsOUT(iSubject) = 1;
                    break % out of Step loop
                end
            end
            %% Catch Problems
        catch e
            fprintf('Subject: %s. The Error message is \n %s \n', Subject, e.message);
            if isfile(RunningFileName)
                delete(RunningFileName)
            end
            CountErrorsOUT(iSubject) = 1;
            continue % in parfor loop
            
        end
    catch
        fprintf('Problem with ParforLoop.\n')
    end
end

CountErrorsOUT = sum([CountErrorsOUT; CountErrorsIN]);
CountCompletedOUT = sum([CountCompletedOUT; CountCompletedIN]);
CountPreviouslyCompletedOUT = sum([CountPreviouslyCompletedOUT; CountPreviouslyCompletedIN]);

end
