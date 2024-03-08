function cleanECG = beatRepair(artifacts,peakPosition, peakAmplitude)

ibi=diff(peakPosition);

% check first if there are any artifactual short beats
if ~isempty(artifacts.short_artifact(artifacts.fa_short==0)) 
       
    % find repairable short beat artifacts
    ibi_idx = artifacts.short_artifact(artifacts.fa_short==0);
    
    % NANs are followed by artifact  (IBIa + 2)
    repaired_beats = artifacts.repairedShort.repairedBeat(artifacts.fa_short==0); 

    sa_idx=artifacts.short_artifact(artifacts.fa_short==0);

    rgl = ibi(sa_idx+1) < ibi(sa_idx-1);
    rgl=double(rgl); rgl((rgl==0))=-1;
    sbc=rgl+1;sbc(sbc==0)=1; pbc=rgl-1; pbc(pbc==0)=-1;

    new_beat(:,1)=ibi(sa_idx) + ibi(sa_idx+rgl);

    new_beat_crit(:,1)=ibi(sa_idx) + ibi(sa_idx+rgl) - ibi(sa_idx+sbc) > artifacts.cbd;
    new_beat_crit(:,2)=ibi(sa_idx) + ibi(sa_idx+rgl) - ibi(sa_idx+pbc) > artifacts.cbd;

    %% Find repearable IBIs by detecting additional r peaks between two legit peaks
    extra_del_peak=NaN(length(new_beat),1);
    for i=1:size(repaired_beats,1)

        % Check if the short beat could be reapired by the core Berntson algorithm
        if ~isnan(repaired_beats(i)) && sum(new_beat_crit(i,:))==0

            % delete spurious R peak
            del_peak(i) = ibi_idx(i) + rgl(i);

            % Check if beat can be repaired but could not be evaluated since it is
            % followed by an artifact.
        elseif isnan(repaired_beats(i)) && sum(new_beat_crit(i,:))==0

            % check if sub-subsequent beat is a long artifact and delete
            % artifactual peak
            if ismember(ibi_idx(i)+2, artifacts.long_artifact) && ...
                    abs(new_beat(i) - ibi(ibi_idx(i)+2)) < artifacts.cbd && ...
                    abs(ibi(ibi_idx(i)+1) - ibi(ibi_idx(i)+2)) > artifacts.cbd

                del_peak(i) = ibi_idx(i) + rgl(i);

                % check if subsequent beat(s) are residual artifacts
            elseif  ismember(ibi_idx(i)+2, ...
                    artifacts.residualArtifacts) && ...
                    abs(new_beat(i) - ibi(ibi_idx(i)+2)) < artifacts.cbd

                del_peak(i) = ibi_idx(i) + rgl(i);

            else
                del_peak(i) = NaN;
            end

            % Check if there is another short beat artifact
            %(that was not flagged by the Berntson algortihm since it would be
            % preceded by an artifact) adjacent to the current short artifact
        elseif  sum(new_beat_crit(i,:))==1

            % check if new beat fits criterion with preceding beat. if yes:
            % subsequent beat might also be a short artifact
            if new_beat_crit(i,1) == 1 && ...
                    abs(new_beat(i) - (ibi(ibi_idx(i)+2) + ibi(ibi_idx(i)+3))) < artifacts.cbd...
                    && abs(ibi(ibi_idx(i)+4) - (ibi(ibi_idx(i)+2) + ibi(ibi_idx(i)+3)))  < artifacts.cbd

                del_peak(i) = ibi_idx(i) + rgl(i);
                extra_del_peak(i,1) = ibi_idx(i)+3;

                % check if new beat fits criterion with subsequent beat. if yes:
                % preceding beat might also be a short artifact
            elseif  new_beat_crit(i,2) == 1 && ...
                    abs(new_beat(i) - (ibi(ibi_idx(i)-2) + ibi(ibi_idx(i)-3))) < artifacts.cbd...
                    && abs(ibi(ibi_idx(i)-4) - (ibi(ibi_idx(i)-2) + ibi(ibi_idx(i)-3)))  < artifacts.cbd


                del_peak(i) = ibi_idx(i);
                extra_del_peak(i,1) = ibi_idx(i)-2;

            else

                del_peak(i)=NaN;
            end

        else
            del_peak(i)=NaN;
        end
    end

    if ~isempty(repaired_beats) % workaround 03/10/23 PB

        del_peak=del_peak';
        del_peak(isnan(del_peak))=[];
        extra_del_peak(isnan(extra_del_peak))=[];
        del_peak=[del_peak; extra_del_peak];

        % workaround for error #01. 03/10/23 PB
        del_peak=unique(del_peak);

        new_peaks=peakPosition;
        new_peaks(del_peak)=[];
        new_amplitude=peakAmplitude;
        new_amplitude(del_peak)=[];

    else
        del_peak=[];
        new_peaks=peakPosition;
        new_peaks(del_peak)=[];
        new_amplitude=peakAmplitude;
        new_amplitude(del_peak)=[];
    end

    %% save corrected ECG with repaired beats
    cleanECG=struct;
    cleanECG.deleted_peaks=del_peak;
    cleanECG.peakPosition=new_peaks;
    cleanECG.peakAmplitude=new_amplitude;

else

    %% save "corrected" ECG (for participants without artifactual short beats): modPB 2306
    cleanECG=struct;
    cleanECG.deleted_peaks=[];
    cleanECG.peakPosition=peakPosition; % newPeak position = old peakPosition
    cleanECG.peakAmplitude=peakAmplitude; % newAmplitude = oldAmplitude
end
