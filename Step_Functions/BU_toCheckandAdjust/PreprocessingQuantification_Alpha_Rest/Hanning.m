function  OUTPUT = Hanning(INPUT, Choice);

StepName = "Hanning";
Choices = ["100", "10"];
Conditional = ["contains(Epoching, ""50"")", "contains(Epoching, ""90"")"];
SaveInterim = logical([0]);
Order = [16];

%****** Updating the OUTPUT structure ******
INPUT.StepHistory.Hanning = Choice;
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
