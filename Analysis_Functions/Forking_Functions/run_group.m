function  run_subjects(FolderName, DESIGN, OUTPUT, InputFolder, OutputFolder, Index_to_Continue, RetryError)
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
    OutputFolder(end) = "/";
end
if contains(InputFolder(end), ["\", "/"])
    InputFolder(end) = [];
end

if contains(FolderName(end), ["\", "/"])
    FolderName = strrep(FolderName, '/', '');
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
    
    idxStep =Index_to_Continue;
    FinalFolder = [];
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
        FinalFolder=strcat(FinalFolder, "_",num2str(idxStep), ".", num2str(idxChoice));
        Allfolders(iStep) = FinalFolder;
    end
    Allfolders = strcat(OutputFolder, FolderName, Allfolders);
    AllFiles = fullfile(strcat(Allfolders, "/GroupData.mat"));
    
    
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
        

        %% check if Step was already run and load if so
              % if no Step was already calculated, then run fist Step 
              if steps_already_done == 0
                  Randomfile = dir(strcat(InputFolder, '/', FolderName, '/sub*.mat'));
                  Randomfile = Randomfile(1);
                  Data = load(strcat(Randomfile.folder, '/', Randomfile.name), 'Data') ;
                  Data = Data.Data;
              else
                Data = load(AllFiles{steps_already_done}, 'Data');
                Data.Inputfile = AllFiles(steps_already_done);
              end
                
        
       
        %% RUN REMAINING Steps
        % Carry out remaining steps. Each Step is run after each other.
        % File is kept in memory until new Combination is done.
        for iStep = steps_already_done+1: length(Steps)
            
            % if SubjectName == "sub-ARO7AN21" %sub-AHSAER12
            %    Choice = relevantPath{iStep}
            %   1-1;
            % end
            Choice = relevantPath{iStep};
            % only continue if no Error ocurred in previous attempt ( or if retry is on)
            % if Errors are retried, remove Errorenous Marks
            ErrorFileName = strrep(AllFiles{iStep},'.mat', '_error.mat');
            if  (RetryError == 1 && exist(ErrorFileName)); delete(ErrorFileName); end
            if exist(strrep(AllFiles{iStep},'.mat', '_error.mat'))
                break
            end
            
            %run only if not already running, otherwise add to "to be done later" ist
            if exist(strrep(AllFiles{iStep},'.mat', '_running.mat'))
                Combinations_to_try_later = [Combinations_to_try_later, iPath];
                break
            end
            
            
            
            % If no errors and Step not already running, start running step
            % initate folder and mark file as "running" = in progress
            FolderInterim =  Allfolders{iStep};
            if ~exist(FolderInterim, 'dir'); mkdir(FolderInterim); end
            save(strrep(AllFiles{iStep},'.mat', '_running.mat'), 'Dummy');
            
            Index = strsplit(FolderInterim, '_'); Index = Index(end);
            
            fprintf('Analyzing Forking Path %d. Step %s, Choice %s (Index %s). \n', iPath, Steps{iStep}, Choice, Index{1});
            
            
            
            % Run Step Function for this Step and Choice
            if iStep == 1 
                Data=run_first_step(Steps{iStep}, Data, Choice, FolderName, InputFolder);
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
                delete(strrep(AllFiles{iStep},'.mat', '_running.mat'));
                
                
                
            else
                % if an error occurrs when running the Step, make a log
                save(ErrorFileName, 'Dummy');
                Combination =  strsplit(AllFiles{iStep}, "/"); Combination = Combination{end-1};
                filename = strcat(ErrorFolder, 'ErrorLog_Step-', Steps{iStep},'_Choice-', Choice, '_Combination-', Combination, '.txt');
                fid = fopen( filename, 'wt' );
                fprintf(fid,'Error with Folder %s, Step %s, Choice %s. Error Message: %s\n', FolderName, Steps{iStep}, Choice,  Data.Error);  % Method 1
                fclose(fid);
                delete(strrep(AllFiles{iStep},'.mat', '_running.mat'));
                break
            end
            
        end
    end
end

% keep redoing it until all combinations were done.
Combinations_to_try_later_Check = Combinations_to_try_later;

while ~ isempty(Combinations_to_try_later_Check)
    run_subjects(FolderName, DESIGN, OUTPUT(Combinations_to_try_later), OutputFolder, FolderName, RetryError)
end

end
