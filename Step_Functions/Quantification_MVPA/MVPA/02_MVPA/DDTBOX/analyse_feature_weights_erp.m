function [FW_ANALYSIS]=analyse_feature_weights_erp(ANALYSIS)
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
% This script will analyse and plot the feature weights from the group
% analysis

%__________________________________________________________________________
%
% Variable naming convention: STRUCTURE_NAME.example_variable

%% GENERAL PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

% Prompt user to input time-steps used in feature weights analysis
fprintf('\n');
FW_ANALYSIS.fw_analyse = input('Enter the time-steps for statistical testing of feature weights (e.g. [4 6 7 10]): ');
FW_ANALYSIS.fw_disp = input('Enter the consecutive time steps for which a feature weight matrix should be displayed (e.g. [4:12]): ');


%% load in channel information %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

channel_file = [ANALYSIS.channellocs ANALYSIS.channel_names_file];
load(channel_file);


%% GET INDIVIDUAL DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

for sbj = 1:ANALYSIS.nsbj
           
    %% collect data from all participants
    % results are stored in:
    % RESULTS.feature_weights{analysis}{time_step,cross_val_step,repetition_step}=(data_point,feature_weight,absolute_feature_weight)
    %
    % Feature weights are then averaged. Attention - averaged absolute
    % feature weights are not just | average feature weights | (!!!)
    
    if ANALYSIS.stmode ~= 2 % Spatial/Spatio-temporal decoding
        
        for steps = 1:size(ANALYSIS.RES.feature_weights{sbj},1)
            
            % Preallocate summed feature weights matrices
            sz = size(ANALYSIS.RES.feature_weights{sbj}{steps,1,1},1);
            sum_step_fw(sz,1) = zeros;
            sum_step_abs(sz,1) = zeros;
            
            for cross_val = 1:size(ANALYSIS.RES.feature_weights{sbj},2)
                
                for rep = 1:size(ANALYSIS.RES.feature_weights{sbj},3)
                    
                    temp_step_fw = ANALYSIS.RES.feature_weights{1,sbj}{steps,cross_val,rep}(:,2);
                    temp_step_abs = ANALYSIS.RES.feature_weights{1,sbj}{steps,cross_val,rep}(:,3);
                    
                    FW_ANALYSIS.ALL_FW{sbj,steps,cross_val,rep} = temp_step_fw; % feature weights
                    FW_ANALYSIS.ALL_FW{sbj,steps,cross_val,rep}(:,2) = temp_step_abs; % absolute feature weights
                    
                    sum_step_fw = sum_step_fw + temp_step_fw; clear temp_step_fw;
                    sum_step_abs = sum_step_abs + temp_step_abs; clear temp_step_abs;
                    
                end % rep
            
            end % cross_val
            
            % Average feature weights
            FW_ANALYSIS.ALL_FW_STEP{sbj,steps}(:,1) = (sum_step_fw ./ (size(ANALYSIS.RES.feature_weights{sbj},2) + size(ANALYSIS.RES.feature_weights{sbj},3) ) );
            FW_ANALYSIS.ALL_FW_STEP{sbj,steps}(:,2) = (sum_step_abs ./ (size(ANALYSIS.RES.feature_weights{sbj},2) + size(ANALYSIS.RES.feature_weights{sbj},3) ) );
            
            clear sum_step_abs; clear sum_step_fw;
            
        end % step
        
    elseif ANALYSIS.stmode == 2 % Temporal decoding
        
        fprintf('error - temporal decoding uses data WITHIN time analysis window as features, not channels. \n')
        
    end % if
    
    %% average FWs across time WITHIN a time step (for temporal/spatio-temporal decoding)
    
    % not required for spatial decoding, because that is based on average
    % of time step
    if ANALYSIS.stmode == 3 % Spatio-temporal decoding
             
       for steps = 1:size(FW_ANALYSIS.ALL_FW_STEP,2)
                    
            start_point = 1;
            for withinstep = 1:ANALYSIS.nchannels
                    
                temp_fw = FW_ANALYSIS.ALL_FW_STEP{sbj,steps}( start_point : (start_point + ANALYSIS.window_width - 1) ,1);
                temp_abs = FW_ANALYSIS.ALL_FW_STEP{sbj,steps}( start_point : (start_point + ANALYSIS.window_width - 1) ,2);
                       
                m_temp_fw = mean(temp_fw);
                m_temp_abs = mean(temp_abs);
                       
                FW_ANALYSIS.ALL_FW_STEP_CHANNEL{sbj,steps}(withinstep,1) = m_temp_fw;
                FW_ANALYSIS.ALL_FW_STEP_CHANNEL{sbj,steps}(withinstep,2) = m_temp_abs;
                       
                start_point = start_point + ANALYSIS.window_width;
                        
                clear temp_fw; clear temp_abs;
                clear m_temp_fw; clear m_temp_abs;
                                                
            end % withinstep
                    
        end % step
                
        fprintf('Averaging across time-steps WITHIN analysis time window performed for subject %d. \n',sbj)
        
    else
        
        FW_ANALYSIS.ALL_FW_STEP_CHANNEL = FW_ANALYSIS.ALL_FW_STEP;
        fprintf('Averaging across time-steps WITHIN analysis time window was not required. \n')
        
    end % if
    
end % subject

%% TRANSFORM ABSOLUTE FEATURE WEIGHTS FOR EACH CHANNEL INTO Z_SCORES %%%%%%
%__________________________________________________________________________
%
% this is done separately for each analysis (as comparing feature weights
% between analyses is not meaningful, because they are relative to others for the same analysis)

for sbj = 1:size(FW_ANALYSIS.ALL_FW_STEP_CHANNEL,1)

    for steps = 1:size(FW_ANALYSIS.ALL_FW_STEP_CHANNEL,2)
           
        temp(:,1) = FW_ANALYSIS.ALL_FW_STEP_CHANNEL{sbj,steps}(:,2);
        fw_all_abs(sbj,steps,:) = temp;
        
        % convert to z-score_______________________________________________
        temp_z = zscore(temp);
        fw_all_z(sbj,steps,:) = temp_z;
        % third column contains z-scores of absolute feature weights
        FW_ANALYSIS.ALL_FW_STEP_CHANNEL{sbj,steps}(:,3) = temp_z;
        
        clear temp; clear temp_z;
                
    end % step
   
end % sbj

FW_ANALYSIS.ALL_Z = fw_all_z; clear fw_all_z;
FW_ANALYSIS.ALL_ABS = fw_all_abs; clear fw_all_abs;

fprintf('Absolute feature weights (per channel) transformed into z-values. \n')

%% AVERAGE Z-SCORES ACROSS PARTICIPANTS FOR EACH STEP
%__________________________________________________________________________
%
% generates FW_ANALYSIS.AVERAGE_Z(step,channel)

mean_fw_all_z(:,:) = mean(FW_ANALYSIS.ALL_Z,1);
FW_ANALYSIS.AVERAGE_Z = mean_fw_all_z;

fprintf('Z-transformed absolute feature weights averaged across participants. \n')

% analysis time windows for matrix display
FW_ANALYSIS.AVERAGE_Z_DISP = FW_ANALYSIS.AVERAGE_Z(FW_ANALYSIS.fw_disp(1):FW_ANALYSIS.fw_disp(end),:);

fprintf('Z-transformed absolute feature weights selected from specified analysis time-steps for display. \n')

% analysis time windows for heat map displays
for stat_step = 1:size(FW_ANALYSIS.fw_analyse,2)
    FW_ANALYSIS.AVERAGE_Z_HEATS(stat_step,:) = FW_ANALYSIS.AVERAGE_Z(FW_ANALYSIS.fw_disp(stat_step),:);
end

fprintf('Z-transformed absolute averaged feature weights selected from specified analysis time-steps for statstical tests. \n')

%% AVERAGE RELEVANT TIME STEPS FOR STATS/DISPLAY
%__________________________________________________________________________

sum_fw = [];
for steps = 1:size(FW_ANALYSIS.fw_analyse,2)
    % Extract absolute and Z-scored feature weights at each analysis step
    temp_fw_select(:,:) = FW_ANALYSIS.ALL_ABS(:,FW_ANALYSIS.fw_analyse(steps),:);
    temp_fw_select_z(:,:) = FW_ANALYSIS.ALL_Z(:,FW_ANALYSIS.fw_analyse(steps),:);
    
    % Preallocate the feature weight sum matrices for the first step
    if steps == 1
        sz = size(temp_fw_select);
        sum_fw(sz(1),sz(2)) = zeros;
        sum_fw_z(sz(1),sz(2)) = zeros;
    end
    sum_fw = sum_fw + temp_fw_select;
    sum_fw_z = sum_fw_z + temp_fw_select_z;
    
    clear temp_fw_pre;
    clear temp_fw_pre_z;
    
end
% Average absolute and Z-scored feature weights
FW_ANALYSIS.AVERAGESTEPS_SELECT_FW_ABS = sum_fw ./ size(FW_ANALYSIS.fw_analyse,2);
FW_ANALYSIS.AVERAGESTEPS_SELECT_FW_Z = sum_fw_z ./ size(FW_ANALYSIS.fw_analyse,2);

FW_ANALYSIS.AVERAGESTEPS_SELECT_FW_ABS_MEAN = mean(FW_ANALYSIS.AVERAGESTEPS_SELECT_FW_ABS,1);
FW_ANALYSIS.AVERAGESTEPS_SELECT_FW_Z_MEAN = mean(FW_ANALYSIS.AVERAGESTEPS_SELECT_FW_Z,1);

fprintf('Z-transformed absolute feature weights from specified analysis time-steps averaged across time-steps. \n')

%% T-TESTS FOR FW - AVERAGED RELEVANT TIME BINS & SINGLE RELEVANT TIME BINS
%__________________________________________________________________________
%
% Output is one matrix for each analysis, once with correction for multiple
% comparisons (=features/channels) and once without (p < critical value)

% T-test for all single analysis time steps________________________________
for p_corr = 1:2 % run for corrected/uncorrected
    
    if p_corr == 1 % Uncorrected for multiple comparisons
        p_crit = ANALYSIS.pstats; % Uncorrected alpha level

        for steps = 1:size(FW_ANALYSIS.fw_analyse,2)
            
            for channel = 1:size(FW_ANALYSIS.ALL_Z,3)
                
                temp_z = FW_ANALYSIS.ALL_Z(:,FW_ANALYSIS.fw_analyse(steps),channel);

                % Run a one-sample t-test on Z-scored feature weights
                [h,p] = ttest(temp_z,0,p_crit,'right'); % DF NOTE: One-tailed test, denoted by 'right' argument.
                h_matrix_z(channel,1) = h; % Stores significant/non-significant decisions
                p_matrix_z(channel,1) = p; % Stores p-values

                clear temp_z; clear h; clear p;

            end % channel loop

            % Copy t-test results into FW_ANALYSIS structure
            FW_ANALYSIS.p_matrix_z_uncorr{steps} = p_matrix_z; 
            FW_ANALYSIS.p_matrix_z_uncorr_label = FW_ANALYSIS.fw_analyse;
            FW_ANALYSIS.h_matrix_z_uncorr{steps} = h_matrix_z;
            clear p_matrix_z; clear h_matrix_z;
        
        end % steps loop

        elseif p_corr == 2 % Corrected for multiple comparisons
            
            switch ANALYSIS.fw.multcompstats % Selects a multiple comparisons correction             
                case 1 % Bonferroni correction
                    FW_ANALYSIS.p_matrix_z_corr_label = FW_ANALYSIS.p_matrix_z_uncorr_label; % Copy same labels as uncorrected
                    for steps = 1:size(FW_ANALYSIS.fw_analyse,2)
                        FW_ANALYSIS.p_matrix_z_corr{steps} = FW_ANALYSIS.p_matrix_z_uncorr{steps}; % Copy same p-values as uncorrected
                        FW_ANALYSIS.h_matrix_z_corr{steps} = multcomp_bonferroni(FW_ANALYSIS.p_matrix_z_uncorr{steps}, 'alpha', ANALYSIS.pstats);
                    end % steps loop
            
                case 2 % Holm-Bonferroni correction
                    FW_ANALYSIS.p_matrix_z_corr_label = FW_ANALYSIS.p_matrix_z_uncorr_label; % Copy same labels as uncorrected
                    for steps = 1:size(FW_ANALYSIS.fw_analyse,2)
                        FW_ANALYSIS.p_matrix_z_corr{steps} = FW_ANALYSIS.p_matrix_z_uncorr{steps}; % Copy same p-values as uncorrected
                        FW_ANALYSIS.h_matrix_z_corr{steps} = multcomp_holm_bonferroni(FW_ANALYSIS.p_matrix_z_uncorr{steps}, 'alpha', ANALYSIS.pstats);
                    end % steps loop
                    
                case 3 % strong FWER control permutation test
                    FW_ANALYSIS.p_matrix_z_corr_label = FW_ANALYSIS.p_matrix_z_uncorr_label; % Copy same labels as uncorrected
                    for steps = 1:size(FW_ANALYSIS.fw_analyse,2)
                        real_decoding_fw = FW_ANALYSIS.ALL_Z(:,FW_ANALYSIS.fw_analyse(steps),:); % Results matrix (subjects x channels)
                        fw_chance_level = zeros(size(real_decoding_fw, 1), size(real_decoding_fw, 2)); % Matrix of chance level values (zeros)
                        [FW_ANALYSIS.h_matrix_z_corr{steps}, FW_ANALYSIS.p_matrix_z_corr{steps}] = multcomp_blaire_karniski_permtest(real_decoding_fw, fw_chance_level, 'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations);
                    end % steps loop
                    clear real_decoding_fw;
                    clear fw_chance_level;
                    
                case 4 % cluster-based permutation test (To be implemented in future, once we can easily set up neighborhood matrices)
                    % Stopgap until cluster-based permutation testing is
                    % implemented (needs neighborhood matrix from electrode
                    % posititons).
                    fprintf('Cluster-based correction not currently available... No correction was performed');
                    FW_ANALYSIS.p_matrix_z_corr_label = FW_ANALYSIS.p_matrix_z_uncorr_label;
                    for steps = 1:size(FW_ANALYSIS.fw_analyse,2)
                        FW_ANALYSIS.p_matrix_z_corr{steps} = FW_ANALYSIS.p_matrix_z_uncorr{steps}; 
                        FW_ANALYSIS.h_matrix_z_corr{steps} = FW_ANALYSIS.h_matrix_z_uncorr{steps};
                    end % steps
                    
                    % NOTE: We will need to make a version that has an
                    % electrode neighborhood matrix for this version of the
                    % cluster-based permutation test.
                    
                case 5 % Generalised FWER control procedure
                    
                    FW_ANALYSIS.p_matrix_z_corr_label = FW_ANALYSIS.p_matrix_z_uncorr_label; % Copy same labels as uncorrected
                    for steps = 1:size(FW_ANALYSIS.fw_analyse,2)
                        real_decoding_fw = FW_ANALYSIS.ALL_Z(:,FW_ANALYSIS.fw_analyse(steps),:); % Results matrix (subjects x channels)
                        fw_chance_level = zeros(size(real_decoding_fw, 1), size(real_decoding_fw, 2)); % Matrix of chance level values (zeros)
                        [FW_ANALYSIS.h_matrix_z_corr{steps}, FW_ANALYSIS.p_matrix_z_corr{steps}] = multcomp_ktms(real_decoding_fw, fw_chance_level, 'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations, 'ktms_u', ANALYSIS.ktms_u);
                    end % steps loop
                    clear real_decoding_fw;
                    clear fw_chance_level;
                    
                case 6 % Benjamini-Hochberg false discovery rate control
                    FW_ANALYSIS.p_matrix_z_corr_label = FW_ANALYSIS.p_matrix_z_uncorr_label; % Copy same labels as uncorrected
                    for steps = 1:size(FW_ANALYSIS.fw_analyse,2)
                        FW_ANALYSIS.p_matrix_z_corr{steps} = FW_ANALYSIS.p_matrix_z_uncorr{steps}; % Copy same p-values as uncorrected
                        FW_ANALYSIS.h_matrix_z_corr{steps} = multcomp_fdr_bh(FW_ANALYSIS.p_matrix_z_uncorr{steps}, 'alpha', ANALYSIS.pstats); 
                    end % steps loop
                    
                case 7 % Benjamini-Krieger-Yekutieli false discovery rate control
                    FW_ANALYSIS.p_matrix_z_corr_label = FW_ANALYSIS.p_matrix_z_uncorr_label; % Copy same labels as uncorrected
                    for steps = 1:size(FW_ANALYSIS.fw_analyse,2)
                        FW_ANALYSIS.p_matrix_z_corr{steps} = FW_ANALYSIS.p_matrix_z_uncorr{steps}; % Copy same p-values as uncorrected
                        FW_ANALYSIS.h_matrix_z_corr{steps} = multcomp_fdr_bky(FW_ANALYSIS.p_matrix_z_uncorr{steps}, 'alpha', ANALYSIS.pstats);
                    end % steps loop
                      
                case 8 % Benjamini-Yekutieli false discovery rate control
                    FW_ANALYSIS.p_matrix_z_corr_label = FW_ANALYSIS.p_matrix_z_uncorr_label; % Copy same labels as uncorrected
                    for steps = 1:size(FW_ANALYSIS.fw_analyse,2)
                        FW_ANALYSIS.p_matrix_z_corr{steps} = FW_ANALYSIS.p_matrix_z_uncorr{steps}; % Copy same p-values as uncorrected
                        FW_ANALYSIS.h_matrix_z_corr{steps} = multcomp_fdr_by(FW_ANALYSIS.p_matrix_z_uncorr{steps}, 'alpha', ANALYSIS.pstats);
                    end % steps loop

            end % ANALYSIS.fw.multcompstats switch
    end % if p_corr ==1 statement
    
end % p_corr loop

fprintf('T-Tests (corrected and uncorrected for multiple comparisons) performed on averaged (across selected time-steps) results. \n')

%% T-test for averaged analysis time window_________________________________
for p_corr = 1:2 % run for corrected/uncorrected
    
    if p_corr == 1
        p_crit = ANALYSIS.pstats; % Uncorrected alpha level

        for channel = 1:size(FW_ANALYSIS.ALL_Z,3)

            temp = FW_ANALYSIS.AVERAGESTEPS_SELECT_FW_Z(:,channel);

            [h,p] = ttest(temp,0,p_crit,'right'); % DF NOTE: One-tailed test, denoted by 'right' argument
            h_matrix_z(channel,1) = h; % Stores significant/non-significant decisions
            p_matrix_z(channel,1) = p; % Stores p-values

        end  % channel loop

        % Copy t-test results into FW_ANALYSIS structure
        FW_ANALYSIS.p_matrix_z_averagestep_uncorr = p_matrix_z; 
        FW_ANALYSIS.p_matrix_z_averagestep_uncorr_label = FW_ANALYSIS.fw_analyse;
        FW_ANALYSIS.h_matrix_z_averagestep_uncorr = h_matrix_z;
        clear p_matrix_z; clear h_matrix_z;
        
    elseif p_corr == 2
        
        
        
        switch ANALYSIS.fw.multcompstats % Selects a multiple comparisons correction           
                case 1 % Bonferroni correction          
                    FW_ANALYSIS.p_matrix_z_averagestep_corr = FW_ANALYSIS.p_matrix_z_averagestep_uncorr; % Copy from uncorrected ver.
                    FW_ANALYSIS.p_matrix_z_averagestep_corr_label = FW_ANALYSIS.p_matrix_z_averagestep_uncorr_label; % Copy from uncorrected ver.
                    FW_ANALYSIS.h_matrix_z_averagestep_corr = multcomp_bonferroni(FW_ANALYSIS.p_matrix_z_averagestep_uncorr, 'alpha', ANALYSIS.pstats); 
 
                case 2 % Holm-Bonferroni correction
                    FW_ANALYSIS.p_matrix_z_averagestep_corr = FW_ANALYSIS.p_matrix_z_averagestep_uncorr; % Copy from uncorrected ver.
                    FW_ANALYSIS.p_matrix_z_averagestep_corr_label = FW_ANALYSIS.p_matrix_z_averagestep_uncorr_label; % Copy from uncorrected ver.
                    FW_ANALYSIS.h_matrix_z_averagestep_corr = multcomp_holm_bonferroni(FW_ANALYSIS.p_matrix_z_averagestep_uncorr, 'alpha', ANALYSIS.pstats); 
                    
                case 3 % strong FWER control permutation test
                    FW_ANALYSIS.p_matrix_z_averagestep_corr = FW_ANALYSIS.p_matrix_z_averagestep_uncorr; % Copy from uncorrected ver.
                    FW_ANALYSIS.p_matrix_z_averagestep_corr_label = FW_ANALYSIS.p_matrix_z_averagestep_uncorr_label;
                    real_decoding_fw = FW_ANALYSIS.AVERAGESTEPS_SELECT_FW_Z(:,:); % Results matrix (subjects x channels)
                    fw_chance_level = zeros(size(real_decoding_fw, 1), size(real_decoding_fw, 2)); % Matrix of chance level values (zeros)
                    [FW_ANALYSIS.h_matrix_z_averagestep_corr, FW_ANALYSIS.p_matrix_z_averagestep_corr_label] = multcomp_blaire_karniski_permtest(real_decoding_fw, fw_chance_level, 'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations);
                    clear real_decoding_fw;
                    clear fw_chance_level;
                    
                case 4 % cluster-based permutation test
                    fprintf('Cluster-based correction not currently available... No correction was performed');
                    FW_ANALYSIS.p_matrix_z_averagestep_corr = FW_ANALYSIS.p_matrix_z_averagestep_uncorr; % Copy from uncorrected ver.
                    FW_ANALYSIS.p_matrix_z_averagestep_corr_label = FW_ANALYSIS.p_matrix_z_averagestep_uncorr_label; % Copy from uncorrected ver.
                    FW_ANALYSIS.h_matrix_z_averagestep_corr = FW_ANALYSIS.h_matrix_z_averagestep_uncorr;
                    
                case 5 % Generalised FWER control procedure
                    FW_ANALYSIS.p_matrix_z_averagestep_corr = FW_ANALYSIS.p_matrix_z_averagestep_uncorr; % Copy from uncorrected ver.
                    FW_ANALYSIS.p_matrix_z_averagestep_corr_label = FW_ANALYSIS.p_matrix_z_averagestep_uncorr_label;
                    real_decoding_fw = FW_ANALYSIS.AVERAGESTEPS_SELECT_FW_Z(:,:); % Results matrix (subjects x channels)
                    fw_chance_level = zeros(size(real_decoding_fw, 1), size(real_decoding_fw, 2)); % Matrix of chance level values (zeros)
                    [FW_ANALYSIS.h_matrix_z_averagestep_corr] = multcomp_ktms(real_decoding_fw, fw_chance_level, 'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations, 'ktms_u', ANALYSIS.ktms_u);
                    clear real_decoding_fw;
                    clear fw_chance_level;

                case 6 % Benjamini-Hochberg false discovery rate control
                    FW_ANALYSIS.p_matrix_z_averagestep_corr = FW_ANALYSIS.p_matrix_z_averagestep_uncorr; 
                    FW_ANALYSIS.p_matrix_z_averagestep_corr_label = FW_ANALYSIS.p_matrix_z_averagestep_uncorr_label;
                    FW_ANALYSIS.h_matrix_z_averagestep_corr = multcomp_fdr_bh(FW_ANALYSIS.p_matrix_z_averagestep_uncorr, 'alpha', ANALYSIS.pstats);

                case 7 % Benjamini-Krieger-Yekutieli false discovery rate control
                    FW_ANALYSIS.p_matrix_z_averagestep_corr = FW_ANALYSIS.p_matrix_z_averagestep_uncorr; 
                    FW_ANALYSIS.p_matrix_z_averagestep_corr_label = FW_ANALYSIS.p_matrix_z_averagestep_uncorr_label;
                    FW_ANALYSIS.h_matrix_z_averagestep_corr = multcomp_fdr_bky(FW_ANALYSIS.p_matrix_z_averagestep_uncorr, 'alpha', ANALYSIS.pstats);
                      
                case 8 % Benjamini-Yekutieli false discovery rate control
                    FW_ANALYSIS.p_matrix_z_averagestep_corr = FW_ANALYSIS.p_matrix_z_averagestep_uncorr; 
                    FW_ANALYSIS.p_matrix_z_averagestep_corr_label = FW_ANALYSIS.p_matrix_z_averagestep_uncorr_label;
                    FW_ANALYSIS.h_matrix_z_averagestep_corr = multcomp_fdr_by(FW_ANALYSIS.p_matrix_z_averagestep_uncorr, 'alpha', ANALYSIS.pstats);

        end % of switch ANALYSIS.fw.multcompstats
    end % if p_corr ==1 statement
    
end % p_corr loop

fprintf('T-Tests (corrected and uncorrected for multiple comparisons) performed on results from single selected time-steps. \n')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DISPLAY - MATRIX OF ALL STEPS: Z-STANDARDISED ABSOLUTE FEAUTRE WEIGHTS (FOR DISPLAY)
%__________________________________________________________________________
%
% This matrix is plotted from
% FW_ANALYSIS.AVERAGE_Z_DISP{analysis-time-steps,channel}. Note that this
% can be different from the statistically tested analysis time-windows 

if ANALYSIS.fw.display_matrix == 1

    %create labels
    channel_labels = [];
    for channel = 1:size(chanlocs,2)
   
        channel_labels{channel} = chanlocs(1,channel).labels;
    
    end
    
    % channels plotted as rows, time-windows as colums
    resorted_data = [];
    resorted_data(:,:) = FW_ANALYSIS.AVERAGE_Z_DISP(:,:);
    resorted_data = resorted_data';

    % create figure
    figure;
    imagesc(resorted_data(:,:));
    hold on;
    
    set(gca,'Ytick',[1:size(FW_ANALYSIS.AVERAGE_Z_DISP,2)]);
    set(gca,'YTickLabel',(channel_labels));
    ylabel('Channel','FontSize',12,'FontWeight','b');
    
    set(gca,'Xtick',[1:size(FW_ANALYSIS.AVERAGE_Z_DISP,1)]);
    set(gca,'XTickLabel',(FW_ANALYSIS.fw_disp));
    xlabel('Analysis time-step','FontSize',12,'FontWeight','b');
    
    title('Z-standardised absolute feature weights','FontSize',14,'FontWeight','b');

end % ANALYSIS.fw.display_matrix


%% DISPLAY - AVERAGE HEAT MAP FOR RELEVANT STEPS: Z-STANDARDISED ABSOLUTE FEAUTRE WEIGHTS (FOR STATS)
%__________________________________________________________________________

if ANALYSIS.fw.display_average_zmap == 1
     
    to_plot = FW_ANALYSIS.AVERAGESTEPS_SELECT_FW_Z_MEAN';
    
    figure;
    topoplot_decoding(to_plot,...
        chanlocs,'style','both','electrodes','labelpoint','maplimits','minmax','chaninfo',chaninfo); % or: [MIN MAX]
    
    hold on;
    title('Z-standardised absolute feature weights averaged across time-steps','FontSize',10,'FontWeight','b');
    
    clear to_plot;
    
end


%% DISPLAY - AVERAGE HEAT MAP FOR RELEVANT STEPS: THRESHOLD MAP FOR P UNCORRECTED (FOR STATS)
%__________________________________________________________________________

if ANALYSIS.fw.display_average_uncorr_threshmap == 1
    
    to_plot = FW_ANALYSIS.h_matrix_z_averagestep_uncorr;
    
    figure;
    topoplot_decoding(to_plot,...
        chanlocs,'style','fill','electrodes','labelpoint','numcontour',1,'conv','off','maplimits',[0 1],'ccolor',[0 0 0],'ecolor',[1 1 1],'chaninfo',chaninfo);
    
    hold on;
    title('Feature weights uncorrected threshold-map (averaged across time-steps)','FontSize',10,'FontWeight','b');
    
    clear to_plot;
    
end


%% DISPLAY - AVERAGE HEAT MAP FOR RELEVANT STEPS: THRESHOLD MAP FOR P CORRECTED (FOR STATS)
%__________________________________________________________________________

if ANALYSIS.fw.display_average_corr_threshmap == 1
    
    to_plot = FW_ANALYSIS.h_matrix_z_averagestep_corr;
    
    figure;
    topoplot_decoding(to_plot,...
        chanlocs,'style','fill','electrodes','labelpoint','numcontour',1,'conv','off','maplimits',[0 1],'ccolor',[0 0 0],'ecolor',[1 1 1],'chaninfo',chaninfo);
    
    hold on;
    title('Feature weights corrected threshold-map (averaged across time-steps)','FontSize',10,'FontWeight','b');
    
    clear to_plot;
    
end


%% DISPLAY - HEAT MAP FOR EACH RELEVANT STEP: Z-STANDARDISED ABSOLUTE FEATURE WEIGHTS (FOR STATS)
%__________________________________________________________________________

if ANALYSIS.fw.display_all_zmaps == 1
    
    for steps = 1:size(FW_ANALYSIS.p_matrix_z_corr,2)
        
        to_plot = FW_ANALYSIS.AVERAGE_Z_HEATS(steps,:);
        to_plot = to_plot';
        
        figure;
        topoplot_decoding(to_plot,...
            chanlocs,'style','both','electrodes','labelpoint','maplimits','minmax','chaninfo',chaninfo); % or: [MIN MAX]
        
        hold on;
        title(['Z-standardised absolute feature weights time-step ' num2str(FW_ANALYSIS.fw_analyse(steps))],'FontSize',10,'FontWeight','b');
    
        clear to_plot;
        
    end % step
    
end


%% DISPLAY - HEAT MAP FOR EACH RELEVANT STEP: THRESHOLD MAPS FOR P UNCORRECTED (FOR STATS)
%__________________________________________________________________________

if ANALYSIS.fw.display_all_uncorr_thresh_maps == 1
    
    for steps = 1:size(FW_ANALYSIS.h_matrix_z_uncorr,2)
        
        to_plot(:,:) = FW_ANALYSIS.h_matrix_z_uncorr{steps};
    
        figure;
        topoplot_decoding(to_plot,...
        chanlocs,'style','fill','electrodes','labelpoint','numcontour',1,'conv','off','maplimits',[0 1],'ccolor',[0 0 0],'ecolor',[1 1 1],'chaninfo',chaninfo);
    
        hold on;
        title(['Feature weights uncorrected threshold-map for time-step ' num2str(FW_ANALYSIS.fw_analyse(steps))],'FontSize',10,'FontWeight','b');
    
        clear to_plot;
        
    end % step
    
end


%% DISPLAY - HEAT MAP FOR EACH RELEVANT STEP: THRESHOLD MAPS FOR P CORRECTED (FOR STATS)
%__________________________________________________________________________

if ANALYSIS.fw.display_all_corr_thresh_maps == 1
    
    for steps = 1:size(FW_ANALYSIS.h_matrix_z_corr,2)
        
        to_plot(:,:) = FW_ANALYSIS.h_matrix_z_corr{steps};
    
        figure;
        topoplot_decoding(to_plot,...
        chanlocs,'style','fill','electrodes','labelpoint','numcontour',1,'conv','off','maplimits',[0 1],'ccolor',[0 0 0],'ecolor',[1 1 1],'chaninfo',chaninfo);
    
        hold on;
        title(['Feature weights corrected threshold-map for time-step ' num2str(FW_ANALYSIS.fw_analyse(steps))],'FontSize',10,'FontWeight','b');
    
        clear to_plot;
        
    end % step
    
end

%__________________________________________________________________________