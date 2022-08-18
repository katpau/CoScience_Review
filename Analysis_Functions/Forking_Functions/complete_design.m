function DESIGN = complete_design(DESIGN)
% Takes Design Structure with Fields for each Step
% each step has subfields Choices, Conditional, SaveInterim
% checks if all fields exist, otherwise they are created with the default
% values

    Steps = fields(DESIGN);
        for iStep = 1: length(Steps);
            nrChoices = length(DESIGN.(Steps{iStep}).Choices);

        

            if isfield(DESIGN.(Steps{iStep}), 'Conditional') == false;
               DESIGN.(Steps{iStep}).Conditional = repmat("NaN", 1, nrChoices);
            elseif (length( DESIGN.(Steps{iStep}).Conditional) < nrChoices & length( DESIGN.(Steps{iStep}).Conditional) > 1) == true;
            fprintf('Error! The Conditional Statements did not match the number of Choices for Step: %s\n Please add either only one (applied for all Choices), or include as many as Choices (NaN if no conditions need to be met for others) \n Now all conditional statements have been removed. \n', char(Steps{iStep}));  % Method 1           
               DESIGN.(Steps{iStep}).Conditional = repmat(NaN, 1, nrChoices);
            elseif length( DESIGN.(Steps{iStep}).Conditional) < nrChoices;
               DESIGN.(Steps{iStep}).Conditional = repmat(DESIGN.(Steps{iStep}).Conditional, 1, nrChoices);
            end

            if isfield(DESIGN.(Steps{iStep}), 'SaveInterim') == false;
               DESIGN.(Steps{iStep}).SaveInterim = false;
             end    
            
            DESIGN.(Steps{iStep}).Order = iStep;

        end
end