USE [CAD911_RMS_94]
GO
/****** Object:  StoredProcedure [dbo].[sp_CADLink_XML2Table]    Script Date: 6/4/2020 10:24:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_CADLink_XML2Table]
AS


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Section 1. Save each XML file into the DirectoryTree in tempDB.
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

SET NOCOUNT ON
 
Declare @FilePath varchar(100);
DECLARE @tmpmsg varchar(200);

set @FilePath = 'D:\RMSfiles\';

DECLARE @LogFile varchar(100);
Set @LogFile = @FilePath + 'log\log' + Convert(varchar(100), GETDATE(), 110) + '.txt';

EXEC sp_WriteToFile @LogFile, ' - Step # 1 - Read directory and insert each filename into the locally scoped DirectoryTree Table';

DECLARE @DirectoryTree TABLE (
      filename nvarchar(512)
      ,depth int
      ,isfile bit);

INSERT INTO @DirectoryTree (filename,depth,isfile)
EXEC master.sys.xp_dirtree @FilePath,1,1;

declare @DirectoryTreeCount as VarChar(1000);
 select @DirectoryTreeCount =  Cast( ( select Count(*) from @DirectoryTree ) as VarChar(1000) );

set @tmpmsg = ' - Step # 1 - Total number of files found in directory - ' +  @DirectoryTreeCount;
EXEC sp_WriteToFile @LogFile, @tmpmsg;

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Section 2. Read each existing XML file into a XML holder table
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

EXEC sp_WriteToFile @LogFile, ' - Step # 2 - Save XML file contents into table RMSwithOpenXML.';

DECLARE @ErrorMessage NVARCHAR(4000);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;

Declare @FileName varchar(200);
Declare @Process_Date datetime;
Declare @sqlcmd as nvarchar(300);
DECLARE @jcount int = 0  ;

DECLARE @ErrFolder varchar(100);
Set @ErrFolder = @FilePath + 'ExceptionXML' ;
	
DECLARE cr_xmlFileList cursor for
SELECT filename FROM @DirectoryTree
WHERE isfile = 1 AND RIGHT(filename,4) = '.xml'  
ORDER BY filename desc;

Open cr_xmlFileList;

set @Process_Date = GETDATE();
FETCH NEXT FROM cr_xmlFileList
INTO @FileName;

TRUNCATE TABLE CAD911_RMS_94.dbo.RMSwithOpenXML;

-- Check @@FETCH_STATUS to see if there are any more rows to fetch.
WHILE @@FETCH_STATUS = 0
BEGIN

	begin try  -- error trapping
	
		Select @FileName = @FilePath + @FileName;

		Set @sqlcmd = '
			INSERT INTO CAD911_RMS_94.dbo.RMSwithOpenXML( XMLData, xmlFileName)
			SELECT  CONVERT(XML, BulkColumn) AS BulkColumn, ''' + @FileName + '''
			FROM OPENROWSET(BULK ''' + @FileName + ''', SINGLE_BLOB) as x
			';

		
		Exec master.sys.sp_executesql @sqlcmd;
		
	  end try
	  begin catch
		-- Action to be taken here, such as to move the file to an exception folder.

		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();

			--print 'Got error [' + cast(@@Error as varchar(10)) + '] in file = ' + @FileName
			--print 'Error Number [' +  cast(-error_number() as varchar(20)) + '] - ' + @ErrorMessage

			-- if error, then move the file to error folder
			set @tmpmsg = 'move /Y ' + @FileName + ' ' + @ErrFolder;

			exec master.sys.xp_cmdShell @tmpmsg
		
			set @tmpmsg = ' - ' + 'Error Number [' +  cast(-error_number() as varchar(20)) + '] - ' + @ErrorMessage;
			EXEC sp_WriteToFile @LogFile, @tmpmsg;

			RAISERROR (@ErrorMessage, -- Message text.
					   @ErrorSeverity, -- Severity.
					   @ErrorState -- State.	 
				  );
		end catch
	
	FETCH NEXT FROM cr_xmlFileList
	INTO @FileName;

	set @jcount = @jcount + 1;
End
Close cr_xmlFileList;
Deallocate cr_xmlFileList;

set @tmpmsg = ' - Step # 2 - Total files read  = ' + Convert(varchar(10), @jcount);
EXEC sp_WriteToFile @LogFile, @tmpmsg;

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Section 3. Loop through each XML Data record and processing Data Import
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SET NOCOUNT ON
DECLARE @XML AS XML ;
DECLARE @MessageType varchar(50);
DECLARE @CaseNumber varchar(50);
DECLARE @SuccFolder varchar(100);

Set @SuccFolder = @FilePath + 'Success' ;



-- 3.1 Loop through each XML data record 

EXEC sp_WriteToFile @LogFile, ' - Step # 3 - Begin of parsing XML data into SQL tables.';

DECLARE cr_xmlData cursor for
SELECT XMLData, xmlFileName FROM RMSwithOpenXML;

Open cr_xmlData;

FETCH NEXT FROM cr_xmlData
INTO @XML, @FileName;

DECLARE @icount int = 0  -- count how many xml documents successfully processed 
DECLARE @TransactionName varchar(30);

-- Check @@FETCH_STATUS to see if there are any more rows to fetch.
WHILE @@FETCH_STATUS = 0 
BEGIN
	
 -- check if EVENT node is present, if not then error and continue with next xml
 	set @tmpmsg = ' Part 1 - Pocessing file = ' + @FileName
	-- Checking message type first
	EXEC sp_WriteToFile @LogFile, @tmpmsg

	IF  NOT ( @XML.exist('/ICADLINK_EVENT/EVENT') = 1 )
	BEGIN
		SET @tmpmsg = 'move /Y ' + @FileName + ' ' + @ErrFolder

		EXEC master.sys.xp_cmdShell @tmpmsg
	
		SET @tmpmsg = ' - ' + 'Error unable to find element /ICADLINK_EVENT/EVENT. Moving to failed directory.' 
		EXEC sp_WriteToFile @LogFile, @tmpmsg
		FETCH NEXT FROM cr_xmlData
		INTO @XML, @FileName;
		CONTINUE;
	END;
	SET @TransactionName= 'CADLINK_TRANSACTION_' + CAST(@icount as varchar(10));
	BEGIN TRAN @TransactionName
	-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- Update database from XML data
	-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	  begin try
		
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		-- 1. Handle EVENT Segment
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


	INSERT INTO EVENT (
		filename,
		process_date,
		is_processed,
		CDTS,
		CDTS_DATE,
		CDTS_TIME,
		CECUST1,
		CECUST2,
		CECUST3,
		CECUST4,
		CPERS,
		CSEC,
		CTERM,
		CURENT,
		DOW,
		EAPT,
		EAREA,
		ECOMPL,
		EDIRPRE,
		EDIRSUF,
		EFEANME,
		EFEATYP,
		EID,
		ELOC_FLD1,
		ELOC_FLD2,
		ELOC_FLD3,
		ELOC_FLD4,
		ELOCATION,
		EMUN,
		ESTNUM,
		FEA_MSLINK,
		HASH,
		LOC_COM,
		LOC_VER,
		LOI_EVENT,
		LOI_INF,
		LOI_SPECSIT,
		MAPLEVS,
		PARSE_TYPE,
		PATIENT,
		PCAD_CASE_NUM,
		REV_NUM,
		S_ESZ,
		UDTS,
		UDTS_DATE,
		UDTS_TIME,
		UPDT_FLAG,
		UPERS,
		UTERM,
		X_CORD,
		XSTREET1,
		XSTREET2,
		Y_CORD,
		ZIP,
		LATITUDE,
		LONGITUDE,
		MAPGRIDS
		)
	select
		@FileName,
		@Process_Date,
		0,
		a.value('CDTS[1]', 'varchar(50)') as CDTS,
		a.value('CDTS_TIMESTAMP[1]/CDTS_DATE[1]', 'varchar(50)') as CDTS_DATE,
		a.value('CDTS_TIMESTAMP[1]/CDTS_TIME[1]', 'varchar(50)') as CDTS_TIME,
		a.value('CECUST1[1]', 'varchar(50)') as CECUST1,
		a.value('CECUST2[1]', 'varchar(50)') as CECUST2,
		a.value('CECUST3[1]', 'varchar(50)') as CECUST3,
		a.value('CECUST4[1]', 'varchar(50)') as CECUST4,
		a.value('CPERS[1]', 'varchar(50)') as CPERS,
		a.value('CSEC[1]', 'varchar(50)') as CSEC,
		a.value('CTERM[1]', 'varchar(50)') as CTERM,
		a.value('CURENT[1]', 'varchar(50)') as CURENT,
		a.value('DOW[1]', 'varchar(50)') as DOW,
		a.value('EAPT[1]',  'varchar(50)') as EAPT,
		a.value('EAREA[1]',  'varchar(100)') as EAREA,
		a.value('ECOMPL[1]',  'varchar(50)') as ECOMPL,
		a.value('EDIRPRE[1]',  'varchar(50)') as EDIRPRE,
		a.value('EDIRSUF[1]',  'varchar(50)') as EDIRSUF,
		a.value('EFEANME[1]',  'varchar(300)') as EFEANME,
		a.value('EFEATYP[1]',  'varchar(300)') as EFEATYP,
		a.value('EID[1]',  'int') as EID,
		a.value('ELOC_FLD1[1]',  'varchar(50)') as ELOC_FLD1,		
		a.value('ELOC_FLD2[1]',  'varchar(50)') as ELOC_FLD2,		
		a.value('ELOC_FLD3[1]',  'varchar(100)') as ELOC_FLD3,		
		a.value('ELOC_FLD4[1]',  'varchar(50)') as ELOC_FLD4,
		a.value('ELOCATION[1]',  'varchar(50)') as ELOCATION,
		a.value('EMUN[1]',  'varchar(50)') as EMUN,		
		a.value('ESTNUM[1]',  'varchar(50)') as ESTNUM,		
		a.value('FEA_MSLINK[1]',  'varchar(50)') as FEA_MSLINK,		
		a.value('HASH[1]',  'varchar(350)') as EV_HASH,  -- HASH IS RESERVED
		a.value('LOC_COM[1]',  'varchar(50)') as LOC_COM,		
		a.value('LOC_VER[1]',  'varchar(100)') as LOC_VER,		
		a.value('LOI_EVENT[1]',  'varchar(100)') as LOI_EVENT,		
		a.value('LOI_INF[1]',  'varchar(50)') as LOI_INF,		
		a.value('LOI_SPECSIT[1]',  'varchar(50)') as LOI_SPECSIT,		
		a.value('MAPLEVS[1]',  'varchar(50)') as MAPLEVS,		
		a.value('PARSE_TYPE[1]',  'varchar(50)') as PARSE_TYPE,		
		a.value('PATIENT[1]',  'varchar(50)') as PATIENT,	
		a.value('PCAD_CASE_NUM[1]',  'varchar(50)') as PCAD_CASE_NUM,		
		a.value('REV_NUM[1]',  'varchar(300)') as REV_NUM,		
		a.value('S_ESZ[1]','varchar(50)') as S_ESZ,
		a.value('UPDTS[1]','varchar(50)') as UDTS,
		a.value('UDTS_TIMESTAMP[1]/UDTS_DATE[1]', 'varchar(50)') as UDTS_DATE,
		a.value('UDTS_TIMESTAMP[1]/UDTS_TIME[1]', 'varchar(50)') as UDTS_TIME,
		a.value('UPDT_FLAG[1]','varchar(50)') as UPDT_FLAG,
		a.value('UPERS[1]','varchar(50)') as UPERS,
		a.value('UTERM[1]','varchar(50)') as UTERM,
		a.value('X_CORD[1]','varchar(50)') as X_CORD,
		a.value('XSTREET1[1]','varchar(50)') as XSTREET1,
		a.value('XSTREET2[1]','varchar(50)') as XSTREET2,
		a.value('Y_CORD[1]','varchar(50)') as Y_CORD,
		a.value('ZIP[1]','varchar(50)') as ZIP,
		a.value('LATITUDE[1]','varchar(50)') as LATITUDE,
		a.value('LONGITUDE[1]','varchar(50)') as LONGITUDE,
		a.value('MAPGRIDS[1]','varchar(50)') as MAPGRIDS 
	FROM @XML.nodes('/ICADLINK_EVENT/EVENT') as E(a)	

		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		-- 1.1 Handle DERIVED_DATA Segment
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	INSERT INTO DERIVED_DATA (
		filename,
		process_date,
		LOCATION,
		COMMENTS)
	SELECT
		@FileName,
		@Process_Date,
		b.value('LOCATION[1]','varchar(50)') as EV_LOCATION  ,
		b.value('COMMENTS[1]','varchar(4096)') as COMMENTS   
	FROM @XML.nodes('/ICADLINK_EVENT/DERIVED_DATA') as F(b);

		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		-- 2. Handle EVCOM Segment
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

		INSERT INTO EVCOMM
		SELECT 
			@FileName,
			@Process_Date,
			x.value('CDTS[1]', '[varchar](50)') as CDTS, 
			x.value('CDTS_TIMESTAMP[1]/CDTS_DATE[1]', 'varchar(50)')  as CDTS_DATE,
			x.value('CDTS_TIMESTAMP[1]/CDTS_TIME[1]', 'varchar(50)')  as CDTS_TIME,
			x.value('CDTS_TIMESTAMP[1]/CDTS_DATETIME[1]', 'varchar(50)')  as CDTS_DATETIME,
			x.value('COMM[1]','[varchar](255)') as COMM, 
			x.value('COMM_KEY[1]', '[varchar](50)')as COMM_KEY, 
			x.value('COMM_SCOPE[1]', '[varchar](50)') as COMM_SCOPE, 
			x.value('CPERS[1]', '[varchar](50)') as CPERS,
			x.value('CSEC[1]', '[varchar](50)') as CSEC,
			x.value('CTERM[1]', '[varchar](50)') as CTERM, 
			x.value('EID[1]', 'int') as EID,
			x.value('LIN_GRP[1]','[varchar](50)') as LIN_GRP_OLD,
			x.value('LIN_ORD[1]', '[varchar](50)') as LIN_ORD_OLD,
			x.value('UNIQUE_ID[1]', '[varchar](50)') as UNIQUE_ID_OLD,
			x.value('C2CSENT[1]', '[varchar](50)') as C2CSENT,
			x.value('C2CSENT_UNIQUE_ID[1]', '[varchar](50)') AS C2CSENT_UNIQUE_ID,
			x.value('C2C_UNIQUE_ID[1]', '[varchar](50)') as C2CSENT_UNIQUE_ID,
			x.value('C2C_SENT[1]', '[varchar](50)') AS C2C_SENT,
			x.value('ADORNED_COMM[1]', '[varchar](50)') as ADORNED_COMM,
			x.value('ADORNED_COMM_STYLE[1]', '[varchar](50)') as ADORNED_COMM_STYLE,
			x.value('COMM_SCOPE_GROUP[1]', '[varchar](50)') as COMM_SCOPE_GROUP,
			x.value('ID[1]', '[varchar](50)') as  EVCOMMID,
			x.value('PRIORITY[1]', '[varchar](50)') as PRIORITY ,
			x.value('REMOTE_AGENCY[1]', '[varchar](50)') as REMOTE_AGENCY,
			x.value('REMOTE_COMMENT_ID[1]', '[varchar](50)') as REMOTE_COMMENT_ID,
			x.value('TYPE[1]', '[varchar](50)') as EVCOMMTYPE
		FROM @XML.nodes('/ICADLINK_EVENT/EVCOM_LIST/EVCOM') as U(x);

		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		-- 3. Handle AEVEN Segment
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		INSERT INTO AEVEN
		SELECT
			@FileName
			,@Process_Date
			,x.value ('ACKNOWLEDGE_TIMER[1]', 'varchar(50)') as ACKNOWLEDGE_TIMER
			,x.value ('AD_SEC[1]', 'varchar(50)') as AD_SEC
			,x.value ('AD_TS[1]', 'varchar(50)') as AD_TS
			,x.value('AD_TS_TIMESTAMP[1]/AD_TS_DATE[1]', 'varchar(50)')  as AD_TS_DATE
			,x.value('AD_TS_TIMESTAMP[1]/AD_TS_TIME[1]', 'varchar(50)')  as AD_TS_TIME
			,x.value ('AECUST1[1]', 'varchar(50)') as AECUST1
			,x.value ('AECUST2[1]', 'varchar(50)') as AECUST2
			,x.value ('AECUST3[1]', 'varchar(50)') as AECUST3
			,x.value ('AECUST4[1]', 'varchar(50)') as AECUST4
			,x.value ('AG_ID[1]', 'varchar(50)') as AG_ID
			,x.value ('ALARM_LEV[1]', 'varchar(50)') as ALARM_LEV
			,x.value ('APPT_ALARM_UNTIL[1]', 'varchar(50)') as APPT_ALARM_UNTIL
			,x.value ('APPT_END_TS[1]', 'varchar(50)') as APPT_END_TS
			,x.value ('APPT_END_TS_TIMESTAMP[1]/APPT_END_TS_DATE[1]', 'varchar(50)') as APPT_END_TS_DATE
			,x.value ('APPT_END_TS_TIMESTAMP[1]/APPT_END_TS_TIME[1]', 'varchar(50)') as APPT_END_TS_TIME
			,x.value ('APPT_START_DTS[1]', 'varchar(50)') as APPT_START_DTS
			,x.value ('AR_SEC[1]', 'varchar(50)') as AR_SEC
			,x.value ('AR_TS[1]', 'varchar(50)') as AR_TS
			,x.value ('AR_TS_TIMESTAMP[1]/AR_TS_DATE[1]', 'varchar(50)') as AR_TS_DATE
			,x.value ('AR_TS_TIMESTAMP[1]/AR_TS_TIME[1]', 'varchar(50)') as AR_TS_TIME
			,x.value ('ARRIVE_TIMER[1]', 'varchar(50)') as ARRIVE_TIMER
			,x.value ('ASSIGNED_UNITS[1]', 'varchar(50)') as ASSIGNED_UNITS
			,x.value ('CALLBACK_DTS[1]', 'varchar(50)') as CALLBACK_DTS
			,x.value ('CBTIME2[1]', 'varchar(50)') as CBTIME2
			,x.value ('CDTS[1]', 'varchar(50)') as CDTS
			,x.value ('CDTS_TIMESTAMP[1]/CDTS_DATE[1]', 'varchar(50)') as CDTS_DATE
			,x.value ('CDTS_TIMESTAMP[1]/CDTS_TIME[1]', 'varchar(50)') as CDTS_TIME
			,x.value ('CLOSING_ALLOWED[1]', 'varchar(50)') as CLOSING_ALLOWED
			,x.value ('CPERS[1]', 'varchar(50)') as CPERS
			,x.value ('CREATE_PERS[1]', 'varchar(50)') as CREATE_PERS
			,x.value ('CREATE_TERM[1]', 'varchar(50)') as CREATE_TERM
			,x.value ('CSEC[1]', 'varchar(50)') as CSEC
			,x.value ('CTERM[1]', 'varchar(50)') as CTERM
			,x.value ('CURENT[1]', 'varchar(50)') as CURENT
			,x.value ('DEST_EID[1]', 'varchar(50)') as DEST_EID
			,x.value ('DGROUP[1]', 'varchar(50)') as DGROUP
			,x.value ('DISPASS_UNIT[1]', 'varchar(50)') as DISPASS_UNIT
			,x.value ('DISPATCH_TIMER[1]', 'varchar(50)') as DISPATCH_TIMER
			,x.value ('DS_SEC[1]', 'varchar(50)') as DS_SEC
			,x.value ('DS_TS[1]', 'varchar(50)') as DS_TS
			,x.value ('DS_TS_TIMESTAMP[1]/DS_TS_DATE[1]', 'varchar(50)') as DS_TS_DATE
			,x.value ('DS_TS_TIMESTAMP[1]/DS_TS_TIME[1]', 'varchar(50)') as DS_TS_TIME
			,x.value ('DUE_DTS[1]', 'varchar(50)') as DUE_DTS
			,x.value ('EID[1]', 'varchar(50)') as EID
			,x.value ('EN_SEC[1]', 'varchar(50)') as EN_SEC
			,x.value ('EN_TS[1]', 'varchar(50)') as EN_TS
			,x.value ('EN_TS_TIMESTAMP[1]/EN_TS_DATE[1]', 'varchar(50)') as EN_TS_DATE
			,x.value ('EN_TS_TIMESTAMP[1]/EN_TS_TIME[1]', 'varchar(50)') as EN_TS_TIME
			,x.value ('ENROUTE_TIMER[1]', 'varchar(50)') as ENROUTE_TIMER
			,x.value ('ESZ[1]', 'varchar(50)') as ESZ
			,x.value ('ETA[1]', 'varchar(50)') as ETA
			,x.value ('EVENT_DESC[1]', 'varchar(50)') as EVENT_DESC
			,x.value ('EVT_REV_NUM[1]', 'varchar(50)') as EVT_REV_NUM
			,x.value ('EX_EVT[1]', 'varchar(50)') as EX_EVT
			,x.value ('EXTERNAL_EVENT_ID[1]', 'varchar(50)') as EXTERNAL_EVENT_ID
			,x.value ('FLAGS[1]', 'varchar(50)') as FLAGS
			,x.value ('GROUP_ID[1]', 'varchar(50)') as GROUP_ID
			,x.value ('GROUP_ORDER[1]', 'varchar(50)') as GROUP_ORDER
			,x.value ('HOLD_DTS[1]', 'varchar(50)') as HOLD_DTS
			,x.value ('HOLD_DTS_TIMESTAMP[1]/HOLD_DTS_DATE[1]', 'varchar(50)') as HOLD_DTS_DATE
			,x.value ('HOLD_DTS_TIMESTAMP[1]/HOLD_DTS_TIME[1]', 'varchar(50)') as HOLD_DTS_TIME
			,x.value ('HOLD_TYPE[1]', 'varchar(50)') as HOLD_TYPE
			,x.value ('HOLD_UNT[1]', 'varchar(50)') as HOLD_UNT
			,x.value ('IS_OPEN[1]', 'varchar(50)') as IS_OPEN
			,x.value ('IS_REC_ENABLED[1]', 'varchar(50)') as IS_REC_ENABLED
			,x.value ('IS_REC_PREEMPT_ENABLED[1]', 'varchar(50)') as IS_REC_PREEMPT_ENABLED
			,x.value ('LATE_RUN[1]', 'varchar(50)') as LATE_RUN
			,x.value ('LEV2[1]', 'varchar(50)') as LEV2
			,x.value ('LEV3[1]', 'varchar(50)') as LEV3
			,x.value ('LEV4[1]', 'varchar(50)') as LEV4
			,x.value ('LEV5[1]', 'varchar(50)') as LEV5
			,x.value ('LOI_AVAIL_DTS[1]', 'varchar(50)') as LOI_AVAIL_DTS
			,x.value ('LOI_AVAIL_DTS_TIMESTAMP[1]/LOI_AVAIL_DTS_DATE[1]', 'varchar(50)') as LOI_AVAIL_DTS_DATE
			,x.value ('LOI_AVAIL_DTS_TIMESTAMP[1]/LOI_AVAIL_DTS_TIME[1]', 'varchar(50)') as LOI_AVAIL_DTS_TIME
			,x.value ('MAJEVT_EVTY[1]', 'varchar(50)') as MAJEVT_EVTY
			,x.value ('MAJEVT_LOC[1]', 'varchar(50)') as MAJEVT_LOC
			,x.value ('MUN[1]', 'varchar(50)') as MUN
			,x.value ('NUM_1[1]', 'varchar(50)') as NUM_1
			,x.value ('OPEN_AND_CURENT[1]', 'varchar(50)') as OPEN_AND_CURENT
			,x.value ('PEND_DTS[1]', 'varchar(50)') as PEND_DTS
			,x.value ('PEND_DTS_TIMESTAMP[1]/PEND_DTS_DATE[1]', 'varchar(50)') as PEND_DTS_DATE
			,x.value ('PEND_DTS_TIMESTAMP[1]/PEND_DTS_TIME[1]', 'varchar(50)') as PEND_DTS_TIME
			,x.value ('PENDING_TIMER[1]', 'varchar(50)') as PENDING_TIMER
			,x.value ('PLANNED_TASK_END_DTS[1]', 'varchar(50)') as PLANNED_TASK_END_DTS
			,x.value ('PLANNED_TASK_END_DTS_TIMESTAMP[1]/PLANNED_TASK_END_DTS_DATE[1]', 'varchar(50)') as PLANNED_TASK_END_DTS_DATE
			,x.value ('PLANNED_TASK_END_DTS_TIMESTAMP[1]/PLANNED_TASK_END_DTS_TIME[1]', 'varchar(50)') as PLANNED_TASK_END_DTS_TIME
			,x.value ('PLANNED_TASK_START_DTS[1]', 'varchar(50)') as PLANNED_TASK_START_DTS
			,x.value ('PLANNED_TASK_START_DTS_TIMESTAMP[1]/PLANNED_TASK_START_DTS_DATE[1]', 'varchar(50)') as PLANNED_TASK_START_DTS_DATE
			,x.value ('PLANNED_TASK_START_DTS_TIMESTAMP[1]/PLANNED_TASK_START_DTS_TIME[1]', 'varchar(50)') as PLANNED_TASK_START_DTS_TIME
			,x.value ('PRIM_MEMBER[1]', 'varchar(50)') as PRIM_MEMBER
			,x.value ('PRIM_UNIT[1]', 'varchar(50)') as PRIM_UNIT
			,x.value ('PRIORITY[1]', 'varchar(50)') as PRIORITY
			,x.value ('PRIORITY_CHANGED_DTS[1]', 'varchar(50)') as PRIORITY_CHANGED_DTS
			,x.value ('PROBE_FLAG[1]', 'varchar(50)') as PROBE_FLAG
			,x.value ('PROQA_CASE_NUM[1]', 'varchar(50)') as PROQA_CASE_NUM
			,x.value ('PROQA_CASE_TYPE[1]', 'varchar(50)') as PROQA_CASE_TYPE
			,x.value ('REC_FEA_MSLINK[1]', 'varchar(50)') as REC_FEA_MSLINK
			,x.value ('REC_SELECT_MODE[1]', 'varchar(50)') as REC_SELECT_MODE
			,x.value ('REC_X_CORD[1]', 'varchar(50)') as REC_X_CORD
			,x.value ('REC_Y_CORD[1]', 'varchar(50)') as REC_Y_CORD
			,x.value ('RECOM_INCOMPLETE[1]', 'varchar(50)') as RECOM_INCOMPLETE
			,x.value ('RECOMMEND_MODE[1]', 'varchar(50)') as RECOMMEND_MODE
			,x.value ('REOPEN[1]', 'varchar(50)') as REOPEN
			,x.value ('RESP_DOWN[1]', 'varchar(50)') as RESP_DOWN
			,x.value ('REV_NUM[1]', 'varchar(50)') as REV_NUM
			,x.value ('SCDTS[1]', 'varchar(50)') as SCDTS
			,x.value ('SCDTS_TIMESTAMP[1]/SCDTS_DATE[1]', 'varchar(50)') as SCDTS_DATE
			,x.value ('SCDTS_TIMESTAMP[1]/SCDTS_TIME[1]', 'varchar(50)') as SCDTS_TIME
			,x.value ('SDTS[1]', 'varchar(50)') as SDTS
			,x.value ('SDTS_TIMESTAMP[1]/SDTS_DATE[1]', 'varchar(50)') as SDTS_DATE
			,x.value ('SDTS_TIMESTAMP[1]/SDTS_TIME[1]', 'varchar(50)') as SDTS_TIME
			,x.value ('SITFND[1]', 'varchar(50)') as SITFND
			,x.value ('SSEC[1]', 'varchar(50)') as SSEC
			,x.value ('STATUS_CODE[1]', 'varchar(50)') as STATUS_CODE
			,x.value ('SUB_ENG[1]', 'varchar(50)') as SUB_ENG
			,x.value ('SUB_SITFND[1]', 'varchar(50)') as SUB_SITFND
			,x.value ('SUB_TYCOD[1]', 'varchar(50)') as SUB_TYCOD
			,x.value ('SUPP_INFO[1]', 'varchar(50)') as SUPP_INFO
			,x.value ('TA_SEC[1]', 'varchar(50)') as TA_SEC
			,x.value ('TA_TS[1]', 'varchar(50)') as TA_TS
			,x.value ('TA_TS_TIMESTAMP[1]/TA_TS_DATE[1]', 'varchar(50)') as TA_TS_DATE
			,x.value ('TA_TS_TIMESTAMP[1]/TA_TS_TIME[1]', 'varchar(50)') as TA_TS_TIME
			,x.value ('TALK_GROUP_LABEL[1]', 'varchar(50)') as TALK_GROUP_LABEL
			,x.value ('TR_SEC[1]', 'varchar(50)') as TR_SEC
			,x.value ('TR_TS[1]', 'varchar(50)') as TR_TS
			,x.value ('TR_TS_TIMESTAMP[1]/TR_TS_DATE[1]', 'varchar(50)') as TR_TS_DATE
			,x.value ('TR_TS_TIMESTAMP[1]/TR_TS_TIME[1]', 'varchar(50)') as TR_TS_TIMES
			,x.value ('TYCOD[1]', 'varchar(50)') as TYCOD
			,x.value ('TYP_ENG[1]', 'varchar(50)') as TYP_ENG
			,x.value ('UDTS[1]', 'varchar(50)') as UDTS
			,x.value ('UDTS_TIMESTAMP[1]/UDTS_DATE[1]', 'varchar(50)') as UDTS_DATE
			,x.value ('UDTS_TIMESTAMP[1]/UDTS_TIME[1]', 'varchar(50)') as UDTS_TIME
			,x.value ('UPERS[1]', 'varchar(50)') as UPERS
			,x.value ('UTERM[1]', 'varchar(50)') as UTERM
			,x.value ('VDTS[1]', 'varchar(50)') as VDTS
			,x.value ('VDTS_TIMESTAMP[1]/VDTS_DATE[1]', 'varchar(50)') as VDTS_DATE
			,x.value ('VDTS_TIMESTAMP[1]/VDTS_TIME[1]', 'varchar(50)') as VDTS_TIMES
			,x.value ('VSEC[1]', 'varchar(50)') as VSEC
			,x.value ('XCMT[1]', 'varchar(50)') as XCMT
			,x.value ('XDOW[1]', 'varchar(50)') as XDOW
			,x.value ('XDTS[1]', 'varchar(50)') as XDTS
			,x.value ('XDTS_TIMESTAMP[1]/XDTS_DATE[1]', 'varchar(50)') as XDTS_DATE
			,x.value ('XDTS_TIMESTAMP[1]/XDTS_TIME[1]', 'varchar(50)') as XDTS_TIME
			,x.value ('XPERS[1]', 'varchar(50)') as XPERS
			,x.value ('XSEC[1]', 'varchar(50)') as XSEC
			,x.value ('XTERM[1]', 'varchar(50)') as XTERM
			,x.value ('CHAN[1]', 'varchar(50)') as CHAN
			,x.value ('MAPGRIDS[1]', 'varchar(50)') as MAPGRIDS
			,x.value ('MEDS_CASE[1]', 'varchar(50)') as MEDS_CASE
			,x.value ('SEE_CP[1]', 'varchar(50)') as SEE_CP
			FROM @XML.nodes('/ICADLINK_EVENT/AEVEN') as U(x);


		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		-- 4. Handle EV_DISPO list Segment
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

		INSERT INTO EV_DISPO
			SELECT
			@FileName
			,@Process_Date
			,x.value ('CASE_NUM[1]', 'varchar(50)') as  CASE_NUM
			,x.value ('CDTS[1]', 'varchar(50)') as  CDTS
			,x.value ('CDTS_TIMESTAMP[1]/CDTS_DATE[1]', 'varchar(50)') as  CDTS_DATE
			,x.value ('CDTS_TIMESTAMP[1]/CDTS_TIME[1]', 'varchar(50)') as  CDTS_TIME
			,x.value ('CPERS[1]', 'varchar(50)') as  CPERS
			,x.value ('CTERM[1]', 'varchar(50)') as  CTERM
			,x.value ('CURENT[1]', 'varchar(50)') as  CURENT
			,x.value ('DISPO[1]', 'varchar(50)') as  DISPO
			,x.value ('EID[1]', 'varchar(50)') as  EID
			,x.value ('MEMBER_ID[1]', 'varchar(50)') as  MEMBER_ID
			,x.value ('NUM_1[1]', 'varchar(50)') as  NUM_1
			,x.value ('QUAL1[1]', 'varchar(50)') as  QUAL1
			,x.value ('QUAL2[1]', 'varchar(50)') as  QUAL2
			,x.value ('QUAL3[1]', 'varchar(50)') as  QUAL3
			,x.value ('REV_NUM[1]', 'varchar(50)') as  REV_NUM
			,x.value ('ROW_NUM[1]', 'varchar(50)') as  ROW_NUM
			,x.value ('UDTS[1]', 'varchar(50)') as  UDTS
			,x.value ('UDTS_TIMESTAMP[1]/UDTS_DATE[1]', 'varchar(50)') as  UDTS_DATE
			,x.value ('UDTS_TIMESTAMP[1]/UDTS_TIME[1]', 'varchar(50)') as  UDTS_TIME
			,x.value ('UNIT_ID[1]', 'varchar(50)') as  UNIT_ID
			,x.value ('UPERS[1]', 'varchar(50)') as  UPERS
			,x.value ('UTERM[1]', 'varchar(50)') as  UTERM
			FROM @XML.nodes('/ICADLINK_EVENT/EV_DISPO_LIST/EV_DISPO') as U(x);
		
		
		
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		-- 5. Handle UN_HI list Segment
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		INSERT INTO UN_HI
		SELECT
			@FileName
			,@Process_Date
			,x.value ('ACT_CHECK[1]', 'varchar(50)') as  ACT_CHECK
			,x.value ('AG_ID[1]', 'varchar(50)') as  AG_ID
			,x.value ('AGENCY_EVENT_REV_NUM[1]', 'varchar(50)') as  AGENCY_EVENT_REV_NUM
			,x.value ('CARID[1]', 'varchar(50)') as  CARID
			,x.value ('CDTS[1]', 'varchar(50)') as  CDTS
			,x.value ('CDTS_TIMESTAMP[1]/CDTS_DATE[1]', 'varchar(50)') as  CDTS_DATE
			,x.value ('CDTS_TIMESTAMP[1]/CDTS_TIME[1]', 'varchar(50)') as  CDTS_TIME
			,x.value ('CPERS[1]', 'varchar(50)') as  CPERS
			,x.value ('CREW_ID[1]', 'varchar(50)') as  CREW_ID
			,x.value ('CSEC[1]', 'varchar(50)') as  CSEC
			,x.value ('CTERM[1]', 'varchar(50)') as  CTERM
			,x.value ('DGROUP[1]', 'varchar(50)') as  DGROUP
			,x.value ('DISP_ALARM_LEV[1]', 'varchar(50)') as  DISP_ALARM_LEV
			,x.value ('DISP_NUM[1]', 'varchar(50)') as  DISP_NUM
			,x.value ('EID[1]', 'varchar(50)') as  EID
			,x.value ('LASTXOR[1]', 'varchar(50)') as  LASTXOR
			,x.value ('LASTYOR[1]', 'varchar(50)') as  LASTYOR
			,x.value ('LOCATION[1]', 'varchar(50)') as  LOCATION
			,x.value ('MDTHOSTNAME[1]', 'varchar(50)') as  MDTHOSTNAME
			,x.value ('MDTID_OLD[1]', 'varchar(50)') as  MDTID_OLD
			,x.value ('MILEAGE[1]', 'varchar(50)') as  MILEAGE
			,x.value ('NUM_1[1]', 'varchar(50)') as  NUM_1
			,x.value ('OAG_ID[1]', 'varchar(50)') as  OAG_ID
			,x.value ('ODGROUP[1]', 'varchar(50)') as  ODGROUP
			,x.value ('PAGE_ID[1]', 'varchar(50)') as  PAGE_ID
			,x.value ('RADIO_ALIAS_OLD[1]', 'varchar(50)') as  RADIO_ALIAS_OLD
			,x.value ('RECOVERY_CDTS[1]', 'varchar(50)') as  RECOVERY_CDTS
			,x.value ('RECOVERY_CDTS_TIMESTAMP[1]/RECOVERY_CDTS_DATE[1]', 'varchar(50)') as  RECOVERY_CDTS_DATE
			,x.value ('RECOVERY_CDTS_TIMESTAMP[1]/RECOVERY_CDTS_TIME[1]', 'varchar(50)') as  RECOVERY_CDTS_TIME
			,x.value ('STATION[1]', 'varchar(50)') as  STATION
			,x.value ('SUB_TYCOD[1]', 'varchar(50)') as  SUB_TYCOD
			,x.value ('TYCOD[1]', 'varchar(50)') as  TYCOD
			,x.value ('UCUST1[1]', 'varchar(50)') as  UCUST1
			,x.value ('UCUST2[1]', 'varchar(50)') as  UCUST2
			,x.value ('UCUST3[1]', 'varchar(50)') as  UCUST3
			,x.value ('UCUST4[1]', 'varchar(50)') as  UCUST4
			,x.value ('UHISCM[1]', 'varchar(50)') as  UHISCM
			,x.value ('UNID[1]', 'varchar(50)') as  UNID
			,x.value ('UNIQUE_ID[1]', 'varchar(50)') as  UNIQUE_ID
			,x.value ('UNIT_STATUS[1]', 'varchar(50)') as  UNIT_STATUS
			,x.value ('UNITYP[1]', 'varchar(50)') as  UNITYP
			,x.value ('CDTS2[1]', 'varchar(50)') as  CDTS2
			,x.value ('LATITUDE[1]', 'varchar(50)') as  LATITUDE
			,x.value ('LONGITUDE[1]', 'varchar(50)') as  LONGITUDE
			,x.value ('TRACK_PERSONNEL[1]', 'varchar(50)') as  TRACK_PERSONNEL
			,x.value ('UN_HI_CHILD_CHANGE_ID[1]', 'varchar(50)') as  UN_HI_CHILD_CHANGE_ID
			,x.value ('ACTION_CODE[1]', 'varchar(50)') as  ACTION_CODE
			,x.value ('ASSIGNED_NUM_1[1]', 'varchar(50)') as  ASSIGNED_NUM_1
			,x.value ('FACILITY_ENTRANCE_ID[1]', 'varchar(50)') as  FACILITY_ENTRANCE_ID
			,x.value ('ORDER_WITHIN_CDTS[1]', 'varchar(50)') as  ORDER_WITHIN_CDTS
			,x.value ('ROLE_DESIGNATOR[1]', 'varchar(50)') as  ROLE_DESIGNATOR
			,x.value ('STAGING_AREA_ID[1]', 'varchar(50)') as  STAGING_AREA_ID
			,x.value ('TRANSPORT_LATITUDE[1]', 'varchar(50)') as  TRANSPORT_LATITUDE
			,x.value ('TRANSPORT_LOCATION[1]', 'varchar(50)') as  TRANSPORT_LOCATION
			,x.value ('TRANSPORT_LONGITUDE[1]', 'varchar(50)') as  TRANSPORT_LONGITUDE
		FROM @XML.nodes('/ICADLINK_EVENT/UN_HI_LIST/UN_HI') as U(x);
		
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		-- 6. Handle UN_HI_PERSL list Segment
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

		Insert UN_HI_PERSL (filename, process_date, CDTS, EMPID, HT_RADIO, PRIMARY_EMPID, RECOVERY_CDTS,
			UN_HI_REC_ID)
		SELECT 
			@FileName,
			@Process_Date,
			x.value('CDTS[1]','[varchar](255)') as CDTS, 
			x.value('EMPID[1]', '[varchar](50)')as EMPID, 
			x.value('HT_RADIO[1]', '[varchar](50)') as HT_RADIO, 
			x.value('PRIMARY_EMPID[1]', '[varchar](50)') as PRIMARY_EMPID,
			x.value('RECOVERY_CDTS[1]', '[varchar](50)') as RECOVERY_CDTS,
			x.value('UN_HI_REC_ID[1]', '[varchar](50)') as UN_HI_REC_ID 
 		FROM @XML.nodes('/ICADLINK_EVENT/UN_HI_LIST/UN_HI/UN_HI_PERSL_LIST/UN_HI_PERSL') as U(x)
		
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		-- 7. Handle CASE_NUM_LIST list Segment
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		INSERT INTO CASE_NUM
		(	filename, 
			process_date,
			AG_ID,
			CASE_NUM,
			CDTS,
			CDTS_DATE,
			CDTS_TIME,
			CPERS,
			CTERM,
			CURENT,
			DGROUP,
			EID,
			NUM_1,
			UDTS,
			UDTS_DATE,
			UDTS_TIME,
			UPERS,
			UTERM,
			SUNPRO_AG_ID
		)
		select
		@FileName
		,@Process_Date
		,x.value ('AG_ID[1]', 'varchar(50)') as  AG_ID
		,x.value ('CASE_NUM[1]', 'varchar(50)') as  CASE_NUM
		,x.value ('CDTS[1]', 'varchar(50)') as  CDTS
		,x.value ('CDTS_TIMESTAMP[1]/CDTS_DATE[1]', 'varchar(50)') as  CDTS_DATE
		,x.value ('CDTS_TIMESTAMP[1]/CDTS_TIME[1]', 'varchar(50)') as  CDTS_TIME
		,x.value ('CPERS[1]', 'varchar(50)') as  CPERS
		,x.value ('CTERM[1]', 'varchar(50)') as  CTERM
		,x.value ('CURENT[1]', 'varchar(50)') as  CURENT
		,x.value ('DGROUP[1]', 'varchar(50)') as  DGROUP
		,x.value ('EID[1]', 'varchar(50)') as  EID
		,x.value ('NUM_1[1]', 'varchar(50)') as  NUM_1
		,x.value ('UDTS[1]', 'varchar(50)') as  UDTS
		,x.value ('UDTS_DATE[1]', 'varchar(50)') as  UDTS_DATE
		,x.value ('UDTS_TIME[1]', 'varchar(50)') as  UDTS_TIME
		,x.value ('UPERS[1]', 'varchar(50)') as  UPERS
		,x.value ('UTERM[1]', 'varchar(50)') as  UTERM
		,x.value ('SUNPRO_AG_ID[1]', 'varchar(50)') as  SUNPRO_AG_ID
			FROM @XML.nodes('/ICADLINK_EVENT/CASE_NUM_LIST/CASE_NUM') as U(x);
		
		
		INSERT INTO PERSL
		SELECT
			@FileName
			,@Process_Date
			,x.value ('AG_ID[1]', ' varchar(50)') as  AG_ID
			,x.value ('APP_TYPE[1]', ' varchar(50)') as  APP_TYPE
			,x.value ('BL_TYP[1]', ' varchar(50)') as  BL_TYP
			,x.value ('CAD_CMD_MASK[1]', ' varchar(50)') as  CAD_CMD_MASK
			,x.value ('CHATID[1]', ' varchar(50)') as  CHATID
			,x.value ('CURENT[1]', ' varchar(50)') as  CURENT
			,x.value ('DBM_CMD_MASK[1]', ' varchar(50)') as  DBM_CMD_MASK
			,x.value ('DEFAULT_UNID[1]', ' varchar(50)') as  DEFAULT_UNID
			,x.value ('DELEX[1]', ' varchar(50)') as  DELEX
			,x.value ('DELNO[1]', ' varchar(50)') as  DELNO
			,x.value ('DOMAIN[1]', ' varchar(50)') as  DOMAIN
			,x.value ('EMAIL[1]', ' varchar(50)') as  EMAIL
			,x.value ('EMP_ADD[1]', ' varchar(50)') as  EMP_ADD
			,x.value ('EMP_CITY[1]', ' varchar(50)') as  EMP_CITY
			,x.value ('EMP_NUM[1]', ' varchar(50)') as  EMP_NUM
			,x.value ('EMP_ST[1]', ' varchar(50)') as  EMP_ST
			,x.value ('EMPID[1]', ' varchar(50)') as  EMPID
			,x.value ('FNAME[1]', ' varchar(50)') as  FNAME
			,x.value ('HOST_TERM[1]', ' varchar(50)') as  HOST_TERM
			,x.value ('HT_RADIO_OLD[1]', ' varchar(50)') as  HT_RADIO_OLD
			,x.value ('LDTS[1]', ' varchar(50)') as  LDTS
			,x.value ('LDTS_TIMESTAMP[1]/LDTS_DATE[1]', ' varchar(50)') as  LDTS_DATE
			,x.value ('LDTS_TIMESTAMP[1]/LDTS_TIME[1]', ' varchar(50)') as  LDTS_TIME
			,x.value ('LNAME[1]', ' varchar(50)') as  LNAME
			,x.value ('LODTS[1]', ' varchar(50)') as  LODTS
			,x.value ('LODTS_TIMESTAMP[1]/LODTS_DATE[1]', ' varchar(50)') as  LODTS_DATE
			,x.value ('LODTS_TIMESTAMP[1]/LODTS_TIME[1]', ' varchar(50)') as  LODTS_TIME
			,x.value ('LOGGED_ON[1]', ' varchar(50)') as  LOGGED_ON
			,x.value ('MI[1]', ' varchar(50)') as  MI
			,x.value ('NOT_ADD[1]', ' varchar(50)') as  NOT_ADD
			,x.value ('NOT_CITY[1]', ' varchar(50)') as  NOT_CITY
			,x.value ('NOT_NME[1]', ' varchar(50)') as  NOT_NME
			,x.value ('NOT_PH[1]', ' varchar(50)') as  NOT_PH
			,x.value ('NOT_ST[1]', ' varchar(50)') as  NOT_ST
			,x.value ('PAGE_ID[1]', ' varchar(50)') as  PAGE_ID
			,x.value ('PASS_DATE[1]', ' varchar(50)') as  PASS_DATE
			,x.value ('PCUST1[1]', ' varchar(50)') as  PCUST1
			,x.value ('PCUST2[1]', ' varchar(50)') as  PCUST2
			,x.value ('PCUST3[1]', ' varchar(50)') as  PCUST3
			,x.value ('PCUST4[1]', ' varchar(50)') as  PCUST4
			,x.value ('PHONE[1]', ' varchar(50)') as  PHONE
			,x.value ('PID[1]', ' varchar(50)') as  PID
			,x.value ('PSWRD[1]', ' varchar(50)') as  PSWRD
			,x.value ('PSWRD_HASH_ID[1]', ' varchar(50)') as  PSWRD_HASH_ID
			,x.value ('RMS_ID[1]', ' varchar(50)') as  RMS_ID
			,x.value ('SOUNDEX[1]', ' varchar(50)') as  SOUNDEX
			,x.value ('TERM[1]', ' varchar(50)') as  TERM
			,x.value ('USR_ID[1]', ' varchar(50)') as  USR_ID
			,x.value ('DEFAULT_USER_GROUP[1]', ' varchar(50)') as  DEFAULT_USER_GROUP
		FROM @XML.nodes('/ICADLINK_EVENT/PERSL_LIST/PERSL') as U(x);
		
		INSERT INTO COMMON_EVENT_CALL 
		(
			filename,
			process_date,
			CALL_ID ,
			CALL_SOUR ,
			CCITY ,
			CDTS ,
			CDTS_DATE ,
			CDTS_TIME ,
			CLNAME ,
			CLRNUM ,
			CPERS ,
			CSTR_ADD ,
			CTERM ,
			EID ,
			EVENT_CALL_ID ,
			FIRST_CALL ,
			REV_NUM ,
			UDTS ,
			UDTS_DATE ,
			UDTS_TIME ,
			UPERS ,
			UTERM ,
			LATITUDE ,
			LOC_VER ,
			LONGITUDE 
		)
		SELECT
			@FileName
			,@Process_Date
			, x.value ('CALL_ID[1]', 'varchar(50)') as CALL_ID
			,x.value ('CALL_SOUR[1]', 'varchar(50)') as CALL_SOUR
			,x.value ('CCITY[1]', 'varchar(50)') as CCITY
			,x.value ('CDTS[1]', 'varchar(50)') as CDTS
			,x.value ('CDTS_TIMESTAMP[1]/CDTS_DATE[1]', 'varchar(50)') as CDTS_DATE
			,x.value ('CDTS_TIMESTAMP[1]/CDTS_TIME[1]', 'varchar(50)') as CDTS_TIME
			,x.value ('CLNAME[1]', 'varchar(50)') as CLNAME
			,x.value ('CLRNUM[1]', 'varchar(50)') as CLRNUM
			,x.value ('CPERS[1]', 'varchar(50)') as CPERS
			,x.value ('CSTR_ADD[1]', 'varchar(50)') as CSTR_ADD
			,x.value ('CTERM[1]', 'varchar(50)') as CTERM
			,x.value ('EID[1]', 'varchar(50)') as EID
			,x.value ('EVENT_CALL_ID[1]', 'varchar(50)') as EVENT_CALL_ID
			,x.value ('FIRST_CALL[1]', 'varchar(50)') as FIRST_CALL
			,x.value ('REV_NUM[1]', 'varchar(50)') as REV_NUM
			,x.value ('UDTS[1]', 'varchar(50)') as UDTS
			,x.value ('UDTS_TIMESTAMP[1]/UDTS_DATE[1]', 'varchar(50)') as UDTS_DATE
			,x.value ('UDTS_TIMESTAMP[1]/UDTS_TIME[1]', 'varchar(50)') as UDTS_TIME
			,x.value ('UPERS[1]', 'varchar(50)') as UPERS
			,x.value ('UTERM[1]', 'varchar(50)') as UTERM
			,x.value ('LATITUDE[1]', 'varchar(50)') as LATITUDE
			,x.value ('LOC_VER[1]', 'varchar(50)') as LOC_VER
			,x.value ('LONGITUDE[1]', 'varchar(50)') as LONGITUDE
			FROM @XML.nodes('/ICADLINK_EVENT/COMMON_EVENT_CALL_LIST/COMMON_EVENT_CALL') as U(x);
		
	
 	-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- 8. Handle VEHIC list Segment
	-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
		Insert VEHIC (filename, process_date, CDTS, CDTS2, CPERS, CTERM, CURENT, DISABLEAUTOQUERY,EID,INFO_SCOPE,
				LICENSE, LICENSE_YR, MAKE, MODEL, MODEL_YEAR, REMARKS, REV_NUM, ROW_NUM, [STATE],
				SUPP_AVAIL_DTS, UDTS, UDTS2,UNID, UPDT_FLAG,UPERS, UTERM, VEHIC_COLOR, VIN)
		SELECT 		
			@FileName,
			@Process_Date,
			a.value('CDTS[1]', 'varchar(50)') as CDTS,
			a.value('CDTS2[1]', 'varchar(50)') as CDTS2,
			a.value('CPERS[1]', 'varchar(50)') as CPERS,
			a.value('CTERM[1]', 'varchar(50)') as CTERM,
			a.value('CURENT[1]', 'varchar(50)') as CURENT,
			a.value('DISABLEAUTOQUERY[1]', 'varchar(50)') as DISABLEAUTOQUERY,
			a.value('EID[1]', 'int') as EID,
			a.value('INFO_SCOPE[1]', 'varchar(50)') as INFO_SCOPE,
			a.value('LICENSE[1]', 'varchar(50)') as LICENSE,
			a.value('LICENSE_YR[1]', 'varchar(50)') as LICENSE_YR,
			a.value('MAKE[1]', 'varchar(50)') as MAKE,
			a.value('MODEL[1]', 'varchar(50)') as MODEL,
			a.value('MODEL_YEAR[1]', 'varchar(50)') as MODEL_YEAR,
			a.value('REMARKS[1]', 'varchar(50)') as REMARKS,
			a.value('REV_NUM[1]', 'varchar(50)') as REV_NUM,
			a.value('ROW_NUM[1]', 'varchar(50)') as ROW_NUM,
			a.value('STATE[1]', 'varchar(50)') as [STATE],
			a.value('SUPP_AVAIL_DTS[1]', 'varchar(50)') as SUPP_AVAIL_DTS,
			a.value('UDTS[1]', 'varchar(50)') as UDTS,
			a.value('UDTS2[1]', 'varchar(50)') as UDTS2,
			a.value('UNID[1]', 'varchar(50)') as UNID,
			a.value('UPDT_FLAG[1]', 'varchar(50)') as UPDT_FLAG,
			a.value('UPERS[1]', 'varchar(50)') as UPERS,
			a.value('UTERM[1]', 'varchar(50)') as UTERM,
			a.value('VEHIC_COLOR[1]', 'varchar(50)') as VEHIC_COLOR,
			a.value('VIN[1]', 'varchar(50)') as VIN
		FROM @XML.nodes('/ICADLINK_EVENT/VEHIC_LIST/VEHIC') as U(a)
	
		-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- 9. Handle PERSO list Segment
	-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
		Insert PERSO (filename, process_date, AGE, CDTS, CPERS, CTERM, [CURRENT], DISABLEAUTOQUERY,DOB, EID,EYE,
				FORM_FLAG, HAIR, HEIGHT, INFO_SCOPE, NME, OLN, RACE, REMARKS, REV_NUM,
				ROW_NUM, SEX, SOC, [STATE], SUPP_AVAIL_DTS, UDTS, UNID, UPDT_FLAG, UPERS, UTERM, [WEIGHT])
		SELECT 
			@FileName,
			@Process_Date,
			a.value('AGE[1]', 'varchar(50)') as AGE,
			a.value('CDTS[1]', 'varchar(50)') as CDTS,
			a.value('CPERS[1]', 'varchar(50)') as CPERS,
			a.value('CTERM[1]', 'varchar(50)') as CTERM,
			a.value('CURRENT[1]', 'varchar(50)') as [CURRENT],
			a.value('DISABLEAUTOQUERY[1]', 'varchar(50)') as DISABLEAUTOQUERY,
			a.value('DOB[1]', 'varchar(50)') as DOB,
			a.value('EID[1]', 'int') as EID,
			a.value('EYE[1]', 'varchar') as EYE,
			a.value('FORM_FLAG[1]', 'varchar') as FORM_FLAG,
			a.value('HAIR[1]', 'varchar(50)') as HAIR,
			a.value('HEIGHT[1]', 'varchar(50)') as HEIGHT,
			a.value('INFO_SCOPE[1]', 'varchar(50)') as INFO_SCOPE,
			a.value('NME[1]', 'varchar(50)') as NME,
			a.value('OLN[1]', 'varchar(50)') as OLN,
			a.value('RACE[1]', 'varchar(50)') as RACE,
			a.value('REMARKS[1]', 'varchar(2000)') as REMARKS,
			a.value('REV_NUM[1]', 'varchar(50)') as REV_NUM,
			a.value('ROW_NUM[1]', 'varchar(50)') as ROW_NUM,
			a.value('SEX[1]', 'varchar(50)') as SEX,
			a.value('SOC[1]', 'varchar(50)') as SOC,
			a.value('STATE[1]', 'varchar(50)') as [STATE],
			a.value('SUPP_AVAIL_DTS[1]', 'varchar(50)') as SUPP_AVAIL_DTS,
			a.value('UDTS[1]', 'varchar(50)') as UDTS,
			a.value('UNID[1]', 'varchar(50)') as UNID,
			a.value('UPDT_FLAG[1]', 'varchar(50)') as UPDT_FLAG,
			a.value('UPERS[1]', 'varchar(50)') as UPERS,
			a.value('UTERM[1]', 'varchar(50)') as UTERM,
			a.value('WEIGHT[1]', 'varchar(50)') as [WEIGHT]
		FROM @XML.nodes('/ICADLINK_EVENT/PERSO_LIST/PERSO') as U(a)
	-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- End of update script
	-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

		-- move to success folder
		set @tmpmsg = 'move /Y ' + @FileName + ' ' + @SuccFolder
		--print @tmpmsg
		exec master.sys.xp_cmdShell @tmpmsg
		COMMIT TRAN @TransactionName;
	  end try
	  begin catch
		-- Action to be taken here, such as to move the file to an exception folder.
		ROLLBACK TRAN @TransactionName;
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();

		--print 'Got error [' + cast(@@Error as varchar(10)) + '] in file = ' + @FileName
		--print 'Error Number [' +  cast(-error_number() as varchar(20)) + '] - ' + @ErrorMessage

		-- if error, then move the file to error folder
		set @tmpmsg = 'move /Y ' + @FileName + ' ' + @ErrFolder
		--print @tmpmsg
		exec master.sys.xp_cmdShell @tmpmsg
	
		set @tmpmsg = ' - ' + 'Error Number [' +  cast(-error_number() as varchar(20)) + '] - ' + @ErrorMessage
		EXEC sp_WriteToFile @LogFile, @tmpmsg
		--print @tmpmsg
		
		-- Use RAISERROR inside the CATCH block to return error
		-- information about the original error that caused
		-- execution to jump to the CATCH block.
		RAISERROR (@ErrorMessage, -- Message text.
				   @ErrorSeverity, -- Severity.
				   @ErrorState -- State.	 
              );
    end catch
		
	set @icount = @icount + 1   
	FETCH NEXT FROM cr_xmlData
	INTO @XML, @FileName;
	
END

set @tmpmsg = ' Part 1 - Total file processed = ' + Convert(varchar(10), @icount)
-- Checking message type first
EXEC sp_WriteToFile @LogFile, @tmpmsg
	
Close cr_xmlData;
Deallocate cr_xmlData;

