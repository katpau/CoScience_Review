function  OUTPUT = Electrodes(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following:
% Script only marks which Electrodes are used for quantification.
% Also determines the Electrodes for the P3 [= not forked independently]
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
Choices = ["Fz, FCz, Cz",        "FCz, Cz", "FCz",       "Cz", "Fz"]; 
Conditional = ["NaN", "NaN",  "Cluster_Electrodes == ""no_cluster""", "Cluster_Electrodes == ""no_cluster""", "Cluster_Electrodes == ""no_cluster"""]; 
SaveInterim = logical([0]); 
Order = [20]; 

% For P3 save other electrodes
if strcmp(Choice , "Fz, FCz, Cz")
    ChoiceP3 = "Cz,CPz,Pz";
elseif strcmp(Choice , "FCz, Cz")
    ChoiceP3 = "Pz, Fz, Cz";
elseif strcmp(Choice , "FCz")
    ChoiceP3 = "Cz";
elseif strcmp(Choice , "Cz")
    ChoiceP3 = "Pz";
elseif strcmp(Choice , "Fz")
    ChoiceP3 = "Pz";
end

INPUT.StepHistory.Electrodes_P3 = ChoiceP3;


% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
end 

