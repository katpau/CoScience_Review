function OUTPUT = Quantification_GMA(INPUT, Choice)
    % Last Checked by OCS 06/23
    % Planned Reviewer: KP
    % Reviewed by:

    % This script does the following:
    % Based on information of previous steps, and depending on the forking
    % choice, runs the GMA either optimized for the nonnegative segment or for
    % the full data range (as in Kummer et al., 2020) for comparison.
    %
    % Requirements
    % - EEGLAB (for pop_select and pop_epoch)
    % - The GMA "package"
    %
    % See also pop_select, pop_epoch, gmaFitEeg, gmaFit, GmaResults
    %
    % Script also extracts Measurement error and reshapes Output to be easily
    % merged into a R-readable Dataframe for further analysis.
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
    StepName = "Quantification_GMA";
    Choices = ["full", "nonneg"];
    Conditional = ["NaN", "NaN"];
    SaveInterim = true;
    Order = 19;


    %% ToDo
    %   - TODO: Choices include fitting the nonnegative interval ('nonneg'),
    %     only, and fitting the full epoch ('full', as in Kummer et al., 2020).

    %% Constants
    % Ne/c only, time (response locked) in ms
    COMPONENT = 'Ne/c';
    EVENT_WIN = [-100, 250];
    MIN_TRIALS = 10;
    SEG_MIN_MS = 20;

    ELECTRODES = {'Fz', 'FCz', 'Cz'};
    nElectrodes = length(ELECTRODES);

    RESP_TYPE = ["correct", "error"];
    RESP_TYPE_LABEL = ["Correct", "Error"];
    nRespType = length(RESP_TYPE);

    FLANKER_ID = "Flanker_GMA";
    FLANKER_LABEL = "Flanker Task";
    % Only responses Experimenter Absent
    FLANKER_TRIGGERS = [ ...
        106, 116, 126, 136, 107, 117, 127, 137; ...
        108, 118, 128, 138, 109, 119, 129, 139];

    GO_NOGO_ID = "GoNoGo_GMA";
    GO_NOGO_LABEL = "Go/NoGo Task";
    %Only responses Speed/Acc emphasis
    GO_NOGO_TRIGGERS = [ ...
        211; ...
        220];

    %% Data from previous steps
    timeWin = str2double(strsplit(INPUT.StepHistory.TimeWindow, ","));
    alysName = INPUT.AnalysisName;


    %% Updating the SubjectStructure. No changes should be made here.
    INPUT.StepHistory.(StepName) = Choice;
    OUTPUT = INPUT;
    OUTPUT.data = [];

    subjectLabel = char(strrep(INPUT.Subject, "sub-", ""));


    %% Response type conditions: triggers depend on the analysis name
    if alysName == FLANKER_ID
        respTriggers = FLANKER_TRIGGERS;
        taskLabel = FLANKER_LABEL;
    elseif alysName == GO_NOGO_ID
        respTriggers = GO_NOGO_TRIGGERS;
        taskLabel = GO_NOGO_LABEL;
    else
        error("Unknown analysis name %s.", alysName);
    end


    % Some Error Handling
    try
        %% Loop INPUT.data (most likely only EEG)
        data = fieldnames(INPUT.data);
        for iData = 1:length(data)
            % Get EEGlab EEG structure from the provided Input Structure
            EEG = INPUT.data.(data{iData});

            %#####################################################################
            %### Start Preprocessing Routine                               #######
            %#####################################################################

            % EARLY EXIT if not epoched
            if isempty(EEG.epoch)
                error("Data is not epoched.");
            end

            % ELECTRODES: Get indices and extract
            eegChannels = upper({EEG.chanlocs.labels});
            [~, elPresent] = ismember(upper(ELECTRODES), eegChannels);
            chValid = elPresent > 0;
            chPresent = find(chValid);
            elPresent = elPresent(chValid);

            EEG = pop_select(EEG, 'channel', elPresent);
            srate = EEG.srate;
            % Minimum nonnegative segment in points (20 ms @500 Hz).
            segMinPnts = round(SEG_MIN_MS * srate / 1000);


            %% Master table for output variables

            % # of combinations
            nComb = nRespType * nElectrodes;

            emp = repmat({NaN}, nComb, 1);
            gmaOut = struct( ...
                'subject', repmat({INPUT.Subject}, nComb, 1), ...
                'lab', repmat({EEG.Info_Lab.RecordingLab}, nComb, 1), ...
                'experimenter', repmat({EEG.Info_Lab.Experimenter}, nComb, 1), ...
                'task', repmat({alysName}, nComb, 1), ...
                'condition', repelem(cellstr(char(RESP_TYPE')), nElectrodes, 1), ...
                'channel', repmat(ELECTRODES', nRespType, 1), ...
                'ch_valid', repmat(num2cell(chValid'), nRespType, 1), ...
                'component', repmat({COMPONENT}, nComb, 1), ...
                'time_win', repmat({num2str(timeWin)}, nComb, 1), ...
                'n_trials', emp, ...
                'eeg_data', emp, ...
                'eeg_srate', repmat({srate}, nComb, 1), ...
                'eeg_mean', emp, ...
                'eeg_sme', emp, ...
                'eeg_peak_neg', emp, ...
                'eeg_peak_neg_sme', emp, ...
                'fit', num2cell(false(nComb, 1)), ...
                'inverted', num2cell(true(nComb, 1)), ...
                'GmaResult', repmat({GmaResults}, nComb, 1), ...
                'GmaArgs', repmat({struct}, nComb, 1), ...
                'x', emp, ...
                'y', emp, ...
                'shape', emp, ...
                'rate', emp, ...
                'yscale', emp, ...
                'ip1', emp, ...
                'ip1_ms', emp, ...
                'mode', emp, ...
                'mode_ms', emp, ...
                'ip2', emp, ...
                'ip2_ms', emp, ...
                'skew', emp, ...
                'excess', emp, ...
                'rmse', emp, ...
                'nrmse', emp, ...
                'r', emp, ...
                'rmse_full', emp, ...
                'nrmse_full', emp, ...
                'r_full', emp, ...
                'version', repmat({GmaResults.version}, nComb, 1), ...
                'timestamp', repmat({char(NaT)}, nComb, 1), ...
                'gma_error', num2cell(true(nComb, 1)), ...
                'gma_log', repmat({''}, nComb, 1));


            %% Loop response types and channels
            for iResp = 1:nRespType
                % filter by triggers, shorten epoch and average over all trials
                triggers = num2cell(respTriggers(iResp, :));
                epochMs = EVENT_WIN / 1000;
                ERP = pop_epoch(EEG, triggers, epochMs, 'epochinfo', 'yes');
                ntrials = ERP.trials;

                % TIME WINDOW of interest, relative to the epoch in samples
                sampleWin = round((timeWin / 1000 - ERP.xmin) * srate + 1);
                winLength = sampleWin(2) - sampleWin(1) + 1;

                % Indices of present channels
                outIdx = (iResp - 1) * nElectrodes + chPresent;

                ntrialsCond = repmat({ntrials}, nElectrodes, 1);
                [gmaOut(outIdx).('n_trials')] = ntrialsCond{:};

                % SKIP channel(s), if below number of minimum trials
                if ntrials < MIN_TRIALS, continue; end

                ERPavg = ERP;
                ERPavg.data = mean(ERP.data, 3);
                ERPavg.trials = 1;
                ERPavg.etc.gma.dataid = subjectLabel;
                ERPavg.etc.gma.desc = strjoin([ ...
                    ["Avg. of", ntrials, "trials"], ...
                    "[#" + subjectLabel + "]"]);

                ERPavg.condition = char(strjoin([taskLabel, RESP_TYPE_LABEL(iResp)]));
                ERPavg.setname = ERPavg.condition;

                eegData = num2cell(ERPavg.data, 2);
                [gmaOut(outIdx).('eeg_data')] = eegData{:};
                eegMean = num2cell(mean(ERPavg.data, 2), 2);
                [gmaOut(outIdx).('eeg_mean')] = eegMean{:};
                eegSme = num2cell(Mean_SME(ERP.data));
                [gmaOut(outIdx).('eeg_sme')] = eegSme{:};
                eegPeakNeg = num2cell(Peaks_Detection(ERPavg.data, "NEG"));
                [gmaOut(outIdx).('eeg_peak_neg')] = eegPeakNeg{:};
                eegPeakNegSme = num2cell(Peaks_SME(ERP.data, "NEG"));
                [gmaOut(outIdx).('eeg_peak_neg_sme')] = eegPeakNegSme{:};

                % Loop available channels for GMA
                for iCh = 1:nElectrodes
                    % SKIP invalid electrodes
                    if ~chValid(iCh), continue; end

                    iOut = (iResp - 1) * nElectrodes + iCh;

                    % Index within remaining ERP
                    chIdx = sum(chValid(1:iCh));

                    rightNow = datetime();
                    rightNow.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
                    gmaOut(iOut).('timestamp') = char(rightNow);
                    
                    try
                        %% Run the GMA
                        % Determine if the GRNMA should use the complete data
                        if strcmpi(Choice, 'full'), fullOpt = true;
                        else, fullOpt = false; end

                        [gResult, ~, gArgsUsed] = gmaFitEeg(ERPavg, chIdx, ...
                            sampleWin(1), winLength, invData = true, ...
                            segMinLength = segMinPnts, optimizeFull = fullOpt, ...
                            logEnabled = false);

                        gmaOut(iOut).('GmaResult') = gResult;
                        gmaOut(iOut).('fit') = gResult.isFit;
                        gmaOut(iOut).('x') = gResult.x;
                        gmaOut(iOut).('y') = gResult.y;
                        gmaOut(iOut).('shape') = gResult.shape;
                        gmaOut(iOut).('rate') = gResult.rate;
                        gmaOut(iOut).('yscale') = gResult.yscale;
                        gmaOut(iOut).('ip1') = gResult.ip1;
                        gmaOut(iOut).('ip1_ms') = gResult.pnt2ms(gResult.ip1);
                        gmaOut(iOut).('mode') = gResult.mode;
                        gmaOut(iOut).('mode_ms') = gResult.pnt2ms(gResult.mode);
                        gmaOut(iOut).('ip2') = gResult.ip2;
                        gmaOut(iOut).('ip2_ms') = gResult.pnt2ms(gResult.ip2);
                        gmaOut(iOut).('skew') = gResult.skew;
                        gmaOut(iOut).('excess') = gResult.excess;
                        gmaOut(iOut).('rmse') = gResult.rmse;
                        gmaOut(iOut).('nrmse') = gResult.nrmse;
                        gmaOut(iOut).('r') = gResult.r;
                        gmaOut(iOut).('GmaArgs') = gArgsUsed;
                        gmaOut(iOut).('gma_error') = false;
                        
                        % Relate fitted PDF to the full data range to obtain
                        % correlation and  error messages for the complete
                        % epoch.
                        if gResult.isValidPdf
                            try
                                gmaFull = gResult.relateWhole();
                                gmaOut(iOut).('rmse_full') = gmaFull.rmse;
                                gmaOut(iOut).('nrmse_full') = gmaFull.nrmse;
                                gmaOut(iOut).('r_full') = gmaFull.r;
                            catch
                                % Should only happen, if the GmaResult is not
                                % zero-padded for the whole segment preceding
                                % the Gamma PDF (see help GmaResults.isaligned).
                            end
                        end

                    catch ME
                        % Add  (error) log, but continue
                        gmaOut(iOut).('gma_error') = true;
                        gmaOut(iOut).('gma_log') = ME.message;
                    end
                end
            end


            %% Extract table with the common fields
            % ID, Lab, Experimenter, Condition, (Electrode), ...

            tblStruct = gmaOut;
            tblDrop = {'task', 'ch_valid', 'eeg_data', 'GmaResult', ...
                'GmaArgs', 'x', 'y', 'version', 'timestamp', 'gma_log'};
            tblStruct = rmfield(tblStruct, tblDrop);
            % A table, which can easily be written to file (e.g., as csv)
            OUTPUT.data.ExportTbl = struct2table(tblStruct);

            % In case, the exported data MUST be without a header… (having a
            % table with proper variable names, this seems to be redundant).
            OUTPUT.data.Export = struct2cell(tblStruct)';


            %% Extract struct for plotting and the GmaResults
            % including instance for further statistics.
            % Important: when loading the mat-file, the GmaResults class MUST be
            % on the MATLAB path! Otherwise the instance cannot be created and
            % the 'GmaResult' field will be empty. Sadly, MATLAB load() does not
            % throw errors in these cases.
            gmaDrop = {'lab', 'experimenter', 'time_win', 'eeg_mean', ...
                'eeg_sme', 'eeg_peak_neg', 'eeg_peak_neg_sme', 'shape', ...
                'rate', 'yscale', 'ip1', 'mode', 'ip2', 'skew', 'excess', ...
                'rmse', 'nrmse', 'r', 'rmse_full', 'nrmse_full', 'r_full'};

            gmaOut = rmfield(gmaOut, gmaDrop);
            OUTPUT.data.GMA = gmaOut;
        end

    catch e
        % ****** Error Management ******
        % If error ocurrs, create ErrorMessage(concatenated for all nested
        % errors). This string is given to the OUTPUT struct.
        ErrorMessage = string(e.message);
        for ierrors = 1:length(e.stack)
            ErrorMessage = strcat(ErrorMessage, "//", num2str(e.stack(ierrors).name), ", Line: ", num2str(e.stack(ierrors).line));
        end

        OUTPUT.Error = ErrorMessage;

    end
end