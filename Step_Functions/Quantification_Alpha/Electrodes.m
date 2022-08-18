function  OUTPUT = Electrodes(INPUT, Choice);
 
StepName = "Electrodes";
Choices = ["F3,F4", "F3,F4,F5,F6,AF3,AF4", "F3,F4,P3,P4", "F3,F4,F5,F6,AF3,AF4,P3,P4,P5,P6,PO3,PO4"]; 
Conditional = ["NaN", "NaN", "NaN", "NaN"]; 
SaveInterim = logical([0]); 
Order = [18]; 
 
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
