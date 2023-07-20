function coscience_config_v1
%__________________________________________________________________________
% DDTBOX script written by Stefan Bode 01/03/2013
%
% The toolbox was written with contributions from:
% Daniel Bennett, Jutta Stahl, Daniel Feuerriegel, Phillip Alday
%
% The author further acknowledges helpful conceptual input/work from: 
% Simon Lilburn, Philip L. Smith, Carsten Murawski, Carsten Bogler,
% John-Dylan Haynes
%__________________________________________________________________________
%
% This script is the configuration script for the DDTBOX. All
% study-specific information for decoding, regression and groupl-level
% analyses are specified here.
%
%__________________________________________________________________________
%
% Variable naming convention: STRUCTURE_NAME.example_variable

global SLIST;
global SBJTODO;
global CALL_MODE;
global EEG_mvpa
global eeg_sorted_cond

%% CREATE SLIST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

SLIST = []; 

    % subject parameters
    SLIST.sbj_code = EEG_mvpa.subject;    
    SLIST.data_struct_name = 'eeg_sorted_cond';
    
    % channels    
    SLIST.nchannels = 59; % Number of channels in the dataset
    SLIST.channellocs = EEG_mvpa.chanlocs; % Directory of the .mat file containing channel information
    SLIST.eyes = []; % Channel indices of ocular electrodes
    SLIST.extra = []; % Channel indices of electrodes to exclude from the classification analyses
    
    % baseline
    SLIST.pointzero = 300; % Corresponds to time zero, for example stimulus onset (in ms, from the beginning of the epoch)
     
        
%% CREATE DCGs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

    % Label each condition
    % Example: SLIST.cond_labels{condition number} = 'Name of condition';
    SLIST.cond_labels{1} = 'correct';
    SLIST.cond_labels{2} = 'error';
 
    % Discrimination groups
    
    % Enter the condition numbers of the conditions to discriminate between
    % Example: SLIST.dcg{Discrimination group number} = [condition number 1, condition number 2];
    SLIST.dcg{1} = [1 2]; %Corrects vs error 
      
    % Label each discrimination group
    % Example: SLIST.dcg_labels{Discrimination group number} = 'Name of discrimination group'
    SLIST.dcg_labels{1} = 'correct vs error';
       
    %SLIST.ndcg = size(SLIST.dcg,2);
    SLIST.nclasses = size(SLIST.dcg{1},2);      
 
    SLIST.ncond = size(SLIST.cond_labels,2);
    SLIST.nruns = 1;

    SLIST.sampling_rate = EEG_mvpa.srate;
    
end  

