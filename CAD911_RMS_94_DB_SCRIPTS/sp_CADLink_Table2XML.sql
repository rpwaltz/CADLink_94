USE [CAD911_RMS_94]
GO
/****** Object:  StoredProcedure [dbo].[sp_CADLink_Table2XML]    Script Date: 6/4/2020 10:23:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_CADLink_Table2XML]
AS
BEGIN
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Section 1. Proces each record in EVENT table.
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Declare @FilePath varchar(100);

set @FilePath = 'D:\CADLink\CFS\'

DECLARE @xmlFile varchar(100);
DECLARE @LogFile varchar(100);
Set @LogFile = @FilePath + 'logs\ICADlog' + Convert(varchar(100), GETDATE(), 110) + '.txt';
DECLARE @tmpmsg varchar(200);

Declare @FileName varchar(200);
Declare @Process_Date datetime;
Declare @RESULTXML XML;
DECLARE @icount int = 0;
DECLARE @xmlText varchar(Max);
DECLARE @ReportNumber varchar(100);
DECLARE @DispCode varchar(10);
DECLARE @EventID int;
DECLARE @Jurisdiction varchar(10);
DECLARE cr_Event cursor for
SELECT EID, filename, process_date FROM EVENT
WHERE is_processed = 0;

EXEC sp_WriteToFile @LogFile, '- Part 2 - STARTING';

Open cr_Event;

FETCH NEXT FROM cr_Event
INTO @EventID, @FileName, @Process_Date;

-- Check @@FETCH_STATUS to see if there are any more rows to fetch.
WHILE @@FETCH_STATUS = 0 
BEGIN
	set @Jurisdiction = 'XXXXXXXXX';
	--Print @EventID
	Set  @tmpmsg = ' - Process CADLINK file = ' + @FileName;
	EXEC sp_WriteToFile @LogFile, @tmpmsg;

	Set @xmlFile = @FilePath + 'CAD_' + CAST(@EventID AS varchar(512)) + '.xml';
	
	-- Get special data for simplification and convert report number

	Select top 1 @DispCode = DISPO, @ReportNumber = CASE_NUM from EV_DISPO where filename = @FileName and process_date = @Process_Date order by CDTS desc;
	set @ReportNumber = SUBSTRING(@ReportNumber, 2, 2) + '-' + right(@ReportNumber, 6)	;
	
	Select @RESULTXML =( SELECT
		(SELECT top 1 b.AG_ID as dept_name, @Jurisdiction as jurisdiction, b.NUM_1 as oca_number, @ReportNumber as call_number, 
			e.FNAME + ' ' + e.LNAME as call_taker, e.USR_ID as answer_pos, b.ALARM_LEV as alarm_code, b.TYP_ENG as complaint_reported_as, 
			@DispCode as complaint_found_as, dbo.fn_ToDateTime(b.AD_TS) as date_received, b.STATUS_CODE as call_status, 
			substring(b.TYCOD, 3, 2) as call_ten_code, b.PRIORITY as priority, c.LOCATION as actual_incid_location,
			a.EAPT as actual_incid_apartment, a.EMUN as actual_incid_city, 
			d.CLNAME as caller_name, d.CLRNUM as phone_number, a.ELOCATION as caller_location, a.EAPT as caller_apartment,
			a.EMUN as caller_city, a.ECOMPL as landmark, b.PRIM_UNIT as first_unit, dbo.fn_ToDateTime(b.AD_TS) as time_received, 
			dbo.fn_ToDateTime(b.TR_TS) as time_transmitted, dbo.fn_ToDateTime(b.DS_TS) as time_dispatched, 
			dbo.fn_ToDateTime(b.EN_TS) as time_enoute, dbo.fn_ToDateTime(b.AR_TS) as time_onscene, 
			dbo.fn_ToDateTime(b.XDTS) as time_complete, c.COMMENTS as narrative
		 FROM EVENT as a 
		 Left Join AEVEN as b on a.filename = b.filename and a.process_date = b.process_date
		 Left Join DERIVED_DATA c on a.filename = c.filename and a.process_date = c.process_date
		 Left Join COMMON_EVENT_CALL d on a.filename = d.filename and a.process_date = d.process_date
		 Left Join PERSL e on a.filename = e.filename and a.process_date = e.process_date
		 where a.filename = @FileName and a.process_date = @Process_Date FOR XML PATH(''), TYPE),
		(SELECT top 1 b.DGROUP as disp_zone, b.LEV3 as tract, b.ESZ as grid, a.X_CORD as x_coord, a.Y_CORD as y_coord 
    		 FROM EVENT as a Left Join AEVEN as b on a.filename = b.filename and a.process_date = b.process_date 
			 where a.filename = @FileName and a.process_date = @Process_Date
			FOR XML PATH('CFS_CALL_GEOGRAPHY'), TYPE),
		(SELECT MAKE as vehicle_make, model as vehicle_model, VEHIC_COLOR as vehicle_color, MODEL_YEAR as vehicle_year,
			VIN as vehicle_vin, LICENSE as vehicle_tag, [STATE] as vehicle_state, LICENSE_YR as vehicle_tag_year,
			REMARKS as Comments
    		 FROM VEHIC where filename = @FileName and process_date = @Process_Date 
			FOR XML PATH('CFS_CALL_VEHICLE'), TYPE),
		(SELECT NME as name_last, HEIGHT as height, [WEIGHT] as [weight], RACE as race,
			SEX as sex, DOB as dob, AGE as age_min, OLN as ol_number, [STATE] as ol_state, SOC as ssn,
			REMARKS as [description]
			 FROM PERSO where filename = @FileName and process_date = @Process_Date 
			FOR XML PATH('CFS_CALL_PERSON'), TYPE)
		FOR XML PATH('CFS_ACTIVE_CALL'), ROOT('CFS'));
	    
	set @xmlText = '<?xml version="1.0" encoding="UTF-8" ?>' + CONVERT(varchar(Max), @RESULTXML);
	---- Write the XML heading statement

	-- Create a XML file on target folder
	EXEC sp_WriteToFile @xmlFile, @xmlText, NODATESTAMP;
	Set  @tmpmsg = ' - Saved file = ' + @xmlFile;
	EXEC sp_WriteToFile @LogFile, @tmpmsg;
	-- Update flagt in the EVENT table (dateProcessed)
	Update Event set is_processed = 1  where filename = @FileName and process_date = @Process_Date;
		
	set @icount = @icount + 1 ;
		
	FETCH NEXT FROM cr_Event
	INTO @EventID, @FileName, @Process_Date;


End

set @tmpmsg = ' Part 2 - Total Records updated = ' + CONVERT(Varchar(40), @icount);
EXEC sp_WriteToFile @LogFile, @tmpmsg;

-- Clean cursor
Close cr_Event;

Deallocate cr_Event;
END;
GO

GRANT EXECUTE ON [dbo].[sp_CADLink_Table2XML] TO sqlconn ;
GRANT EXECUTE ON [dbo].[sp_CADLink_Table2XML] TO [KNOXVILLE\sqlconn] ;
GO
