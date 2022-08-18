function  OUTPUT = Cluster_Electrodes(INPUT, Choice);
 
StepName = "Cluster_Electrodes";
Choices = ["no_cluster", "cluster"]; 
Conditional = ["(Electrodes == ""F3, F4"" || Electrodes == ""F3, F4, P3, P4"")", "Reference ~= ""CSD"" && contains(Electrodes, ""F5"") "]; 
SaveInterim = logical([0]); 
Order = [19]; 
 
%****** Updating the OUTPUT structure ****** 
INPUT.StepHistory.Cluster_Electrodes = Choice; 
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
