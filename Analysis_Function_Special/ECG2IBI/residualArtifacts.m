function [ibi_result, art_inf] = residualArtifacts(ibi, srate, interpolation)

% This function deletes unphysiological and residual artifacts/ extreme IBIvalues that
% are close to already removed artifacts and thus were liekly missed by the algorithm
% 
% INPUT:
% ibi = ibi data 1xN matrix containing contionus IBI data (N = sampling
% points)
% srate = sampling rate of the ibi data
% interpolate = 'interpolation' vs. 'no_interpolation'
% no interpolation = artifacts remain as NaNs in the continous data
%
% OUTPUT:
% ibi_results = contains continous ibi data with removed residual artifacts
% ('no_interpolation') or contionious ibi data with removed residual
% artifacts and interpolated IBI values ('interpolate'). 

%*************************************
%% remove unphysiological IBI values
%*************************************
% < 25 BPM: >2400ms
% > 200 BPM: <300ms

unphysArt = ibi < 300 | ibi > 2400;
ibi(1,unphysArt) = NaN;

%*************************************
%% mark detected artifacts in IBI data
%*************************************

% Detect NaN islands
nanIndices = isnan(ibi);
diffNan = diff([0, nanIndices, 0]);
startIslands = find(diffNan == 1);
endIslands = find(diffNan == -1) - 1;

% Discard first and last NaN islands
startIslands([1, length(startIslands)]) = [];
endIslands([1, length(endIslands)]) = [];
nanIslands = [startIslands; endIslands]';

%****************************************
%% Remove extreme values around artifacts
%****************************************

% define buffer size which is used to detect extreme values before and
% after a detected artifact
buffer = srate*3;
% initialize output array
outliers = [];

for i = 1:size(nanIslands, 1)
    % Define the search region around the current NaN island
    startSearch = max(1, nanIslands(i, 1) - buffer);
    endSearch = min(length(ibi), nanIslands(i, 2) + buffer);

    % Extract the region
    searchRegion = ibi(startSearch:endSearch);

    % Compute the quartiles and IQR
    q1 = quantile(ibi, 0.25, 'all');
    q3 = quantile(ibi, 0.75, 'all');
    iqr = q3 - q1;

    % Identify outliers within this region
    lowerBound = q1 - 1.5 * iqr;
    upperBound = q3 + 1.5 * iqr;
    outlierIndices = find(searchRegion < lowerBound | searchRegion > upperBound);

    % Store the indices of detected outliers (adjusting for the actual ibi index)
    outliers = [outliers, (startSearch-1) + outlierIndices];
end

% remove outliers
ibi_result = ibi; 
ibi_result(1,outliers) = NaN;
art_inf.artifacts.number = length(nanIslands);
art_inf.artifacts.size = nanIslands;

art_inf.percentBadSignal = sum(isnan(ibi_result))/length(ibi_result);

%*******************************************
%% Linear interpolation of removed artifacts
%*******************************************
if strcmp(interpolation, 'interpolation')
    % detect artifact caused NaNs
    nanIndices = isnan(ibi_result);
    diffNan = diff([0, nanIndices, 0]);
    startIslands = find(diffNan == 1);
    endIslands = find(diffNan == -1) - 1;

    % Discard first and last NaN islands
    startIslands([1, length(startIslands)]) = [];
    endIslands([1, length(endIslands)]) = [];

    % Identify indices of valid and invalid points
    nanIDX=[];
    for i=1:length(startIslands)
        nanIDX = [nanIDX, startIslands(i):endIslands(i)];
    end
    valid_signal = ones(length(ibi_result),1);
    valid_signal(nanIDX) = 0;

    % Obtain the indices and values for interpolation
    idxValid = find(valid_signal);
    ibiValid = ibi_result(1,find(valid_signal));

    % Perform linear interpolation at the locations of the NaNs
    ibi_result(nanIDX) = interp1(idxValid , ibiValid, nanIDX, 'linear');
    art_inf.interpolated_pnts = nanIDX;

else
end