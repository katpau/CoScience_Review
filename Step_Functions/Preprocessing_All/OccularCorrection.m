function  OUTPUT = OccularCorrection(INPUT, Choice)
% Last Checked by KP 12/22
% Planned Reviewer:
% Reviewed by: 

% This script does the following:
% Depending on the forking choice, an artefacts based on occular activity
% is removed. Most of the procedure are based on identifying artefactous
% ICA components.
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
StepName = "OccularCorrection";
Choices =    ["ICLabel",            "EPOS",               "ADJUST",             "MARA",                "FASTER",             "APPLE",                "Gratton_Coles",                               "No_OccularCorrection"];
Conditional = ["Run_ICA == ""ICA""", "Run_ICA == ""ICA""", "Run_ICA == ""ICA""",  "Run_ICA == ""ICA""", "Run_ICA == ""ICA""", "Run_ICA == ""ICA""", "Epoching_AC == ""epoched"" & Run_ICA == ""No_ICA""",    "Run_ICA == ""No_ICA"""];
SaveInterim = logical([0]);
Order = [11];

% ****** Updating the OUTPUT structure ******
% No changes should be made here.
INPUT.StepHistory.(StepName) = Choice;
OUTPUT = INPUT;
tic % for keeping track of time
try % For Error Handling, all steps are positioned in a try loop to capture errors
    
    %#####################################################################
    %### Start Preprocessing Routine                               #######
    %#####################################################################
    
    Conditions = fieldnames(INPUT.data);
    
    for i_cond = 1:length(Conditions)
        % Get EEGlab EEG structure from the provided Input Structure
        EEG = INPUT.data.(Conditions{i_cond});
        
        if ~strcmpi(Choice, "No_OccularCorrection")
            
            % ****** ICA based correction methods ******
            if ~strcmpi(Choice,"Gratton_Coles")
                % Important: Many of the below approaches work better if done
                % on the filtered Data, not the unfiltered one
                EEG_fil = EEG.filteredData;
                % calculate ICA activity based on weights etc. (excluded for
                % reducing file size)
                EEG_fil.icaact = eeg_getica(EEG_fil);
                
                % initalize clean ICA mask
                clean_ICA_Mask = ones(size(EEG_fil.icaact,1), 1);
                
                badIC =[];
                % ****** identify bad ICA components ******
                if strcmpi(Choice, "EPOS")
                    if  EEG.trials * EEG.pnts /EEG.srate < 15
                        e.message = 'Not Enough Data for Mara, less than 15s.';
                        error(e.message);
                    end
                    [Adjust_badIC, ~] =    ADJUST(EEG_fil);
                    [Mara_badIC, ~] =    MARA(EEG_fil);
                    badIC = sort(unique([Adjust_badIC, Mara_badIC]));
                    
                elseif strcmpi(Choice,"ADJUST")
                    [badIC , ~] =    ADJUST(EEG_fil);
                    
                elseif strcmpi(Choice, "MARA")
                    if  EEG.trials * EEG.pnts /EEG.srate < 15
                        e.message = 'Not Enough Data for Mara, less than 15s.';
                        error(e.message);
                    end
                    [badIC, ~] =    MARA(EEG_fil);
                    
                elseif strcmpi(Choice, "FASTER")
                    badFaster =    component_properties(EEG_fil);
                    badIC = find(min_z(badFaster));
                    
                elseif strcmpi(Choice, "APPLE")
                    % uses a correlation with the VEOG channels
                    VEOG_Chans = find(contains({EEG.chanlocs.labels}, {'VOG'}));
                    % some labs did not record VOGabove, so use FP1 instead
                    if length(VEOG_Chans)<2
                        VEOG_Chans = find(contains({EEG.chanlocs.labels}, {'FP1', 'VOGbelow'}));
                    end                
                    
                    badApple = APPLE_corr(EEG_fil, VEOG_Chans);
                    badIC = sort(unique([badApple.BlinkTemplate_badIC(:), badApple.VEOG_badIC(:)']));
                    
                    
                elseif strcmpi(Choice, "ICLabel")
                    Temp = iclabel(EEG_fil, 'default');
                    badIC_Info = Temp.etc.ic_classification.ICLabel;
                    % Find Components that are probably (70%) Eye and not Brain
                    badIC = find(badIC_Info.classifications(:,3)>0.7 & badIC_Info.classifications(:,1)<0.7);
                    % If none found like that, pick the three that most
                    % probably eyes, but still not brain
                    if isempty(badIC)
                        [~, possiblybad] = maxk(badIC_Info.classifications(:,3),3);
                        badIC = possiblybad(badIC_Info.classifications(possiblybad,1) <0.7);
                    end
                    
                    
                end
                
                clean_ICA_Mask(badIC) = 0;
                
                % ****** Apply Correction ******
                % Remove marked ICA components from unfiltered data
                if ~isempty(badIC)
                    EEG.icaact = eeg_getica(EEG);
                    EEG = pop_subcomp(EEG, badIC, 0);
                end
                
                % ****** Clean Up ******
                % to reduce filesize, remove ICA information
                EEG.icaact = []; EEG.icachansind =[]; EEG.icasphere = []; EEG.icasplinefile =[]; EEG.icaweights =[]; EEG.icawinv =[];
                % remove filtered Data
                EEG= rmfield(EEG, 'filteredData');
                
                
                % ****** "Gratton_Coles ******
            else
                % Determine the VEOG channels, as these are used for Regression and
                % Correlations in the analyses below
                VEOG_Chans = find(contains({EEG.chanlocs.labels}, {'VOG'}));
                % some labs did not record VOGabove, so use FP1 instead
                if length(VEOG_Chans)<2
                    VEOG_Chans = find(contains({EEG.chanlocs.labels}, {'FP1', 'VOGbelow'}));
                end
                
                % Determine EEG Channels that are corrected, VEOG channels are removed
                EEG_channels = 1:EEG.nbchan;
                EEG_channels = EEG_channels(~ismember(EEG_channels, [VEOG_Chans]));
                
                % Criteria/Thresholds for detection
                criteria_veog = 200; % voltage sufficient for blink detection
                window_width = 20; % width of window for relative increases
                
                EEG  =  gratton(EEG, EEG_channels, VEOG_Chans,  ...
                    criteria_veog, window_width);
                
            end
        end
        
        
        %#####################################################################
        %### Wrapping up Preprocessing Routine                         #######
        %#####################################################################
        % ****** Export ******
        % Script creates an OUTPUT structure. Assign here what should be saved
        % and made available for next step. Always save the EEG structure in
        % the OUTPUT.data field, overwriting previous EEG information.
        OUTPUT.data.(Conditions{i_cond}) = EEG;
        if ~strcmpi(Choice,"Gratton_Coles") && ~strcmpi(Choice, "No_OccularCorrection")
            OUTPUT.AC.(Conditions{i_cond}).clean_ICA_Mask = clean_ICA_Mask;
        end
    end
    OUTPUT.StepDuration = [OUTPUT.StepDuration; toc];
    
    
    % ****** Error Management ******
catch e
    % If error ocurrs, create ErrorMessage(concatenated for all nested
    % errors). This string is given to the OUTPUT struct.
    ErrorMessage = string(e.message);
    for ierrors = 1:length(e.stack)
        ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ",  num2str(e.stack(ierrors).line));
    end
    
    if isfield(OUTPUT.AC, 'clean_ICA_Mask') & sum(OUTPUT.AC.clean_ICA_Mask)<1
        ErrorMessage = strcat(ErrorMessage, "Note: All Components marked as bad");
    end
    
    OUTPUT.Error = ErrorMessage;
end
end