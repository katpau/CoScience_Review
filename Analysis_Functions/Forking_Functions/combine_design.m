function [DESIGN] = combine_design(DESIGN1, DESIGN2, Combine_Output, FolderToSave, OUTPUT1, OUTPUT2, Overwrite, JunkSize, PartToContinue)

if nargin < 3
    Combine_Output = 0;
end
if nargin < 4
    SaveOutput = 0;
end
if Combine_Output == 1
    if nargin<7
        Overwrite = 1;
    end
    
    if nargin<8
        JunkSize = 1000;
    end
    
    if nargin<9
        PartToContinue = "Part";
    end
end

% Merge Design Structures
mergestructs = @(x,y) cell2struct([struct2cell(x);struct2cell(y)],[fieldnames(x);fieldnames(y)]);
DESIGN = mergestructs(DESIGN1, DESIGN2);

% Make sure that Order is adjusted in
Step_Names =fields(DESIGN);
for istep = 1:length(Step_Names)
    DESIGN.(Step_Names{istep}).Order = istep;
end
if SaveOutput == 1
save([FolderToSave '/DESIGN.mat'], 'DESIGN');
end
if Combine_Output == 1
    % Merge Outputs
    OUTPUT_Merged = allcomb(OUTPUT1, OUTPUT2);
    clear OUTPUT1 OUTPUT2
    
    % Split Output File in Several ones
    Parts = ceil(size(OUTPUT_Merged,1)/JunkSize);
    
    
    % Prepare Saving
    if Overwrite == 1
        SavedPart = 0;
    elseif Overwrite == 0
        SavedPart = dir([FolderToSave 'OUTPUT*']);
        SavedPart = length(SavedPart);
    end
    
    for ipart = 1:Parts
        SavedPart = SavedPart +1; % For Naming Output
        % Split in Parts that can be handled
        if ipart < Parts
            LL = JunkSize;
        else
            LL = size(OUTPUT_Merged,1);
        end
        OUTPUT = OUTPUT_Merged(1:LL,:);
        OUTPUT_Merged(1:LL,:) = [];
        OUTPUT = join(OUTPUT, '%');
        
        
        % For each junk, go through newly added Designsteps and check if
        % Conditions are all matched
        for iStep = (length(fieldnames(DESIGN1))+1):length(Step_Names)
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
                        
                        
                        Indices_Delimiters = cell2mat(strfind(OUTPUT(:,1), '%', 'ForceCellOutput', true));
                        ChoiceOptions = extractAfter(OUTPUT, Indices_Delimiters(:,iStep-1));
                        ToTest = extractBetween(OUTPUT, Indices_Delimiters(:,iCondition-1)+1, Indices_Delimiters(:,iCondition)-1);
                        idxDelete = repmat(0, length(ChoiceOptions),1);
                        idxRelevant = ChoiceOptions == DESIGN.(Step_Names{iStep}).Choices(iChoice);
                        if Operation == "Equal"
                            idxnotMet = (ToTest~=  Conditional_String(2));
                        elseif Operation == "NotEqual"
                            idxnotMet = (ToTest ==  Conditional_String(2));
                        elseif Operation == "contains"
                            idxnotMet = ~eval(strrep(Conditional_String, Step_Names{iCondition}, "ToTest"));
                        end
                        
                        if ConditionsCombined == "AND"
                            idxDelete = idxRelevant&idxnotMet;
                            OUTPUT = OUTPUT(~idxDelete);
                            
                        elseif ConditionsCombined == "OR"
                            idxMet_temp = or(idxMet, ~idxnotMet);
                            idxMet = idxMet_temp;
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
        
        % Join Parts together again
        save([FolderToSave '/OUTPUT_' PartToContinue '_' num2str(SavedPart) '.mat'], 'OUTPUT', '-v7.3');
        OUTPUT =  [];
    end
end
end