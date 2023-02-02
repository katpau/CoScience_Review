
load('participants.mat')
r = 1;

for i = participants
    
    filename = ['C:\Users\elisa\Desktop\MVPA_exp1_exp2\02_Preprocessing\PreprocessedData\-900_to_200_ms\splithalf\',num2str(i),'.mat'];
    load(filename, 'info');
    
    trials(r,:) = [i info.n_EC info.n_EN info.n_CC info.n_CN i info.n_EB info.n_ER info.n_CB info.n_CR info.n_total];
    
    r = r+1;

    
end