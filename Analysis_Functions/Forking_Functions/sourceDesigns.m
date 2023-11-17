function [DESIGN, OUTPUT] = sourceDesigns(Paths_StepFunctions, mainPathOnly)
    %% sourceDesigns
    % A slightly extended variant of source_design.
    %
    %% Description
    % If you want an OUTPUT of all forks, just assign a second output
    % parameter (no additional argument required).
    %
    %% Details:
    % The main performance bottleneck of the original source_design was handling
    % the OUTPUT as strings and parsing |cell2mat(strfind…)|. Instead, we deal
    % with structured data until the we return the finished paths.
    %
    %% Input Parameters:
    % Paths_StepFunctions   - [char, string, cell] A single or multiple paths
    %                         to folders, which contain the Step functions.
    % mainPathOnly          - [logical]; true = reduce the OUTPUT to the first
    %                         choice of each step to create the main path. 
    %                         false = (default) combine all choices of each step.
    %
    %% Examples:
    %   [DESIGN, OUT] = sourceDesigns({'Step_Functions/Preprocessing_All/',
    %   'Step_Functions/Epoching_Tasks/'});
    %
    %% See also
    % source_design

    %% Disclaimer
    % Original code by katpau (Katharina Paul, Universität Hamburg)
    % GitHub https://github.com/katpau/CoScience_Review
    % Modifications by Olaf Schmidtmann (University of Cologne).

    %% Changelog
    % 31.05.2023 [ocs] Removed some unused variables and assignmnts.
    % 01.06.2023 [ocs] FIXED It was not possible to search for conditions, which
    %   include inner spaces (e.g. for Electrodes = "C3, C4").
    % 13.06.2023 [ocs] ADDED option to pursue the main path (i.e., only the fist
    % choice of each step), only.
    %

    if nargin < 2, mainPathOnly = false; end

    if nargout > 1, Combine_Output = 1;
    else
        Combine_Output = 0;
        OUTPUT = [];
    end

    DESIGN = [];

    Steps = {};
    Step_Names = {};

    if ~iscell(Paths_StepFunctions)
        if isstring(Paths_StepFunctions)
            Paths_StepFunctions = cellstr(Paths_StepFunctions);
        else
            Paths_StepFunctions = {Paths_StepFunctions};
        end
    end

    for ipath = 1:length(Paths_StepFunctions)
        stepDir = dir(fullfile(Paths_StepFunctions{ipath}, '*.m'));
        stepNames = {stepDir.name};
        Steps = [Steps; fullfile({stepDir.folder}, stepNames)']; %#ok<AGROW>
        Step_Names = [Step_Names; strrep(stepNames', '.m', '')]; %#ok<AGROW>
    end

    Fields = ["Choices", "Conditional", "SaveInterim", "Order"];

    % Retrieve Information about Choices from Step-Function files
    for iStep = 1:length(Steps)
        Content = strsplit(fileread(Steps{iStep}), '\n');
        for iField = 1:length(Fields)
            currField = Fields(iField);
            Field = Content(contains(Content, strcat(currField, ' =')));
            eval(char(Field));
            DESIGN.(Step_Names{iStep}).(currField) = eval(currField);
        end
    end

    Order = [Step_Names, {struct2array(DESIGN).Order}'];
    Order = sortrows(Order, 2);
    DESIGN = orderfields(DESIGN, Order(:, 1));
    Step_Names = fields(DESIGN);


    if Combine_Output == 1
        % Combine all Choices and remove those excdluded by the conditionals.
        if mainPathOnly
            choicePath = DESIGN.(Step_Names{1}).Choices(1);
        else
            choicePath = DESIGN.(Step_Names{1}).Choices';
        end

        for iStep = 2:length(Step_Names)
            currStep = DESIGN.(Step_Names{iStep});

            if mainPathOnly
                currChoices = currStep.Choices(1);
            else
                currChoices = currStep.Choices';
            end
            newChoiceIdx = 1:size(currChoices, 1);
            combChoices = allcomb(1:size(choicePath, 1), newChoiceIdx);

            nCombChoices = size(combChoices, 1);
            extPath = strings(nCombChoices, size(choicePath, 2) + 1);

            for iext = 1:nCombChoices
                extPath(iext, 1:iStep - 1) = choicePath(combChoices(iext, 1), :);
            end

            for ic = newChoiceIdx
                extPath(combChoices(:, 2) == ic, iStep) = currChoices(ic);
            end

            choicePath = extPath;

            if any(currStep.Conditional ~= "NaN")
                RelevantChoices = find(currStep.Conditional ~= "NaN");

                for iChoice = RelevantChoices
                    Conditional_Strings = currStep.Conditional(iChoice);
                    Conditional_Strings = strsplit(Conditional_Strings, " & ")';
                    if contains(Conditional_Strings, "|")
                        ConditionsCombined = "OR";
                        Conditional_Strings = strsplit(Conditional_Strings, " | ")';
                        idxMet = zeros(size(choicePath, 1), 1);
                    else
                        ConditionsCombined = "AND";
                    end

                    for numberCondition = 1:length(Conditional_Strings)
                        Conditional_String = Conditional_Strings(numberCondition);
                        if contains(Conditional_String, "==")
                            Conditional_String = strsplit(Conditional_String, " == ");
                            Operation = "Equal";
                        elseif contains(Conditional_String, "~=")
                            Conditional_String = strsplit(Conditional_String, " ~= ");
                            Operation = "NotEqual";
                        elseif contains(Conditional_String, "contains")
                            Operation = "contains";
                        end

                        if Operation ~= "contains"
                            % Remove double ""
                            Conditional_String(2) = strrep(Conditional_String(2), """", "");
                            Conditional_String(2) = strtrim(Conditional_String(2));
                            iStepForCond = find(Step_Names == Conditional_String(1));
                        elseif Operation == "contains"
                            for iS = 1:length(Step_Names)
                                if contains(Conditional_String, Step_Names{iS})
                                    iStepForCond = iS;
                                end
                            end
                        end

                        % Unresolved Condition in current DESIGN
                        if size(iStepForCond, 1) == 0
                            fprintf(['Problem with asessing conditional ', ...
                                'statement for Step %s: %s. ', ...
                                'Please add manually. \n'], ...
                                Step_Names{iStep}, Conditional_Strings(numberCondition));
                            continue
                        end

                        idxRelevant = choicePath(:, iStep) == currStep.Choices(iChoice);
                        ToTest = choicePath(:, iStepForCond);
                        if Operation == "Equal"
                            idxnotMet = (ToTest ~= Conditional_String(2));
                        elseif Operation == "NotEqual"
                            idxnotMet = (ToTest == Conditional_String(2));
                        elseif Operation == "contains"
                            idxnotMet = ~eval(strrep(Conditional_String, ...
                                Step_Names{iStepForCond}, "ToTest"));
                        end

                        if ConditionsCombined == "AND"
                            idxDelete = idxRelevant & idxnotMet;
                            choicePath = choicePath(~idxDelete, :);

                        elseif ConditionsCombined == "OR"
                            idxMet = or(idxMet, ~idxnotMet);
                        end

                        idxnotMet = [];
                    end
                    if ConditionsCombined == "OR"
                        idxDelete = idxRelevant & ~idxMet;
                        choicePath = choicePath(~idxDelete, :);
                    end
                end
            end
        end

        OUTPUT = join(choicePath, '%');
    end
end