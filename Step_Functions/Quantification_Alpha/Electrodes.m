function  OUTPUT = Electrodes(INPUT, Choice);
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: Cassie (CAS) 4/23
 

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
Choices = ["F3,F4", "F3,F4,F5,F6,AF3,AF4", "F3,F4,P3,P4", "F3,F4,F5,F6,AF3,AF4,P3,P4,P5,P6,PO3,PO4"]; 
Conditional = ["Cluster_Electrodes == ""no_cluster"" ", "NaN", "Cluster_Electrodes == ""no_cluster"" ", "NaN"]; 
% Is it correct that "F3,F4,P3,P4" is "no cluster"? As it could be clustered as F3P3 and F4P4.
SaveInterim = logical([0]); 
Order = [19]; 
 
%****** Updating the OUTPUT structure ****** 
INPUT.StepHistory.Electrodes = Choice; 
OUTPUT = INPUT; 
tic
try
    % This is calculated in Step Asymmetry Score     
    OUTPUT.StepDuration = [OUTPUT.StepDuration; toc];

catch e
ErrorMessage = string(e.message);
for ierrors = 1:length(e.stack)
    ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
end 

OUTPUT.Error = ErrorMessage;
end
end
