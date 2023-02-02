pc_a = 1;
pc_b = [];
pc_c = [];
error = 1;


for part = pc_a
    
    for group = 1
        
        try
            
            DECODING_ERP_coscience('ARTDIF', 7, 0, part, group, 0);
            
        catch
            
            protocol(error, 1) = part;
            protocol(error, 2) = group;
            error = error + 1;
            
        end %trycatch
        
    end %group
    
end %part


