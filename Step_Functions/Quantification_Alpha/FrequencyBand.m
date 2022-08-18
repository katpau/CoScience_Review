function  OUTPUT = FrequencyBand(INPUT, Choice);
 
StepName = "FrequencyBand";
Choices = ["single_8-13", "double_8-10.5;10.5-13;", "relative_single", "relative_double"]; 
Conditional = ["NaN", "NaN", "NaN", "NaN"]; 
SaveInterim = logical([0]); 
Order = [17]; 
 
%****** Updating the OUTPUT structure ****** 
INPUT.StepHistory.FrequencyBand = Choice; 
OUTPUT = INPUT; 
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
