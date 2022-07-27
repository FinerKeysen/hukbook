

```mssql
USE master
GO

-- create table
IF NOT EXISTS (SELECT * 
       FROM sys.objects 
       WHERE OBJECT_ID = OBJECT_ID(N'[dbo].[filestats]') 
       AND type IN (N'U'))
BEGIN
   CREATE TABLE filestats
    (dbname  VARCHAR(128),
    fName  VARCHAR(2048), 
    timeStart  datetime,
    timeEnd datetime,
    timeDiff bigint,
    readsNum1 bigint,
    readsNum2 bigint,
    readsBytes1 bigint,
    readsBytes2 bigint,
    readsIoStall1 bigint,
    readsIoStall2 bigint,
    writesNum1 bigint,
    writesNum2 bigint,
    writesBytes1 bigint,
    writesBytes2 bigint,
    writesIoStall1 bigint,
    writesIoStall2 bigint,
    ioStall1 bigint,
    ioStall2 bigint
    )
END

-- clear data
TRUNCATE TABLE dbo.filestats

-- insert first segment counters
INSERT INTO dbo.filestats
   (dbname,
   fName, 
   TimeStart,
   readsNum1,
   readsBytes1,
   readsIoStall1, 
   writesNum1,
   writesBytes1,
   writesIoStall1, 
   IoStall1
   )
SELECT 
   DB_NAME(a.dbid) AS Database_name,
   b.filename,
   GETDATE(),
   numberReads,
   BytesRead,
   IoStallReadMS,
   NumberWrites,
   BytesWritten,
   IoStallWriteMS,
   IoStallMS
FROM 
   fn_virtualfilestats(NULL,NULL) a INNER JOIN
   sysaltfiles b ON a.dbid = b.dbid AND a.fileid = b.fileid
ORDER BY 
   Database_Name

/*Delay second read */
WAITFOR DELAY '000:00:10'

-- add second segment counters
UPDATE dbo.filestats 
SET 
   timeEnd = GETDATE(),
   readsNum2 = a.numberReads,
   readsBytes2 = a.BytesRead,
   readsIoStall2 = a.IoStallReadMS ,
   writesNum2 = a.NumberWrites,
   writesBytes2 = a.BytesWritten,
   writesIoStall2 = a.IoStallWriteMS,
   IoStall2 = a.IoStallMS,
   timeDiff = DATEDIFF(s,timeStart,GETDATE())
FROM 
   fn_virtualfilestats(NULL,NULL) a INNER JOIN
   sysaltfiles b ON a.dbid = b.dbid AND a.fileid = b.fileid
WHERE   
   fName= b.filename AND dbname=DB_NAME(a.dbid)

-- select data
SELECT 
   dbname,
   fName,
   timeDiff,
   readsNum2 - readsNum1 AS readsNumDiff,
   readsBytes2 - readsBytes1 AS readsBytesDiff,
   readsIoStall2 - readsIOStall1 AS readsIOStallDiff,
   writesNum2 - writesNum1 AS writesNumDiff,
   writesBytes2 - writesBytes1 AS writesBytesDiff,
   writesIoStall2 - writesIOStall1 AS writesIOStallDiff,   
   ioStall2 - ioStall1 AS ioStallDiff
FROM dbo.filestats
```

