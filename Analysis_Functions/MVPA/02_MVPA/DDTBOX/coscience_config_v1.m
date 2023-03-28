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
global AnalysisName;
global bdir;

%% ABOUT THIS SCRIPT
%Normal classification

%% GENERAL STUDY PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

% Decide whether to save the SLIST structure and EEG data in a .mat file
savemode = 0; % 1 = Save the SLIST as a mat file; 0 = Don't save the SLIST

if strcmp(AnalysisName, "Flanker_MVPA")
    input_dir = [bdir '\Analysis_Functions\MVPA\01_Preprocessing\PreprocessedData\flanker\']; % Directory in which the decoding results will be saved
    output_dir = [bdir '\Analysis_Functions\MVPA\02_MVPA\DECODING_RESULTS\level_1\flanker\']; % Directory in which the decoding results will be saved
    output_dir_group = [bdir '\Analysis_Functions\MVPA\02_MVPA\DECODING_RESULTS\level_2\flanker\']; % Directory in which the group level results will be saved
elseif strcmp(AnalysisName, "GoNoGo_MVPA") 
    input_dir = [bdir '\Analysis_Functions\MVPA\01_Preprocessing\PreprocessedData\go_nogo\']; % Directory in which the decoding results will be saved
    output_dir = [bdir '\Analysis_Functions\MVPA\02_MVPA\DECODING_RESULTS\level_1\go_nogo\']; % Directory in which the decoding results will be saved
    output_dir_group = [bdir '\Analysis_Functions\MVPA\02_MVPA\DECODING_RESULTS\level_2\go_nogo\']; % Directory in which the group level results will be saved
end

sbj_code = get_participant_codes(input_dir);


%% CREATE SLIST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

SLIST = []; 
sn = SBJTODO;

   
    % subject parameters
    SLIST.number = sn;
    SLIST.sbj_code = sbj_code{sn};    
    SLIST.output_dir = output_dir;
    SLIST.output_dir_group = output_dir_group;
    SLIST.data_struct_name = 'eeg_sorted_cond';
    
    % channels    
    SLIST.nchannels = 61; % Number of channels in the dataset
    SLIST.channels = 'ChannelLabels'; 
    SLIST.channel_names_file = 'channel_inf.mat'; % Name of the .mat file containing channel information
    SLIST.channellocs = [bdir '\Analysis_Functions\MVPA\02_MVPA\locations\']; % Directory of the .mat file containing channel information
    SLIST.eyes = []; % Channel indices of ocular electrodes
    SLIST.extra = []; % Channel indices of electrodes to exclude from the classification analyses
    
    % sampling rate and baseline
    % [elisa ]for sampling rate see lines 103-112 
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
 
    %SLIST.ncond = size(SLIST.cond_labels,2);
    SLIST.nruns = 1;
    
    SLIST.data_open_name = [input_dir (sbj_code{sn}) '.mat'];
    SLIST.data_save_name = [input_dir (sbj_code{sn}) '_data.mat'];

    % [elisa] read files to extract sampling rate from info
    open_file = (SLIST.data_open_name);
    load(open_file);
    if info.sampling_rate == 500
        SLIST.sampling_rate = 500; % Sampling rate (Hz)
    elseif info.sampling_rate == 512
        SLIST.sampling_rate = 512; % Sampling rate (Hz)
    end
    clear eeg_sorted_cond info    
%% SAVE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

% Save the SLIST structure and eeg_sorted_cond to a .mat file
if savemode == 1
    
    % DF NOTE: I have changed the second argument from 'eeg_sorted_cond' to
    % SLIST.data_struct_name so that it will still save the EEG data file
    % if the user decides to use a different variable name than
    % 'eeg_sorted_cond'
    save(SLIST.data_save_name, SLIST.data_struct_name, 'SLIST');
    
end  

