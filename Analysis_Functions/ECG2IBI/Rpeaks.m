function [peakAmplitude,peakPosition, ECG] = Rpeaks(ECG, min_dis)
% R-Peak detection. This function detects R-Peaks within a continous ECG
% signal. R-Peak detection is based on an adapted version of the 
% Pan–Tompkins algorithm. Pan et al. (1985) doi:10.1109/TBME.1985.325532 
%
% ECG data has to be provided as eeglab structure contaning only a
% single channel (i.e., the ECG channel).
%
% the min_dis defines the minimum distance between two consecutive peaks.
% Typical values:
%
% - 200 ms (i.e., the minimum time between to consecutive R
% peaks): The 200 ms correspond to the refractory period following 
% ventricular contration which prevents an immediate ventricular
% depolarization (might cause the detection of artifactual extra detections 
% due to the small miminum distannce)
%
% - 300 ms corresponds to a maximum heart frequency of 200 beats
% per second. 
%
% - 400 ms corresponds to a maximum heart frequency of 150 beats
% per second. Seems to work quite well in experimentel settings 
% (i.e., seated participants, no physical exertion)
%
% OUTPUT:
% - peakAmplitude: Amplitude of detected R-peak (for plotting)
% - peakPosition: Position (in sampling points) of the detected R-peak. 
% This will be used for InterbeatInterval (IBI) calculation
% - ECG: eeglab structure containing the ECG data



%% Prepeare ECG signal for R peak detection
% filter ECG data via the EEGlab function 'pop_eegfiltnew.m'
ECG_filtered = pop_eegfiltnew(ECG, 'locutoff',5,'hicutoff',15,...
    'plotfreqz',0);
ecg_data=ECG_filtered.data; clear ECG_filtered

% remove mean of ECG signal
ecg_data=ecg_data-mean(ecg_data);

%%
% calculate first derivative of ECG signal 
ecg_data_d = diff(ecg_data); 

% square the first derivation of the ecg signal
ecg_data_ds = ecg_data_d.^2; clear ecg_data_d

% moving average filter - with a 150 ms window - to smooth QRS complexes. 
ecg_data_dsm = movmean(ecg_data_ds, round(ECG.srate/1000*150)); clear ecg_data_ds

% fill up preprocessed ECG vector with 1 NaN. 
ecg_data_dsm = [NaN ecg_data_dsm];

% *************************************************************************
%% Define minimum distance between consecutive peaks, find threshold
% and R peak detection
% *************************************************************************

% minimum distance criteria for consecutive  peaks
minpeakdist= ECG.srate/1000*min_dis; 

%% Platzhalter: adaptiven Threshold einbauen (maybe Hilbert envelope?)
% threshold = nanmean(ecg_data_dsm)/2;

% discard artifactual ECG signal to determine reliable threshold
artifact_thresh = quantile(ecg_data_dsm, 0.75) + 15*iqr(ecg_data_dsm);
ecg_outliers = ecg_data_dsm(1,:);


% Discard signal 3 seconds before extreme ECG values
ecg_artifacts=...
    [find(ecg_outliers > artifact_thresh)-3*ECG.srate ...
    find(ecg_outliers > artifact_thresh)-ECG.srate + 3*ECG.srate];
ecg_artifacts = unique(ecg_artifacts);

% remove potential negative. PB 04.01.24
ecg_artifacts((ecg_artifacts < 0))=[];

artifact_free_ecg=ecg_data_dsm;artifact_free_ecg(1,ecg_artifacts)=NaN;
threshold = mean(artifact_free_ecg,'omitnan');

%%
% Initial R peak detection
[~,t_peakPosition] = findpeaks(ecg_data_dsm(:),'minpeakheight',threshold,...
    'minpeakdistance',minpeakdist);


%% check polarity of ECG signal
clean_ecg_data = ecg_data; clean_ecg_data(1,ecg_artifacts)=NaN;
if abs(quantile(clean_ecg_data, 0.01)) > abs(quantile(clean_ecg_data, 0.99)) 
    % If ECG signal is inverted,
    % the absoultue values below the 1st percentile should be greater than
    % the values above the 99th percentile. 
    % invert signal:
    ecg_data=ecg_data*-1;
    ECG.data=ECG.data*-1;
else
end

%% Precise R peak detection ("R magnet")
% define time window (ms) before and after the detected R-Peak to find 
% the precise local maxima
max_peak_window=75;
peakAmplitude=zeros(length(t_peakPosition),1);
peakPosition=zeros(length(t_peakPosition),1);

for i=1:length(t_peakPosition)
    
    % if the first r peak occurs during the first max_peak_window:
    % set the start of the ECG signal as lower border of the
    % max_peak_window for the first trial
    if t_peakPosition(i) <= max_peak_window
        [peakAmplitude(1),peakPosition(i)] = ...
            max(ECG.data(1,1:...
            t_peakPosition(1)+round(ECG.srate/1000*max_peak_window)));
        
    % Same thing applies for the end of the ECG signal.   
    elseif i==length(t_peakPosition) && size(ECG.data,2) - t_peakPosition(end) < max_peak_window*ECG.srate/1000 %modPB0507 multiply with ECG.srate/1000 to transfrom sapmling points in ms 
        [peakAmplitude(i),tmp_peakPosition] = ...
            max(ECG.data(1,t_peakPosition(i)-round(ECG.srate/1000*max_peak_window):...
            size(ECG.data,2)));   
         % find general peak time 
        peakPosition(i) = tmp_peakPosition-1 + t_peakPosition(i)-round(ECG.srate/1000*max_peak_window);
        
    else
        
        % find amplitude and peak time in window
        [peakAmplitude(i),tmp_peakPosition] = ...
            max(ECG.data(1,t_peakPosition(i)-round(ECG.srate/1000*max_peak_window):...
            t_peakPosition(i)+round(ECG.srate/1000*max_peak_window))); 
        
        % find general peak time 
        peakPosition(i) = tmp_peakPosition-1 + t_peakPosition(i)-round(ECG.srate/1000*max_peak_window);
    end

    clear tmp_peakPosition
    
end











