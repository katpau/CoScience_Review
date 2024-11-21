pc_a = [4,6,7,10,11,13:15,17:20,24:26,28,30,32,34,37,38];
dcg_1 = 'correct_exp1_part1 vs. correct_exp2_part2';
dcg_2 = 'correct_exp1_part2 vs. correct_exp2_part1';
dcg_3 = 'error_exp1_part1 vs. error_exp2_part2';
dcg_4 = 'error_exp1_part2 vs. error_exp2_part1';
dcg_5 = 'correct_exp2_part1 vs. correct_exp2_part2';
dcg_6 = 'error_exp2_part1 vs. error_exp2_part2';
dcg_7 = 'correct_exp1_part1 vs. correct_exp2_part1';
dcg_8 = 'correct_exp1_part2 vs. correct_exp2_part2';
dcg_9 = 'error_exp1_part1 vs. error_exp2_part1';
dcg_10 = 'error_exp1_part2 vs. error_exp2_part2';
dcg_11 = 'correct_exp1_part1 vs. correct_exp1_part2';
dcg_12 = 'error_exp1_part1 vs. error_exp1_part2';

bdir = 'C:\Users\elisa\Desktop\MVPA_exp1_exp2\03_MVPA_-900to200ms\DECODING_RESULTS\level_1\splithalf_not_rt_matched\';

for part = pc_a
    
 load([bdir, 'ARTDIF_SBJ' num2str(part) '_win10_steps10_av1_st3_DCG' dcg_5 '.mat']) 
 classacc(:,part) = RESULTS.subj_acc;
 permacc(:,part) = RESULTS.subj_perm_acc;
 global SBJTODO;
 SBJTODO = part;
 global SLIST;
 eval(STUDY.sbj_list);  
 clear STUDY RESULTS SBJTODO SLIST
end %part

for j = 1:(length(classacc(1,:)));
    if length(find(classacc(:,j) == 0)) == 110; 
        removerow(j) = 1;
    else removerow(j) = 0;
    end
end

idx = find(removerow == 1);
classacc(:,idx) = [];
clear removerow idx

for j = 1:(length(permacc(1,:)));
    if length(find(permacc(:,j) == 0)) == 110; 
        removerow(j) = 1;
    else removerow(j) = 0;
    end
end

idx = find(removerow == 1);
permacc(:,idx) = [];

diffacc = [classacc(:,:) - permacc(:,:)]; 
diffacc1 = transpose(diffacc);

clear removerow idx permacc diffacc classacc

for part = pc_a
    
 load([bdir, 'ARTDIF_SBJ' num2str(part) '_win10_steps10_av1_st3_DCG' dcg_11 '.mat']) 
 classacc(:,part) = RESULTS.subj_acc;
 permacc(:,part) = RESULTS.subj_perm_acc;
 global SBJTODO;
 SBJTODO = part;
 global SLIST;
 eval(STUDY.sbj_list);  
 clear STUDY RESULTS SBJTODO SLIST
end %part

for j = 1:(length(classacc(1,:)));
    if length(find(classacc(:,j) == 0)) == 110; 
        removerow(j) = 1;
    else removerow(j) = 0;
    end
end

idx = find(removerow == 1);
classacc(:,idx) = [];
clear removerow idx

for j = 1:(length(permacc(1,:)));
    if length(find(permacc(:,j) == 0)) == 110; 
        removerow(j) = 1;
    else removerow(j) = 0;
    end
end

idx = find(removerow == 1);
permacc(:,idx) = [];

diffacc = [classacc(:,:) - permacc(:,:)]; 
diffacc2 = transpose(diffacc);

for i = 1:length(diffacc1)
    [h,p] = ttest(diffacc1(:,i), diffacc2(:,i));
    ttest_values(:,i) = [h,p];
end

ttest_values = transpose(ttest_values);
diff_effects = [diffacc1 - diffacc2];

for i = 1:length(diff_effects)
    mean_effects(:,i) = mean(diff_effects(:,i));
    SD_effects(:,i) = std(diff_effects(:,i));
    d_distribution(:,i) = [mean_effects/SD_effects];
end

significant_differences = sum(ttest_values(:,1));
d = mean(d_distribution)
d_quantile = quantile(d_distribution,3)

for i = 1:length(diffacc1(:,1))
mean_diffacc1(i,:) = mean(diffacc1(i,:));
mean_diffacc2(i,:) = mean(diffacc2(i,:));
end

[h,p] = ttest(mean_diffacc1, mean_diffacc2)
overallmean_diffacc1 = mean(mean_diffacc1)
overallmean_diffacc2 = mean(mean_diffacc2)

clear all