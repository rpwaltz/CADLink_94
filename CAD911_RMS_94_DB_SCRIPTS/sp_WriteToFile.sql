USE [CAD911_KPD_94]
GO
/****** Object:  StoredProcedure [dbo].[sp_WriteToFile]    Script Date: 6/4/2020 10:33:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_WriteToFile]
 
@File        VARCHAR(2000),
@Text        VARCHAR(MAX),
@NoTimStamp	 VARCHAR (100) = NULL
 
AS 
 
BEGIN 
 
DECLARE @OLE            INT 
DECLARE @FileID         INT 
 
 
EXECUTE master.sys.sp_OACreate 'Scripting.FileSystemObject', @OLE OUT 
       
EXECUTE master.sys.sp_OAMethod @OLE, 'OpenTextFile', @FileID OUT, @File, 8, 1 

If (@NoTimStamp is null)
Begin
	set @Text = Convert(varchar(100), GetDate(), 120) + @Text
end     
EXECUTE master.sys.sp_OAMethod @FileID, 'WriteLine', Null, @Text
 
EXECUTE master.sys.sp_OADestroy @FileID 
EXECUTE master.sys.sp_OADestroy @OLE 
 
END 
 
