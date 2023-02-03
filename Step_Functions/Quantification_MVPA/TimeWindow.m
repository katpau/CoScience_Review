function  OUTPUT = TimeWindow(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following:
% Gets previouses choices and current one (=Time Window of LRP)
% exports MVPA (since it is not forked how its done) and LRP onsets

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
Choices = ["relative_peak", "absolute_criteria"];
Conditional = ["NaN", "NaN"];
SaveInterim = logical([1]);
Order = [21];

INPUT.StepHistory.TimeWindow = Choice;
OUTPUT = INPUT;
% Some Error Handling
try
    %%%%%%%%%%%%%%%% Routine for the analysis of this step
    % This functions starts from using INPUT and returns OUTPUT
    EEG = INPUT.data.EEG;
    
    % Condition Names and Triggers depend on analysisname
    if INPUT.AnalysisName == "Flanker_MVPA"
        Condition_Triggers = { 106, 116, 126,  136, 107, 117, 127, 137; ...
            108, 118, 128, 138, 109, 119, 129, 139  }; %Responses Experimenter Absent
        Condition_Names = ["Flanker_Correct", "Flanker_Error"];
        
    elseif INPUT.AnalysisName == "GoNoGo_MVPA"
        Condition_Triggers = [211; 220 ]; %Responses Speed/Acc emphasis
        Condition_Names = ["GoNoGo_Correct", "GoNoGo_Error"];
    end
    
    % [elisa] CHANGED time window from -0.500 0.800 to -0.300 0.300
    Event_Window = [-0.300 0.300]; % Epoch length in seconds
    NrConditions = length(Condition_Names);
   
    % Get Info on Electrodes for LRP
    Electrodes = upper(strsplit(INPUT.StepHistory.Electrodes , ","));
    Electrodes = strrep(Electrodes, " ", "");    
    
    % Loop Through the conditions like this?
    for i_Cond = 1:NrConditions
        (Condition_Names(i_Cond))
        pop_epoch(EEG, Condition_Triggers(i_Cond,:), Event_Window, 'epochinfo', 'yes');
        
        
        % ********************************************************************************************
        % **** Prepare LRP jack knife   **************************************************************
        % ********************************************************************************************
        
        % Remove interpolated channels => INPUT.AC.EEG.Bad_Channel_Names
        
        % also: count epochs, prepare some kind of SME
        

    end
    
    % Export should have format like this:
    % Subject, Lab, Experimenter, Condition (Correct/Error), Task, Onset (?) or DV, Component (LRP, MVPA, etc.), EpochCount ...
    NrComponents = 2; % LRP and MVPA?
    Subject_L = repmat(INPUT.Subject, NrConditions*NrComponents,1 );
    Lab_L = repmat(EEG.Info_Lab.RecordingLab, NrConditions*NrComponents,1 );
    Experimenter_L = repmat(EEG.Info_Lab.Experimenter, NrConditions*NrComponents,1 );
    Conditions_L = repelem(Condition_Names', NrComponents,1);
    ACC = repmat(INPUT.data.EEG.ACC, NrConditions*NrComponents,1 );
    
    Export = [cellstr([Subject_L, Lab_L, Experimenter_L, Conditions_L]), ...
        num2cell(ACC)]; % add other
    OUTPUT.data = [];
    OUTPUT.data.Export = Export;
    
    
    % ****** Updating the OUTPUT structure ******
    % No changes should be made here.
    INPUT.StepHistory.(StepName) = Choice;
    
    % ****** Error Management ******
catch e
    % If error ocurrs, create ErrorMessage(concatenated for all nested
    % errors). This string is given to the OUTPUT struct.
    ErrorMessage = string(e.message);
    for ierrors = 1:length(e.stack)
        ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
    end
    
    OUTPUT.Error = ErrorMessage;
    
end
end