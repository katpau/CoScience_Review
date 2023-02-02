function prep_mvpa_coscience_all(first_part, last_part)

%% This simple function allows to run the function prep_mvpa on several participants without
% having to reiniciate for each participant.


for current_part = first_part:last_part
    
    try
        
        prep_mvpa_coscience(current_part)
        
    catch
        
        fprintf('Participant %d does not exist \n', current_part)
        
    end
    
end