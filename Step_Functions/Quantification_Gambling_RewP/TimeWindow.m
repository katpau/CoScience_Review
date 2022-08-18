function  OUTPUT = TimeWindow(INPUT, Choice)
% This script does the following:
% Script only marks which Times are used for quantification.
% Nothing is done here as this will be used in a later 
% Step (Quantificiation ERP).

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
StepName = "TimeWindow";
Choices = ["Relative_Group_wide", "Relative_Group_narrow", "Relative_Subject", "250,350", "200,400"];
Conditional = ["NaN", "NaN", "NaN", "NaN", "NaN"];
SaveInterim = logical([1]);
Order = [21];

% For P300 save other timeWindow
if strcmp(Choice , "Relative_Group_wide")
	ChoiceP3 = "Relative_Group_wide";
elseif strcmp(Choice , "Relative_Group_narrow")
	ChoiceP3 = "Relative_Group_narrow";
elseif strcmp(Choice , "Relative_Subject")
	ChoiceP3 = "Relative_Subject";
elseif strcmp(Choice , "250,350")
	ChoiceP3 = "300,600";
elseif strcmp(Choice , "200,400")
	ChoiceP3 = "250,500";
end

INPUT.StepHistory.TimeWindow_P3 = ChoiceP3;

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
end
