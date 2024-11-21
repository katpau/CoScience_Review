function [artifact]=IBIartifacts(peakPosition)

%% calculate IBIs and beat-to-beat differences
ibi = diff(peakPosition);
% calculate error of estimate
beat_diff = diff(ibi);

%% calculate percentile-based statistics for artifact detection (see Berntson et al.)
% calculate the quartile deviation (qd) based on the interquartile range
qd = diff(quantile(ibi, [0.25, 0.75]))/2;
% calculate the Maximum Expected Difference (med) for non-artifactual beats.
% flags approximately 2.5% of non-artifactual beats as artifact
med = 3.32*qd;
% calulate the Minimal Expected Difference (mad)
mad = (median(ibi) - 2.9 * qd)/3;
% calculate cirterion beat difference (cbd)
cbd = (mad+med)/2;

%  ************************************************************************
%% Artifact detection and classification of long and short artifacts
%  ************************************************************************

% detect beat differences exceeding cirterion (cbd) and set inital artifact
% flags
artifact_flag = find(abs(beat_diff)/cbd > 1);

% check if there are any detcted artfifacts in the data
if ~isempty(artifact_flag) 

    % Check if there is an artifactual beat at the end of the data
    % and save it separately
    if artifact_flag(end) >= length(beat_diff)
        artifact_save = artifact_flag(end);
        artifact_flag(end)=[];

        if artifact_flag(end)+1 >= length(beat_diff)
            artifact_save = [artifact_save;artifact_flag(end)];
            artifact_flag(end)=[];
        else
        end
    else
    end

    % *********************************************************************
    %% Classify flagged artifacts as "long" or "short" artifactual beats
    % *********************************************************************

    % check if flagged artifactual beat was preceded by a "clean" 
    % beat. First artefactual beat can't be preceded  by an
    % artifactual one: thus first flagged beat is automatically added to
    % the "prior_clean" index
    prior_clean = [1; find(diff(artifact_flag)~=1)+1];

    short_beat_artifact = artifact_flag...
        (prior_clean(beat_diff(artifact_flag(prior_clean)) < 0))+1;
    long_beat_artifact = artifact_flag...
        (prior_clean(beat_diff(artifact_flag(prior_clean)) > 0))+1;

    artifacts=artifact_flag+1;
    % find all flagged artifacts that were already preceded by an artifact
    residualArtifacts = artifacts(find(diff(artifacts)==1)+1);

    

    % *********************************************************************
    %% Detection of false alarms
    % *********************************************************************

    %% Long beat routine

    % check if the following IBI after the flagged IBI (i.e., after 
    % the potential long artifact) is clean
    lb_idx = abs(beat_diff(long_beat_artifact+1)) < cbd;
    
    % split the alleged long artifact in half
    x = ibi(long_beat_artifact(lb_idx))/2; 

    % a genuine missed beat should result in two "new beats" which 
    % don't exceed the artifact criterion (cbd)
    % (i.e., resulting in differences with adjacent beats < -cbd)
    fa_long = x-ibi(long_beat_artifact(lb_idx)+1) < -cbd & ...
        x-ibi(long_beat_artifact(lb_idx)-1) < -cbd;
    
    % prepare all long artifacts
    long_beat_artifact_forfa = long_beat_artifact(lb_idx);

    all_long_artifacts = [long_beat_artifact(lb_idx==0); ...
        long_beat_artifact_forfa(fa_long==0)];

    clear x

    %% Short beat routine
    
    % check first if the following IBI after the flagged IBI (i.e., after 
    % the potential short artifact) is clean
    fa_short = (abs(beat_diff(short_beat_artifact+1)) < cbd);
    sb_idx = find(fa_short);

    % if the IBI is not followed by an artifact, check 
    x_idx = NaN(length(fa_short),1);
    x = x_idx ;
    
    % preceding beat greater than subsequent beat == 1
    % subsequent beat greater than preceding beat == 0
    x_idx(sb_idx,1) = ibi(short_beat_artifact(sb_idx)-1) > ...
        ibi(short_beat_artifact(sb_idx)+1);

    % Try to repair short beats
    x(x_idx==1, 1) = ibi(short_beat_artifact(x_idx==1)+1) + ...
        ibi(short_beat_artifact(x_idx==1));

    x(x_idx==0, 1) = ibi(short_beat_artifact(x_idx==0)-1) + ...
        ibi(short_beat_artifact(x_idx==0));

    % compare repaired beat with adjacent beats and set false alarm flags
    fa_short(x_idx==1,1) = x(x_idx==1, 1) - ibi(short_beat_artifact(x_idx==1)-1)...
        > cbd & x(x_idx==1, 1) - ibi(short_beat_artifact(x_idx==1)+2) > cbd;
    fa_short(x_idx==0,1) = x(x_idx==0, 1) - ibi(short_beat_artifact(x_idx==0)-2)...
        > cbd & x(x_idx==0, 1) - ibi(short_beat_artifact(x_idx==0)+1) > cbd;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Save detected artifacts and false alarms
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    artifact.allArtifacts = artifacts;
    artifact.short_artifact = short_beat_artifact;
    artifact.long_artifact = long_beat_artifact;
    artifact.all_long_artifacts = all_long_artifacts;
    artifact.long_artifact_fa=long_beat_artifact_forfa;
    artifact.residualArtifacts=residualArtifacts;
    artifact.allArtifacts=artifacts;
    artifact.fa_short=fa_short;
    artifact.fa_long=fa_long;
    artifact.repairedShort.rightleft=x_idx;
    artifact.repairedShort.repairedBeat=x;
    artifact.cbd=cbd;
    artifact.med=med;
    artifact.mad=mad;

    if exist('artifact_save')
        artifact.endArtifacts = artifact_save;
    else
    end
else
    artifact=[];
end



