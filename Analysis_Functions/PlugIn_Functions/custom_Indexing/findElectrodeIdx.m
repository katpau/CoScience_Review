function [ElectrodeIdx] = findElectrodeIdx(chanlocs, Electrodes)
    Electrodes = strrep(Electrodes, " ", "");
    ElectrodeIdx = zeros(1, length(Electrodes));
    for iel = 1:length(Electrodes)
        [~, ElectrodeIdx(iel)] = ismember(Electrodes(iel), upper({chanlocs.labels})); 
    end
end