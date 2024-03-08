function [ibi, ibi_des] = IBIchannel(peakPosition, ECGdata)

ibi = diff(peakPosition);

% initialize NaN vector for IBI channel
ibi_des = NaN(length(ECGdata),1);

for i = 1:length(peakPosition)-1
    ibi_des(peakPosition(i,1):peakPosition(i+1,1))=ibi(i,1);
end
  

