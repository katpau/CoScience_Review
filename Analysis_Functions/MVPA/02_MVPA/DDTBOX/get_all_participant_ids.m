
%% Information
% When running ANALYSE_DECODING_ERP, we need to give the participant
% numbers to the function which we want to analyse. This can be a bit
% nerve-wrecking when we simply want to analyse ALL participants. The
% current script is called when the string 'all' is handed to the
% ANALYSE_DECODING_ERP function instead of a vector of participant numbers.
% The script scans the folder where the preanalysed data are stored and
% returns the participant numbers for which preanalysed data is available.
% In short, this script will make sure the data of all participants are
% analysed.

%% Script

% The pattern of data name to be looked for (depending on the output
% directory, the analysis window width, the step width, the analysis mode
% and the decoding group)
global SBJTODO;
SBJTODO = 1;
%sbj = ANALYSIS.sbjs(1);
global SLIST
eval(sbj_list);
pattern = [(SLIST.output_dir) study_name '_SBJ*_win' num2str(ANALYSIS.window_width_ms) '_steps' num2str(ANALYSIS.step_width_ms)...
    '_av' num2str(ANALYSIS.avmode) '_st' num2str(ANALYSIS.stmode) '_DCG' SLIST.dcg_labels{ANALYSIS.dcg_todo} '.mat'];

% List all the available files
% listing = struct2dataset(dir(pattern));
listing = dir(pattern);
files = listing.name;

% How many characters are there before and after the participant number 
% (in the data file name)? This is needed to extract the participant id as a
% numeric variable later on.
before = [study_name '_SBJ'];
after = ['_win' num2str(ANALYSIS.window_width_ms) '_steps' num2str(ANALYSIS.step_width_ms)...
    '_av' num2str(ANALYSIS.avmode) '_st' num2str(ANALYSIS.stmode) '_DCG' SLIST.dcg_labels{ANALYSIS.dcg_todo} '.mat'];
nchar_before = length(before);
nchar_after = length(after);

% Loop through the file names and extract the participant number as a
% numeric variable.
% for i = 1:length(files)
for i = 1:length(files(:,1))
%     file = files{i};
    file = files(i,:);
    number = file((nchar_before+1):(length(file)-nchar_after));
    numbers(i) = str2num(number);
end

% Sort the participant numbers.
numbers = sort(numbers);

% Replace the string 'all' in the argument 'sbjs_todo' by the sorted vector
% of participant numbers of available participant data
sbjs_todo = numbers;
ANALYSIS.nsbj = size(sbjs_todo,2);
ANALYSIS.sbjs = sbjs_todo;

% Clean up
clear pattern listing files before after nchar_before nchar_after i file number numbers



