 function Status = test_DB_Status(Folder_to_Test, conn) 
        sqlquery = strcat("SELECT Status FROM ExistingFiles WHERE Folder = '", Folder_to_Test, "'");
        Status = fetch(conn,sqlquery);
 end

