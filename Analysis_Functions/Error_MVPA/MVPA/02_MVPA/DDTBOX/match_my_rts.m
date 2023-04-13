function [eeg_sorted_cond_matched_rt,ntrials_dcg_todo,final_rts]=match_my_rts(eeg_sorted_cond,rt_sorted_cond,dcg_todo)

%% Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
min_rt = 100; % allowed deviation of rts for match +/- range
eeg_sorted_cond_matched_rt=eeg_sorted_cond; % stays the same if no matching required...
global SLIST;

%% read in data from respective conditions for DCG to do
% can't do all at once, because matching will be different for each condition


% Script modified by André on July 31st, 2018: Replaced all "SLIST{1}" by
% "SLIST". I don't know where the "{1}" came from...


for run=1:SLIST.nruns

    % second one is always error (=less trials, to keep), first one is correct (=to match with errors)
    dk=rt_sorted_cond(run,(SLIST.dcg{dcg_todo}(1,2))); data_to_keep=dk.data; clear dk;
    dm=rt_sorted_cond(run,(SLIST.dcg{dcg_todo}(1,1))); data_to_match=dm.data; clear dm;

    % EEG data in same format as rt_sorted_cond
    teegd=eeg_sorted_cond(run,SLIST.dcg{dcg_todo}(1,1)); temp_eeg_data=teegd.data; clear teegd;
    teegd=eeg_sorted_cond(run,SLIST.dcg{dcg_todo}(1,2)); temp_eeg_data_keep=teegd.data; clear teegd;

    %% sort the data and create array with RTs

    % sort data to keep and index the position (i.e. trial)
    [sort_data_to_keep,I_dtk]=sort(data_to_keep,2);

    kill=find(sort_data_to_keep<min_rt);
    sort_data_to_keep(kill)=[];
    I_dtk(kill)=[];

    %% find middle position and sort from there alternating left and right
    med_sdtk=median(sort_data_to_keep);
    [diff_mid pos_mid] = min(abs(sort_data_to_keep-med_sdtk));

    left=sort_data_to_keep(1:pos_mid-1); 
    left_idx=I_dtk(1:pos_mid-1); 
    size_left=size(left,2);

    right=sort_data_to_keep(pos_mid+1:end); 
    right_idx=I_dtk(pos_mid+1:end);
    size_right=size(right,2);

    % start with larger array...
    if size_left>size_right || size_left==size_right
        first_array=left; first_idx=left_idx;
        sec_array=right; sec_idx=right_idx;
    elseif size_left<size_right
        first_array=right; first_idx=right_idx;
        sec_array=left; sec_idx=left_idx;
    end 

    % ...sort into new array and take indices too
    sort_data_to_keep_draw(1)=sort_data_to_keep(pos_mid);
    I_dtk_draw(1)=I_dtk(pos_mid);

    x=1;
    for step=1:size(first_array,2)

        sort_data_to_keep_draw(x+1)=first_array(step); 
        I_dtk_draw(x+1)=first_idx(step); x=x+1;
        if step<=size(sec_array,2)
            sort_data_to_keep_draw(x+1)=sec_array(step);
            I_dtk_draw(x+1)=sec_idx(step); x=x+1;
        end

    end

    clear sort_data_to_keep; clear I_dtk;
    sort_data_to_keep=sort_data_to_keep_draw; 
    I_dtk=I_dtk_draw;
    
    n_final_trials=size(sort_data_to_keep,2);
    SLIST.n_cond{run,(SLIST.dcg{dcg_todo}(1,1))}=n_final_trials;
    SLIST.n_cond{run,(SLIST.dcg{dcg_todo}(1,2))}=n_final_trials;
    
    ntrials_dcg_todo(run,1)=SLIST.n_cond{run,(SLIST.dcg{dcg_todo}(1,1))};
    ntrials_dcg_todo(run,2)=SLIST.n_cond{run,(SLIST.dcg{dcg_todo}(1,2))};
    ntrials_dcg_todo(run,3)=n_final_trials;
    
    fprintf('Condition %d and %d will have %d trials. \n',SLIST.dcg{dcg_todo}(1,1),SLIST.dcg{dcg_todo}(1,2),n_final_trials);

    %% find matches and select EEG trails accordingly %%%%%%%%%%%%%%%%%%%%%%%%%

    for t=1:size(sort_data_to_keep,2)

        % find the best match using minimal distance
        [d index] = min(abs(data_to_match-sort_data_to_keep(t)));
        closestRT = data_to_match(index);
        data_to_match(index)=0; % keeps index intact but prevents that same value is chosen again

        % save index and RTs
        fprintf('Trial %d: RT(cond %d - keep) %d ms in trial %d matches RT(cond %d - match) %d ms in trial %d. Difference is %d ms. \n',...
            t,SLIST.dcg{dcg_todo}(1,2),sort_data_to_keep(t),I_dtk(t),SLIST.dcg{dcg_todo}(1,1),closestRT,index,d);
        
        final_rts{run,1}(t)=I_dtk(t); % index of error trial in original data
        final_rts{run,2}(t)=sort_data_to_keep(t); % error RT in original data
        final_rts{run,3}(t)=index; % index of correct trial in original data
        final_rts{run,4}(t)=closestRT; % correct RT in original data

        % select respective EEG trial data
        new_eeg_data_matched(:,:,t)=temp_eeg_data(:,:,index);
        new_eeg_data_keep(:,:,t)=temp_eeg_data_keep(:,:,I_dtk(t));

        clear closestRT; clear d; clear index; 

    end % trials

    %% replace old EEG data (for to match condition) with new selected trials % 
    % These will be shuffled again in decoding script to avoid order effects

    eeg_sorted_cond_matched_rt(run,SLIST.dcg{dcg_todo}(1,1)).data=[];
    eeg_sorted_cond_matched_rt(run,SLIST.dcg{dcg_todo}(1,2)).data=[];
    eeg_sorted_cond_matched_rt(run,SLIST.dcg{dcg_todo}(1,1)).data=new_eeg_data_matched;
    eeg_sorted_cond_matched_rt(run,SLIST.dcg{dcg_todo}(1,2)).data=new_eeg_data_keep;

end % run