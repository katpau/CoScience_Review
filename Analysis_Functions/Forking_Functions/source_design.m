
function [DESIGN, OUTPUT] = source_design(Paths_StepFunctions, Combine_Output)
if nargin < 2
    Combine_Output = 0;
    OUTPUT = [];
end
Paths_StepFunctions = char(Paths_StepFunctions);
DESIGN = [];
Steps = dir([Paths_StepFunctions '/*.m']);
Steps = {Steps.name}';

Step_Names = char(strrep(Steps, '.m', ''));
Step_Names = cellstr(Step_Names);

Steps = strcat(Paths_StepFunctions, Steps);

Fields = ["Choices", "Conditional", "SaveInterim", "Order"];

% Retrieve Information about Choices from Step-Function files
for iStep = 1:length(Steps);
    Content   = strsplit(fileread(Steps{iStep}), '\n');
    for iField = 1:length(Fields);
        Field = Content( find(contains(Content,strcat(Fields(iField), ' ='))));
        eval(char(Field ));
        DESIGN.(Step_Names{iStep}).(Fields{iField}) =   eval(Fields{iField});
    end
    OrderSteps(iStep) = DESIGN.(Step_Names{iStep}).Order;
end

Step_Names =fields(DESIGN);
Order ={};
for istep = 1:length(Step_Names)
    Order{istep,1} ={Step_Names{istep}};
    Order{istep,2} =DESIGN.(Step_Names{istep}).Order;
end

Order = sortrows(Order,2);
DESIGN=orderfields(DESIGN, [Order{:,1}]);
Step_Names =fields(DESIGN);

if Combine_Output == 1
% Combine all Choices and keep only possible ones
OUTPUT = DESIGN.(Step_Names{1}).Choices';
for iStep = 2:length(Step_Names)
    OUTPUT = allcomb(OUTPUT, DESIGN.(Step_Names{iStep}).Choices);
    OUTPUT = join(OUTPUT, '%');
    if any(DESIGN.(Step_Names{iStep}).Conditional ~= "NaN")
        RelevantChoices = find(DESIGN.(Step_Names{iStep}).Conditional ~= "NaN");
        for iChoice = RelevantChoices
            Conditional_Strings = DESIGN.(Step_Names{iStep}).Conditional(iChoice);
            Conditional_Strings =  strsplit(Conditional_Strings, " & ")';
            if contains(Conditional_Strings, "|")
                ConditionsCombined = "OR";
                Conditional_Strings =  strsplit(Conditional_Strings, " | ")';
                idxMet = repmat(0,size(OUTPUT,1),1) ;
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
                
                % happens when the Condition is not specified in current
                % DESIGN
                if size(iCondition, 1) == 0
                     fprintf('Problem with asessing conditional statement for Step %s: %s. Please add manually. \n', Step_Names{iStep}, Conditional_Strings(numberCondition));
                    continue
                end
                
                Indices_Delimiters = cell2mat(strfind(OUTPUT, '%', 'ForceCellOutput', true));
                ChoiceOptions = extractAfter(OUTPUT, Indices_Delimiters(:,iStep-1));
                if iCondition>1
                ToTest = extractBetween(OUTPUT, Indices_Delimiters(:,iCondition-1)+1, Indices_Delimiters(:,iCondition)-1);
                else
                ToTest = extractBetween(OUTPUT, 1, Indices_Delimiters(:,iCondition)-1);
                end
                idxDelete = repmat(0, length(ChoiceOptions),1);
                idxRelevant = ChoiceOptions == DESIGN.(Step_Names{iStep}).Choices(iChoice);
                %idxRelevant = Table_Combinations(:,iStep) == DESIGN.(Step_Names{iStep}).Choices(iChoice);
                if Operation == "Equal"
                    idxnotMet = (ToTest~=  Conditional_String(2));
                    %idxnotMet = (Table_Combinations(:,iCondition) ~=  Conditional_String(2));
                elseif Operation == "NotEqual"
                    idxnotMet = (ToTest ==  Conditional_String(2));
                    %idxnotMet = (Table_Combinations(:,iCondition) ==  Conditional_String(2));               
                elseif Operation == "contains" 
                    idxnotMet = ~eval(strrep(Conditional_String, Step_Names{iCondition}, "ToTest"));                  
                end
                
                if ConditionsCombined == "AND"
                    idxDelete = idxRelevant&idxnotMet;
                    OUTPUT = OUTPUT(~idxDelete);

                elseif ConditionsCombined == "OR"
                    idxMet = or(idxMet, ~idxnotMet);
                end
                
                idxDelete =[]; idxRelevant = []; idxnotMet =[]; Indices_Delimiters =[]; 
            end
                if ConditionsCombined == "OR"
                idxDelete = repmat(0, length(ChoiceOptions),1);
                idxRelevant = ChoiceOptions == DESIGN.(Step_Names{iStep}).Choices(iChoice);
                idxDelete = idxRelevant&~idxMet;
                OUTPUT = OUTPUT(~idxDelete);
                end
                ConditionsCombined =[];
        end
    end    
end
end

%save(strcat("OUTPUT.mat"), 'OUTPUT', '-v7.3');
%save("DESIGN.mat", 'DESIGN');

end



