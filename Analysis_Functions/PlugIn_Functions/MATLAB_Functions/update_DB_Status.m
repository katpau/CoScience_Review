 function update_DB_Status(Folder_to_Test, newstatus, conn)
    sqlquery = strcat("SELECT Status FROM ExistingFiles WHERE Folder = '", Folder_to_Test, "'");
    Entry_in_DB = ~isempty(fetch(conn,sqlquery));

    if Entry_in_DB == 1
        sqlquery = strcat("UPDATE ExistingFiles SET Status = '", char(newstatus), ...
        "' WHERE Folder = '", char(Folder_to_Test), "'");
        exec(conn,sqlquery)
    else
        insert(conn,'ExistingFiles',{'Folder','Status'}, {char(Folder_to_Test), char(newstatus)})
    end
 end
