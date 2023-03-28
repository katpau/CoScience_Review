function [RESULTS] =  prepare_my_vectors_erp(training_set, test_set, SLIST, STUDY)
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
% This function gets input from DECODING_ERP.m and organises the data stored in 
% training_set and test_set for classification. The data is cut out and handed 
% over to do_my_classification.m as data vectors and labels. 
% The output is handed back to DECODING_ERP.
%
%
%__________________________________________________________________________
%
% Variable naming convention: STRUCTURE_NAME.example_variable

%% DEFINE NUMBER OF STEPS (default = all possible steps)
% only needs to be changed for de-bugging!

allsteps = 1; % (1=all possible steps; 0=pre-defined number of steps) 
% defined_steps=6;

% number of rounds: will be 1 if no permutation test;
nr_rounds = 1 + STUDY.perm_test;


%% ESTABLISH NUMBER OF ANALYSES / CLASSES
% number analyses depends whether analysis is performed for each channel
% separately or for spatial configuration
if STUDY.stmode ~= 2 % Spatial or spatiotemporal decoding
    no_analyses = 1;
elseif STUDY.stmode == 2 % Temporal decoding
    no_analyses = size(training_set{1,1,1,1},2);
end

nconds = STUDY.nconds;


%% LOAD IN REGRESSION LABELS (IF PERFORMING REGRESSION) % put in by Dan 14/3/2014
if STUDY.analysis_mode == 4
    training_labels = STUDY.training_labels;
    test_labels = STUDY.test_labels;
end


%% PREPARE RESULTS MATRICES AND DEFINE REPETITIONS

RESULTS.prediction_accuracy = [];
RESULTS.feature_weights = [];
RESULTS.perm_prediction_accuracy = [];

% Set up matrix with repetition information 
repetition_data_steps = repmat([1:size(test_set,3)],1,STUDY.permut_rep);

crossval_repetitions(1,1) = size(test_set,4); % repetition of cross_validation cycle for real decoding
if STUDY.avmode ~= 2 % repetition of cross_validation cycle for permutation test
    crossval_repetitions(2,1) = STUDY.permut_rep; 
elseif STUDY.avmode == 2
   crossval_repetitions(2,1) = crossval_repetitions(1,1);
end


%% PERFORM VECTOR PREPARATION AND HAND OVER TO CLASSIFICATION SCRIPT

for main_analysis = 1:nr_rounds % 1=real decoding, 2=permutation test

    trial_length = size(training_set{1,1,1,1},1); % use first one to determine trial length - all identical
        
    if allsteps == 1 % Analyse all steps
        nsteps = floor((trial_length-(STUDY.window_width-STUDY.step_width))/STUDY.step_width);   
    elseif allsteps == 0 % Analyse a predefined number of steps 
        nsteps = defined_steps;
    end
                
    for rep = 1:crossval_repetitions(main_analysis,1) % repetition of cross_validation cycle    
            
        for cv = 1:size(test_set,3) % cross-validation step
            
            %André
            if main_analysis == 1
                fprintf('CLASSIFICATION: participant %d, cross-validation step %d in cycle %d: \n',STUDY.sbj,cv,rep);
            elseif main_analysis == 2
                fprintf('PERMUTATION: participant %d, cross-validation step %d in cycle %d: \n',STUDY.sbj,cv,rep);
            end
        
            %if main_analysis == 1
                    %    fprintf('Classifying step %d of %d steps, cross-validation step %d in cycle %d: \n',s,nsteps,cv,rep);
                    %elseif main_analysis == 2
                    %    fprintf('Permutation test step %d of %d steps, cross-validation step %d in cycle %d: \n',s,nsteps,cv,rep);
                    %end
        
            for ch = 1:no_analyses % repetition for each channel (if required)
                              
                for s = 1:nsteps
                
                    vectors_train = [];
                    vectors_test = [];
                    labels_train = [];
                    labels_test = [];
               
                    for con = 1:size(test_set,2) % condition 
                    
                        % get correct data position from matrix
                        ncv = repetition_data_steps(rep);
                        
                        if STUDY.cross == 0 % regular: train on A, predict left-out from A
                        
                            % extract training and test data for current step for time window
                            data_training = double(training_set{1,con,cv,ncv}( (1 + ( (s - 1) * STUDY.step_width)):( (s * STUDY.window_width) - ( (s - 1) * (STUDY.window_width-STUDY.step_width) ) ),:,:));
                            data_test = double(test_set{1,con,cv,ncv}((1 + ( (s - 1) * STUDY.step_width) ):( (s * STUDY.window_width) - ( (s - 1) * (STUDY.window_width-STUDY.step_width) ) ),:,:));
                                                
                        elseif STUDY.cross == 1 % train on A, predict left-out from B
                            
                         % extract training and test data for current step for time window
                            data_training = double(training_set{1,con,cv,ncv}((1 + ( (s - 1) * STUDY.step_width) ):( (s * STUDY.window_width) - ( (s - 1) * (STUDY.window_width-STUDY.step_width) ) ),:,:));
                            data_test = double(test_set{2,con,cv,ncv}((1 + ( (s - 1) * STUDY.step_width) ):( (s * STUDY.window_width) - ( (s - 1) * (STUDY.window_width-STUDY.step_width) ) ),:,:));
                        
                         elseif STUDY.cross == 2 % train on B, predict left-out from A
                            
                         % extract training and test data for current step for time window
                            data_training = double(training_set{2,con,cv,ncv}((1+( (s-1)*STUDY.step_width) ):( (s * STUDY.window_width) - ( (s - 1) * (STUDY.window_width-STUDY.step_width) ) ),:,:));
                            data_test = double(test_set{1,con,cv,ncv}((1 + ( (s - 1) * STUDY.step_width) ):( (s * STUDY.window_width) - ( (s - 1) * (STUDY.window_width-STUDY.step_width) ) ),:,:));
                            
                        end
                        
                        % spatial decoding: vectors consist of average data within time-window
                        % calculate number of steps with given step width and window width one data point per channel
                        if STUDY.stmode == 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
                            % Training data vectors
                            mean_data_training = mean(data_training,1);
                            mean_data_test = mean(data_test,1);
                        
                            temp(:,:) = mean_data_training(1,:,:);
                            vectors_train = [vectors_train temp];     
                            
                            if STUDY.analysis_mode == 4 % if continuous regression, get labels from external file
                                    
                                for trl = 1:size(temp,2)
                                    labels_train = [labels_train  training_labels{con,cv,ncv}(trl)];
                                end
                                clear temp;
                                    
                            else % if not continuous regression, label = condition
                                
                                for ntrls = 1:(size(temp,2))
                                    labels_train = [labels_train con];
                                end
                                clear temp;
                            
                            end % if analysis_mode==4
                            
                            % permutation test data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            %_________________________________________________________________________________
                            if main_analysis == 2
                                
                                % generate new labels from old labels!!!!!!
                                perm_order = randperm(size(labels_train,2));
                                for no = 1:size(labels_train,2)
                                    new_labels_train(1,no) = labels_train(1,perm_order(no));
                                end
                                clear labels_train;
                                labels_train = new_labels_train;
                                clear new_labels_train;
                                
                            end % of main_analysis == 2 statement
                            %_________________________________________________________________________________
                        
                            % Test data vectors
                            temp(:,:) = mean_data_test(1,:,:);
                            vectors_test = [vectors_test temp];      
                            
                            if STUDY.analysis_mode == 4 % if continuous regression, get labels from external file
                                    
                                for trl = 1:size(temp,2)
                                    labels_test = [labels_test  test_labels{con,cv,ncv}(trl)];
                                end
                                clear temp;
                                    
                            else % if not continuous regression, label = condition   
                                    
                                for ntrls = 1:(size(temp,2))
                                    labels_test = [labels_test con];
                                end  
                                clear temp;      
                                
                            end % if analysis_mode==4
                        
                        % temporal decoding: vectors consist of single data-points within time
                        % window, one analysis per channel
                        elseif STUDY.stmode == 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                            % Training data vectors
                            for exmpl = 1:size(data_training,3)     
                                temp = data_training(:,ch,exmpl);
                                vectors_train = [vectors_train temp];
                                
                                if STUDY.analysis_mode == 4 % if continuous regression, get labels from external file
                                        
                                    labels_train = [labels_train training_labels{con,cv,ncv}(exmpl)];
                                    clear temp;
                                        
                                else % if not continuous regression, label = condition
                                
                                    labels_train = [labels_train con];
                                    clear temp;
                                    
                                end % if analysis_mode==4
                            
                            end % exmpl
                            
                            % permutation test data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            %_________________________________________________________________________________
                            if main_analysis == 2
                                
                                % generate new labels from old labels!!!!!!
                                perm_order = randperm(size(labels_train,2));
                                for no = 1:size(labels_train,2)
                                    new_labels_train(1,no) = labels_train(1,perm_order(no));
                                end
                                clear labels_train;
                                labels_train = new_labels_train;
                                clear new_labels_train;
                                
                            end % main_analysis == 2
                            %_________________________________________________________________________________
       
                            % Test data vectors
                            for exmpl = 1:size(data_test,3)
                                temp = data_test(:,ch,exmpl);
                                vectors_test = [vectors_test temp];
                                
                                if STUDY.analysis_mode == 4 % if continuous regression, get labels from external file
                                        
                                    for ntrls = 1:size(temp,2)
                                        labels_test = [labels_test  test_labels{con,cv,ncv}(exmpl)];
                                    end
                                    clear temp;

                                else % if not continuous regression, label = condition
                                        
                                    labels_test = [labels_test con];
                                    clear temp;
                                
                                end % analysis_mode == 4
                                
                            end % exmpl 
    
                        % spatio-temporal decoding: vectors consist of all data points within time
                        % window across channels
                        elseif STUDY.stmode == 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
            
                            % channels used within each step / only one analysis!
                            
                            % Training data vectors
                            for exmpl = 1:size(data_training,3) 
                                temp = [];
                                for chann = 1:size(data_training,2)  
                                    scrap = data_training(:,chann,exmpl);
                                    temp = cat(1,temp,scrap);
                                    clear scrap;                                    
                                end
                                vectors_train = [vectors_train temp];
                                clear temp;
                                
                                if STUDY.analysis_mode == 4 % if continuous regression, get labels from external trial
                                        
                                    labels_train = [labels_train training_labels{con,cv,ncv}(exmpl)];
                                        
                                else % if not continuous regression, label = condition
                                        
                                    labels_train = [labels_train con];
                                
                                end % if analysis_mode==4
                                
                            end % for exmpl
                            
                            % permutation test data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            %_________________________________________________________________________________
                            if main_analysis == 2
                                
                                % generate new labels from old labels!!!!!!
                                perm_order = randperm(size(labels_train,2));
                                for no = 1:size(labels_train,2)
                                    new_labels_train(1,no) = labels_train(1,perm_order(no));
                                end
                                clear labels_train;
                                labels_train = new_labels_train;
                                clear new_labels_train;
                                
                            end % main_analysis == 2 
                            %_________________________________________________________________________________
       
                            % Test data vectors
                            for exmpl = 1:size(data_test,3)
                                temp = [];
                                for chann = 1:size(data_test,2)
                                    scrap = data_test(:,chann,exmpl);
                                    temp = cat(1,temp,scrap);
                                    clear scrap
                                end
                                vectors_test = [vectors_test temp];
                                clear temp;
                                
                                if STUDY.analysis_mode == 4 % if continuous regression, get labels from external trial
                                        
                                    labels_test = [labels_test test_labels{con,cv,ncv}(exmpl)];
                                        
                                else % if not continuous regression, label = condition
                                        
                                    labels_test = [labels_test con];
                                
                                end % if analysis_mode == 4
                                
                            end % exmpl 
                                                            
                        end % if stmode
  
                    end % condition
                
                    
                    
                    %_________________________________________________________________________________
                    % Z-score the training and test sets (optional)
                                        
                    if STUDY.zscore_convert == 1
                        switch STUDY.stmode
                            case 1 % spatial decoding
                                % Organisation of vectors:
                                % vectors_train(channel, epoch)
                                % vectors_test(channel, epoch)
                                
                                vectors_train = zscore(vectors_train);
                                vectors_test = zscore(vectors_test);
                               
                            case 2 % temporal decoding
                                % Organisation of vectors:
                                % vectors_train(timepoint, epoch)
                                % vectors_test(timepoint, epoch)
                                
                                vectors_train = zscore(vectors_train);
                                vectors_test = zscore(vectors_test);
                            
                            case 3 % spatio-temporal decoding
                                % Organisation of vectors:
                                % vectors_train(channel/timept combination, epoch)
                                % vectors_test(channel/timept combination, epoch)
                                
                                % Training Vectors
                                tmp = zscore( reshape(vectors_train, ...
                                    size(data_training, 1), size(data_training, 2), size(vectors_train, 2)) );
                                vectors_train = reshape(tmp, size(data_training, 1) * size(data_training,2), size(vectors_train, 2));

                                % Test Vectors
                                tmp = zscore( reshape(vectors_test, ...
                                    size(data_test, 1), size(data_test, 2), size(vectors_test, 2)) );
                                vectors_test = reshape(tmp, size(data_test, 1) * size(data_test,2), size(vectors_test, 2));

                        end % of if STUDY.stmode
                    end % of if STUDY.zscore_convert

                    
                    % PASS ON TO CLASSIFIER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %
                    % Data is sorted into vectors_test, vectors_train, labels_test, labels_train. Based on analysis_mode,
                    % the appropriate classifier is chosen for the pattern analysis
                    % 
                    % each analysis-step will fill the results matrices: 
                    % *** prediction_accuracy{analysis}(time-step,crossvalidation-step,repetition-step)
                    % *** perm_prediction_accuracy{analysis}(time-step,crossvalidation-step,repetition-step)
                    % *** feature_weights{analysis}(time-step,crossvalidation-step,repetition-step)
                    %______________________________________________________
                    
                    vectors_train = vectors_train';
                    vectors_test = vectors_test';
                    labels_train = labels_train';
                    labels_test = labels_test';
                    
                    % The following 5 lines were commented by André on
                    % July 31st, 2018 in order to increase performance by
                    % suppressing unnecessary output.
                    %if main_analysis == 1
                    %    fprintf('Classifying step %d of %d steps, cross-validation step %d in cycle %d: \n',s,nsteps,cv,rep);
                    %elseif main_analysis == 2
                    %    fprintf('Permutation test step %d of %d steps, cross-validation step %d in cycle %d: \n',s,nsteps,cv,rep);
                    %end
                    [acc,feat_weights] = do_my_classification(vectors_train,labels_train,vectors_test,labels_test,STUDY);
                
                    if main_analysis == 1
                        RESULTS.prediction_accuracy{ch}(s,cv,rep) = acc;
                        RESULTS.feature_weights{ch}{s,cv,rep} = feat_weights;
                    elseif main_analysis == 2
                        RESULTS.perm_prediction_accuracy{ch}(s,cv,repetition_data_steps(rep)) = acc;           
                    end
                        
                    clear acc;
                    clear feat_weights;
                    
                end % steps
                    
            end % number analyses (na / channels)
                
        end % cross-val step
            
    end % repetition of cross_validation rounds
    fprintf('Finished classification. \n');
    
    % optional: only when debugging script
    % save('crash_data.mat');    
    
end % (real decoding vs permutation test data)   

%% SAVE
%
% optional: only when debugging script - the decoding script will save
% all data in correct folder
%
% save('CHRASH_SAVE.mat','STUDY','RESULTS')