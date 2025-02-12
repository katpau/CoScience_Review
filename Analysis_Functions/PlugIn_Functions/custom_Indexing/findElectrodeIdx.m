function [ElectrodeIdx] = findElectrodeIdx(chanlocs, Electrodes)
    Electrodes = strrep(Electrodes, " ", "");
    Electrodes = upper(Electrodes);
    ElectrodeIdx = zeros(1, length(Electrodes));
    if isstruct(chanlocs)
        ElectrodeNames = upper({chanlocs.labels});
    else
        ElectrodeNames = upper(chanlocs);
    end
    for iel = 1:length(Electrodes)
        [~, ElectrodeIdx(iel)] = ismember(Electrodes(iel), ElectrodeNames); 
    end
end