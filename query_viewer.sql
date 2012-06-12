--sp_who2
declare
    @spid int
,   @stmt_start int
,   @stmt_end int
,   @sql_handle binary(20)

set @spid = 78 -- Fill this in

select  top 1
    @sql_handle = sql_handle
,   @stmt_start = case stmt_start when 0 then 0 else stmt_start / 2 end
,   @stmt_end = case stmt_end when -1 then -1 else stmt_end / 2 end
from    master.dbo.sysprocesses
where   spid = @spid
order by ecid

SELECT
    SUBSTRING(  text,
                COALESCE(NULLIF(@stmt_start, 0), 1),
                CASE @stmt_end
                        WHEN -1
                                THEN DATALENGTH(text)
                        ELSE
                                (@stmt_end - @stmt_start)
                        END
        )
FROM ::fn_get_sql(@sql_handle)



-----
--version2
/*

select t.text, substring(t.text, (r.statement_start_offset/2)+1, 
    ((case r.statement_end_offset when -1 then datalength(t.text)
     else r.statement_end_offset end - r.statement_start_offset)/2) + 1) from sys.dm_exec_requests r 
cross apply sys.dm_exec_sql_text(r.sql_handle) t
where r.session_id=@spid

*/