function ibi = ecg2ibi(ECG, filename, interpolation)
% wrapper function to consecutively call custom-made ECG2IBI functions that:
%
% 1. detect R peaks within a continous ECG signal (Rpeaks.m) according to
% an adapted version of the Pan–Tompkins algorithm: 
% Pan et al. (1985) doi:10.1109/TBME.1985.325532 
%
% 2 and 3: detect, repair, and remove Interbeat Interval (IBI) artifacts
% according to an adapted version of Berntsons et al. approach to 
% (IBI, i.e. heart period) artifact identification. 
% Berntson et al. (1990) https://doi.org/10.1111/j.1469-8986.1990.tb01982.x
% 
% 4. Removes residual artifacts that were in close proximity to artifacts 
% already deleted during steps 3 and 4, and were therefore missed.  In
% addition, if interpolation is chosen, deleted artifacts will be
% interpolated using linear interpolation
%
% INPUT: 
% ECG -> Continous ECG signal provided in EEGlab format, containing only one
% (ECG) channel. (EEGlab needs to be on the Matlab pathway).
%
% filename = string containing the filename, particpant code, etc.
% interpolation = 'interpolation' vs. 'no_interpolation'
%                 'interpolation' -> artifacts are interpolated using linear interpolation 
%                 'no_interpolation -> Artifacts are deleted and are
%                 replaced by NaNs. Thus, the IBI signal contains NaN but
%                 has an identical amount of sampling points compared to
%                 the original signal
%
% OUTPUT:
% Structure containing the artifact-corrected ibi data (output.data(1,:)),
% the non-corrected ibi data (output.data(2,:)), and the ECG signal ((output.data(3,:))
% Moreover, several experimental parameter like the srate, the event
% structure, and artifact information are also saved.

%% 1 - r peak detection via r_peaks.m
[peakAmplitude,peakPosition, ECG]  = Rpeaks(ECG, 400);

%% 2 - artifact detection via IBIartifacts.m
artifacts = IBIartifacts(peakPosition);

%% 3 - clean ECG signal of spurious R peaks via beatRepair.m 

if ~isempty(artifacts)
    % if there are (short) artifacts try to repair them with beatRepair
    cleanECG = beatRepair(artifacts, peakPosition, peakAmplitude);
else
    cleanECG=struct;
    cleanECG.deleted_peaks=[];
    cleanECG.peakPosition=peakPosition; % newPeak position = old peakPosition
    cleanECG.peakAmplitude=peakAmplitude; % newAmplitude = oldAmplitude
end

%% 4 - remove residual artifacts via artifactRemoval.m and residualArtifacts.m 
[ibi_des_clean,  ibi_des_raw]=artifactRemoval(ECG, cleanECG,...
    peakPosition, artifacts);

[ibi_des_clean, art_inf] = residualArtifacts(ibi_des_clean', ECG.srate, interpolation);

%% prepare results
ibi = struct;
ibi.file = filename;
ibi.data(1,:) = ibi_des_clean';
ibi.data(2,:) = ibi_des_raw;
ibi.data(3,:) = ECG.data;
ibi.time = ECG.times;
ibi.artifacts = artifacts;
ibi.artifacts.residuals = art_inf;
ibi.events = ECG.event;
ibi.srate = ECG.srate;
ibi.Rpeaks.peakPosition = peakPosition;
ibi.Rpeaks.peakAmplitude = peakAmplitude;



