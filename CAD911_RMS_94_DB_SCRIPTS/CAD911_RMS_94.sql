

USE [CAD911_RMS_94]
GO


DROP TABLE  RMSwithOpenXML
CREATE TABLE  RMSwithOpenXML
(
Id INT IDENTITY PRIMARY KEY,
XMLData XML,
xmlFileName varchar(400));


DROP TABLE EVCOMM;
DROP TABLE AEVEN;
DROP TABLE EV_DISPO;
DROP TABLE UN_HI;
DROP TABLE UN_HI_PERSL ;
DROP TABLE CASE_NUM;
DROP TABLE PERSL;
DROP TABLE COMMON_EVENT_CALL ;
DROP TABLE PERSO ;
DROP TABLE VEHIC;
DROP TABLE DERIVED_DATA;
DROP TABLE EVENT;


CREATE TABLE EVENT (
filename nvarchar(400) NOT NULL
,process_date datetime NOT NULL
,is_processed int
,CDTS   nvarchar(50)   -->20200521163430ED, CDTS   nvarchar(50)   -->
,CDTS_TIMESTAMP   nvarchar(50)   -->
,CDTS_DATE   nvarchar(50)   -->5 21 2020, CDTS_DATE   nvarchar(50)   -->
,CDTS_TIME   nvarchar(50)   -->16:34:30, CDTS_TIME   nvarchar(50)   -->
,CECUST1    nvarchar(50)   -->
,CECUST2    nvarchar(50)   -->
,CECUST3    nvarchar(50)   -->
,CECUST4    nvarchar(50)   -->
,CPERS   nvarchar(50)   -->100537, CPERS   nvarchar(50)   -->
,CSEC   nvarchar(50)   -->1590093270, CSEC   nvarchar(50)   -->
,CTERM   nvarchar(50)   -->100537, CTERM   nvarchar(50)   -->
,CURENT   nvarchar(50)   -->T, CURENT   nvarchar(50)   -->
,DOW   nvarchar(50)   -->5, DOW   nvarchar(50)   -->
,EAPT    nvarchar(50)   -->
,EAREA    nvarchar(50)   -->
,ECOMPL   nvarchar(50)   -->KPD, ECOMPL   nvarchar(50)   -->
,EDIRPRE   nvarchar(50)   -->E, EDIRPRE   nvarchar(50)   -->
,EDIRSUF    nvarchar(50)   -->
,EFEANME   nvarchar(50)   -->5TH, EFEANME   nvarchar(50)   -->
,EFEATYP   nvarchar(50)   -->AVE, EFEATYP   nvarchar(50)   -->
,EID   nvarchar(50)   -->2511762, EID   nvarchar(50)   -->
,ELOC_FLD1    nvarchar(50)   -->
,ELOC_FLD2    nvarchar(50)   -->
,ELOC_FLD3    nvarchar(50)   -->
,ELOC_FLD4    nvarchar(50)   -->
,ELOCATION   nvarchar(512)   -->913 E 5TH AVE KNOX: @KPD, ELOCATION   nvarchar(50)   -->
,EMUN   nvarchar(50)   -->KNOX, EMUN   nvarchar(50)   -->
,ESTNUM   nvarchar(50)   -->913, ESTNUM   nvarchar(50)   -->
,FEA_MSLINK   nvarchar(50)   -->10329, FEA_MSLINK   nvarchar(50)   -->
,HASH   nvarchar(50)   -->712392916, HASH   nvarchar(50)   -->
,LOC_COM   nvarchar(50)   -->: @KPD, LOC_COM   nvarchar(50)   -->
,LOC_VER   nvarchar(50)   -->T, LOC_VER   nvarchar(50)   -->
,LOI_EVENT   nvarchar(50)   -->T, LOI_EVENT   nvarchar(50)   -->
,LOI_INF   nvarchar(50)   -->F, LOI_INF   nvarchar(50)   -->
,LOI_SPECSIT   nvarchar(50)   -->T, LOI_SPECSIT   nvarchar(50)   -->
,MAPLEVS    nvarchar(50)   -->
,PARSE_TYPE   nvarchar(50)   -->2, PARSE_TYPE   nvarchar(50)   -->
,PATIENT    nvarchar(50)   -->
,PCAD_CASE_NUM    nvarchar(50)   -->
,REV_NUM   nvarchar(50)   -->1, REV_NUM   nvarchar(50)   -->
,S_ESZ   nvarchar(50)   -->-1, S_ESZ   nvarchar(50)   -->
,UDTS   nvarchar(50)   -->20200521163431ED, UDTS   nvarchar(50)   -->
,UDTS_DATE   nvarchar(50)   -->5 21 2020, UDTS_DATE   nvarchar(50)   -->
,UDTS_TIME   nvarchar(50)   -->16:34:31, UDTS_TIME   nvarchar(50)   -->
,UPDT_FLAG   nvarchar(50)   -->NULLTERM, UPDT_FLAG   nvarchar(50)   -->
,UPERS    nvarchar(50)   -->
,UTERM   nvarchar(50)   -->db_server, UTERM   nvarchar(50)   -->
,X_CORD   nvarchar(50)   -->258537614, X_CORD   nvarchar(50)   -->
,XSTREET1   nvarchar(50)   -->FRAZIER ST, XSTREET1   nvarchar(50)   -->
,XSTREET2   nvarchar(50)   -->JESSAMINE ST, XSTREET2   nvarchar(50)   -->
,Y_CORD   nvarchar(50)   -->60540900, Y_CORD   nvarchar(50)   -->
,ZIP    nvarchar(50)   -->
,LATITUDE   nvarchar(50)   -->35.978465, LATITUDE   nvarchar(50)   -->
,LONGITUDE   nvarchar(50)   -->-83.914943, LONGITUDE   nvarchar(50)   -->
,MAPGRIDS    nvarchar(50)   -->
)

ALTER TABLE EVENT
   ADD CONSTRAINT PK_EVENT_CAD911_RMS_94 PRIMARY KEY CLUSTERED (filename, process_date);


CREATE TABLE DERIVED_DATA (
	filename nvarchar(400) NOT NULL
	,process_date datetime NOT NULL
	,is_processed int
	,LOCATION varchar(50)
	,COMMENTS varchar(4096) );
   
ALTER TABLE DERIVED_DATA  WITH CHECK ADD  CONSTRAINT [FK_DERIVED_DATA_CAD911_RMS_94] FOREIGN KEY(filename, process_date)
REFERENCES EVENT (filename, process_date)
ON DELETE CASCADE;


CREATE TABLE EVCOMM(
	filename nvarchar(400) NOT NULL
	,process_date datetime NOT NULL
    ,CDTS   nvarchar(50) -- AS CDTS, 
,   CDTS_DATE 	NVARCHAR(50)  --CDTS_TIMESTAMP[1]/CDTS_DATE   varchar(50)')  AS  CDTS_DATE,
,   CDTS_TIME   NVARCHAR(50)  -- CDTS_TIMESTAMP[1]/CDTS_TIME   varchar(50)') AS  CDTS_TIME,
,   CDTS_DATETIME NVARCHAR(50) -- CDTS_TIMESTAMP[1]/CDTS_DATETIME   varchar(50)')  AS  CDTS_DATETIME,
,   COMM	varchar(255)-- AS  COMM, 
,   COMM_KEY   nvarchar(50) -- AS  COMM_KEY, 
,   COMM_SCOPE   nvarchar(50)-- AS COMM_SCOPE, 
,   CPERS   nvarchar(50)-- AS CPERS,
,   CSEC   nvarchar(50)-- AS CSEC,
,   CTERM   nvarchar(50)-- AS CTERM, 
,   EID   int -- AS EID,
,   LIN_GRP   nvarchar(50)-- AS LIN_GRP_OLD,
,   LIN_ORD   nvarchar(50)-- AS LIN_ORD_OLD,
,   UNIQUE_ID   nvarchar(50)-- AS UNIQUE_ID_OLD,
,   C2CSENT   nvarchar(50)-- AS C2CSENT,
,   C2CSENT_UNIQUE_ID   nvarchar(50)-- AS C2CSENT_UNIQUE_ID
,   C2C_UNIQUE_ID   nvarchar(50)-- AS C2C_UNIQUE_ID
,   C2C_SENT   nvarchar(50)-- AS C2C_SENT
,   ADORNED_COMM   nvarchar(50)-- AS ADORNED_COMM
,   ADORNED_COMM_STYLE   nvarchar(50)-- AS ADORNED_COMM_STYLE
,   COMM_SCOPE_GROUP   nvarchar(50)-- AS COMM_SCOPE_GROUP
,   EVCOMMID   nvarchar(50)-- AS  EVCOMMID
,   EVCOMM_PRIORITY   nvarchar(50)-- AS PRIORITY 
,   REMOTE_AGENCY   nvarchar(50)-- AS REMOTE_AGENCY
,   REMOTE_COMMENT_ID   nvarchar(50)-- AS REMOTE_COMMENT_ID
,   EVCOMM_TYPE   nvarchar(50)-- AS EVCOMMTYPE
);

ALTER TABLE EVCOMM  WITH CHECK ADD  CONSTRAINT [FK_EVCOMM_CAD911_RMS_94] FOREIGN KEY(filename, process_date)
REFERENCES EVENT (filename, process_date)
ON DELETE CASCADE;


CREATE TABLE AEVEN (
filename nvarchar(400) NOT NULL
,process_date datetime NOT NULL
,ACKNOWLEDGE_TIMER    nvarchar(50)   -- as ACKNOWLEDGE_TIMER
,AD_SEC    nvarchar(50)   -- as AD_SEC
,AD_TS    nvarchar(50)   -- as AD_TS
,AD_TS_DATE    nvarchar(50) --AD_TS_TIMESTAMP[1]/AD_TS_DATE    nvarchar(50)    -- as AD_TS_DATE
,AD_TS_TIME	   nvarchar(50) --AD_TS_TIMESTAMP[1]/AD_TS_TIME    nvarchar(50)    -- as AD_TS_TIME
,AECUST1    nvarchar(50)   -- as AECUST1
,AECUST2    nvarchar(50)   -- as AECUST2
,AECUST3    nvarchar(50)   -- as AECUST3
,AECUST4    nvarchar(50)   -- as AECUST4
,AG_ID    nvarchar(50)   -- as AG_ID
,ALARM_LEV    nvarchar(50)   -- as ALARM_LEV
,APPT_ALARM_UNTIL    nvarchar(50)   -- as APPT_ALARM_UNTIL
,APPT_END_TS    nvarchar(50)   -- as APPT_END_TS
,APPT_END_TS_DATE	NVARCHAR(50)  -- APPT_END_TS_TIMESTAMP
,APPT_END_TS_TIME	NVARCHAR(50)  -- APPT_END_TS_TIMESTAMP
,APPT_START_DTS    nvarchar(50)   -- as APPT_START_DTS
,AR_SEC    nvarchar(50)   -- as AR_SEC
,AR_TS    nvarchar(50)   -- as AR_TS
,AR_TS_DATE    nvarchar(50)   -- as AR_TS_TIMESTAMP
,AR_TS_TIME    nvarchar(50)   -- as AR_TS_TIMESTAMP
,ARRIVE_TIMER    nvarchar(50)   -- as ARRIVE_TIMER
,ASSIGNED_UNITS    nvarchar(50)   -- as -- asSIGNED_UNITS
,CALLBACK_DTS    nvarchar(50)   -- as CALLBACK_DTS
,CBTIME2    nvarchar(50)   -- as CBTIME2
,CDTS    nvarchar(50)   -- as CDTS
,CDTS_DATE   nvarchar(50)   -- as CDTS_TIMESTAMP
,CDTS_TIME   nvarchar(50)   -- as CDTS_TIMESTAMP
,CLOSING_ALLOWED    nvarchar(50)   -- as CLOSING_ALLOWED
,CPERS    nvarchar(50)   -- as CPERS
,CREATE_PERS    nvarchar(50)   -- as CREATE_PERS
,CREATE_TERM    nvarchar(50)   -- as CREATE_TERM
,CSEC    nvarchar(50)   -- as CSEC
,CTERM    nvarchar(50)   -- as CTERM
,CURENT    nvarchar(50)   -- as CURENT
,DEST_EID    nvarchar(50)   -- as DEST_EID
,DGROUP    nvarchar(50)   -- as DGROUP
,DISPAAS_UNIT    nvarchar(50)   -- as DISP-- asS_UNIT
,DISPATCH_TIMER    nvarchar(50)   -- as DISPATCH_TIMER
,DS_SEC    nvarchar(50)   -- as DS_SEC
,DS_TS    nvarchar(50)   -- as DS_TS
,DS_TS_DATE    nvarchar(50)   -- as DS_TS_TIMESTAMP
,DS_TS_TIME    nvarchar(50)   -- as DS_TS_TIMESTAMP
,DUE_DTS    nvarchar(50)   -- as DUE_DTS
,EID    nvarchar(50)   -- as EID
,EN_SEC    nvarchar(50)   -- as EN_SEC
,EN_TS    nvarchar(50)   -- as EN_TS
,EN_TS_DATE    nvarchar(50)   -- as EN_TS_TIMESTAMP
,EN_TS_TIME    nvarchar(50)   -- as EN_TS_TIMESTAMP
,ENROUTE_TIMER    nvarchar(50)   -- as ENROUTE_TIMER
,ESZ    nvarchar(50)   -- as ESZ
,ETA    nvarchar(50)   -- as ETA
,EVENT_DESC    nvarchar(50)   -- as EVENT_DESC
,EVT_REV_NUM    nvarchar(50)   -- as EVT_REV_NUM
,EX_EVT    nvarchar(50)   -- as EX_EVT
,EXTERNAL_EVENT_ID    nvarchar(50)   -- as EXTERNAL_EVENT_ID
,FLAGS    nvarchar(50)   -- as FLAGS
,GROUP_ID    nvarchar(50)   -- as GROUP_ID
,GROUP_ORDER    nvarchar(50)   -- as GROUP_ORDER
,HOLD_DTS    nvarchar(50)   -- as HOLD_DTS
,HOLD_DTS_DATE    nvarchar(50)   -- as HOLD_DTS_TIMESTAMP
,HOLD_DTS_TIME    nvarchar(50)   -- as HOLD_DTS_TIMESTAMP
,HOLD_TYPE    nvarchar(50)   -- as HOLD_TYPE
,HOLD_UNT    nvarchar(50)   -- as HOLD_UNT
,IS_OPEN    nvarchar(50)   -- as IS_OPEN
,IS_REC_ENABLED    nvarchar(50)   -- as IS_REC_ENABLED
,IS_REC_PREEMPT_ENABLED    nvarchar(50)   -- as IS_REC_PREEMPT_ENABLED
,LATE_RUN    nvarchar(50)   -- as LATE_RUN
,LEV2    nvarchar(50)   -- as LEV2
,LEV3    nvarchar(50)   -- as LEV3
,LEV4    nvarchar(50)   -- as LEV4
,LEV5    nvarchar(50)   -- as LEV5
,LOI_AVAIL_DTS    nvarchar(50)   -- as LOI_AVAIL_DTS
,LOI_AVAIL_DTS_DATE    nvarchar(50)   -- as LOI_AVAIL_DTS_TIMESTAMP
,LOI_AVAIL_DTS_TIME    nvarchar(50)   -- as LOI_AVAIL_DTS_TIMESTAMP
,MAJEVT_EVTY    nvarchar(50)   -- as MAJEVT_EVTY
,MAJEVT_LOC    nvarchar(50)   -- as MAJEVT_LOC
,MUN    nvarchar(50)   -- as MUN
,NUM_1    nvarchar(50)   -- as NUM_1
,OPEN_AND_CURENT    nvarchar(50)   -- as OPEN_AND_CURENT
,PEND_DTS    nvarchar(50)   -- as PEND_DTS
,PEND_DTS_DATE    nvarchar(50)   -- as PEND_DTS_TIMESTAMP
,PEND_DTS_TIME    nvarchar(50)   -- as PEND_DTS_TIMESTAMP
,PENDING_TIMER    nvarchar(50)   -- as PENDING_TIMER
,PLANNED_TASK_END_DTS    nvarchar(50)   -- as PLANNED_TasK_END_DTS
,PLANNED_TASK_END_DTS_DATE    nvarchar(50)   -- as PLANNED_TasK_END_DTS_TIMESTAMP
,PLANNED_TASK_END_DTS_TIME    nvarchar(50)   -- as PLANNED_TasK_END_DTS_TIMESTAMP
,PLANNED_TASK_START_DTS    nvarchar(50)   -- as PLANNED_TasK_START_DTS
,PLANNED_TASK_START_DTS_DATE    nvarchar(50)   -- as PLANNED_TasK_START_DTS_TIMESTAMP
,PLANNED_TASK_START_DTS_TIME    nvarchar(50)   -- as PLANNED_TasK_START_DTS_TIMESTAMP
,PRIM_MEMBER    nvarchar(50)   -- as PRIM_MEMBER
,PRIM_UNIT    nvarchar(50)   -- as PRIM_UNIT
,PRIORITY    nvarchar(50)   -- as PRIORITY
,PRIORITY_CHANGED_DTS    nvarchar(50)   -- as PRIORITY_CHANGED_DTS
,PROBE_FLAG    nvarchar(50)   -- as PROBE_FLAG
,PROQA_CASE_NUM    nvarchar(50)   -- as PROQA_C-- asE_NUM
,PROQA_CASE_TYPE    nvarchar(50)   -- as PROQA_C-- asE_TYPE
,REC_FEA_MSLINK    nvarchar(50)   -- as REC_FEA_MSLINK
,REC_SELECT_MODE    nvarchar(50)   -- as REC_SELECT_MODE
,REC_X_CORD    nvarchar(50)   -- as REC_X_CORD
,REC_Y_CORD    nvarchar(50)   -- as REC_Y_CORD
,RECOM_INCOMPLETE    nvarchar(50)   -- as RECOM_INCOMPLETE
,RECOMMEND_MODE    nvarchar(50)   -- as RECOMMEND_MODE
,REOPEN    nvarchar(50)   -- as REOPEN
,RESP_DOWN    nvarchar(50)   -- as RESP_DOWN
,REV_NUM    nvarchar(50)   -- as REV_NUM
,SCDTS    nvarchar(50)   -- as SCDTS
,SCDTS_DATE    nvarchar(50)   -- as SCDTS_TIMESTAMP
,SCDTS_TIME    nvarchar(50)   -- as SCDTS_TIMESTAMP
,SDTS    nvarchar(50)   -- as SDTS
,SDTS_DATE    nvarchar(50)   -- as SDTS_TIMESTAMP
,SDTS_TIME    nvarchar(50)   -- as SDTS_TIMESTAMP
,SITFND    nvarchar(50)   -- as SITFND
,SSEC    nvarchar(50)   -- as SSEC
,STATUS_CODE    nvarchar(50)   -- as STATUS_CODE
,SUB_ENG    nvarchar(50)   -- as SUB_ENG
,SUB_SITFND    nvarchar(50)   -- as SUB_SITFND
,SUB_TYCOD    nvarchar(50)   -- as SUB_TYCOD
,SUPP_INFO    nvarchar(50)   -- as SUPP_INFO
,TA_SEC    nvarchar(50)   -- as TA_SEC
,TA_TS    nvarchar(50)   -- as TA_TS
,TA_TS_DATE    nvarchar(50)   -- as TA_TS_TIMESTAMP
,TA_TS_TIME    nvarchar(50)   -- as TA_TS_TIMESTAMP
,TALK_GROUP_LABEL    nvarchar(50)   -- as TALK_GROUP_LABEL
,TR_SEC    nvarchar(50)   -- as TR_SEC
,TR_TS    nvarchar(50)   -- as TR_TS
,TR_TS_DATE    nvarchar(50)   -- as TR_TS_TIMESTAMP
,TR_TS_TIME    nvarchar(50)   -- as TR_TS_TIMESTAMP
,TYCOD    nvarchar(50)   -- as TYCOD
,TYP_ENG    nvarchar(50)   -- as TYP_ENG
,UDTS    nvarchar(50)   -- as UDTS
,UDTS_DATE    nvarchar(50)   -- as UDTS_TIMESTAMP
,UDTS_TIME    nvarchar(50)   -- as UDTS_TIMESTAMP
,UPERS    nvarchar(50)   -- as UPERS
,UTERM    nvarchar(50)   -- as UTERM
,VDTS    nvarchar(50)   -- as VDTS
,VDTS_DATE    nvarchar(50)   -- as VDTS_TIMESTAMP
,VDTS_TIME    nvarchar(50)   -- as VDTS_TIMESTAMP
,VSEC    nvarchar(50)   -- as VSEC
,XCMT    nvarchar(50)   -- as XCMT
,XDOW    nvarchar(50)   -- as XDOW
,XDTS    nvarchar(50)   -- as XDTS
,XDTS_DATE    nvarchar(50)   -- as XDTS_TIMESTAMP
,XDTS_TIME    nvarchar(50)   -- as XDTS_TIMESTAMP
,XPERS    nvarchar(50)   -- as XPERS
,XSEC    nvarchar(50)   -- as XSEC
,XTERM    nvarchar(50)   -- as XTERM
,CHAN    nvarchar(50)   -- as CHAN
,MAPGRIDS    nvarchar(50)   -- as MAPGRIDS
,MEDS_CASE    nvarchar(50)   -- as MEDS_C-- asE
,SEE_CP    nvarchar(50)   -- as SEE_CP
);

ALTER TABLE AEVEN  WITH CHECK ADD  CONSTRAINT [FK_AEVEN_CAD911_RMS_94] FOREIGN KEY(filename, process_date)
REFERENCES EVENT (filename, process_date)
ON DELETE CASCADE;


CREATE TABLE EV_DISPO (
filename nvarchar(400) NOT NULL
,process_date datetime NOT NULL
,  CASE_NUM  NVARCHAR(50)-- AS CASE_NUM
, CDTS  NVARCHAR(50)-- AS CDTS
, CDTS_DATE  NVARCHAR(50)-- AS CDTS_DATE
, CDTS_TIME  NVARCHAR(50)-- AS CDTS_TIME
, CPERS  NVARCHAR(50)-- AS CPERS
, CTERM  NVARCHAR(50)-- AS CTERM
, CURENT  NVARCHAR(50)-- AS CURENT
, DISPO  NVARCHAR(50)-- AS DISPO
, EID  NVARCHAR(50)-- AS EID
, MEMBER_ID  NVARCHAR(50)-- AS MEMBER_ID
, NUM_1  NVARCHAR(50)-- AS NUM_1
, QUAL1  NVARCHAR(50)-- AS QUAL1
, QUAL2  NVARCHAR(50)-- AS QUAL2
, QUAL3  NVARCHAR(50)-- AS QUAL3
, REV_NUM  NVARCHAR(50)-- AS REV_NUM
, ROW_NUM  NVARCHAR(50)-- AS ROW_NUM
, UDTS  NVARCHAR(50)-- AS UDTS
, UDTS_DATE  NVARCHAR(50)-- AS UDTS_DATE
, UDTS_TIME  NVARCHAR(50)-- AS UDTS_TIME
, UNIT_ID  NVARCHAR(50)-- AS UNIT_ID
, UPERS  NVARCHAR(50)-- AS UPERS
, UTERM  NVARCHAR(50)-- AS UTERM
);

ALTER TABLE EV_DISPO  WITH CHECK ADD  CONSTRAINT [FK_EV_DISPO_CAD911_RMS_94] FOREIGN KEY(filename, process_date)
REFERENCES EVENT (filename, process_date)
ON DELETE CASCADE;


CREATE TABLE UN_HI (
filename nvarchar(400) NOT NULL
,process_date datetime NOT NULL
, ACT_CHECK   nvarchar(50)-- AS ACT_CHECK
, AG_ID   nvarchar(50)-- AS AG_ID
, AGENCY_EVENT_REV_NUM   nvarchar(50)-- AS AGENCY_EVENT_REV_NUM
, CARID   nvarchar(50)-- AS CARID
, CDTS   nvarchar(50)-- AS CDTS
, CDTS_DATE   nvarchar(50)-- AS CDTS_DATE
, CDTS_TIME   nvarchar(50)-- AS CDTS_TIME
, CPERS   nvarchar(50)-- AS CPERS
, CREW_ID   nvarchar(50)-- AS CREW_ID
, CSEC   nvarchar(50)-- AS CSEC
, CTERM   nvarchar(50)-- AS CTERM
, DGROUP   nvarchar(50)-- AS DGROUP
, DISP_ALARM_LEV   nvarchar(50)-- AS DISP_ALARM_LEV
, DISP_NUM   nvarchar(50)-- AS DISP_NUM
, EID   nvarchar(50)-- AS EID
, LASTXOR   nvarchar(50)-- AS LASTXOR
, LASTYOR   nvarchar(50)-- AS LASTYOR
, LOCATION   nvarchar(50)-- AS LOCATION
, MDTHOSTNAME   nvarchar(50)-- AS MDTHOSTNAME
, MDTID_OLD   nvarchar(50)-- AS MDTID_OLD
, MILEAGE   nvarchar(50)-- AS MILEAGE
, NUM_1   nvarchar(50)-- AS NUM_1
, OAG_ID   nvarchar(50)-- AS OAG_ID
, ODGROUP   nvarchar(50)-- AS ODGROUP
, PAGE_ID   nvarchar(50)-- AS PAGE_ID
, RADIO_ALIAS_OLD   nvarchar(50) -- AS RADIO_ALIAS_OLD
, RECOVERY_CDTS   nvarchar(50)-- AS RECOVERY_CDTS
, RECOVERY_CDTS_DATE   nvarchar(50)-- AS RECOVERY_CDTS_DATE
, RECOVERY_CDTS_TIME   nvarchar(50)-- AS RECOVERY_CDTS_TIME
, STATION   nvarchar(50)-- AS STATION
, SUB_TYCOD   nvarchar(50)-- AS SUB_TYCOD
, TYCOD   nvarchar(50)-- AS TYCOD
, UCUST1   nvarchar(50)-- AS UCUST1
, UCUST2   nvarchar(50)-- AS UCUST2
, UCUST3   nvarchar(50)-- AS UCUST3
, UCUST4   nvarchar(50)-- AS UCUST4
, UHISCM   nvarchar(50)-- AS UHISCM
, UNID   nvarchar(50)-- AS UNID
, UNIQUE_ID   nvarchar(50)-- AS UNIQUE_ID
, UNIT_STATUS   nvarchar(50)-- AS UNIT_STATUS
, UNITYP   nvarchar(50)-- AS UNITYP
, CDTS2   nvarchar(50)-- AS CDTS2
, LATITUDE   nvarchar(50)-- AS LATITUDE
, LONGITUDE   nvarchar(50)-- AS LONGITUDE
, TRACK_PERSONNEL   nvarchar(50)-- AS TRACK_PERSONNEL
, UN_HI_CHILD_CHANGE_ID   nvarchar(50)-- AS UN_HI_CHILD_CHANGE_ID
, ACTION_CODE   nvarchar(50)-- AS ACTION_CODE
, ASSIGNED_NUM_1   nvarchar(50)-- AS ASSIGNED_NUM_1
, FACILITY_ENTRANCE_ID   nvarchar(50)-- AS FACILITY_ENTRANCE_ID
, ORDER_WITHIN_CDTS   nvarchar(50)-- AS ORDER_WITHIN_CDTS
, ROLE_DESIGNATOR   nvarchar(50)-- AS ROLE_DESIGNATOR
, STAGING_AREA_ID   nvarchar(50)-- AS STAGING_AREA_ID
, TRANSPORT_LATITUDE   nvarchar(50)-- AS TRANSPORT_LATITUDE
, TRANSPORT_LOCATION   nvarchar(50)-- AS TRANSPORT_LOCATION
, TRANSPORT_LONGITUDE   nvarchar(50)-- AS TRANSPORT_LONGITUDE
)

ALTER TABLE UN_HI  WITH CHECK ADD  CONSTRAINT [FK_UN_HI_CAD911_RMS_94] FOREIGN KEY(filename, process_date)
REFERENCES EVENT (filename, process_date)
ON DELETE CASCADE;

CREATE TABLE UN_HI_PERSL (
	filename nvarchar(400) NOT NULL,
	process_date datetime NOT NULL,
	CDTS nvarchar(255) NULL,
	EMPID bigint NULL,
	HT_RADIO nvarchar(255) NULL,
	PRIMARY_EMPID nvarchar(255) NULL,
	RECOVERY_CDTS nvarchar(255) NULL,
	UN_HI_REC_ID nvarchar(255) NULL,
	UN_HI_PERSL_LIST_Id [numeric](20, 0) NULL);
	
ALTER TABLE UN_HI_PERSL  WITH CHECK ADD  CONSTRAINT [FK_UN_HI_PERSL_CAD911_RMS_94] FOREIGN KEY(filename, process_date)
REFERENCES EVENT (filename, process_date)
ON DELETE CASCADE;


 CREATE TABLE CASE_NUM(
 	filename nvarchar(400) NOT NULL
, process_date datetime NOT NULL
, AG_ID   NVARCHAR(50) -- AS AG_ID
, CASE_NUM   NVARCHAR(50)-- AS CASE_NUM
, CDTS   NVARCHAR(50)-- AS CDTS
, CDTS_DATE   NVARCHAR(50)-- AS CDTS_DATE
, CDTS_TIME   NVARCHAR(50)-- AS CDTS_TIME
, CPERS   NVARCHAR(50)-- AS CPERS
, CTERM   NVARCHAR(50)-- AS CTERM
, CURENT   NVARCHAR(50)-- AS CURENT
, DGROUP   NVARCHAR(50)-- AS DGROUP
, EID   NVARCHAR(50)-- AS EID
, NUM_1   NVARCHAR(50)-- AS NUM_1
, UDTS   NVARCHAR(50)-- AS UDTS
, UDTS_DATE   NVARCHAR(50)-- AS UDTS_DATE
, UDTS_TIME   NVARCHAR(50)-- AS UDTS_TIME
, UPERS   NVARCHAR(50)-- AS UPERS
, UTERM   NVARCHAR(50)-- AS UTERM
, SUNPRO_AG_ID   NVARCHAR(50)-- AS SUNPRO_AG_ID
);

ALTER TABLE CASE_NUM  WITH CHECK ADD  CONSTRAINT [FK_CASE_NUM_CAD911_RMS_94] FOREIGN KEY(filename, process_date)
REFERENCES EVENT (filename, process_date)
ON DELETE CASCADE;


create table PERSL (
 filename nvarchar(400) NOT NULL
, process_date datetime NOT NULL
, AG_ID      varchar(50)-- AS  AG_ID
,APP_TYPE      varchar(50)-- AS  APP_TYPE
,BL_TYP      varchar(50)-- AS  BL_TYP
,CAD_CMD_MASK      varchar(50)-- AS  CAD_CMD_MASK
,CHATID      varchar(50)-- AS  CHATID
,CURENT      varchar(50)-- AS  CURENT
,DBM_CMD_MASK      varchar(50)-- AS  DBM_CMD_MASK
,DEFAULT_UNID      varchar(50)-- AS  DEFAULT_UNID
,DELEX      varchar(50)-- AS  DELEX
,DELNO      varchar(50)-- AS  DELNO
,DOMAIN      varchar(50)-- AS  DOMAIN
,EMAIL      varchar(50)-- AS  EMAIL
,EMP_ADD      varchar(50)-- AS  EMP_ADD
,EMP_CITY      varchar(50)-- AS  EMP_CITY
,EMP_NUM      varchar(50)-- AS  EMP_NUM
,EMP_ST      varchar(50)-- AS  EMP_ST
,EMPID      varchar(50)-- AS  EMPID
,FNAME      varchar(50)-- AS  FNAME
,HOST_TERM      varchar(50)-- AS  HOST_TERM
,HT_RADIO_OLD      varchar(50)-- AS  HT_RADIO_OLD
,LDTS      varchar(50)-- AS  LDTS
,LDTS_DATE      varchar(50)-- AS  LDTS_DATE
,LDTS_TIME      varchar(50)-- AS  LDTS_TIME
,LNAME      varchar(50)-- AS  LNAME
,LODTS      varchar(50)-- AS  LODTS
,LODTS_DATE      varchar(50)-- AS  LODTS_DATE
,LODTS_TIME      varchar(50)-- AS  LODTS_TIME
,LOGGED_ON      varchar(50)-- AS  LOGGED_ON
,MI      varchar(50)-- AS  MI
,NOT_ADD      varchar(50)-- AS  NOT_ADD
,NOT_CITY      varchar(50)-- AS  NOT_CITY
,NOT_NME      varchar(50)-- AS  NOT_NME
,NOT_PH      varchar(50)-- AS  NOT_PH
,NOT_ST      varchar(50)-- AS  NOT_ST
,PAGE_ID      varchar(50)-- AS  PAGE_ID
,PASS_DATE      varchar(50)-- AS  PASS_DATE
,PCUST1      varchar(50)-- AS  PCUST1
,PCUST2      varchar(50)-- AS  PCUST2
,PCUST3      varchar(50)-- AS  PCUST3
,PCUST4      varchar(50)-- AS  PCUST4
,PHONE      varchar(50)-- AS  PHONE
,PID      varchar(50)-- AS  PID
,PSWRD      varchar(50)-- AS  PSWRD
,PSWRD_HASH_ID      varchar(50)-- AS  PSWRD_HASH_ID
,RMS_ID      varchar(50)-- AS  RMS_ID
,PERSL_SOUNDEX      varchar(50)-- AS  SOUNDEX
,TERM      varchar(50)-- AS  TERM
,USR_ID      varchar(50)-- AS  USR_ID
,DEFAULT_USER_GROUP      varchar(50)-- AS  DEFAULT_USER_GROUP

);

ALTER TABLE PERSL  WITH CHECK ADD  CONSTRAINT [FK_PERSL_CAD911_RMS_94] FOREIGN KEY(filename, process_date)
REFERENCES EVENT (filename, process_date)
ON DELETE CASCADE;
		

CREATE TABLE COMMON_EVENT_CALL(
 filename nvarchar(400) NOT NULL
, process_date datetime NOT NULL
, CALL_ID   varchar(50)-- AS CALL_ID
, CALL_SOUR   varchar(50)-- AS CALL_SOUR
, CCITY   varchar(50)-- AS CCITY
, CDTS   varchar(50)-- AS CDTS
, CDTS_DATE   varchar(50)-- AS CDTS_DATE
, CDTS_TIME   varchar(50)-- AS CDTS_TIME
, CLNAME   varchar(50)-- AS CLNAME
, CLRNUM   varchar(50)-- AS CLRNUM
, CPERS   varchar(50)-- AS CPERS
, CSTR_ADD   varchar(50)-- AS CSTR_ADD
, CTERM   varchar(50)-- AS CTERM
, EID   varchar(50)-- AS EID
, EVENT_CALL_ID   varchar(50)-- AS EVENT_CALL_ID
, FIRST_CALL   varchar(50)-- AS FIRST_CALL
, REV_NUM   varchar(50)-- AS REV_NUM
, UDTS   varchar(50)-- AS UDTS
, UDTS_DATE   varchar(50)-- AS UDTS_DATE
, UDTS_TIME   varchar(50)-- AS UDTS_TIME
, UPERS   varchar(50)-- AS UPERS
, UTERM   varchar(50)-- AS UTERM
, LATITUDE   varchar(50)-- AS LATITUDE
, LOC_VER   varchar(50)-- AS LOC_VER
, LONGITUDE   varchar(50)-- AS LONGITUDE

);

ALTER TABLE COMMON_EVENT_CALL  WITH CHECK ADD  CONSTRAINT [FK_COMMON_EVENT_CALL_CAD911_RMS_94] FOREIGN KEY(filename, process_date)
REFERENCES EVENT (filename, process_date)
ON DELETE CASCADE;


CREATE TABLE PERSO (
	filename nvarchar(400) NOT NULL,
	process_date datetime NOT NULL,
	AGE varchar(50) NULL,
	CDTS varchar(50) NULL,
	CPERS varchar(50) NULL,
	CTERM varchar(50) NULL,
	[CURRENT] varchar(50) NULL,
	DISABLEAUTOQUERY varchar(50) NULL,
	DOB varchar(50) NULL,
	EID int NOT NULL,
	EYE varchar(50) NULL,
	FORM_FLAG varchar(50) NULL,
	HAIR varchar(50) NULL,
	HEIGHT varchar(50) NULL,
	INFO_SCOPE varchar(50) NULL,
	NME varchar(100) NULL,
	OLN varchar(50) NULL,
	RACE varchar(50) NULL,
	REMARKS varchar(2000) NULL,
	REV_NUM varchar(50) NULL,
	ROW_NUM varchar(50) NULL,
	SEX varchar(50) NULL,
	SOC varchar(50) NULL,
	[STATE] varchar(50) NULL,
	SUPP_AVAIL_DTS varchar(50) NULL,
	UDTS varchar(50) NULL,
	UNID varchar(50) NULL,
	UPDT_FLAG varchar(50) NULL,
	UPERS varchar(50) NULL,
	UTERM varchar(50) NULL,
	WEIGHT varchar(50) NULL
	);
	
ALTER TABLE PERSO  WITH CHECK ADD  CONSTRAINT [FK_PERSO_CAD911_RMS_94] FOREIGN KEY(filename, process_date)
REFERENCES EVENT (filename, process_date)
ON DELETE CASCADE;

CREATE TABLE VEHIC (
	filename nvarchar(400) NOT NULL,
	process_date datetime NOT NULL,
	CDTS varchar(50) NULL,
	CDTS2 varchar(50) NULL,
	CPERS varchar(50) NULL,
	CTERM varchar(50) NULL,
	CURENT varchar(50) NULL,
	DISABLEAUTOQUERY varchar(50) NULL,
	EID int NULL,
	INFO_SCOPE varchar(50) NULL,
	LICENSE varchar(50) NULL,
	LICENSE_YR varchar(50) NULL,
	MAKE varchar(50) NULL,
	MODEL varchar(50) NULL,
	MODEL_YEAR varchar(50) NULL,
	REMARKS varchar(50) NULL,
	REV_NUM varchar(50) NULL,
	ROW_NUM varchar(50) NULL,
	STATE varchar(50) NULL,
	SUPP_AVAIL_DTS varchar(50) NULL,
	UDTS varchar(50) NULL,
	UDTS2 varchar(50) NULL,
	UNID varchar(50) NULL,
	UPDT_FLAG varchar(50) NULL,
	UPERS varchar(50) NULL,
	UTERM varchar(50) NULL,
	VEHIC_COLOR varchar(50) NULL,
	VIN varchar(50) NULL
		);
		
ALTER TABLE VEHIC  WITH CHECK ADD  CONSTRAINT [FK_VEHIC_CAD911_RMS_94] FOREIGN KEY(filename, process_date)
REFERENCES EVENT (filename, process_date)
ON DELETE CASCADE;

GO