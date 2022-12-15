
% SME of PeakDifference
    function SME = Peaks_to_Peak_SME(Subset, Component, Subset2, Component2)
        % similiar to ERPlab toolbox
        % Initate some variables
        n_boots = 100;
        replacement = 1;
        trials = size(Subset,3);
        electrodes = size(Subset,1);
        Peak_perBoot = NaN(electrodes,n_boots);
        % Bootstrap and create different ERPS, pick peaks
        for i_bs = 1:n_boots
            rng(i_bs, 'twister')
            bs_trialidx = sort(randsample(1:trials,trials,replacement));
            bs_ERP = squeeze(mean(Subset(:,:,bs_trialidx),3));
            bs_ERP2 = squeeze(mean(Subset2(:,:,bs_trialidx),3));
            Peak_perBoot1 = Peaks_Detection(bs_ERP, Component);
            Peak_perBoot2 = Peaks_Detection(bs_ERP2, Component2);
            Peak_perBoot(:,i_bs)=Peak_perBoot1-Peak_perBoot2;
        end
        % use sd of this distribution for SME
        SME = std(Peak_perBoot, [], 2);
    end