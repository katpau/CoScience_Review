
pc_a = [1:4 6:32 34:35 37:39];
pc_b = [37:39];

bdir = 'C:\Users\elisa\Desktop\MVPA_exp1_exp2\03_MVPA_-900to200ms\DECODING_RESULTS\level_1\stimuluslocked\'

for part = pc_a
    
 load([bdir, 'ARTDIF_SBJ' num2str(part) '_win10_steps10_av1_st3_DCGcorrect_exp2 vs. error_exp2.mat']) 
 global SBJTODO;
 SBJTODO = part;
 global SLIST;
 eval(STUDY.sbj_list);
 display_indiv_results_erp(STUDY, RESULTS)
 clear STUDY RESULTS SBJTODO SLIST
    
end %part


