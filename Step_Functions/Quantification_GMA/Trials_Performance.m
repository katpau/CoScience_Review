function OUTPUT = Trials_Performance(INPUT, Choice)
    % Last Checked by OCS 06/23
    % Planned Reviewer: KP
    % Reviewed by:

    % This script does the following:
    % Depending on the forking choice, trials are excluded based on
    % performance in that trial. The event structure of the CoScience Data
    % includes details on each trial (Performance, RT, Condition etc.).
    % It is able to handle all options from "Choices" below (see Summary).
    %
    % For GMA, the exclusion by RTs were moved to the primary choice (main
    % path), swapping the place with the exclusions by RT and of post-error
    % trials as originally pre-registered.


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
    StepName = "Trials_Performance";
    Choices = ["RTs", "NoPostError+RTs", "None"];
    Conditional = ["NaN", "NaN", "NaN"];
    SaveInterim = false;
    Order = 18;

    % ****** Updating the OUTPUT structure ******
    % No changes should be made here.
    INPUT.StepHistory.(StepName) = Choice;
    OUTPUT = INPUT;

    % Constants
    % Excluded for NoPostError
    EXCL_POST = {'post_error', 'post_slow_correct', 'post_slow_error'};

    try % For Error Handling, all steps are positioned in a try loop to capture errors

        Conditions = fieldnames(INPUT.data);
        for i_cond = 1:length(Conditions)
            % Get EEGlab EEG structure from the provided Input Structure
            EEG = INPUT.data.(Conditions{i_cond});

            %#####################################################################
            %### Start Preprocessing Routine                               #######
            %#####################################################################

            % EARLY EXIT if not epoched
            if isempty(EEG.epoch)
                error("Data is not epoched.");
            end

            if ~strcmp(Choice, "None")

                postValid = true(1, length(EEG.epoch));
                if strcmp(Choice, "NoPostError+RTs")
                    postValid = cellfun(@(x) ~isempty(x) && ...
                        ~any(contains(EXCL_POST, x{1})), ...
                        {EEG.epoch.eventPost_Trial});
                end

                % % Mark Trials with RTs faster than 0.1 and slower than 0.8s
                rtValid = cellfun( ...
                    @(x) ~isempty(x) && x{1} > 0.1 && x{1} < 0.8, {EEG.epoch.eventRT});

                % Combine Indices
                validEpochs = postValid & rtValid;

                if all(~validEpochs)
                    error("No trials could be matched.");
                elseif all(validEpochs)
                    % No Change needed
                else
                    validEpochIdx = find(validEpochs);
                    EEG = pop_select(EEG, 'trial', validEpochIdx);
                end
                OUTPUT.data.EEG = EEG;
            end
        end

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
