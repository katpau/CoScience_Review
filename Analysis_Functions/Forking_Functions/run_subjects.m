function  run_subjects(SubjectName, DESIGN, OUTPUT, OutputFolder, FilePath_to_Import, DesignName, AnalysisName)
% for each Subject, carries out all RDF combinatins as defined in OUTPUT
% Output: For each Subject, creates a structure including EEG.Data,
%         Subjectname, StepHistory, InputFile and Miscellaneous
%         applies corresponding step_functions to the data
%         saves final file (or interims) as SubjectName.mat in a folder
%         with the corresponding step/choice combination, 1.1_2.3
%
% Inputs
%       SubjectName: String, Idx to retrieve corresponding data
%       PathStepFunctions: String pointing to the Folder that includes all
%               prepared Step Functions
%       OutputFolder: String pointing to the Folder where Data should be
%               saved
%       DESIGN: Structure including all possible Steps and Choices
%       OUTPUT: Table, based on DESIGN Structure, contains all possible
%               Combinations of Step-Choices
%       RetryError: Numeric (0|1). When step was run before and resulted in an error, try
%               stepagain (1). Default: 0
%       FilePath_to_Import: String pointing to the Folder that includes all
%               raw files (in BIDS structure)


% check if Retry Error is specidied
if nargin<7
    RetryError = 0;
end




% Set Up Export Folders if they do not exist yet
if ~contains(OutputFolder(end), ["\", "/"])
    OutputFolder = strcat(OutputFolder, "/");
end
OutputFolder = fullfile(OutputFolder);
if ~exist(OutputFolder, 'dir'); mkdir(OutputFolder); end
ErrorFolder = strcat(OutputFolder, "/ErrorMessages/");
if ~exist(ErrorFolder, 'dir'); mkdir(ErrorFolder); end

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
nrCombinations = length(OUTPUT);
% Initate some Variables for Logkeeping
Dummy = [];
Combinations_to_try_later = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iPath = 1:nrCombinations
    
    relevantPath = strsplit(OUTPUT{iPath}, '%');
    
    % Set Up FinalFolderName = Combination of Stepnumber and Choice Number,
    % including all previous Steps/Choices
    
        idxStep =0;
        FinalFolder = OutputFolder;

        Allfolders = ",";
    % Loop throgh each Step and get the Index of that Step/Choice
    % combination. Concatenate all of them together to create the
    % "FinalFolder" Name, which includes all Step/Choice Combinations
    % Basically Translate the Verbal Description of Step/Choices into
    % numeric indices (as Filepaths would be too long otherwise)
    for iStep = 1:length(fieldnames(DESIGN))
        idxStep = idxStep + 1;
        Choice = relevantPath{iStep};
        idxChoice = find(strcmp(Choice, DESIGN.(Steps{iStep}).Choices));
        if idxStep ~= 1
            FinalFolder=strcat(FinalFolder,"_",num2str(idxStep), ".", num2str(idxChoice));
        else
            FinalFolder=strcat(FinalFolder,num2str(idxStep), ".", num2str(idxChoice));
        end
        Allfolders(iStep) = FinalFolder;
    end
    AllFiles = fullfile(strcat(Allfolders, "/", SubjectName, ".mat"));
    
    
    
    
    
    % Test if one of the Steps were already saved and can be used to start
    % forking
    
    % Start with final Path and test if it already exists, exit if so
    if ~isfile(AllFiles(length(Steps)))
        
        % Find "Highest" Path that was already calculated
        steps_already_done = length(Steps);
        while  ~isfile(AllFiles(steps_already_done))
            steps_already_done = steps_already_done - 1;
            if steps_already_done < 1
                break
            end
        end
        % if no Step was already calculated, then initialize Structure
            if steps_already_done == 0
                Data = [];
                f = fieldnames(DESIGN)';
                f{2,1} = {NaN};
                Data = struct('SubjectName',{SubjectName},'StepHistory',{struct(f{:})},...
                    'Inputfile',{NaN}, 'Analysis', AnalysisName);
            else
                % if not first step, then load existing data
                Data = load(AllFiles{steps_already_done}, 'Data');
                Data = Data.Data;
                Data.Inputfile = AllFiles(steps_already_done);
            end

        
        
        
        %% RUN REMAINING Steps
        % Carry out remaining steps. Each Step is run after each other.
        % File is kept in memory until new Combination is done.
        for iStep = steps_already_done+1: length(Steps)
            RunningFileName = strrep(AllFiles{iStep},'.mat', '_running.txt');
            ErrorFileName = strrep(AllFiles{iStep},'.mat', '_error.txt');
            
            Choice = relevantPath{iStep};
            % only continue if no Error ocurred in previous attempt ( or if retry is on)
            % if Errors are retried, remove Errorenous Marks
            if  (RetryError == 1 && exist(ErrorFileName)); delete(ErrorFileName); end
            
            %run only if not already running, otherwise add to "to be done later" ist
            if  exist(RunningFileName)
                Combinations_to_try_later = [Combinations_to_try_later, iPath];
                break
            end           
            
            % If no errors and Step not already running, start running step
            % initate folder and mark file as "running" = in progress
            FolderInterim =  Allfolders{iStep};
            if DESIGN.(Steps{iStep}).SaveInterim == 1 
                if ~exist(FolderInterim, 'dir'); mkdir(FolderInterim); end
                fid = fopen(RunningFileName, 'w'); fclose(fid); 
            end
            
            Index = strsplit(FolderInterim, '_'); Index = Index(end);
            fprintf('Analyzing Subject %s, Forking Path %d. Step %s, Choice %s (Index %s). \n', SubjectName, iPath, Steps{iStep}, Choice, Index{1});
                       
            % Run Step Function for this Step and Choice
            if iStep == 1
                Data=run_first_step(Steps{iStep}, Data, Choice, SubjectName, FilePath_to_Import);
            else
                Data=run_step(Steps{iStep}, Data, Choice);
            end
            
            % If step is done correctly, continue with saving Interim Step
            if ~isfield (Data, 'Error')
                % save Interim Step
                if DESIGN.(Steps{iStep}).SaveInterim == 1 || iStep == length(Steps)
                    if ~exist(FolderInterim, 'dir'); mkdir(FolderInterim); end
                    % the following loop is added as there are
                    % sometimes problems with saving in parloop, can be
                    % possibly deleted?
                    saved = -1;
                    while saved == -1
                        try
                            pause(2)
                            try save(AllFiles{iStep}, 'Data'); catch parsave(AllFiles(iStep), Data); end
                            saved = 1;
                        end
                    end
                end            
          
                
            else
                % if an error occurrs when running the Step, make a log
                fid = fopen(ErrorFileName, 'w'); fclose(fid); 
                if contains(AllFiles{iStep}, "/")
                Combination =  strsplit(AllFiles{iStep}, "/"); 
                else
                Combination =  strsplit(AllFiles{iStep}, "\"); 
                end
                Combination = Combination{end-1};
                ErrorLogFileName = strcat(ErrorFolder, 'ErrorLog_', SubjectName, '_Step-', Steps{iStep},'_Choice-', Choice, '_Combination-', Combination, '.txt');
                fid = fopen( ErrorLogFileName, 'wt' );
                fprintf(fid,'Error with Subject %s, Step %s, Choice %s. Error Message: %s\n', SubjectName, Steps{iStep}, Choice,  Data.Error);  % Method 1
                fclose(fid);
                delete(RunningFileName);
                break
            end
            % delete running file
            if DESIGN.(Steps{iStep}).SaveInterim == 1 
                 delete(RunningFileName);
            end
            
        end
    end
end

% keep redoing it until all combinations were done.
Combinations_to_try_later_Check = Combinations_to_try_later;

while ~ isempty(Combinations_to_try_later_Check)
    run_subjects(SubjectName, DESIGN, OUTPUT(Combinations_to_try_later), OutputFolder, FilePath_to_Import, RetryError)
end

end
