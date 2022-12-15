
% detect peaks (and latencies)
    function [Peaks, Latency] = Peaks_Detection(Subset, PeakValence)
    SubsetBU = Subset;
        if PeakValence == "NEG"
            % Find possible Peak
            possiblePeaks = islocalmin(Subset,2);
            Subset(~possiblePeaks) = NaN;
            % Identify largest Peak
            [Peaks, Latency]  = min(Subset,[],2);
            
        elseif PeakValence == "POS"
            % Find Possible Peak
            possiblePeaks = islocalmax(Subset,2);
            Subset(~possiblePeaks) = NaN;
            % Identify largest Peak
            [Peaks, Latency]  = max(Subset,[],2);
        end
        
        % if no peak was detected, take mean
        if any(isnan(Peaks))
            noPeak = find(isnan(Peaks));
            MeanNoPeak = mean(SubsetBU(noPeak,:), 2);
            Peaks(noPeak) = MeanNoPeak;
        end
    end
