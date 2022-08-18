function EEG_cor = gratton( EEG, eeg_channels, veog_channels, crit, win)
% % gratton() - Applies Ocular Correction as specified by Gratton et al.,
% %             1983 to the EEG-data using channel eog for regression.
% % This script follows the implementation of Matthias Mittner, changes
% % concern only the way the input is parsed

% % Usage:
% %   >>  corrected_EEG = gratton(EEG, eeg_channels, veog_channels, window,
% %   criteria, heog_channels, window_heog, criteria_heog, windowidth, make_Plot);
% 
% % Inputs:
% % EEG               - to be corrected EEG data, eeglab format
% % eeg_channels      - array of channels to be corrected (others will be
% %                     deleted!)
% % veog_channels     - array of channels with veog data 
% % crit             - criteria_veog, integer, voltage sufficient for blink detection
% % win             - window_width, integer, for relative differences. eg. if
% %                   window_width is 20, then every datapoint is compared to
% %                   the datapoints 20 sampling points earlier and later and
% %                   checked if any of them exceed threshold.
% % Outputs:
% % EEG_cor             - EEGlab format, corrected data only including eeg_channels. 



% Input type changed to make it easier to use (i.e. gives and takes EEG
% structure, therefore needed to take indices not data)
eeg = EEG.data(eeg_channels,:,:); %added KP 15/05/2022 
eog = squeeze(EEG.data(veog_channels(1),:,:)- EEG.data(veog_channels(2),:,:));  %added KP 15/05/2022      
            
if nargin < 2
	help gratton;
	return;
end;

[el times trials] = size(eeg);
ceeg = eeg;
assert(all([times trials] == size(eog)), 'bad input data dimensions');

avg = mean(eeg, 3); % avg trials
neeg = eeg - repmat(avg, [1 1 trials]);
neog = eog - repmat(mean(eog, 2), [1 trials]);

% detect blinks
winhalf = round(win/2);
blinks = logical(zeros(size(eog)));
blinks(winhalf+1:end-winhalf,:) = ((2*eog(winhalf+1:end-winhalf,:)-(eog(1:end-win,:)+eog(win+1:end,:)))>crit);
% blinks = ((eog-circshift(eog, [winhalf 0]))+...
%     (eog-circshift(eog, [-winhalf 0])))>crit;
disp(sprintf('  gratton(): Found blinks in %i points', length(find(blinks>0))));

% loop through electrodes and get the K's
Kblinks = []; % coefficients within blinks
K = [];       % coefficients outside blinks
x = neog(:);
b = logical(blinks(:));

% correction within blinks if appropriate
if any(any(blinks))
    for e = 1:el
        y = reshape(neeg(e,:,:), [times trials]);
        y = y(:);
        Kblinks = [Kblinks regress(y(b), x(b))];
    end;
    disp(' gratton(): Coefficients within blinks:');
    disp(Kblinks);
    minus = (repmat(Kblinks', [1 times trials]).*shiftdim(repmat(eog, [1 1 el]), 2));
    ceeg(blinks) = eeg(blinks) - minus(blinks);
    avg = mean(ceeg, 3); % avg trials
    neeg = ceeg - repmat(avg, [1 1 trials]);
    disp(' gratton(): Corrected EEG within blinks');
end;

% correction outside of blinks
for e = 1:el
    y = reshape(neeg(e,:,:), [times trials]);
    y = y(:);
    K = [K regress(y, x)];
end;

disp(' gratton(): Coefficients outside of blinks:');
disp(K);
ceeg = ceeg - (repmat(K', [1 times trials]).*shiftdim(repmat(eog, [1 1 el]), 2));
disp(' gratton(): Corrected EEG outside of blinks');

EEG_cor = pop_select( EEG, 'channel', eeg_channels);  %added KP 15/05/2022 
EEG_cor.data = ceeg; %added KP 15/05/2022 