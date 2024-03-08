function cect = CECT(EEG, IBI, cfg)
% This function calculates "Cardio-Electroencephalographic Covariance
% Tracing" (CECT). 
% Mueller, Stemmler, & Wacker (2010) 10.1016/j.neuroscience.2009.12.051
%
% INPUT: 
% EEG = 3D matrix containing single trial EEG data (electrodes, time points,
% trials)
% IBI = 2D matrix containing single trial IBI data (time points, trials)
% cfg = structure containing the settings for the cect analysis (for an
% example see below)
% 
% OUTPUT:
% 3D matrix containing electrodes, EEG bins, and IBI bins
%
% EEG and IBI segments should be baseline corrected. 
% To get valid results, it is necessary that the EEG and IBI trials/segments are identical.
%
% example cfg structure:
% cfg.segsizeIBI = [-1, 6]; % provided IBI segment size
% cfg.segsizeEEG = [-1, 6]; % provided EEG segment size
% cfg.ibibins = [0, 5]; % IBI bins to analyse
% cfg.eegbins = [0, 1]; % EEG bins to analyse
% cfg.srateEEG = 250; % sampling rate EEG
% cfg.srateIBI = 1024; % sampling rate IBI
% cfg.ibibinsize = 500; % IBI bin size
% cfg.eegbinsize = 20; % EEG bin size

if isempty(cfg)
    disp('You need to provide a configuration structure. See "help cect".')
else

    disp('calculating CECTs')
    %% prepare IBI bins

    % calculate IBI bins
    ibi_bins1 = squeeze(...
        IBI( ...
        round((cfg.ibibins(1)  - cfg.segsizeIBI(1)) * cfg.srateIBI) : ...
        round((cfg.ibibins(1) - cfg.segsizeIBI(1) + cfg.ibibins(2)) * cfg.srateIBI),:));

    no_bins_ibi = round(size(ibi_bins1,1)/(cfg.ibibinsize/1000*cfg.srateIBI));
    ibi_bin_range = round(linspace(1,size(ibi_bins1,1),no_bins_ibi+1));
    % no_bins_ibi+1 linspace steps in order to create the defined number of bins


    for b=1:length(ibi_bin_range)-1
        ibi_bins(b,:) =...
            squeeze(mean(ibi_bins1(ibi_bin_range(b):ibi_bin_range(b+1),:),1));
    end


    %% prepare EEG bins
    % calculate EEG bins
    % round: changed 06.12.
    eeg_bins1 = EEG(:, round((cfg.eegbins(1) - cfg.segsizeEEG(1)) * cfg.srateEEG) : ...
        round((cfg.eegbins(1) - cfg.segsizeEEG(1) + cfg.eegbins(2)) * cfg.srateEEG),:);

    no_bins_eeg = round(size(eeg_bins1,2)/(cfg.eegbinsize/1000*cfg.srateEEG));
    eeg_bin_range = round(linspace(1,size(eeg_bins1,2), no_bins_eeg+1));
    % no_bins_eeg+1 linspace steps in order to create the defined number of bins

    for b=1:length(eeg_bin_range)-1
        eeg_bins(:,b,:) =...
            squeeze(mean(eeg_bins1(:,eeg_bin_range(b):eeg_bin_range(b+1),:),2));
    end


    %% Calculate CECTs via within-subject correlations
    % initialize cect matrix

    cect = NaN(size(EEG,1), size(eeg_bins,2), size(ibi_bins,1));
    for elec = 1:size(EEG,1)
        for bin1 = 1:size(eeg_bins,2)
            for bin2 = 1:size(ibi_bins,1)
                cect(elec,bin1, bin2) = ...
                    corr(squeeze(eeg_bins(elec,bin1,:)),ibi_bins(bin2,:)'); 
            end
        end
    end

end
