function OUTPUT = Reference(INPUT, Choice)
    % Last Checked by OCS 06/23
    % Planned Reviewer: KP
    % Reviewed by:

    % This script does the following:
    % Depending on the forking choice, data is rereferenced.
    % [osc] But only, if the rereference channel actually changed.
    % It is able to handle all options from "Choices" below (see Summary).


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
    StepName = "Reference";
    Choices = ["CSD", "CAV", "Mastoids"];
    Conditional = ["NaN", "NaN", "NaN"];
    SaveInterim = false;
    Order = 15;

    % ****** Updating the OUTPUT structure ******
    % No changes should be made here.
    INPUT.StepHistory.(StepName) = Choice;
    OUTPUT = INPUT;
    try % For Error Handling, all steps are positioned in a try loop to capture errors

        %#####################################################################
        %### Start Preprocessing Routine                               #######
        %#####################################################################

        Conditions = fieldnames(INPUT.data);
        for i_cond = 1:length(Conditions)
            % Get EEGlab EEG structure from the provided Input Structure
            EEG = INPUT.data.(Conditions{i_cond});

            prevRef = INPUT.StepHistory.Reference_AC;
            % No Change for Mastoids needed
            if ~(strcmp(prevRef, "Mastoids") && strcmpi(Choice, "Mastoids"))

                if ~strcmp(prevRef, "CAV")
                    % Add old reference back to signal when not CAV
                    if strcmp(prevRef, "Cz")
                        RefInfo = {'CZ', -0, 0, 0, 0, 1, 0, 90, 1, 'EEG'};
                        ChanlocFields = fields(EEG.chanlocs);
                        for ifield = 1:10
                            EEG.chanlocs(EEG.nbchan + 1).(ChanlocFields{ifield}) = RefInfo{ifield};
                        end
    
                    elseif strcmp(prevRef, "Mastoids")
                        RefInfo = {'MASTr', 108, 0.578, -0.307, -0.946, -0.25, -108, -14.1, 1.03, 'EEG'; ...
                            'MASTl', -108, 0.578, -0.307, 0.946, -0.25, 108, -14.1, 1.03, 'EEG'};
                        ChanlocFields = fields(EEG.chanlocs);
                        for ifield = 1:10
                            EEG.chanlocs(EEG.nbchan + 1).(ChanlocFields{ifield}) = RefInfo{ifield};
                            EEG.chanlocs(EEG.nbchan + 2).(ChanlocFields{ifield}) = RefInfo{ifield};
                        end
                        EEG.data(end + 1, :) = 0;
                    end
    
                    % update EEGlab structure
                    EEG.data(end + 1, :) = 0;
                    EEG.nbchan = size(EEG.data, 1); % update Channel Number
                    EEG = eeg_checkset(EEG);
                end
    
                % ****** Apply new reference ******
               if strcmpi(Choice, "CAV")
                    EEG = pop_select( EEG, 'nochannel',{'VOGabove','VOGbelow','HOGr','HOGl'}); 
                    EEG = pop_reref(EEG, []);
                    LRP = EEG;
                elseif strcmpi(Choice, "Mastoids")
                    Mastoids = find(contains({EEG.chanlocs.labels}, {'MAST'}));
                    EEG = pop_reref(EEG, {EEG.chanlocs(Mastoids).labels}, 'keepref', 'on');
                    LRP = EEG;
                elseif strcmpi(Choice, "CSD")
                    % for LRP, we need to rereference data to the Mastoids
                    LRP = EEG; 
                    Mastoids = find(contains({LRP.chanlocs.labels}, {'MAST'}));
                    LRP = pop_reref(LRP, {LRP.chanlocs(Mastoids).labels}, 'keepref', 'on'); % Rereference LRP Data never to CSD
                    EEG = pop_select( EEG, 'nochannel',{'VOGabove','VOGbelow','HOGr','HOGl', 'MASTl', 'MASTr'}); 
                    EEG.data = laplacian_perrinX(EEG.data, [EEG.chanlocs.X], [EEG.chanlocs.Y], [EEG.chanlocs.Z]);
	    		    EEG.data = EEG.data/100;
                end        
          end
        end


            %#####################################################################
            %### Wrapping up Preprocessing Routine                         #######
            %#####################################################################
            % ****** Export ******
            % Script creates an OUTPUT structure. Assign here what should be saved
            % and made available for next step. Always save the EEG structure in
            % the OUTPUT.data field, overwriting previous EEG information.
            OUTPUT.data.EEG = EEG;
            OUTPUT.data.LRP = LRP;
        


        % ****** Error Management ******
    catch e
        % If error ocurrs, create ErrorMessage(concatenated for all nested
        % errors). This string is given to the OUTPUT struct.
        ErrorMessage = string(e.message);
        for ierrors = 1:length(e.stack)
            ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ", num2str(e.stack(ierrors).line));
        end
        OUTPUT.Error = ErrorMessage;
    end
end