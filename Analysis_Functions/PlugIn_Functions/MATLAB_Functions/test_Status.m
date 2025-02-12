 function Status = test_Status(Folder_to_Test, conn) 
        sqlquery = strcat("SELECT Status FROM ExistingFiles WHERE File = '", Folder_to_Test, "'");
        Status = fetch(conn,sqlquery);
 end

