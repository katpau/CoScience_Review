function  OUTPUT = MinimumData(INPUT, Choice);
 
StepName = "MinimumData";
Choices = ["MoreStrict", "LessStrict"]; 
Conditional = ["NaN", "NaN"]; 
SaveInterim = logical([0]); 
Order = [21]; 
 
%****** Updating the OUTPUT structure ****** 
INPUT.StepHistory.MinimumData = Choice; 
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
