%% Function to check that a combination of forking Choices is Valid
% It uses the Conditional statements associated with each choice. 
% These include Equals, not Equals, Contains.
% Also multiple conditions can be listed using and/or
% this function parses the string into an executable formula
function Check_Possibility = test_condition(Conditional_Strings, Combination, Step_Names)
Check_Possibility =[];
list_Tests =[];
if Conditional_Strings == "NaN"
    Check_Possibility = 1;
elseif Conditional_Strings ~= "NaN"
    % Split Conditional String so that it can be deciphered
    Conditional_Strings =  strsplit(Conditional_Strings, " & ")';
    if contains(Conditional_Strings, "|")
        ConditionsCombined = "OR";
        Conditional_Strings =  strsplit(Conditional_Strings, " | ")';
    else
        ConditionsCombined = "AND";
    end
    
    
    for numberCondition = 1:length(Conditional_Strings)
        Conditional_String = Conditional_Strings(numberCondition);
        % Classify what kind of conditional statement was included
        if contains(Conditional_String, "==")
            Conditional_String = strsplit(Conditional_String, " == ");
            Operation = "Equal";
        elseif contains(Conditional_String, "~=")
            Conditional_String = strsplit(Conditional_String, " ~= ");
            Operation = "NotEqual";
        elseif contains(Conditional_String, "contains")
            Operation = "contains";
        end
        
        % Identify the Step that needs to be tested
        if Operation ~= "contains"
            % Remove double ""
            Conditional_String(2) = strrep(Conditional_String(2), """","");
            Conditional_String(2) = strrep(Conditional_String(2), " ","");
            iCondition = find(Step_Names == Conditional_String(1));
            
            
        elseif Operation == "contains"
            for iS = 1:length(Step_Names)
                if contains(Conditional_String, Step_Names{iS})
                    iCondition = iS;
                end
            end
        end
        
        ToTest = strsplit(Combination, "%");
        ToTest = ToTest(iCondition);
        
        if Operation == "Equal"
            Check_Possibility = (ToTest ==  Conditional_String(2));
        elseif Operation == "NotEqual"
            Check_Possibility = (ToTest ~=  Conditional_String(2));
        elseif Operation == "contains"
            Check_Possibility = ~eval(strrep(Conditional_String, Step_Names{iCondition}, "ToTest"));
        end
        
        list_Tests = [list_Tests, Check_Possibility];
    end
    
    if ConditionsCombined == "AND"
        Check_Possibility = all(list_Tests);
    elseif ConditionsCombined == "OR"
        Check_Possibility = any(list_Tests);
    end
    
end
end