

%% Information
% This script reads the preprocessed (not preanalysed) MVPA data and
% extracts the number of trials in the conditions CD, ED, EU and CU. These
% are then saved as a csv file in the folder where the MVPA data are
% stored.

%% Specifications
% Indicate the base directory and the "middle" directory. (You can leave
% the mdir empty and put the entire directory into the bdir variable.)
bdir = 'C:\Users\elisa\Desktop\MVPA_exp1_exp2\02_Preprocessing\PreprocessedData/';
mdir = '-900_to_200_ms/splithalf/';

%% Script

% Create directory
ddir = [bdir, mdir];

% List files in directory
listing = struct2dataset(dir([ddir, '*.mat']));
files = listing.name;

% Get the participant numbers as numeric
for i = 1:length(files)
    file = files{i};
    number = file(1:(length(file)-4));
    numbers(i) = str2num(number);
end
numbers = numbers';

% Set up the output data set
out_data = dataset(files);
out_data.id = numbers;
out_data.n_Correct_Exp1_Part1 = 0;
out_data.n_Correct_Exp1_Part2 = 0;
out_data.n_Error_Exp1_Part1 = 0;
out_data.n_Error_Exp1_Part2 = 0;
out_data.n_Correct_Exp2_Part1 = 0;
out_data.n_Correct_Exp2_Part2 = 0;
out_data.n_Error_Exp2_Part1 = 0;
out_data.n_Error_Exp2_Part2 = 0;

% Loop through the data of each participant, extract the trial numbers and
% write the information in the output data set.
for f = 1:length(files)
    open_name = [bdir, mdir, files{f}];
    load(open_name, 'info');
    out_data.n_Correct_Exp1_Part1(f) = info.n_Correct_Exp1_Part1;
    out_data.n_Correct_Exp1_Part2(f) = info.n_Correct_Exp1_Part2;
    out_data.n_Error_Exp1_Part1(f) = info.n_Error_Exp1_Part1;
    out_data.n_Error_Exp1_Part2(f) = info.n_Error_Exp1_Part2;
    out_data.n_Correct_Exp2_Part1(f) = info.n_Correct_Exp2_Part1;
    out_data.n_Correct_Exp2_Part2(f) = info.n_Correct_Exp2_Part2;
    out_data.n_Error_Exp2_Part1(f) = info.n_Error_Exp2_Part1;
    out_data.n_Error_Exp2_Part2(f) = info.n_Error_Exp2_Part2;
end

% Sort the output data set by participant number.
out_data = sortrows(out_data, 'id');

% Save the data set.
export(out_data, 'File', [bdir, mdir, 'trial_numbers.csv'], 'Delimiter', ',')

% Clean up
clear all




