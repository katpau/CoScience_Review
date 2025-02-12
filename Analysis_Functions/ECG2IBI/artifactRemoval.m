function [ibi_des_clean,  ibi_des_raw]=artifactRemoval(ECG, cleanECG,...
    peakPosition, artifacts)

if ~isempty(artifacts)

    ibi=diff(peakPosition);
    ibi_clean=diff(peakPosition);

    if isfield(artifacts,'endArtifacts')
        ibi_clean(artifacts.endArtifacts) = NaN;
    else
    end

    % remove follow-up artifacts following a spurios extra R peak
    artifacts.residualArtifacts...
        (ismember(artifacts.residualArtifacts,...
        [cleanECG.deleted_peaks; ...
        cleanECG.deleted_peaks+1;...
        cleanECG.deleted_peaks+2])) = [];

    % delete long artifacts with an additional artifactual beat
    ibi_clean([artifacts.long_artifact(~ismember(artifacts.long_artifact,artifacts.long_artifact_fa)); ...
        artifacts.long_artifact(~ismember(artifacts.long_artifact,artifacts.long_artifact_fa))+1])=NaN;

    % delete long artifacts, but check beforehand if long artifact results
    % from short artifact
    % check  if long artifact results from short artifact
    artifacts.fa_long(find...
        (ismember(artifacts.long_artifact_fa-1, cleanECG.deleted_peaks))) = 1;

    % delete long artifacts
    ibi_clean(artifacts.long_artifact_fa(artifacts.fa_long==0))=NaN;


    %% delete short artifacts that can't be fixed (e.g., because they are
    % followed by another artifact)
    del_resshort=artifacts.short_artifact(artifacts.fa_short==0);

    del_c=1;del_idx=[];
    for i =1:length(del_resshort)
        if min(abs(del_resshort(i)-cleanECG.deleted_peaks)) > 1
            del_idx(del_c,1) = del_resshort(i);
            del_c=del_c+1;
        else
        end
    end

    del_idx=[del_idx; del_idx+1;del_idx+2];
    ibi_clean(del_idx)=NaN;


    %% Fix short artifacts
    ibi_sc=cleanECG.peakPosition;
    ibi_sc=diff(ibi_sc);
    ibi_clean2=ibi_clean;

    sub=0;

    for i=1:length(cleanECG.deleted_peaks)
        if ibi(cleanECG.deleted_peaks(i)+1) > ibi(cleanECG.deleted_peaks(i)-1)

            ibi_clean2([cleanECG.deleted_peaks(i)-1]-sub)=...
                ibi(cleanECG.deleted_peaks(i)-1) + ...
                ibi(cleanECG.deleted_peaks(i));

            ibi_clean2([cleanECG.deleted_peaks(i)]-sub)=[];

        else
            ibi_clean2([cleanECG.deleted_peaks(i)-sub]) = ...
                ibi(cleanECG.deleted_peaks(i)) + ...
                ibi(cleanECG.deleted_peaks(i)+1);
            ibi_clean2([cleanECG.deleted_peaks(i)+1]-sub) = [];

        end

        sub=sub+1;
    end

    ibi=diff(cleanECG.peakPosition);
    % initialize NaN vector for IBI channel
    ibi_des = NaN(length(ECG.data),1);
    ibi_des_clean = NaN(length(ECG.data),1);

    for i = 1:length(cleanECG.peakPosition)-1
        ibi_des(cleanECG.peakPosition(i,1):cleanECG.peakPosition(i+1,1)) = ibi(i,1);
        ibi_des_clean(cleanECG.peakPosition(i,1):cleanECG.peakPosition(i+1,1)) = ibi_clean2(i,1);
    end

    [~, ibi_des_raw] = IBIchannel(peakPosition, ECG.data);

else % for participants without artifacts 
    [~, ibi_des_raw] = IBIchannel(peakPosition, ECG.data);
    [~, ibi_des_clean] = IBIchannel(peakPosition, ECG.data);
end

% transform IBI values from sampling points to ms
ibi_des_raw = 1000/ECG.srate*ibi_des_raw;
ibi_des_clean = 1000/ECG.srate*ibi_des_clean;







