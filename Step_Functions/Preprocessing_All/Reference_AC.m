function  OUTPUT = Reference_AC(INPUT, Choice)
% This script does the following:
% It first recreates the online references used in BrainProduct Settings.
% Then it rereferences the data (temporarily) to do the data cleaning.
% It is able to handle all options from "Choices" below (see Summary).


%#####################################################################
%### Usage Information                                         #######
%#####################################################################
% This function requires the following inputs:
% INPUT = structure, containing at least the fields "Data" (containing the
%       EEGlab structure, "StephHistory" (for every forking decision). More
%       fields can be added through other preprocessing steps.
% Choice = string, naming the choice run at this fork (included in "Choices")
%
% This function gives the following output:
% OUTPUT = struct, similiar to the INPUT structure. StepHistory and Data is
%           updated based on the new calculations. Additional fields can be
%           added below


%#####################################################################
%### Summary from the DESIGN structure                         #######
%#####################################################################
% Gives the name of the Step, all possible Choices, as well as any possible
% Conditional statements related to them ("NaN" when none applicable).
% SaveInterim marks if the results of this preprocessing step should be
% saved on the harddrive (in order to be loaded and forked from there).
% Order determines when it should be run.
StepName = "Reference_AC";
Choices = ["Cz", "CAV", "Mastoids"];
Conditional = ["NaN", "NaN", "NaN"];
SaveInterim = logical([0]);
Order = [2];


% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
tic % for keeping track of time
try % For Error Handling, all steps are positioned in a try loop to capture errors
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    
    % Get EEGlab EEG structure from the provided Input Structure
    EEG = INPUT.data.EEG ;
    
    % ****** Recover Reference Channel ******
    % Since the EEG was recorded with different online references, these
    % need to be added back to the signal here (as a 0 filled channel),
    % before rereferencing
    
    % Add Reference Electrode back into the Dataset as 0 filled channel
    if ~strcmp(EEG.Info_Lab.Reference,'CMS/DRL') % for Biosemi we do not recover CMS/DRL        
        % if Reference is not already in the data, add 0 filled Channel
        if ~ismember( upper(EEG.Info_Lab.Reference), upper({EEG.chanlocs.labels}))
             EEG.data(end+1,:) = 0; % add 0 filled Channel
             EEG.nbchan = size(EEG.data,1); % update Channel Number

            % Chanloc information on reference electrode
            if strcmp(EEG.Info_Lab.Reference,'FCZ')
                RefInfo = {'FCZ',	 -0,	0.127,	0.388,	  0, 0.922,	  0	67.2,  1,	'EEG'};
            elseif  strcmp(EEG.Info_Lab.Reference, 'CZ')
                RefInfo = {'CZ',	 -0,     0,	    6.12e-17,  0,  1,	  0,  90,  1,	'EEG'};
            end
            % Loop through Chanloc fields (labels, theta, radius etc.) and add
            % new info
            ChanlocFields = fields(EEG.chanlocs);
            for ifield = 1:10
                EEG.chanlocs(EEG.nbchan).(ChanlocFields{ifield}) = RefInfo{ifield};
            end
            % update EEGlab structure
            EEG = eeg_checkset( EEG );
        end
    end
    
    % ****** Rereference Data ******
    % Reference Channels are kept as 0 filled channels (for later
    % rereferencing)
    % save also index of the Reference Channel
    if strcmpi(Choice, "CAV")
        % includes all channels, also EOGs (necessary for ICA)
        EEG = pop_reref(EEG, []);
        EEG.Reference_Channel = [];
        
    elseif strcmpi(Choice, "Mastoids")
        EEG = pop_reref(EEG, {'MASTl', 'MASTr'}, 'keepref', 'off');
        EEG.Reference_Channel = find(ismember({EEG.chanlocs.labels}, {'MASTl', 'MASTr'}));
        
    elseif strcmpi(Choice,  "Cz")
        EEG = pop_reref(EEG, 'CZ', 'keepref', 'off');
        EEG.Reference_Channel = find(ismember({EEG.chanlocs.labels}, {'CZ'}));
    end
    
    
    
    %#####################################################################
    %### Wrapping up Preprocessing Routine                         #######
    %#####################################################################
    % ****** Export ******
    % Script creates an OUTPUT structure. Assign here what should be saved
    % and made available for next step. Always save the EEG structure in
    % the OUTPUT.data field, overwriting previous EEG information.
    OUTPUT.data.EEG = EEG;
    OUTPUT.StepDuration = [OUTPUT.StepDuration; toc];
    
    % ****** Error Management ******
catch e
    % If error ocurrs, create ErrorMessage(concatenated for all nested
    % errors). This string is given to the OUTPUT struct.
    ErrorMessage = string(e.message);
    for ierrors = 1:length(e.stack)
        ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
    end
    OUTPUT.Error = ErrorMessage;
end
end
