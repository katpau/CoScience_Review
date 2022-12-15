function  OUTPUT = Reference(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

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
Choices = ["CAV", "CSD",  "Mastoids"];
Conditional = ["NaN", "NaN", "NaN"];
SaveInterim = logical([0]);
Order = [14];



% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
try % For Error Handling, all steps are positioned in a try loop to capture errors
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    
    Conditions = fieldnames(INPUT.data);
    for i_cond = 1:length(Conditions)
        % Get EEGlab EEG structure from the provided Input Structure
        EEG = INPUT.data.(Conditions{i_cond});
        
        % Add old reference back to signal
        if ~strcmp(INPUT.StepHistory.Reference_AC,"CAV")
            if strcmp(INPUT.StepHistory.Reference_AC,"Cz")
                RefInfo = {'CZ',	 -0,     0,	   0,  0,  1,	  0,  90,  1,	'EEG'};
                ChanlocFields = fields(EEG.chanlocs);
                for ifield = 1:10
                    EEG.chanlocs(EEG.nbchan+1).(ChanlocFields{ifield}) = RefInfo{ifield};
                end
                
            elseif strcmp(INPUT.StepHistory.Reference_AC,"Mastoids")
                RefInfo = {'MASTr',	108,	0.578,	-0.307,	-0.946,	-0.25,	-108,	-14.1,	1.03, 'EEG';
                    'MASTl',	-108,	0.578,	-0.307,	0.946,	-0.25, 108,	-14.1,	1.03,	'EEG' };
                ChanlocFields = fields(EEG.chanlocs);
                for ifield = 1:10
                    EEG.chanlocs(EEG.nbchan+1).(ChanlocFields{ifield}) = RefInfo{ifield};
                    EEG.chanlocs(EEG.nbchan+2).(ChanlocFields{ifield}) = RefInfo{ifield};
                end
                EEG.data(end+1,:) = 0;
            end
            
            % update EEGlab structure
            EEG.data(end+1,:) = 0;
            EEG.nbchan = size(EEG.data,1); % update Channel Number
            EEG = eeg_checkset( EEG );
        end
        
        % ****** Apply new reference ******
        if strcmpi(Choice,"CAV")
            EEG = pop_reref(EEG, []);
        elseif strcmpi(Choice, "Mastoids")
            Mastoids = find(contains({EEG.chanlocs.labels}, {'MAST'}));
            EEG = pop_reref(EEG, {EEG.chanlocs(Mastoids).labels}, 'keepref', 'on');
        elseif strcmpi(Choice, "CSD")
            EEG.data = laplacian_perrinX(EEG.data, [EEG.chanlocs.X],[EEG.chanlocs.Y],[EEG.chanlocs.Z]);
        end
        
        
        
        %#####################################################################
        %### Wrapping up Preprocessing Routine                         #######
        %#####################################################################
        % ****** Export ******
        % Script creates an OUTPUT structure. Assign here what should be saved
        % and made available for next step. Always save the EEG structure in
        % the OUTPUT.data field, overwriting previous EEG information.
        OUTPUT.data.(Conditions{i_cond}) = EEG;
    end
    
    
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
