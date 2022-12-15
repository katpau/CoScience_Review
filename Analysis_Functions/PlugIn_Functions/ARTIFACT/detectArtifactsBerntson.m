function [artifactPos, processedSignal] = detectArtifactsBerntson(signalToProcess)
% @Author:      Tobias Kaufmann, PhD
%
% @Location:    University of Wuerzburg, Germany
%               Oslo Univeristy Hospital, Norway
%
% @Cite:        Kaufmann, T., Sütterlin, S., Schulz, S. M., & Vögele, C. (2011). 
%               ARTiiFACT: a tool for heart rate artifact processing and heart rate variability analysis. Behavior research methods, 43(4), 1161-1170.
%
% @Function:    signalToProcess = one column of IBI data
%               processedSignal = IBI data with flagged artifacts in second
%               column
%               artifactPos = artifact positions




%% PRE-SETS
% Compute second Quartile (50th percentile)
Q(2) = median(signalToProcess);

% Compute first Quartile (25th percentile)
Q(1) = median(signalToProcess(find(signalToProcess<Q(2))));

% Compute third Quartile (75th percentile)
Q(3) = median(signalToProcess(find(signalToProcess>Q(2))));

% Compute Interquartile Range (IQR)
IQR = Q(3)-Q(1);

% Compute Estimated artifact-free SD
SD = 1.48*((Q(3)-Q(1))/2);

% Compute Maximum expected difference for non-artifactural beats:
MED = 3.32*((Q(3)-Q(1))/2);

% Compute Minimal expected difference for non-arcifactural beats:
MAD = (Q(2) - (2.9*(IQR/2)))/3;

% Compute Criterion Beat Difference (abs):
CBDa = (MED+MAD)/2;



%% DETECT ARTIFACTS
p = 1;
artefactcounter=0;
signalToProcess (:,2) = 0;

% find artifacts and watch out for false alarms
for n=1:length(signalToProcess)
    if n+1<= length(signalToProcess) && n-1 > 0 && ((abs(signalToProcess(n)-signalToProcess(n+1))>CBDa) || (abs(signalToProcess(n)-signalToProcess(n-1))>CBDa))
        % Seems to be an artifact, set flag 999
        signalToProcess(n,2) = 999;   
    else
        p=n;
    end
    
    if signalToProcess(n,2) == 999
        if p==1 || abs(signalToProcess(n,1)-signalToProcess(p,1))>CBDa
            % this is an artefact, count
            artefactcounter=artefactcounter+1;
        else
            signalToProcess(n,2) = 0;
            p=n;
        end
    end
end

artifactPos=find(signalToProcess(:,2)==999);
processedSignal=signalToProcess;