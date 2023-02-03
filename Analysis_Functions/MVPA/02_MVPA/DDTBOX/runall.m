%% Description
% This functions calls the first-level MVPA analyses for all indexed
% participants

%% Specifications
participants = [1:2]; % index of participants in PreprocessedData to analyse

%% Run all
error = 1;
for part = participants
    for group = 1
        try
            DECODING_ERP('coscience', 1, 0, part, group, 0);
        catch
            protocol(error, 1) = part;
            protocol(error, 2) = group;
            error = error + 1;
        end 
    end 
end 


