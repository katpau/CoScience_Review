function  OUTPUT = ECG_TimeWindow(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following:
% Script only marks which Times are used for quantification.
% Nothing is done here as this will be used in a later 
% Step (ECG_Artefact).

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
StepName = "ECG_TimeWindow";
Choices = ["2000,5000","3500,4000","Relative_Group"];
Conditional = ["NaN", "NaN", "NaN"];
SaveInterim = logical([1]);
Order = [22];


% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
end
