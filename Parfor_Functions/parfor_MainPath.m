function  parfor_MainPath(IndexSubjects, SubjectListFile, DESIGN, OUTPUT, OutputFolder, ImportFolder, AnalysisName, SubsetSize, RetryError, LogFolder, ParPools, PrintLocation)
% for each Subject, carries out all RDF combinatins as defined in
% OUTPUT(File)
% Output: For each Subject, creates a structure including EEG.Data,
%         Subjectname, StepHistory, InputFile and Miscellaneous
%         applies corresponding step_functions to the data
%         saves final file (or interims) as SubjectName.mat in a folder
%         with the corresponding step/choice combination, e.g. 1.1_2.3
%
% Inputs
%       IndexSubjects: Integer, to manage parallelization on several nodes; points to subset of data;
%	SubjectListFile: String, pointing to list of Subjects to be analyzed (completed ones are removed)
%       DESIGN: Full FileName (incl. Path) to Structure including all possible Steps and Choices
%       OUTPUT: Full FileName to saved List of Strings, based on DESIGN Structure, contains all possible
%               Combinations of Step-Choices
%       OutputFolder: String pointing to the Folder where Data should be saved
%       ImportFolder: String pointing to the Folder that includes all raw files (in BIDS structure)
%       RetryError: Numeric (0|1). When step was run before and resulted in an error, try
%               stepagain (1). Default: 0
%       FilePath_to_Import: String pointing to the Folder that includes all
%               raw files (in BIDS structure)
%       LogFolder: String pointing to the Folder where Logs should be saved



% check if Retry Error is specidied
if nargin<9
    RetryError = "0";
end


% Set Up Export Folders if they do not exist yet
if ~contains(OutputFolder(end), filesep)
    OutputFolder = strcat(OutputFolder, filesep);
end

if nargin<10
    LogFolder = OutputFolder;
end
if nargin<11
    ParPools = "16";
end

if nargin<12
    PrintLocation = "0";
end



fprintf(IndexSubjects);fprintf(SubjectListFile);fprintf(DESIGN);fprintf(OUTPUT);fprintf(OutputFolder);
fprintf(ImportFolder);fprintf(AnalysisName);fprintf(SubsetSize);fprintf(LogFolder);fprintf(ParPools);fprintf(PrintLocation)



% make input numeric
IndexSubjects = str2double(IndexSubjects);
IndexSubset = IndexSubjects;
RetryError = str2double(RetryError);
SubsetSize = str2double(SubsetSize);
ParPools = str2double(ParPools);
PrintLocation = str2double(PrintLocation);


if PrintLocation == 1; fprintf('Line 70\n'); end


%% Prepare List of Subjects to be Processed
Subjects = table2cell(readtable( SubjectListFile, 'ReadVariableNames', false));  % read csv file with subject Ids to be run

%% To parallelize across nodes, subsets of Subjects are created
IndexSubjects = ((IndexSubjects-1)*SubsetSize+1): IndexSubjects*SubsetSize;
if max(IndexSubjects) > length(Subjects)
    IndexSubjects = IndexSubjects(ismember(IndexSubjects, 1:length(Subjects)));
end

if length(IndexSubjects) == 0
    fprintf('Index for Subset %d does not contain any subjects.\n', IndexSubset);
    return
end

% Finalize Information on Subjects
Subjects = Subjects(IndexSubjects);




if PrintLocation == 1; fprintf('Line 92\n'); end

% Set Up Folders for export and logging
OutputFolder = fullfile(OutputFolder);
if ~exist(OutputFolder, 'dir'); mkdir(OutputFolder); end
ErrorFolder = strcat(LogFolder, "ErrorMessages/");
if ~exist(ErrorFolder, 'dir'); mkdir(ErrorFolder); end
CompletionFolder =strcat(LogFolder, "/CompletionStatus/");
if ~exist(CompletionFolder, 'dir'); mkdir(CompletionFolder); end


% Check if Design and Forking Matrix is string pointing to File
if isstring(DESIGN) || ischar(DESIGN)
    RetryLoad = 0; SuccessfulLoad = 0;
    while RetryLoad <200 & SuccessfulLoad == 0% Parfor sometimes has problems with loading
        RetryLoad = RetryLoad +1;
        try
            Import = load(DESIGN);
            DESIGN = Import.(whos('-file',DESIGN).name);
            clearvars Import;
            SuccessfulLoad = 1;
        end
    end
end

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

if PrintLocation == 1; fprintf('Line 131\n'); end

% Get all Steps and all Choices from the Design Structure (important for
% indexing the Combination)
Steps =fieldnames(DESIGN);
Order = zeros(length(Steps),2);
for iStep = 1:length(Steps)
    Order(iStep,:) =[iStep, DESIGN.(Steps{iStep}).Order];
end
Order = sortrows(Order,2);
Steps = Steps(Order(:,1));



%% PREPARE Step COMBINATION and test if to run
% Initate some Variables for Logkeeping
Dummy = [];

% Loop throgh each Step and get the Index of that Step/Choice
% combination. Concatenate all of them together to create the
% "FinalFolder" Name, which includes all Step/Choice Combinations
% Basically Translate the Verbal Description of Step/Choices into
% numeric indices (as Filepaths would be too long otherwise)

OUTPUT_Choices = split(OUTPUT, '%');
OUTPUT_FolderName = repmat("FF", length(OUTPUT_Choices), MaxStep);

for iStep = 1:MaxStep
    Choices = DESIGN.(Step_Names{iStep}).Choices;
    for iChoice = 1:length(Choices)
        OUTPUT_FolderName(strcmp(OUTPUT_Choices(:, iStep), Choices{iChoice}),iStep) = iStep + "." + iChoice ;
    end
end
OUTPUT_FolderName  = join(OUTPUT_FolderName, "_");

if PrintLocation == 1; fprintf('Line 164\n'); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% Set Up FinalFolderName
% Combination of Stepnumber and Choice Number,
% including all previous Steps/Choices
Allfolders = "";
FinalFolder = OUTPUT_FolderName;
FinalFolder = split(FinalFolder, "_");
for iComb = 1:length(Steps)
    Allfolders(iComb) = join(FinalFolder(1:iComb), "_");
end
Allfolders  = OutputFolder + Allfolders;

if PrintLocation == 1; fprintf('Line 185\n'); end


run_Steps(IndexSubset, Subjects, DESIGN, OUTPUT_Choices,...
    Steps, Allfolders, Dummy, ImportFolder,  RetryError, ErrorFolder, CompletionFolder,AnalysisName, PrintLocation, ParPools);
fprintf('Subset %d: End logging \n.', IndexSubset);
end



function run_Steps(IndexSubset, Subjects,  DESIGN, OUTPUT_Choices,...
    Steps, Allfolders, Dummy, ImportFolder, RetryError,  ErrorFolder,CompletionFolder, AnalysisName, PrintLocation, ParPools)
if PrintLocation == 1; fprintf('Line 196\n'); end

%%% For Summary at End %%%
CountErrors = repmat(0, length(Subjects), 1);
CountProblems = repmat(0, length(Subjects), 1);
CountCompleted = repmat(0, length(Subjects), 1);
CountPreviouslyCompleted = repmat(0, length(Subjects), 1);
CountNoDataFile = repmat(0, length(Subjects), 1);



%for iSubject = 1:length(Subjects)
delete(gcp('nocreate')); % make sure that previous pooling is closed
parpool(ParPools);
parfor iSubject = 1:length(Subjects)
    % Initate
    iPath = 1;
    Data =[];
    StopSubject = 0;
    try
        %% Check if Completed Already
        SubjectName = Subjects{iSubject};
        AllFiles  = fullfile(Allfolders + strcat("/", SubjectName, ".mat"));
        % Start with final Path and test if it already exists and completed, exit if so
        if isfile(AllFiles(length(Steps)))
            fprintf('Subset %d: Previously Completed Subject %s. \n', IndexSubset, SubjectName);
            CountPreviouslyCompleted(iSubject) = 1;
            CompletedFileName = fullfile(CompletionFolder, strcat('Completed_', SubjectName, '.mat'));
            if ~isfile(CompletedFileName)
                parfor_save(CompletedFileName , Dummy);
            end
            continue % in parfor Loop
        end
        if PrintLocation == 1; fprintf('Line 220\n'); end
        
        %% not completed yet
        % Find "Highest" Path that was already calculated
        steps_already_done = find(isfile(AllFiles),1,'last');
        RunningFileName  = "";
        
        %% Load or Initate Data
        % if no Step was already calculated, then initialize Structure
        if isempty(steps_already_done)
            steps_already_done = 0;
            Data = [];
            f = fieldnames(DESIGN)';
            f{2,1} = {NaN};
            Data = struct('SubjectName',{SubjectName},'StepHistory',{struct(f{:})},...
                'Inputfile',{NaN}, 'AnalysisName', {AnalysisName});
            if PrintLocation == 1; fprintf('Line 236\n'); end
        else
            % if not first step, then load existing data
            % Problems when multiple instances are trying to read data
            RetryLoad = 0;
            try
                Data = load(AllFiles{steps_already_done}, 'Data');
                Data = Data.Data;
                Data.Inputfile = AllFiles(steps_already_done);
                Data.AnalysisName = AnalysisName;
            catch
                while RetryLoad <11 % Parfor sometimes has problems with loading
                    RetryLoad = RetryLoad +1;
                    pause(3)
                    try
                        Data = load(AllFiles{steps_already_done}, 'Data');
                        Data = Data.Data;
                        Data.Inputfile = AllFiles(steps_already_done);
                    catch errorLoad
                    end
                end
                
                % When Retry Did not work, then go to next Combination and
                % add to Retry Later
                if RetryLoad > 10
                    StopSubject = 1; % do not start run through Stops
                    % if loading does not work and the error is that it is corrupted, delete the file
                    if contains(errorLoad.message, 'File might be corrupt')
                        delete(AllFiles{steps_already_done})
                    end
                    
                end
                
            end
            
        end % End Load or Initate Data
        if PrintLocation == 1; fprintf('Line 271\n'); end
        
        %% RUN REMAINING Steps
        % Carry out remaining steps. Each Step is run after each other.
        % File is kept in memory until new Combination is done.
        fprintf('Subset %d: Analyzing Subject %s. \n', IndexSubset, SubjectName);
        
        if StopSubject == 1
            continue % in parfor loop
        end
        
        for iStep = steps_already_done+1: length(Steps)
            Choice = OUTPUT_Choices(iPath, iStep);
            if PrintLocation == 1; fprintf('Line 280\n'); end
            
            %% Check that can be run
            % Check 1: No errors were reported earlier or that they
            % should be retried
            
            ErrorFileName = strrep(AllFiles{iStep},'.mat', '_error.mat');
            RunningFileName = strrep(AllFiles{iStep},'.mat', '_running.mat');
            
            
            % if Errors are retried, remove Errorenous Marks
            if  (RetryError == 1 && isfile(ErrorFileName))
                delete(ErrorFileName);
            end
            
            % when error exist, then stop path
            if isfile(ErrorFileName)
                % do not continue with next Step Combination
                fprintf('Subset %d: Previous Error with Subject %s, Step %d. \n', IndexSubset, SubjectName, iStep );
                break % out of Step loop
            end
            
            % Check 2: It is not already running (otherwise try later)
            if isfile(RunningFileName)
                % do not continue with next Step Combination
                fprintf('Subset %d: Some Combination in Progress Subject %s, Step %d. \n', IndexSubset, SubjectName, iStep);
                break % out of Step loop
            end
            
            %% Iniate Running Step
            % If no errors and Step not already running, start running step
            % here below
            % Prepare Status Update
            FolderInterim =  Allfolders{iStep};
            Index = strsplit(FolderInterim, '_'); Index = Index(end);
            
            if PrintLocation == 1; fprintf('Line 317\n'); end
            
            % initate folder and mark file as "running" = in progress when
            % intermediate step should be saved
            if DESIGN.(Steps{iStep}).SaveInterim == 1 || iStep == length(Steps)
                if ~exist(FolderInterim, 'dir'); mkdir(FolderInterim); end
                parfor_save(RunningFileName, Dummy);
            end
            
            if PrintLocation == 1; fprintf('Line 326\n'); end
            
            %% Run Step
            % Run Step Function for this Step and Choice
            if iStep == 1
                RawEEGFile= dir(ImportFolder+"/"+Subjects{iSubject}+"/eeg/*.set");
                if (length(RawEEGFile)== 0)
                    fprintf('Subset %d: No Datafile for Subject %s. \n', ...
                        IndexSubset, SubjectName );
                    CountNoDataFile(iSubject) = 1;
                    break % out of Step loop
                end
                RawEEGFolder = RawEEGFile(1).folder;
                RawEEGFile = RawEEGFile(1).name;
                Data=run_first_step(Steps{iStep}, Data, Choice, SubjectName, RawEEGFolder, RawEEGFile);
            else
                Data=run_step(Steps{iStep}, Data, Choice);
            end
            
            if PrintLocation == 1; fprintf('Line 339\n'); end
            
            % If step is done correctly, continue with saving Interim Step
            if ~isfield (Data, 'Error')
                %% Step run correctly
                % save Interim Step
                if DESIGN.(Steps{iStep}).SaveInterim == 1 || iStep == length(Steps)
                    parfor_save(AllFiles{iStep}, Data);
                    delete(RunningFileName);
                    % if final step is completed make a note
                    if iStep == length(Steps)
                        fprintf('Subset %d: Completed Subject %s, Step %d. \n', IndexSubset, SubjectName, iStep );
                        CountCompleted(iSubject) = 1;
                        CompletedFileName = fullfile(CompletionFolder, strcat('Completed_', SubjectName, '.mat'));
                        parfor_save(CompletedFileName , Dummy);
                    end
                end
                if PrintLocation == 1; fprintf('Line 356\n'); end
            else
                %% Step gave Mistake
                % if an error occurrs when running the Step, make a log
                fprintf('Subset: %d Error ocurred with Subject %s, Step %d. \n The returned Error Message is \n %s \n', ...
                    IndexSubset, SubjectName, iStep, Data.Error );
                if ~exist(FolderInterim, 'dir'); mkdir(FolderInterim); end
                parfor_save(ErrorFileName, Dummy);
                if contains(AllFiles{iStep},filesep)
                    Combination =  strsplit(AllFiles{iStep}, filesep);
                end
                Combination = Combination{end-1};
                filename = strcat(ErrorFolder, SubjectName, '_', Steps{iStep}, '.txt');
                fid3 = fopen( filename, 'wt' );
                fprintf(fid3,'Error \n Error-Subject= %s \n More Information: Step was %s, Choice was %s. The returned Error Message is: \n  %s \n', SubjectName, Steps{iStep}, Choice,  Data.Error);
                fclose(fid3);
                if isfile(RunningFileName)
                    delete(RunningFileName); end
                % do not continue with next Step Combination, mark
                % Combination as error
                CountErrors(iSubject) = 1;
                break % out of Step loop
            end
        end
        
        %% Catch Problems
    catch e
        fprintf('Subset: %d Problem with executing Subject %s. The Error message is \n %s \n', IndexSubset, SubjectName, e.message);
        if RunningFileName  ~= ""; if isfile(RunningFileName);
                delete(RunningFileName); end; end
        ErrorFileName = strrep(AllFiles{steps_already_done},'.mat', '_error.mat');
        parfor_save(ErrorFileName, Dummy);
        CountProblems(iSubject) = 1;
        continue % in parfor loop
        
    end
    
end
fprintf('\n ************************ \n')
fprintf('Summary on Achievements \n')
fprintf('Already Completed Subjects: %d. \n', sum(CountPreviouslyCompleted));
fprintf('Newly Completed Subjects: %d. \n', sum(CountCompleted));
fprintf('Step Errors: %d. \n', sum(CountErrors));
fprintf('No Datafile Found: %d. \n', sum(CountNoDataFile));
fprintf('Problems with loop: %d. \n', sum(CountProblems));
fprintf(' ************************ \n')
end