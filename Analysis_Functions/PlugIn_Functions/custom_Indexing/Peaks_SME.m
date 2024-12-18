
% SME of Peaks
    function SME = Peaks_SME(Subset, Component)
        % similiar to ERPlab toolbox
        % Initate some variables
        n_boots = 100;
        replacement = 1;
        trials = size(Subset,3);
        n_boots = max(trials, n_boots);
        electrodes = size(Subset,1);
        Peak_perTrial = NaN(electrodes,n_boots);
        % Bootstrap and create different ERPS, pick peaks
        for i_bs = 1:n_boots % KP: Previously wrong index here
            rng(i_bs, 'twister')
            bs_trialidx = sort(randsample(1:trials,trials,replacement));
            bs_ERP = squeeze(mean(Subset(:,:,bs_trialidx),3));
            Peak_perTrial(:,i_bs) = Peaks_Detection(bs_ERP, Component);
        end
        
        % use sd of this distribution for SME
        SME = std(Peak_perTrial, [], 2);
    end