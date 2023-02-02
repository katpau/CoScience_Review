function [participant_codes] = get_participant_codes(bdir, input_dir)

% this function gets participant codes from the file where the data is
% stored

files = struct2table(dir(fullfile(input_dir,'*.mat')));
participant_filenames = files.name;
participant_codes = cell(size(participant_filenames));

for i = 1:length(participant_filenames)
    
    id = participant_filenames{i};
    participant_codes{i} = id(1:(length(id)-4));
    
end

end

