  function InfoSummary = APPLE_corr(EEG, VEOGidx) 
  % Algorithmic Pre-Processing Line for EEG
    % Intellectual Property of James F Cavanagh   jcavanagh@unm.edu    2013
    % Section on selection on ICAs of occular movements selected by KP 07/01/2020
    
    % INPUT
    % EEG       - EEGlab array (can be continous or epoched), must include ICA
    %             activity
    % VEOGidx   - Idx of VEOG channels to calculate Difference
    
    % OUTPUT
    % InfoSummary   - Structure containing the following fields 
    %                  VEOG_badIC / BlinkTemplate_badIC containing the marked ICA components 
    %                  VEOG_Correlation / BlinkTemplate_Correlation containing the correlations of all ICA components

    
    if ~isfield(EEG,'icaact') || isempty(EEG.icaact)
     EEG.icaact = eeg_getica(EEG);
    end
    
    % make continous if trials (better for correlations)
    if size(EEG.data,3) > 1
        EEG.data = reshape(EEG.data, size(EEG.data,1), []);
        EEG.icaact = reshape(EEG.icaact, size(EEG.icaact,1), []);
    end
    VEOG = squeeze(EEG.data(VEOGidx(1),:)-EEG.data(VEOGidx(2),:));

    % Criteria 1: Correlation with VEOG
    VEOG_ICA_Corrs = NaN(size(EEG.icaact,1),1);
    for ai=1:size(EEG.icaact,1)
        VEOG_ICA_Corrs(ai)=abs(corr((EEG.icaact(ai,:))',VEOG')); % Correlation of each ICA activity with VEOG
    end
    % Select correlations with z > 3
    bad_VEOG_ICAs=find(abs(zscore(VEOG_ICA_Corrs))>3);
    % in case z-scores are too tightly distributed
    if isempty(bad_VEOG_ICAs), bad_VEOG_ICAs=find(VEOG_ICA_Corrs==max(abs(VEOG_ICA_Corrs))); end 

    % Criteria 2: Correlation with blink Template
    % Bootstrap a blink Template based on Gaussian distros around most frontopolar channels
    % Get the most FrontoPolar Sites
    for ai=1:size(EEG.data,1), X(ai)=EEG.chanlocs(ai).X; end
    FrontoPolars=find(X==max(X));  clear X;
    % Make Gaussian Template - code taken from Mike X Cohen
    for fpi=1:length(FrontoPolars)
        e2use=FrontoPolars(fpi);
        eucdist=zeros(1,size(EEG.icawinv,1)); 
        for chani=1:size(EEG.icawinv,1)
            eucdist(chani)=sqrt( (EEG.chanlocs(chani).X-EEG.chanlocs(e2use).X)^2 + (EEG.chanlocs(chani).Y-EEG.chanlocs(e2use).Y)^2 + (EEG.chanlocs(chani).Z-EEG.chanlocs(e2use).Z)^2 );
        end
        s=30;   
        Template(fpi,:) = exp(- (eucdist.^2)/(2*s^2) );
    end
    Template=mean(Template,1);
    % Get each ICA topo correlation with this topo Template
    topocorr=zeros(1,size(EEG.icawinv,1));
    for chani=1:size(EEG.icawinv,2)
        topocorr(chani) = corr(EEG.icawinv(:,chani),Template');
    end
    % Select the max correlations
    bad_Template_ICAs=find(abs(zscore(topocorr))>3);
    % in case z-scores are too tightly distributed
    if isempty(bad_Template_ICAs)
        bad_Template_ICAs=find(abs(topocorr)==max(abs(topocorr)));
    end 
    
    InfoSummary = struct('VEOG_badIC', bad_VEOG_ICAs, 'VEOG_Correlation', VEOG_ICA_Corrs, 'BlinkTemplate_badIC', bad_Template_ICAs, 'BlinkTemplate_Correlation', topocorr);
  end
