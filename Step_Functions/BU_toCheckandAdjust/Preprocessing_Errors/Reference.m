function  OUTPUT = Reference(INPUT, Choice)
% This script does the following:
% Depending onf the forking choice, data is rereferenced.
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
StepName = "Reference";
Choices = ["CAV", "Mastoids", "CSD"];
Conditional = ["NaN", "NaN", "NaN"];
SaveInterim = logical([0]);
Order = [14];



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
    EEG = INPUT.data;
    
    % Recover Reference channels as 0 filled channels before rereferencing
    % so they do not need to be recovered
    
    % Add Reference Electrode back into the Dataset as 0 filled channel
    if ~strcmp(EEG.Info_Lab.Reference,'CAV') % for Biosemi we do not recover CMS/DRL
        EEG.data(end+1,:) = 0; % add 0 filled Channel
        EEG.nbchan = size(EEG.data,1); % update Channel Number
        
        % Chanloc information on reference electrode
        if strcmp(EEG.Info_Lab.Reference,'CZ')
            RefInfo = {'CZ',	 -0,     0,	    6.12e-17,  0,  1,	  0,  90,  1,	'EEG'};
        elseif  strcmp(EEG.Info_Lab.Reference, 'Mastoids')
            RefInfo = {'MASTl',	-108,	0.532,	-0.307,	0.946,	-0.1,	108,	-5.75,	  1,	'EEG'};
        end
        
        % Loop through Chanloc fields (labels, theta, radius etc.) and add
        % new info
        ChanlocFields = fields(EEG.chanlocs);
        for ifield = 1:10
            EEG.chanlocs(EEG.nbchan).(ChanlocFields{ifield}) = RefInfo{ifield};
        end
        
        % for Mastoinds add second Channel
        if  strcmp(EEG.Info_Lab.Reference, 'Mastoids')
            EEG.data(end+1,:) = 0; % add 0 filled Channel
            EEG.nbchan = size(EEG.data,1); % update Channel Number           
            RefInfo = {'MASTr',	108,	0.532,	-0.307,	-0.946,	-0.1,	-108,	-5.74,	  1,	'EEG'};
            for ifield = 1:10
                EEG.chanlocs(EEG.nbchan).(ChanlocFields{ifield}) = RefInfo{ifield};
            end
        end
        
        % update EEGlab structure
        EEG = eeg_checkset( EEG );
    end
    
    
    % ****** Apply new reference ******
    if strcmpi(Choice,"CAV")
        EEG = pop_reref(EEG, []);
    elseif strcmpi(Choice, "Mastoids")
        EEG = pop_reref(EEG, {'Mastl', 'Mastr'}, 'keepref', 'off');
    elseif strcmpi(Choice, "CSD")
        EEG.data= laplacian_perrinX(EEG.data, [EEG.chanlocs.X],[EEG.chanlocs.Y],[EEG.chanlocs.Z]);
    end
    
    
    
    %#####################################################################
    %### Wrapping up Preprocessing Routine                         #######
    %#####################################################################
    % ****** Export ******
    % Script creates an OUTPUT structure. Assign here what should be saved
    % and made available for next step. Always save the EEG structure in
    % the OUTPUT.data field, overwriting previous EEG information.
    OUTPUT.data = EEG;
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
