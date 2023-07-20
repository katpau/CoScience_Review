function ANALYSE_DECODING_ERP(study_name, input_mode,sbjs_todo,dcg_todo)
%__________________________________________________________________________
% DDTBOX script written by Stefan Bode 01/03/2013
%
% The toolbox was written with contributions from:
% Daniel Bennett, Jutta Stahl, Daniel Feuerriegel, Phillip Alday
%
% The author further acknowledges helpful conceptual input/work from: 
% Simon Lilburn, Philip L. Smith, Elaine Corbett, Carsten Murawski, 
% Carsten Bogler, John-Dylan Haynes
%__________________________________________________________________________
%
% This script is the master-script for the group-level analysis of EEG-decoding
% results. It will call several subscripts that run all possible analyses,
% depending on the specific decoding analyses.
%
% requires:
% - study_name (e.g. 'DEMO')
% - vconf (version of study configuration script, e.g., "1" for DEMO_config_v1)
% - input_mode (1 = use coded varialbles from first section / 2 = enter manually)
% - sbjs_todo (e.g., [1 2 3 4 6 7 9 10 13])
% - dcg_todo (discrimination group to analyse, as specified in SLIST.dcg_labels{dcg})

%__________________________________________________________________________
%
% Variable naming convention: STRUCTURE_NAME.example_variable

%% GENERAL PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

% post-processing script = 2 - needed for interaction with other scripts to regulate
% functions such as saving data, calling specific sub-sets of parameters
global CALL_MODE
CALL_MODE = 3;

global DCGTODO;
DCGTODO = dcg_todo;

global AnalysisName

if strcmp(AnalysisName, "Flanker_MVPA")
    input_dir = [pwd '\Only_ForGit_To_TestRun\Preproc_forked\Error_MVPA\task-Flanker\1.1_2.1_3.1_4.1_5.1_6.1_7.1_8.1_9.1_10.1_11.1_12.1_13.1_14.1_15.1_16.1\']; % Directory in which the decoding results will be saved
    output_dir_group = [pwd '\Analysis_Functions\Error_MVPA\MVPA\02_MVPA\DECODING_RESULTS\level_2\flanker\']; % Directory in which the group level results will be saved
elseif strcmp(AnalysisName, "GoNoGo_MVPA") 
    input_dir = [pwd '\Only_ForGit_To_TestRun\Preproc_forked\Error_MVPA\task-GoNogo\1.1_2.1_3.1_4.1_5.1_6.1_7.1_8.1_9.1_10.1_11.1_12.1_13.1_14.1_15.1_16.1\']; % Directory in which the decoding results will be saved
    output_dir_group = [pwd '\Analysis_Functions\Error_MVPA\MVPA\02_MVPA\DECODING_RESULTS\level_2\go_nogo\']; % Directory in which the group level results will be saved
end

sbj_code = get_participant_codes(input_dir);

%% specify details about analysis & plotting

%__________________________________________________________________________
if input_mode == 0 % Hard-coded input

    % define all parameters of results to analyse & Plot
    %______________________________________________________________________
    ANALYSIS.allchan = 1; % Are all possible channels analysed? 1=yes (default if spatial/spatio-temporal) / 2=no
    ANALYSIS.relchan = []; % specify channels to be analysed (for temporal only)
        
    ANALYSIS.stmode = 3; % SPACETIME mode (1=spatial / 2=temporal / 3=spatio-temporal)
    ANALYSIS.avmode = 1; % AVERAGE mode (1=no averaging; single-trial / 2=run average) 
    ANALYSIS.window_width_ms = 10; % width of sliding window in ms
    ANALYSIS.step_width_ms = 10; % step size with which sliding window is moved through the trial
    
    ANALYSIS.permstats = 2; % Testing against: 1=theoretical chance level / 2=permutation test results
    ANALYSIS.drawmode = 1; % Testing against: 1=average permutated distribution (default) / 2=random values drawn form permuted distribution (stricter)
   
    ANALYSIS.pstats = 0.05; % critical p-value
    ANALYSIS.multcompstats = 1; % Correction for multiple comparisons: 
    % 0 = no correction
    % 1 = Bonferroni correction
    % 2 = Holm-Bonferroni correction
    % 3 = Strong FWER Control Permutation Test
    % 4 = Cluster-Based Permutation Test
    % 5 = KTMS Generalised FWER Control
    % 6 = Benjamini-Hochberg FDR Control
    % 7 = Benjamini-Krieger-Yekutieli FDR Control
    % 8 = Benjamini-Yekutieli FDR Control
    ANALYSIS.n_iterations = 1000; % Number of permutation or bootstrap iterations for resampling-based multiple comparisons correction procedures
    ANALYSIS.ktms_u = 2; % u parameter of the KTMS GFWER control procedure
    ANALYSIS.cluster_test_alpha = 0.05; % For cluster-based test: Significance threshold for detecting effects at individual time windows (e.g. 0.05) 
    
    ANALYSIS.disp.on = 1; % display a results figure? 0=no / 1=yes
    ANALYSIS.permdisp = 1; % display the results from permutation test in figure as separate line? 0=no / 1=yes
    ANALYSIS.disp.sign = 1; % display statistically significant steps in results figure? 0=no / 1=yes
    
    ANALYSIS.fw.do = 0; % analyse feature weights? 0=no / 1=yes
    ANALYSIS.fw.multcompstats = 1; % Feature weights correction for multiple comparisons:
    % 1 = Bonferroni correction
    % 2 = Holm-Bonferroni correction
    % 3 = Strong FWER Control Permutation Test
    % 4 = Cluster-Based Permutation Test (Currently not available)
    % 5 = KTMS Generalised FWER Control
    % 6 = Benjamini-Hochberg FDR Control
    % 7 = Benjamini-Krieger-Yekutieli FDR Control
    % 8 = Benjamini-Yekutieli FDR Control
    
        % if feature weights are analysed, specify what is displayed
        %__________________________________________________________________
        
        % 0=no / 1=yes
        ANALYSIS.fw.display_matrix = 1; % feature weights matrix
        
        % averaged maps and stats
        ANALYSIS.fw.display_average_zmap = 1; % z-standardised average FWs
        ANALYSIS.fw.display_average_uncorr_threshmap = 1; % thresholded map uncorrected t-test results
        ANALYSIS.fw.display_average_corr_threshmap = 1; % thresholded map corrected t-test results (Bonferroni)
        
        % individual maps and stats
        ANALYSIS.fw.display_all_zmaps = 0; % z-standardised average FWs
        ANALYSIS.fw.display_all_uncorr_thresh_maps = 0; % thresholded map uncorrected t-test results
        ANALYSIS.fw.display_all_corr_thresh_maps = 0; % thresholded map corrected t-test results (Bonferroni)
%__________________________________________________________________________    

elseif input_mode == 1 % Prompted manual input
    
    % specify analysis channels
    ANALYSIS.allchan = input('Are all possible channels analysed? "0" for no; "1" for yes (default if spatial/spatio-temporal): ');
    
    if ANALYSIS.allchan ~= 1
        
        ANALYSIS.relchan = input('Enter the channels to be analysed (e.g. [1 4 5]): ');
        
    end
    
    % specify properties of the decoding analysis
    ANALYSIS.stmode = input('Specify the s/t-analysis mode of the original analysis. "1" spatial, "2" temporal. "3" spatio-temporal: ');
    ANALYSIS.avmode = input('Specify the average mode of the original analysis. "1" single-trial, "2" run-average: ');
    ANALYSIS.window_width_ms = input('Specify the window width [ms] of the original analysis: ');
    ANALYSIS.step_width_ms = input('Specify the step width [ms] of the original analysis: ');
    
    % specify stats
    ANALYSIS.permstats = input('Testing against: "1" chance level; "2" permutation distribution: ');
    
    if ANALYSIS.permstats == 2
        
        ANALYSIS.drawmode = input('Testing against: "1" average permutated distribution (default); "2" random values drawn form permuted distribution (stricter): ');
        ANALYSIS.permdisp = input('Do you wish to display chance-level test results in figure? "0" for no; "1" for yes: ');
        
    end
    
    ANALYSIS.pstats = input('Specify critical p-value for statistical testing (e.g. 0.05): ');
    ANALYSIS.multcompstats = input(['\nSpecify if you wish to control for multiple comparisons: \n"0" for no correction \n'...
        '"1" for Bonferroni \n"2" for Holm-Bonferroni \n"3" for Strong FWER Control Permutation Testing \n' ...
        '"4" for Cluster-Based Permutation Testing \n"5" for KTMS Generalised FWER Control \n' ...
        '"6" for Benjamini-Hochberg FDR Control \n"7" for Benjamini-Krieger-Yekutieli FDR Control \n' ...
        '"8" for Benjamini-Yekutieli FDR Control \n Option: ']);
    
    if ANALYSIS.multcompstats == 3 || ANALYSIS.multcompstats == 4 || ANALYSIS.multcompstats == 5 % For permutation tests
        ANALYSIS.n_iterations = input('Number of permutation iterations for multiple comparisons procedure (at least 1000 is recommended): ');    
    end
    if ANALYSIS.multcompstats == 5 % For KTMS Generalised FWER control
       ANALYSIS.ktms_u = input('Enter the u parameter for the KTMS Generalised FWER control procedure: '); 
    end
    if ANALYSIS.multcompstats == 4 % For cluster-based permutation testing
       ANALYSIS.cluster_test_alpha = input('Enter the clustering threshold for detecting effects at individual time points (e.g. 0.05): '); 
    end
    
    % specify display options
    ANALYSIS.disp.on = input('Do you wish to display the results in figure(s)? "0" for no; "1" for yes: ');
    ANALYSIS.disp.sign = input('Specify if you wish to highlight significant results in figure. "0" for no; "1" for yes: ');
    
    % analyse feature weights
    ANALYSIS.fw.do = input('Do you wish to analyse the feature weights (only for spatial or spatio-temporal decoding)? "0" for no; "1" for yes: ');
    
    if ANALYSIS.fw.do == 1
        ANALYSIS.multcompstats = input(['\nSpecify which multiple comparisons correction method to use: \n' ...
        '"1" for Bonferroni \n"2" for Holm-Bonferroni \n"3" for Strong FWER Control Permutation Testing \n' ...
        '"4" for Cluster-Based Permutation Testing (Currently not available) \n"5" for KTMS Generalised FWER Control \n' ...
        '"6" for Benjamini-Hochberg FDR Control \n"7" for Benjamini-Krieger-Yekutieli FDR Control \n' ...
        '"8" for Benjamini-Yekutieli FDR Control \n Option: ']);
    
        if ANALYSIS.multcompstats == 3 || ANALYSIS.multcompstats == 4 || ANALYSIS.multcompstats == 5 % For permutation tests
            ANALYSIS.n_iterations = input('Number of permutation iterations for multiple comparisons procedure (at least 1000 is recommended): ');    
        end
        if ANALYSIS.multcompstats == 5 % For KTMS Generalised FWER control
           ANALYSIS.ktms_u = input('Enter the u parameter for the KTMS Generalised FWER control procedure: '); 
        end
        if ANALYSIS.multcompstats == 4 % For cluster-based permutation testing
           fprintf('Cluster-based corrections are currently not available.\n')
           % ANALYSIS.cluster_test_alpha = input('Enter the clustering threshold for detecting effects at individual time points (e.g. 0.05): '); 
        end
        
        ANALYSIS.fw.display_average_zmap = input('Do you wish to display the group-level averaged, z-standardised feature weights as a heat map? "0" for no; "1" for yes: '); % z-standardised average FWs
        ANALYSIS.fw.display_average_uncorr_threshmap = input(...
            'Do you wish to display the statistical threshold map (uncorrected) for the group-level averaged, z-standardised feature weights as a heat map? "0" for no; "1" for yes: '); % thresholded map uncorrected t-test results
        ANALYSIS.fw.display_average_corr_threshmap = input(...
            'Do you wish to display the statistical threshold map (corrected for multiple comparisons) for the group-level averaged, z-standardised feature weights as a heat map? "0" for no; "1" for yes: '); % thresholded map corrected t-test results (Bonferroni)
        
        % individual maps and stats
        ANALYSIS.fw.display_all_zmaps = input('');
        ANALYSIS.fw.display_all_uncorr_thresh_maps = input(...
            'Do you wish to display the statistical threshold map (uncorrected) for the group-level z-standardised feature weights for each time-step as a heat map? "0" for no; "1" for yes: ');
        ANALYSIS.fw.display_all_corr_thresh_maps = input(...
            'Do you wish to display the statistical threshold map (corrected for multiple comparisons) for the group-level z-standardised feature weights for each time-step as a heat map? "0" for no; "1" for yes: ');
        
    end
    
end % input
%__________________________________________________________________________

fprintf('Group-level statistics will now be computed and displayed. \n'); 


%% OPEN FILES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

% [elisa] modified to fit input structure
if ischar(sbjs_todo)
    if sbjs_todo == 'all'
       ANALYSIS.nsbj = length(sbj_code);
       ANALYSIS.sbjs = sbj_code(1:length(sbj_code));
    end
else
   ANALYSIS.nsbj = length(sbjs_todo);
   ANALYSIS.sbjs = sbj_code(sbjs_todo);
end

ANALYSIS.dcg_todo = dcg_todo;

for s = 1:ANALYSIS.nsbj
    
    %% open subject data
    global SBJTODO;
    SBJTODO = s;
    sbj = ANALYSIS.sbjs(SBJTODO);
    
    global SLIST;
    
    % open subject's decoding results       

% [elisa] modified to fit input structure
    sbj_file = append(input_dir, string(sbj), '.mat');    
    load(sbj_file);

    STUDY = Data.MVPA.STUDY;
    SLIST = Data.MVPA.SLIST;
    RESULTS = Data.MVPA.RESULTS;

%     fprintf('Done.\n');
    
%     %[elisa] save otuput file for all participants with part_code and decoding
%     %accuracies to jackknife decoding onset later
    part_accuracies = zeros(length(RESULTS.subj_acc),2);
    part_accuracies(:,1) = RESULTS.subj_acc;
    part_accuracies(:,2) = RESULTS.subj_perm_acc;
    id = repmat(STUDY.part_code,length(part_accuracies),1);
    timestep = [-300:10:290]';
    part_accuracies = [cell2table(cellstr(id)), array2table(timestep), array2table(part_accuracies)];
    colNames={'id', 'timestep', 'subj_acc', 'subj_perm_acc'};
    part_accuracies.Properties.VariableNames = colNames;
    
    if ~isfile([output_dir_group 'all_part_acc.mat'])
             all_part_accuracies = part_accuracies; 
    else 
        load([output_dir_group 'all_part_acc.mat']);
        if ~any(strcmp(STUDY.part_code, all_part_accuracies.id)) %only append when current part has not been appended 
             all_part_accuracies = vertcat(all_part_accuracies, part_accuracies); 
         end
    end
    
    save([output_dir_group 'all_part_acc.mat'], 'all_part_accuracies'); % Save into a .mat file

    ANALYSIS.analysis_mode = STUDY.analysis_mode;
    ANALYSIS.pointzero = SLIST.pointzero;
    
        
    %% fill in parameters and extract results 
    %______________________________________________________________________
    %
    % RESULTS contains averaged results:
    % RESULTS.subj_acc(analysis/channel,time-step) 
    % RESULTS.subj_perm_acc(analysis/channel,time-step) 
    % RESULTS contains raw results:
    % RESULTS.prediction_accuracy{analysis/channel}(time-step,cross-val_step,rep_step)
    % RESULTS.perm_prediction_accuracy{analysis/channel}(time-step,cross-val_step,rep_step)
    %
    % this section adds group results to ANALYSIS:
    % ANALYSIS.RES.all_subj_acc(subject,analysis/channel,time_step(fist_step:last_step))
    % ANALYSIS.RES.all_subj_perm_acc(subject,analysis/channel,time_step(fist_step:last_step))
    % ANALYSIS.RES.all_subj_perm_acc_reps(subject,analysis/channel,time_step(fist_step:last_step),cross-val_step,rep_step)
    
    % Define missing parameters using the first subject's dataset
    %______________________________________________________________________
    if s == 1 
        
        % ask for the specific time steps to analyse
        if ANALYSIS.avmode == 1 || ANALYSIS.avmode == 1 % DF NOTE: Is the second IF statement supposed to specify a different value?
    
            fprintf('\n');
            fprintf('You have %d time-steps in your RESULTS. Each time-step represents a %d ms time-window. \n',size(RESULTS.subj_acc,2),STUDY.window_width_ms);
            ANALYSIS.firststep = 1;
            ANALYSIS.laststep = input('Enter the number of the last time-window you want to analyse: ');

        end
    
        % shift everything back by step-width, as first bin gets label=0ms
        ANALYSIS.firststepms = (ANALYSIS.firststep * STUDY.step_width_ms) - STUDY.step_width_ms;
        ANALYSIS.laststepms = (ANALYSIS.laststep * STUDY.step_width_ms) - STUDY.step_width_ms;

        % create matrix for data indexing
        ANALYSIS.data(1,:) = 1:size(RESULTS.subj_acc,2); % for XTick
        ANALYSIS.data(2,:) = 0:STUDY.step_width_ms:( (size(RESULTS.subj_acc,2) - 1) * STUDY.step_width_ms); % for XLabel
        ptz = find(ANALYSIS.data(2,:) == ANALYSIS.pointzero); % find data with PointZero
        ANALYSIS.data(3,ptz) = 1; clear ptz; % for line location in plot

        % copy parameters from the config file
        ANALYSIS.step_width = STUDY.step_width;
        ANALYSIS.window_width = STUDY.window_width;

        ANALYSIS.feat_weights_mode = STUDY.feat_weights_mode;
        
        ANALYSIS.nchannels = SLIST.nchannels;
        
%         ANALYSIS.channellocs = SLIST.channellocs;
%         ANALYSIS.channel_names_file = SLIST.channel_names_file;     
                
        % extract Tick/Labels for x-axis
        for datastep = 1:ANALYSIS.laststep
            ANALYSIS.xaxis_scale(1,datastep) = ANALYSIS.data(1,datastep);
            ANALYSIS.xaxis_scale(2,datastep) = ANALYSIS.data(2,datastep);
            ANALYSIS.xaxis_scale(3,datastep) = ANALYSIS.data(3,datastep);
        end
        
        % Define chance level for statistical analyses based on the
        % analysis type
        if STUDY.analysis_mode == 1 || STUDY.analysis_mode == 2
            ANALYSIS.chancelevel = ( 100 / size(SLIST.dcg{ANALYSIS.dcg_todo(1)},2) );
        elseif STUDY.analysis_mode == 3 || STUDY.analysis_mode == 4
            ANALYSIS.chancelevel = 0;
        end
        
        % Define channels to be used for group-analyses
        if ANALYSIS.allchan == 1

            % use all channels (default for spatial / spatial-temporal)
            ANALYSIS.allna = size(RESULTS.subj_acc,1);

        elseif ANALYSIS.allchan ~= 1

            % use specified number of channels
            ANALYSIS.allna = size(ANALYSIS.relchan,2);

        end
        
        
        if STUDY.analysis_mode == 1 || STUDY.analysis_mode == 2
            if size(ANALYSIS.dcg_todo,2) == 1
                ANALYSIS.DCG = SLIST.dcg_labels{ANALYSIS.dcg_todo};
            elseif size(ANALYSIS.dcg_todo,2) == 2
                ANALYSIS.DCG{1} = SLIST.dcg_labels{ANALYSIS.dcg_todo(1)};
                ANALYSIS.DCG{2} = SLIST.dcg_labels{ANALYSIS.dcg_todo(2)};
            end
        elseif STUDY.analysis_mode == 3 || STUDY.analysis_mode == 4    
            ANALYSIS.DCG = 'SVR_regression';
        end
        
                
    end % of if s == 1 statement

    % [elisa] added to acommodate different channellocs
%     ANALYSIS.channellocs(s) = SLIST.channellocs;
%     ANALYSIS.sampling_rate(s) = STUDY.sampling_rate;
%         if STUDY.sampling_rate == 512
%             ANALYSIS.channellocs.Biosemi = SLIST.channellocs;
%             ANALYSIS.sampling_rate.Biosemi = STUDY.sampling_rate;    
%         end
% 
%         for lab = 1:ANALYSIS.allna
%             ANALYSIS.channellocs(s,lab,ANALYSIS.firststep:ANALYSIS.laststep) = RESULTS.subj_acc(na,ANALYSIS.firststep:ANALYSIS.laststep);       
%         end


    
    %% extract results data from specified time-steps / channels
    %______________________________________________________________________
    
    for na = 1:ANALYSIS.allna
        
        % Extract classifier and permutation test accuracies
        ANALYSIS.RES.all_subj_acc(s,na,ANALYSIS.firststep:ANALYSIS.laststep) = RESULTS.subj_acc(na,ANALYSIS.firststep:ANALYSIS.laststep);
        ANALYSIS.RES.all_subj_perm_acc(s,na,ANALYSIS.firststep:ANALYSIS.laststep) = RESULTS.subj_perm_acc(na,ANALYSIS.firststep:ANALYSIS.laststep);
            
        % needed if one wants to test against distribution of randomly
        % drawn permutation results (higher variance, stricter testing)
        ANALYSIS.RES.all_subj_perm_acc_reps(s,na,ANALYSIS.firststep:ANALYSIS.laststep,:,:) = RESULTS.perm_prediction_accuracy{na}(ANALYSIS.firststep:ANALYSIS.laststep,:,:);
            
    end
    %______________________________________________________________________

    % Extract feature weights
    if ~isempty(RESULTS.feature_weights)
        ANALYSIS.RES.feature_weights{s} = RESULTS.feature_weights{1};
    end
    
    clear RESULTS;
    clear STUDY;
    
end % of for n = 1:ANALYSIS.nsbj loop

fprintf('All data from all subjects loaded.\n');

%% AVERAGE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

% Calculate average accuracy & standard error across subjects
M(:,:) = mean(ANALYSIS.RES.all_subj_acc,1);
ANALYSIS.RES.mean_subj_acc(:,:) = M'; clear M;

SE(:,:) = (std(ANALYSIS.RES.all_subj_acc,1))/(sqrt(ANALYSIS.nsbj));
ANALYSIS.RES.se_subj_acc(:,:) = SE'; clear SE;

if ANALYSIS.permstats == 2
    
    % OPTION 1: Use average results from random-labels test
    % Calculate average accuracy & standard error across subjects for permutation results
    M(:,:) = mean(ANALYSIS.RES.all_subj_perm_acc,1);
    ANALYSIS.RES.mean_subj_perm_acc(:,:) = M'; clear M;
    
    SE(:,:) = (std(ANALYSIS.RES.all_subj_perm_acc,1)) / (sqrt(ANALYSIS.nsbj));
    ANALYSIS.RES.se_subj_perm_acc(:,:) = SE'; clear SE;

    % OPTION 2: draw values from random-labels test
    % average permutation results across cross-validation steps, but draw later 
    % one for each participant for statistical testing!
    for subj = 1:ANALYSIS.nsbj
        for ana = 1:ANALYSIS.allna
            for step = 1:ANALYSIS.laststep
                temp(:,:) = ANALYSIS.RES.all_subj_perm_acc_reps(subj,ana,step,:,:);
                mtemp = mean(temp,1);
                ANALYSIS.RES.all_subj_perm_acc_reps_draw{subj,ana,step} = mtemp;
                clear temp; clear mtemp;
            end % step
        end % ana
    end % sbj

end % of if ANALYSIS.permstats == 2 statement

fprintf('All data from all subjects averaged.\n');

%% STATISTICAL TESTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

for na = 1:size(ANALYSIS.RES.mean_subj_acc,1) % analysis
        
    for step = 1:size(ANALYSIS.RES.mean_subj_acc,2) % step
            
        % simply test against chance
        if ANALYSIS.permstats == 1
            
            % chance level = 100 / number conditions
            [H,P, ~, otherstats] = ttest(ANALYSIS.RES.all_subj_acc(:,na,step),ANALYSIS.chancelevel,ANALYSIS.pstats); % simply against chance
            T = otherstats.tstat;
            clear otherstats;
            
        % test against permutation test results    
        elseif ANALYSIS.permstats == 2
            
            % against average permuted distribution
            if ANALYSIS.drawmode == 1
                
                [H,P, ~, otherstats] = ttest(ANALYSIS.RES.all_subj_acc(:,na,step),ANALYSIS.RES.all_subj_perm_acc(:,na,step),ANALYSIS.pstats);
                T = otherstats.tstat;
                clear otherstats;
                
            % against one randomly drawn value (from all cross-val repetitions for each participant) for stricter test    
            elseif ANALYSIS.drawmode == 2
                
                for sbj = 1:ANALYSIS.nsbj
                    temp = randperm(size(ANALYSIS.RES.all_subj_perm_acc_reps_draw{sbj,na,step}(:,:),2));
                    drawone = temp(1); clear temp;
                    ANALYSIS.RES.draw_subj_perm_acc(sbj,na,step) = ANALYSIS.RES.all_subj_perm_acc_reps_draw{sbj,na,step}(1,drawone);
                    clear drawone;
                end % sbj
                
                [H,P, ~, otherstats] = ttest(ANALYSIS.RES.all_subj_acc(:,na,step),ANALYSIS.RES.draw_subj_perm_acc(:,na,step),ANALYSIS.pstats);
                T = otherstats.tstat;
                clear otherstats;
            end % if ANALYSIS.drawmode
            
        end % if ANALYSIS.permstats
       
        ANALYSIS.RES.p_ttest(na,step) = P; clear P;
        ANALYSIS.RES.h_ttest_uncorrected(na,step) = H; clear H;
        ANALYSIS.RES.t_ttest(na,step) = T; clear T;
            
    end % of for step = 1:size(ANALYSIS.RES.mean_subj_acc,2) loop
    
end % of for na = 1:size(ANALYSIS.RES.mean_subj_acc,1) loop


%% CORRECTION FOR MULTIPLE COMPARISONS
%__________________________________________________________________________

ANALYSIS.RES.h_ttest = zeros(size(ANALYSIS.RES.mean_subj_acc,1), size(ANALYSIS.RES.mean_subj_acc,2));

switch ANALYSIS.multcompstats

case 0 % No correction for multiple comparisons

    fprintf('Correction for multiple comparisons has not been applied\n');

    ANALYSIS.RES.h_ttest = ANALYSIS.RES.h_ttest_uncorrected; 

%__________________________________________________________________________

case 1 % Bonferroni Correction

    fprintf('Performing corrections for multiple comparisons (Bonferroni)\n');

    for na = 1:size(ANALYSIS.RES.mean_subj_acc,1) % analysis
        [ANALYSIS.RES.h_ttest(na, :), ANALYSIS.RES.bonferroni_adjusted_alpha(na)] = multcomp_bonferroni(ANALYSIS.RES.p_ttest(na,:), 'alpha', ANALYSIS.pstats); % Bonferroni correction
        fprintf('The adjusted critical alpha for analysis %i is %1.6f \n', na, ANALYSIS.RES.bonferroni_adjusted_alpha(na));
    end

%__________________________________________________________________________    

case 2 % Holm-Bonferroni Correction
    
    fprintf('Performing corrections for multiple comparisons (Holm-Bonferroni)\n');

    % Here a family of tests is defined as all steps within a given analysis
    for na = 1:size(ANALYSIS.RES.mean_subj_acc,1) % analysis
        [ANALYSIS.RES.h_ttest(na, :), ANALYSIS.RES.holm_adjusted_alpha(na)] = multcomp_holm_bonferroni(ANALYSIS.RES.p_ttest(na,:), 'alpha', ANALYSIS.pstats); % Holm-Bonferroni correction      
        fprintf('The adjusted critical alpha for analysis %i is %1.6f   \n', na, ANALYSIS.RES.holm_adjusted_alpha(na));
    end % of for na loop

%__________________________________________________________________________    

case 3 % Strong FWER Control Permutation Test (Blaire-Karniski)
    
    fprintf('Performing corrections for multiple comparisons (permutation test)\n');
    
    for na = 1:size(ANALYSIS.RES.mean_subj_acc,1) % analysis
    
        if ANALYSIS.permstats == 1 % If testing against theoretical chance level
            real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
            perm_decoding_scores = zeros(size(real_decoding_scores, 1), 1, size(real_decoding_scores, 3));
            perm_decoding_scores(:, 1, :) = ANALYSIS.chancelevel;
        elseif ANALYSIS.permstats == 2 % If testing against permutation decoding results
            real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
            if ANALYSIS.drawmode == 1 % If testing against average permuted distribution
                perm_decoding_scores = ANALYSIS.RES.all_subj_perm_acc(:, na, :);
            elseif ANALYSIS.drawmode == 2 % If testing against one randomly drawn value
                perm_decoding_scores = ANALYSIS.RES.draw_subj_perm_acc(:, na, :);
            end
        end
        
        % Convert to two-dimensional matrix for multcomp correction algorithm
        tmp = squeeze(real_decoding_scores);
        real_decoding_scores = tmp;
        tmp = squeeze(perm_decoding_scores);
        perm_decoding_scores = tmp;

        [ANALYSIS.RES.h_ttest(na, :), ANALYSIS.RES.p_ttest(na,:), ANALYSIS.RES.critical_t(na)] = multcomp_blaire_karniski_permtest(real_decoding_scores, perm_decoding_scores, 'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations);
        fprintf('The adjusted critical t value for analysis %i is %3.3f \n', na, ANALYSIS.RES.critical_t(na));
    end % of for na loop
    
    clear real_decoding_scores
    clear perm_decoding_scores
%__________________________________________________________________________    

case 4 % Cluster-Based Permutation Test
 
    fprintf('Performing corrections for multiple comparisons (cluster-based permutation test)\n');
    
    for na = 1:size(ANALYSIS.RES.mean_subj_acc,1) % analysis
    
        if ANALYSIS.permstats == 1 % If testing against theoretical chance level
            real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
            perm_decoding_scores = zeros(size(real_decoding_scores, 1), 1, size(real_decoding_scores, 3));
            perm_decoding_scores(:, 1,:) = ANALYSIS.chancelevel;
        elseif ANALYSIS.permstats == 2 % If testing against permutation decoding results
            real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
            if ANALYSIS.drawmode == 1 % If testing against average permuted distribution
                perm_decoding_scores = ANALYSIS.RES.all_subj_perm_acc(:, na, :);
            elseif ANALYSIS.drawmode == 2 % If testing against one randomly drawn value
                perm_decoding_scores = ANALYSIS.RES.draw_subj_perm_acc(:, na, :);
            end    
        end
        % Convert to two-dimensional matrix for multcomp correction algorithm
        tmp = squeeze(real_decoding_scores);
        real_decoding_scores = tmp;
        tmp = squeeze(perm_decoding_scores);
        perm_decoding_scores = tmp;
        
        [ANALYSIS.RES.h_ttest(na, :)] = multcomp_cluster_permtest(real_decoding_scores, perm_decoding_scores,  'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations, 'clusteringalpha', ANALYSIS.cluster_test_alpha);
    end % of for na loop
    clear real_decoding_scores
    clear perm_decoding_scores
%__________________________________________________________________________    

case 5 % KTMS Generalised FWER Control Using Permutation Testing
    
    fprintf('Performing corrections for multiple comparisons (KTMS generalised FWER control)\n');

    % Adapted from permutation test script
    for na = 1:size(ANALYSIS.RES.mean_subj_acc,1) % analysis

        if ANALYSIS.permstats == 1 % If testing against theoretical chance level
            real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
            perm_decoding_scores = zeros(size(real_decoding_scores, 1), 1, size(real_decoding_scores, 3));
            perm_decoding_scores(:, 1,:) = ANALYSIS.chancelevel;
        elseif ANALYSIS.permstats == 2 % If testing against permutation decoding results
            real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
            if ANALYSIS.drawmode == 1 % If testing against average permuted distribution
                perm_decoding_scores = ANALYSIS.RES.all_subj_perm_acc(:, na, :);
            elseif ANALYSIS.drawmode == 2 % If testing against one randomly drawn value
                perm_decoding_scores = ANALYSIS.RES.draw_subj_perm_acc(:, na, :);
            end
        end
        % Convert to two-dimensional matrix for multcomp correction algorithm
        tmp = squeeze(real_decoding_scores);
        real_decoding_scores = tmp;
        tmp = squeeze(perm_decoding_scores);
        perm_decoding_scores = tmp;

        [ANALYSIS.RES.h_ttest(na, :)] = multcomp_ktms(real_decoding_scores, perm_decoding_scores, 'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations, 'ktms_u', ANALYSIS.ktms_u);
    end % of for na loop
    clear real_decoding_scores
    clear perm_decoding_scores

%__________________________________________________________________________    

case 6 % Benjamini-Hochberg FDR Control

    fprintf('Performing corrections for multiple comparisons (Benjamini-Hochberg)\n');
    
    % Here a family of tests is defined as all steps within a given analysis
    for na = 1:size(ANALYSIS.RES.mean_subj_acc,1) % analysis
        [ANALYSIS.RES.h_ttest(na, :), ANALYSIS.RES.bh_crit_alpha(na)] = multcomp_fdr_bh(ANALYSIS.RES.p_ttest(na,:), 'alpha', ANALYSIS.pstats);
        fprintf('The adjusted critical alpha for analysis %i is %1.6f \n', na, ANALYSIS.RES.bh_crit_alpha(na));
    end % of for na loop

%__________________________________________________________________________    

case 7 % Benjamini-Krieger-Yekutieli FDR Control
    
    fprintf('Performing corrections for multiple comparisons (Benjamini-Krieger-Yekutieli)\n');

    % Here a family of tests is defined as all steps within a given analysis
    for na = 1:size(ANALYSIS.RES.mean_subj_acc,1) % analysis
        [ANALYSIS.RES.h_ttest(na, :), ANALYSIS.RES.bky_crit_alpha(na)] = multcomp_fdr_bky(ANALYSIS.RES.p_ttest(na,:), 'alpha', ANALYSIS.pstats);
        fprintf('The adjusted critical alpha for analysis %i is %1.6f \n', na, ANALYSIS.RES.bky_crit_alpha(na));
    end % of for na loop

%__________________________________________________________________________    

case 8 % Benjamini-Yekutieli FDR Control
    
    fprintf('Performing corrections for multiple comparisons (Benjamini-Yekutieli)\n');

    % Here a family of tests is defined as all steps within a given analysis
    for na = 1:size(ANALYSIS.RES.mean_subj_acc,1) % analysis
        [ANALYSIS.RES.h_ttest(na, :), ANALYSIS.RES.by_crit_alpha(na)] = multcomp_fdr_by(ANALYSIS.RES.p_ttest(na,:), 'alpha', ANALYSIS.pstats);
        fprintf('The adjusted critical alpha for analysis %i is %1.6f \n', na, ANALYSIS.RES.by_crit_alpha(na));
    end % of for na loop

%__________________________________________________________________________    
% If some other option is chosen then do not correct, but notify user
otherwise
    fprintf('Unavailable multiple comparisons option chosen. Will use uncorrected p-values \n');
    ANALYSIS.RES.h_ttest = ANALYSIS.RES.h_ttest_uncorrected; 
end % of ANALYSIS.multcompstats switch


fprintf('All group statistics performed.\n');

%% FEATURE WEIGHT ANALYSIS
%__________________________________________________________________________

if ANALYSIS.fw.do == 1
    
    [FW_ANALYSIS] = analyse_feature_weights_erp(ANALYSIS);
    
else
    
    FW_ANALYSIS = [];
    
end


%% SAVE RESULTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

if size(dcg_todo,2) == 1 % Standard decoding analyses

    savename = [(output_dir_group) study_name '_GROUPRES_NSBJ' num2str(ANALYSIS.nsbj) '_win' num2str(ANALYSIS.window_width_ms) '_steps' num2str(ANALYSIS.step_width_ms)...
        '_av' num2str(ANALYSIS.avmode) '_st' num2str(ANALYSIS.stmode) '_DCG' SLIST.dcg_labels{ANALYSIS.dcg_todo} '.mat'];
    
elseif size(dcg_todo,2) == 2 % Cross-condition decoding analyses
    
    savename = [(output_dir_group) study_name '_GROUPRES_NSBJ' num2str(ANALYSIS.nsbj) '_win' num2str(ANALYSIS.window_width_ms) '_steps' num2str(ANALYSIS.step_width_ms)...
        '_av' num2str(ANALYSIS.avmode) '_st' num2str(ANALYSIS.stmode) '_DCG' SLIST.dcg_labels{ANALYSIS.dcg_todo(1)}...
        'toDCG' SLIST.dcg_labels{ANALYSIS.dcg_todo(2)} '.mat'];

end

save(savename,'ANALYSIS','FW_ANALYSIS','-v7.3');

fprintf('All results saved in %s. \n',savename);


%% PLOT DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

if ANALYSIS.disp.on == 1
    
    fprintf('Results will be plotted. \n');
    display_group_results_erp(ANALYSIS);
    
elseif ANALYSIS.disp.on ~= 1
    
    fprintf('No figures were produced for the results. \n');
    
end

%__________________________________________________________________________
