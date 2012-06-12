USE [MASTER] 
GO 

DECLARE @databasename VARCHAR(300)

SET @databasename = 'Geneva3'
DECLARE @spid_to_kill INT
DECLARE @sql_txt VARCHAR(300)

DECLARE kill_spids CURSOR FOR 
            SELECT spid
            FROM sysdatabases sd, sysprocesses sp 
            WHERE sd.NAME = @databasename
            AND sd.dbid = sp.dbid
            ORDER BY spid
            
OPEN kill_spids

FETCH NEXT FROM kill_spids INTO @spid_to_kill

WHILE @@FETCH_STATUS = 0
BEGIN 
            SET @sql_txt = 'kill ' + CAST(@spid_to_kill AS VARCHAR(10))
            EXEC (@sql_txt)
            FETCH NEXT FROM kill_spids INTO @spid_to_kill
END 

CLOSE kill_spids
DEALLOCATE kill_spids
