%% house built functions
% Find Time Index (range)
    function [TimeIndexRange] = findTimeIdx(times, Start, End)
        [~, TimeIndexRange(1)]=min(abs(times - Start));
        [~, TimeIndexRange(2)]=min(abs(times - End));
        TimeIndexRange = TimeIndexRange(1):TimeIndexRange(2);
    end

