function prep_mvpa_all(first_part, last_part)

%% Description
% This simple function allows to run the function prep_mvpa on several participants without
% having to reiniciate for each participant.

%% Input
% first_part = index of first participant in folder to analyse
% last_part = index of last participant in folder to analyse 

%% run for all specified participants

for current_part = first_part:last_part
    
    try
        
        prep_mvpa(current_part)
        
    catch
        
        fprintf('Participant %d does not exist \n', current_part)
        
    end
    
end