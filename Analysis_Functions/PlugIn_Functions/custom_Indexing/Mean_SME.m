
% SME of Mean Values
    function SME = Mean_SME(Subset)
        % Calculate Mean per Trial
        Mean_perTrial = squeeze(mean(Subset,2));
        % Take SD of these means
        if size(Mean_perTrial,2) == 1
            SME = std(Mean_perTrial,[],1)/sqrt(length(Mean_perTrial));
        else
            SME = std(Mean_perTrial,[],2)/sqrt(length(Mean_perTrial));
        end
    end
