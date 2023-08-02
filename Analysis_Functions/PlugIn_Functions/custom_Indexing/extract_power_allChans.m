

function Power_DB = extract_power_allChans(EEG, Electrodes, Freqs, TFBL )



            % Option 1: Over Mean for every Trial
            % Calculate Power
            Power = wavelet_power_2(EEG,'lowfreq', Freqs(1),...
                'highfreq', Freqs(2), ...
                'log_spacing', 1, ...
                'fixed_cycles', 3.5);
            
            % Baseline Correct Power
            TimeIdxBL = findTimeIdx(EEG.times, TFBL(1), TFBL(2));
            % Option one: one mean Baseline for each Tria
            Power_BL = mean(Power(:,TimeIdxBL,:),2);
            Power_BL = repmat(Power_BL, 1, size(Power,2)); % reshape for easier correction
            
             
            Power_DB = Power ./ Power_BL; % add 10*log10() ??? or just for plotting
end