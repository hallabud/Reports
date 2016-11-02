CREATE PROC [dbo].[SERVICE_IndexRebuild]
AS  
SET NOCOUNT ON;
SET LOCK_TIMEOUT 40000;

DECLARE @InTableName NVARCHAR(128);
DECLARE @InIndexName NVARCHAR(128);
DECLARE @InIndexID INT;
DECLARE @InPagesCount BIGINT;
DECLARE @InIndexTypeDescription NVARCHAR(255);
DECLARE @InFragmentationPercent DECIMAL(20,2);
DECLARE @InSQLString NVARCHAR(1024);

SELECT  @InTableName='';
SELECT  @InIndexName='';
SELECT  @InIndexID=0;
SELECT  @InPagesCount=0;
SELECT  @InIndexTypeDescription='';
SELECT  @InFragmentationPercent=0.00;
SELECT  @InSQLString='';

DECLARE @InAddedRecord TABLE(IndexRebuildLog_ID INT);
DECLARE @InAddedRecordID INT;

DECLARE @InFlag INT;

SELECT  @InFlag=0;

DECLARE cIndexCursor CURSOR LOCAL FAST_FORWARD READ_ONLY
 FOR
 (
   SELECT 
    OBJECT_NAME(A.[object_id]) as TableName,
    B.[name] as IndexName,
    A.[index_id],
    A.[page_count],
    A.[index_type_desc],
    A.[avg_fragmentation_in_percent]/*,
    A.[fragment_count]*/
   FROM
    sys.dm_db_index_physical_stats(db_id(),NULL,NULL,NULL,'LIMITED') A INNER JOIN
    sys.indexes B ON A.[object_id] = B.[object_id] and A.index_id = B.index_id 
    WHERE B.[name] IS NOT NULL
    AND OBJECT_NAME(A.[object_id])NOT LIKE 'MS%' 
    AND OBJECT_NAME(A.[object_id])NOT LIKE 'MCC_BACKUP%'
 )ORDER BY TableName,IndexName


OPEN cIndexCursor;

FETCH NEXT FROM cIndexCursor INTO @InTableName,@InIndexName,@InIndexID,
@InPagesCount,@InIndexTypeDescription,@InFragmentationPercent

WHILE @@FETCH_STATUS=0
 BEGIN--START CURSOR
 
 INSERT dbo.SERVICE_IndexRebuildLog(IndexName,StartDate,StopDate,TABLENAME)
  OUTPUT INSERTED.IndexRebuildLog_ID INTO @InAddedRecord
 VALUES(@InIndexName,GETDATE(),NULL,@InTableName)
 
 SELECT @InAddedRecordID=A.IndexRebuildLog_ID
  FROM @InAddedRecord A; 
 
 IF(@InFragmentationPercent BETWEEN 5.00 AND 30.00)
  BEGIN
   SELECT @InSQLString='ALTER INDEX '+@InIndexName+' '+
    'ON '+@InTableName+' '+' REORGANIZE';
    
	-- логирование сгенерированного кода
	--INSERT INTO dbo._temp_SQLString (SQLString) VALUES (@InSQLString);

   EXEC @InFlag=sp_executesql @InSQLString;
   
   --ОШИБКА
   IF(@InFlag<>0)
    BEGIN--^^
     INSERT dbo.SERVICE_BlockLog
      (
       DBName,WhoIsBlocked,BlockedLogin,
       BlockerID,BlockerLogin,BlockerQuery
      )
      SELECT DB_NAME(pr1.dbid)
      ,pr1.spid 
      ,RTRIM(pr1.loginame)
      ,pr2.spid 
      ,RTRIM(pr2.loginame)
      ,txt.[text]
       FROM   MASTER.dbo.sysprocesses pr1(NOLOCK)
       JOIN MASTER.dbo.sysprocesses pr2(NOLOCK)
            ON  (pr2.spid = pr1.blocked)
       OUTER APPLY sys.[dm_exec_sql_text](pr2.[sql_handle]) AS txt
       WHERE  pr1.blocked <> 0
    END--^^
   
  END
 
 IF(@InFragmentationPercent>30.00)
  BEGIN
    SELECT @InSQLString='ALTER INDEX '+@InIndexName+' '+
    'ON '+@InTableName+' '+' REBUILD';
    
	-- логирование сгенерированного кода
	--INSERT INTO dbo._temp_SQLString (SQLString) VALUES (@InSQLString);

    EXEC @InFlag=sp_executesql @InSQLString;
    
    --ОШИБКА
   IF(@InFlag<>0)
    BEGIN--^^
       INSERT dbo.SERVICE_BlockLog
        (
          DBName,WhoIsBlocked,BlockedLogin,
          BlockerID,BlockerLogin,BlockerQuery
        )
        SELECT DB_NAME(pr1.dbid)
      ,pr1.spid 
      ,RTRIM(pr1.loginame)
      ,pr2.spid 
      ,RTRIM(pr2.loginame)
      ,txt.[text]
       FROM   MASTER.dbo.sysprocesses pr1(NOLOCK)
       JOIN MASTER.dbo.sysprocesses pr2(NOLOCK)
            ON  (pr2.spid = pr1.blocked)
       OUTER APPLY sys.[dm_exec_sql_text](pr2.[sql_handle]) AS txt
       WHERE  pr1.blocked <> 0
    END--^^
    
  END 
  --SET @sql = 'ALTER INDEX ALL ON ' + @TableName + 
  --' REBUILD WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ')'
  UPDATE dbo.SERVICE_IndexRebuildLog SET
   StopDate=GETDATE()
   WHERE IndexRebuildLog_ID=@InAddedRecordID; 
  
    
  SELECT  @InTableName='';
  SELECT  @InIndexName='';
  SELECT  @InIndexID=0;
  SELECT  @InPagesCount=0;
  SELECT  @InIndexTypeDescription='';
  SELECT  @InFragmentationPercent=0.00;
  SELECT  @InSQLString='';
  
  DELETE @InAddedRecord;
  SELECT @InAddedRecordID=0;
  
  FETCH NEXT FROM cIndexCursor INTO @InTableName,@InIndexName,@InIndexID,
  @InPagesCount,@InIndexTypeDescription,@InFragmentationPercent
  
 END--END CURSOR
CLOSE cIndexCursor;
DEALLOCATE cIndexCursor; 