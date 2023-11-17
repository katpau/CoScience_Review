function [wavelet_power_vals frex] = wavelet_power_2b(EEG,varargin);

% Function to output wavelet-based alpha power
%
% Computational code is adapted from Chapter 31, Graph Theory, Analyzing Neural Time Series Data
% by Mike X Cohen, January 2014.  Adapted code sections are noted.
%
% Input is EEGLab structure of epoched EEG data.  The function computes
% wavelet-based power in a specified band.  If no band is specified, it
% returns power in the alpha band.
% Output is chans by epochs matrix and list of wavelet frequencies
%
%
% Optional inputs (in any order, a combination of keyword and parameter)
%
%  'lowfreq':          lower frequency cutoff for tf-analysis (default = 7.5)
%  'highfreq':         upper frequency cutoff for tf-analysis (default = 13.5)
%  'log_spacing:       1 for log spacing, 0 for linear (default = 1 log)
%  'fixed_cycles'      # of cycles (suggestd range 3-10); if omitted
%                       keyword, use variable cycles so all wavelets same
%                       length (1 second)
%
% Sample usage specifying all parameters
%
%  [wavelet_power_vals frex] = wavelet_power(EEG, 'lowfreq', 7.5, 'highfreq', 13.5, 'log_spacing', 1, 'fixed_cycles', 4.5);
%
% Created March, 2016, by John JB Allen (jallen@email.arizona.edu)
% Edited December, 2016 by Johannes Rodrigues (Jojo, johannes.rodrigues@uni-wuerzburg.de)


%% Make sure this will run or return errors
% Check that arguments are properly specificied
% Check that EEGLab is avaialble for plotting
% Assign defaults for non-specified parameters

% Is EEGLab in the path?  If not , abort function and return to previous control
if ~exist('topoplot.m','file')
    disp('It appears you did not add EEGLab to the path.');
    return
end

% specify list of possible valid keywords for this function
valid_keywords = {'lowfreq','highfreq', 'log_spacing', 'fixed_cycles' };

% Must specify at least one and at most 3 arguments
narginchk(1,9);

% next check that varargin arguments come in pairs and are the proper type
for n_param = 1:2:length(varargin) % first, third, fifth etc should be keywords
    validateattributes(varargin{n_param},{'char'},{'nonempty'},mfilename);
    if ~ismember(valid_keywords, varargin(n_param))
        disp(['''' varargin{n_param} '''' 'is not a valid keyword.']);
        disp(' Valid keywords are:');
        disp('    lowfreq, highfreq, log_spacing, fixed_cycles');
        doc wavelet_power;
        return
    end
end

% Next parse parameter string and check variable type
% If it is proper, then assign the variables that the users specified
params_proper = true;
for n_param = 1:2:length(varargin) % every other one is a keyword
    switch varargin{n_param}
        case 'lowfreq'                        % if this keyword is found, then we'll assign the variable and check type
            lowfreq = varargin{n_param + 1};  % parameter following the keyword is assigned
            if ~isscalar(lowfreq)             % check variable type, and if wrong, set boolean and set message for later feedback and abort of function
                params_proper = false;
                helpful_message = ['''lowfreq''' ' must be a single number'];
            end
        case 'highfreq'
            highfreq = varargin{n_param + 1};
            if ~isscalar(highfreq)
                params_proper = false;
                helpful_message = ['''highfreq''' ' must be a single number'];
            end
        case 'log_spacing'
            log_spacing = varargin{n_param + 1};
            if ~isscalar(log_spacing)
                params_proper = false;
                helpful_message = ['''log_spacing''' ' must be a single number'];
            end
        case 'fixed_cycles'
            fixed_cycles = varargin{n_param + 1};
            if ~isscalar(fixed_cycles)
                params_proper = false;
                helpful_message = ['''fixed_cycles''' ' must be a single number'];
            end
        otherwise
            % not needed since we validated all possible cases above using validateattributes
    end
    if ~params_proper % we found an improper input
        disp(helpful_message);  % do this here so that we only have to do this one time instead of in every 'case' section above
        return
    end
end

% Assign defaults if user did not specify
if ~exist('lowfreq','var')              % checking iif it is a variable
    lowfreq = 7.5;                        % assigning default, and then creating user message
    display('Assigning default low frequency cutoff of 7.5 Hz for time-frequency power');
end
if ~exist('highfreq','var')
    highfreq = 13.5;
    display('Assigning default high frequency of 13.5 Hz for time-frequency power');
end
if ~exist('log_spacing','var')
    log_spacing = 1;
    display('Assigning default log scaling for frequencies');
end
if ~exist('fixed_cycles','var')
    fixed_cycles = 0;
    display('Assigning default variable cycles so all wavelets are 1 second long');
end



%% Code in this cell derives from Chapter 31, Graph Theory, ==============================================
% provided to accompany the book Analyzing Neural Time Series Data
% by Mike X Cohen, January 2014.  Any alterations noted by JJBA.

numfreq = 2*(highfreq-lowfreq)+1;
num_cycles = 4.5;

% wavelet and FFT parameters
time          = -1:1/EEG.srate:1;
half_wavelet  = (length(time)-1)/2;
n_wavelet     = length(time);
n_data        = EEG.pnts*EEG.trials;
n_convolution = n_wavelet+n_data-1;
n_conv2       = pow2(nextpow2(n_convolution));


if log_spacing
    % Define log-spaced frequencies for t-f decomposition (Comment by JJBA)
    frex = logspace(log10(lowfreq),log10(highfreq),numfreq);
    s = logspace(log10(lowfreq),log10(highfreq),length(frex))./(2*pi.*frex);
else
    % Define linear-spaced frequencies for t-f decomposition (Added by JJBA)
    frex = linspace(lowfreq,highfreq,numfreq);
    s = linspace(lowfreq,highfreq,numfreq)./(2*pi.*frex);
end

if fixed_cycles > 0
    % Constant number of cycles
    s = fixed_cycles*ones(1,length(frex))./(2*pi.*frex);
end

% create wavelet (and take FFT)
wavelets_fft = zeros(length(frex),n_conv2);

for fi=1:length(frex)
    wavelets_fft(fi,:) = fft( exp(2*1i*pi*frex(fi).*time) .* exp(-time.^2./(2*(s(fi)^2))) ,n_conv2);
end

% find time indices
% dsearchn finds the closest point, which is important since not every time
% specfied by the user will be an exact time represented in the file, as this
% may depend on the sample rate (Comment by JJBA)
times2saveidx = dsearchn(EEG.times',EEG.times');
times2save = EEG.times;


% initialize matrices
alldata    = zeros(EEG.nbchan,length(frex),length(times2save),EEG.trials); % chans by freqs by time by epochs

% first, run convolution for all electrodes and save results

fprintf('%s','Computing t-f decomposition ..');   % inserted by JJBA -- give user some idea what's happening
% since this takes a bit of time (JJBA Added)

for chani=1:EEG.nbchan
    
    % FFT of activity at this electrode (note that
    % this is done outside the frequency loop)
    eeg_fft = fft(reshape(EEG.data(chani,:,:),1,[]),n_conv2);
    
    if mod(chani,round(EEG.nbchan/10)) == 0     % inserted by JJBA -- puts out percent complete approx every 10%
        fprintf('%s %s',num2str(round(100*chani/EEG.nbchan)),'%.. ');
    end
    
    
    % loop over frequencies
    for fi=1:length(frex)
        
        % analytic signal from target
        conv_res = ifft(wavelets_fft(fi,:).*eeg_fft,n_conv2);
        conv_res = conv_res(1:n_convolution);
        asig     = reshape(conv_res(half_wavelet+1:end-half_wavelet),EEG.pnts,EEG.trials);
        
        % store the required time points
        alldata(chani,fi,:,:) = asig(times2saveidx,:);
        
    end % end frequency loop
end % end channel loop

fprintf('\n');  % inserted by JJBA -- returns cursor on console after showing percents


%Jojo: Changed Output 

%power_collpsed_over_time = squeeze(mean(abs(alldata).^2,3));
%key_freqs = frex >= lowfreq & frex <= highfreq;
%disp(['Calculating power from ' num2str(frex(find(key_freqs,1, 'first'))) ' to ' num2str(frex(find(key_freqs,1, 'last'))) ' Hz']);
%wavelet_power_vals = squeeze(mean(power_collpsed_over_time(:,key_freqs,:),2));



% END OF MIKE'S CODE (above) ==============================================




%Jojo: Changed Output to an array with dimensions: Channels, Time (in data points, depends on sampling rate), Trials

power_not_collpsed_over_time = (abs(alldata).^2); % removed squeeze KP 05/12/22
key_freqs = frex >= lowfreq & frex <= highfreq; 
disp(['Calculating power from ' num2str(frex(find(key_freqs,1, 'first'))) ' to ' num2str(frex(find(key_freqs,1, 'last'))) ' Hz']);
%wavelet_power_vals = squeeze(mean(power_not_collpsed_over_time(:,key_freqs,:),2)); 
%wavelet_power_vals = squeeze(mean(power_not_collpsed_over_time,2)); % collapse over frequencies
%wavelet_power_vals = reshape(wavelet_power_vals, size(alldata,1), size(alldata,3), size(alldata,4)); % added KP 05/12/22 reshape to keep singleton first dimension as channels might be only 1!
%wavelet_power_vals = power_not_collpsed_over_time;
wavelet_power_vals = reshape(power_not_collpsed_over_time, size(alldata,1), size(alldata,3), size(alldata,4), size(alldata,2)); % added KP 05/12/22 reshape to keep singleton first dimension as channels might be only 1!
