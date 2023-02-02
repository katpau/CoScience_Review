function [acc,feat_weights] = do_my_classification(vectors_train,labels_train,vectors_test,labels_test,STUDY)
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
% This script interacts with LIBSVM toolbox (Chang & Lin) to do the classfication / regression
% see: https://www.csie.ntu.edu.tw/~cjlin/libsvm/
% Chang CC, Lin CJ (2011). LIBSVM : a library for support vector machines. ACM TIST, 2(3):27,
%
%
%__________________________________________________________________________
%
% Variable naming convention: STRUCTURE_NAME.example_variable

%% define samples and labels for training

Samples = vectors_train;
Labels = labels_train;

%% training 
% Comment by André (July 31st, 2018): Despite the semi-colon at the end of the
% line, the svmtrain and svmpredict functions print output to the console.
% In order to suppress it (and hopefully speed up the analysis), I used the 
% evalc function and modified the line of code accordingly. The
% original line is still there, but commented.
%__________________________________________________________________________
if sum(STUDY.analysis_mode == [1 3 4]) %  libsvm
    %model = svmtrain(Labels,Samples,STUDY.backend_flags.all_flags);
    [~, model] = evalc('svmtrain(Labels,Samples,STUDY.backend_flags.all_flags)');
elseif sum(STUDY.analysis_mode == [2]) % LDA classifcation
    % to be implemented in future version
elseif sum(STUDY.analysis_mode == [5]) %  liblinear
   model = train(Labels,sparse(Samples),STUDY.backend_flags.all_flags);
end
%__________________________________________________________________________    

%% define samples and labels for testing
Samples = vectors_test;
Labels = labels_test;

%% prediction
% Comment by André (July 31st, 2018): Despite the semi-colon at the end of the
% line, the svmtrain and svmpredict functions print output to the console.
% In order to suppress it (and hopefully speed up the analysis), I used the 
% evalc function and modified the line of code accordingly. The
% original line is still there, but commented.
%__________________________________________________________________________

if sum(STUDY.analysis_mode == [1 3 4]) % libsvm
    %[predicted_label, accuracy, decision_values] = svmpredict(Labels, Samples, model); 
    [~, predicted_label, accuracy, decision_values] = evalc('svmpredict(Labels, Samples, model)');
elseif sum(STUDY.analysis_mode == [2]) % LDA
    % to be implemented in a future version
elseif sum(STUDY.analysis_mode == [5]) % liblinear
    [predicted_label, accuracy, decision_values] = predict(Labels, sparse(Samples), model); 
end

if sum(STUDY.analysis_mode == [1]) % SVM classification with libsvm
    % calculating feature weights
    w = model.SVs' * model.sv_coef;
    b = -model.rho;

    feat_weights = zeros(size(w,1),3);
    
    if STUDY.feat_weights_mode == 1 
        feat_weights(:,1) = 1:(size(w,1));
        feat_weights(:,2) = w;
        feat_weights(:,3) = abs(w);
    end

    % extracting accuracy for 2-classes 
    if STUDY.nconds == 2

        acc = accuracy(1);

    % extracting accuracy for N-classes
    elseif STUDY.nconds > 2

        classes = 1:STUDY.nconds;
        pairs = nchoosek(classes,2);

        for cl = classes
            wt(:,cl) = (pairs(:,1) == cl) - (pairs(:,2) == cl);
        end

        votes = decision_values * wt;
        [maxvote,winvote] = max(votes');
        classcorrectnes = (classes == winvote) * 100;

        acc = mean(classcorrectnes);

    end % if nclass
    
elseif STUDY.analysis_mode == 2 % LDA classification
    
    % to be implemented in future version % DF NOTE: Scrap this section?
    
elseif STUDY.analysis_mode == 3 % SVM regression
    
    % calculating feature weights
    w = model.SVs' * model.sv_coef;
    b = -model.rho;

    feat_weights = zeros(size(w,1),3);
    
    if STUDY.feat_weights_mode == 1
        feat_weights(:,1) = 1:(size(w,1));
        feat_weights(:,2) = w;
        feat_weights(:,3) = abs(w);
    end
    
    % correlating the predicted label with the test labels
    c_sample = corrcoef(predicted_label,Labels);
    avecorrectness = c_sample(1,2);
    
    % convert into Fisher-Z
    correctness_z = 1/2 * log((1 + avecorrectness) ./ (1 - avecorrectness));
    clear avecorrectness;
    avecorrectness = mean(correctness_z);
    % avecorrectness=(exp(2*avecorrectness)-1)./(exp(2*avecorrectness)+1);
    
    % resultsvol_m_allclass{dcg}(sn,cnt)=avecorrectness;
    acc=avecorrectness;
    
elseif STUDY.analysis_mode == 4 %SVM regression (continuous)
    
    % correlating the predicted label with the test labels
    c_sample = corrcoef(predicted_label,Labels);
    avecorrectness = c_sample(1,2);
    
    % convert into Fisher-Z
    correctness_z = 1/2 * log((1 + avecorrectness) ./ (1 - avecorrectness));
    avecorrectness = mean(correctness_z);
    avecorrectness = (exp(2 * avecorrectness) - 1) ./ (exp(2 * avecorrectness) + 1);
    
    % resultsvol_m_allclass{dcg}(sn,cnt)=avecorrectness;
    acc = avecorrectness;
    
    w = model.SVs' * model.sv_coef;
    feat_weights = zeros(size(w,1),3);  
    
    if STUDY.feat_weights_mode == 1
        feat_weights(:,1) = 1:(size(w,1));
        feat_weights(:,2) = w;
        feat_weights(:,3) = abs(w);
    end
    
elseif sum(STUDY.analysis_mode == [5]) % SVM classification with liblinear
    
    % calculating feature weights
    %w = model.SVs' * model.sv_coef;
    %b = -model.rho;
    w = model.w';

    feat_weights = zeros(size(w,1),3);
    
    if STUDY.feat_weights_mode == 1 
        feat_weights(:,1) = 1:(size(w,1));
        feat_weights(:,2) = w;
        feat_weights(:,3) = abs(w);
    end

    % extracting accuracy for 2-classes 
    if STUDY.nconds == 2

        acc=accuracy(1);
    
    % extracting accuracy for N-classes
    elseif STUDY.nconds > 2

        classes = 1:STUDY.nconds;
        pairs = nchoosek(classes,2);

        for cl = classes
            wt(:,cl) = (pairs(:,1)==cl) - (pairs(:,2)==cl);
        end

        votes = decision_values*wt;
        [maxvote,winvote] = max(votes');
        classcorrectnes = (classes==winvote)*100;

        acc = mean(classcorrectnes);

    end % if nclass

    
end
%__________________________________________________________________________
