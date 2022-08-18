function  parfor_Forks_OtherAnalysis(IndexSubset, SubsetFile, DESIGN, OUTPUT, OutputFolder, ImportFolder, AnalysisName, MaxStep, RetryError, LogFolder, ParPools, PrintLocation)
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


fprintf('Input:   AnalysisName:   %s\n MaxStep:   %s\n Subject:   %s\n DesignFile:   %s\n Outputfolder:    %s\n ImportFolder:    %s\n', ...
    AnalysisName, MaxStep, Subject, DESIGN, OutputFolder, ImportFolder );

% Set Up Export Folders if they do not exist yet
if ~contains(OutputFolder(end), filesep)
    OutputFolder = strcat(OutputFolder, filesep);
end


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


%% Complete all Inputs
% check if Max Step is specified, otherwise use all Steps
if nargin<8;    MaxStep = length(Steps); else; MaxStep = str2double(MaxStep); end
if nargin<9;   RetryError = "0"; end
if nargin<10;  LogFolder = OutputFolder; end
if nargin<11;   ParPools = "16"; end
if nargin<12;    PrintLocation = "0"; end

if MaxStep==0
    MaxStep=length(fieldnames(DESIGN));
end


%% Load OUTPUT File with List of Forks
% Get Name of OUTPUT File that should be run
OUTPUT_List = table2cell(readtable( SubsetFile, 'ReadVariableNames', false, 'Delimiter', ' '));  % read csv file with subject Ids to be run
% if Index (comes from parallel jobber Slurm) is higher than there are
% Forks, stop function
IndexSubset = str2double(IndexSubset);
if IndexSubset > length(OUTPUT_List)
    return
end
OUTPUT_File = OUTPUT_List{IndexSubset};
[~, OUTPUT_Name] = fileparts(OUTPUT_File);
clearvars OUTPUT_List
% Load OUTPUT File (= File with Forking List)
RetryLoad = 0; SuccessfulLoad = 0;
while RetryLoad <200 & SuccessfulLoad == 0% Parfor sometimes has problems with loading
    RetryLoad = RetryLoad +1;
    try
        Import = load(OUTPUT_File);
        OUTPUT = Import.(whos('-file',OUTPUT_File).name);
        clearvars Import;
        SuccessfulLoad = 1;
    end
end


%% Remove Output Combinations if not to run => run only continous ones
OUTPUT = OUTPUT(contains(OUTPUT, 'no_continous'));

fprintf('Input: Number of CombinationsToRun: %d\n NewMaxStep: %d \n', ...
    length(OUTPUT), MaxStep);

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

OUTPUT_Choices = split(OUTPUT, '%');

% Initate Name of Folder
OUTPUT_FolderName = repmat("FF", size(OUTPUT_Choices,1), MaxStep);
for iStep = 1:MaxStep
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
RetryFork =  ones(length(OUTPUT_Choices), 1);

% Prepare Matlabpool
delete(gcp('nocreate')); % make sure that previous pooling is closed
distcomp.feature( 'LocalUseMpiexec', false );
parpool(ParPools);


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
[CountErrors, CountCompleted, CountPreviouslyNotComputed, ...
    RetryFork, OUTPUT_Choices, OUTPUT_FolderName] = run_Steps(Subject, AnalysisName, DESIGN, OUTPUT_Name, ...
    OUTPUT_Choices, OUTPUT_FolderName, ...
    ImportFolder, OutputFolder, LogFolder, ErrorFolder,   ...
    Steps, MaxStep, Dummy,  RetryError, PrintLocation, ParPools,  ...
    CountErrors, CountCompleted, CountPreviouslyCompleted, RetryFork);


% Make Note that this analysis was completed
CompletionFolderSave = strcat(CompletionFolder,  OUTPUT_Name, '_', num2str(MaxStep), "/");
if ~exist(CompletionFolderSave, 'dir'); mkdir(CompletionFolderSave); end
CompletedFileName = strcat(CompletionFolderSave, strcat('Completed_', Subject, "_",   '.mat'));
parfor_save(CompletedFileName , Dummy);
% Make Note how long it took to run this combination
ElapsedTime_Hours = round((toc/60/60), 2);
fprintf('\n ************************ \n Summary on Achievements for Subset %d \n  Running took %0.3f hours. \n Newly Completed Paths: %d. \n Previously Not Completed Paths: %d. \n Encounted Errors: %d. \n \n ************************ \n ',  ...
    IndexSubset, ElapsedTime_Hours, CountCompleted,  CountPreviouslyNotComputed, CountErrors)


end


function [CountErrorsOUT, CountCompletedOUT, CountPreviouslyNotComputed ...
    RetryForkOUT, OUTPUT_Choices, OUTPUT_FolderName]  = run_Steps(Subject, AnalysisName, DESIGN, OUTPUT_Name, ...
    OUTPUT_Choices, OUTPUT_FolderName, ...
    ImportFolder, OutputFolder, LogFolder, ErrorFolder,   ...
    Steps, MaxStep, Dummy,  RetryError, PrintLocation, ParPools,  ...
    CountErrorsIN,  CountCompletedIN, CountPreviouslyCompletedIN, RetryFork)
if PrintLocation == 1; fprintf('Line 216\n'); end

% Initate Outputs for Notes
RetryForkOUT = zeros(size(OUTPUT_Choices,1),1);
CountErrorsOUT = zeros(size(RetryForkOUT));
CountCompletedOUT = zeros(size(RetryForkOUT));
CountPreviouslyNotComputed = zeros(size(RetryForkOUT));


% Loop through all Forking Combinations
% change to for (instead of parfor if checking manualy)
parfor iPath = 1:size(OUTPUT_Choices,1)
     try
   
        %% Find "Highest" Path that was already calculated
        FileFound = 0;
        steps_already_done = 14;
        StopPath = 0;
        while FileFound == 0 & steps_already_done > 0
            steps_already_done = steps_already_done -1;
            Test_completed = strcat(ImportFolder, "/", join(OUTPUT_FolderName(iPath,1:steps_already_done), '_'), "/", Subject, '.mat');
            Test_Error = strcat(ImportFolder, "/", join(OUTPUT_FolderName(iPath,1:steps_already_done), '_'), "/", Subject, '_error.mat');
            
            if isfile(Test_completed) % has this step been completed?
                FileFound = 1;
            elseif isfile(Test_Error) % did this step through an error before and should not be redone?
                StopPath = 1;
                FileFound = 1;
                CountErrorsOUT(iPath) = 1;
            elseif steps_already_done == 0
                StopPath = 1;
                CountPreviouslyNotComputed(iPath) = 1;
            end
        end
        
        %% Do not Start analysis 
        % skip iteration if error has occurred or no file was found
        if StopPath == 1 
            if FileFound == 1
                Test_Error_Out = strcat(OutputFolder, "/", join(OUTPUT_FolderName(iPath,1:steps_already_done), '_'), "/");
                mkdir(Test_Error_Out)
                Test_Error_Out = strcat(Test_Error_Out, Subject, '_error.mat');              
                copyfile(Test_Error, Test_Error_Out)
            end
            continue % with next Parfor iteration
        end
        
        %% if File found, load and continue processing
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

            
        if PrintLocation == 1; fprintf('Line 302\n'); end
        
        %% RUN REMAINING Steps
        % Carry out remaining steps. Each Step is run after each other.
        % File is kept in memory until new Combination is done (completed or error).
        for iStep = (steps_already_done+1): MaxStep
            Choice = OUTPUT_Choices(iPath, iStep);
            if PrintLocation == 1; fprintf('Line 309\n'); end
            
            %% Run Step
            % Run Step Function for this Step and Choice. Initate some
            % Variables
            InterimFolder = strcat(OutputFolder, "/", join(OUTPUT_FolderName(iPath,1:iStep), '_'), "/");
            InterimFileName = strcat(InterimFolder,  Subject, '.mat');
            ErrorFileName = strcat(InterimFolder,  Subject, '_error.mat');
            
            % Run Step
            Data=run_step(Steps{iStep}, Data, Choice);
        
            
            % After Step is done, check success of it
            if ~isfield (Data, 'Error')
                %% Step run correctly
                % if final step is completed make a note
                if iStep == MaxStep
                     if ~exist(InterimFolder, 'dir'); mkdir(InterimFolder); end
                    parfor_save(InterimFileName, Data);
                    CountCompletedOUT(iPath) = 1;
                end
                if PrintLocation == 1; fprintf('Line 362\n'); end
            else
                %% Step gave Mistake
                % if an error occurrs when running the Step, make a log
                fprintf('Subject: %s Error ocurred with Step %s. \n The returned Error Message is \n %s \n', ...
                    Subject, Steps{iStep}, Data.Error );
                if ~exist(InterimFolder, 'dir'); mkdir(InterimFolder); end
                parfor_save(ErrorFileName, Dummy);
                
                FileName = strcat(ErrorFolder, "Error_",  Steps{iStep}, "_", Choice, "_", Subject, "_", join(OUTPUT_FolderName(iPath,:), "_"), ".txt");
                fid3 = fopen( FileName, 'wt' );
                fprintf(fid3,'The returned Error Message is: \n  %s \n', ...
                   Data.Error);
                fclose(fid3);

                % do not continue with next Step Combination, mark Combination as error
                 CountErrorsOUT(iPath) = 1;
                break % out of Step loop
            end
        end
        %% Catch Problems
    catch e
        ErrorMessage = string(e.message);
       for ierrors = 1:length(e.stack)
                 ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
      end
        fprintf('Subject: %s, OutputSubset: %s, Problem with executing Path %d. The Error message is \n %s \n', Subject, OUTPUT_Name, iPath, ErrorMessage);
   
          CountErrorsOUT(iPath) = 1;
        continue % in parfor loop
        
    end    
end

CountErrorsOUT = sum([CountErrorsOUT; CountErrorsIN]);
CountCompletedOUT = sum([CountCompletedOUT; CountCompletedIN]);
CountPreviouslyNotComputed = sum([CountPreviouslyNotComputed; CountPreviouslyCompletedIN]);

end
