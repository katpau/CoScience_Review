% SME of Values in Difference Wave
    function SME = DifferenceWave_SME(Subset1, Subset2, Component)
        % similiar to ERPlab toolbox
        % Initate some variables
        n_boots = 100;
        replacement = 1;
        trials1 = size(Subset1,3);
        trials2 = size(Subset2,3);
        electrodes = size(Subset1,1);
        Peak_perBoot = NaN(electrodes,n_boots);
        % Bootstrap and create different ERPS, pick peaks
        for i_bs = 1:n_boots
            rng(i_bs, 'twister')
            bs_trialidx1 = sort(randsample(1:trials1,trials1,replacement));
            bs_trialidx2 = sort(randsample(1:trials2,trials2,replacement));
            bs_ERP = squeeze(mean(Subset1(:,:,bs_trialidx1),3)- ...
                             mean(Subset2(:,:,bs_trialidx2),3));
             if Component == "MEAN"
                Peak_perBoot(:,i_bs) = mean(bs_ERP,2);
             else
                Peak_perBoot(:,i_bs) = Peaks_Detection(bs_ERP, Component);
             end
        end
        % use sd of this distribution for SME
        SME = std(Peak_perBoot, [], 2);
    end
    