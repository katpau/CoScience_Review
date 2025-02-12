pc_a = [2,4,7,10,11,13:15,17:20,24:26,28,30,32,34,37,38];
pc_b = [2,4];

bdir = 'C:\Users\elisa\Desktop\MVPA_exp1_exp2\03_MVPA_-900to200ms\DECODING_RESULTS\level_1\splithalf_not_rt_matched\';

for part = pc_a
    
 load([bdir, 'ARTDIF_SBJ' num2str(part) '_win10_steps10_av1_st3_DCGcorrect_exp1_part1 vs. correct_exp2_part2.mat']) 
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

%dcg_1([1:length(classacc(:,1))],1) = 1;
%classacc = [classacc,dcg_1];

for part = pc_a
 load([bdir, 'ARTDIF_SBJ' num2str(part) '_win10_steps10_av1_st3_DCGcorrect_exp1_part1 vs. correct_exp2_part1.mat']) 
 classaccb(:,part) = RESULTS.subj_acc;
 global SBJTODO;
 SBJTODO = part;
 global SLIST;
 eval(STUDY.sbj_list);
 clear STUDY RESULTS SBJTODO SLIST
end %part


for j = 1:(length(classaccb(1,:)));
    if length(find(classaccb(:,j) == 0)) == 110; 
        removerow2(j) = 1;
    else removerow2(j) = 0;
    end
end

idx2 = find(removerow2 == 1);

classaccb(:,idx2) = [];

