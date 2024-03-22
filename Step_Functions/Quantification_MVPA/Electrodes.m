function  OUTPUT = Electrodes(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following:
% Script only marks which Electrodes are used for quantification of LRP.
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
StepName = "Electrodes";
Choices = ["C3, C4",        "FC3, FC4"]; 
Conditional = ["NaN", "NaN",  "NaN", "NaN"]; 
SaveInterim = logical([0]); 
Order = [20]; 

% Create EEG substructures from 3d EEGmatrix containing only trials from LRP electrodes (channels x dp x trials)
chanlocs = struct2table(INPUT.data.LRP.chanlocs);
Electrodes = upper(strsplit(Choice, ", ")); 
lrp_chanlocs = [find(strcmp(chanlocs.labels, Electrodes(1))) find(strcmp(chanlocs.labels, Electrodes(2)))]; %only use LRP electrodes of interest

INPUT.data.LRP = pop_select(INPUT.data.LRP, 'channel', lrp_chanlocs); %remove other channels from EEG structure

clear chanlocs lrp_chanlocs

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
end 

