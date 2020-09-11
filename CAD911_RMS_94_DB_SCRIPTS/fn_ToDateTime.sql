USE [CAD911_RMS_94]
GO

/****** Object:  UserDefinedFunction [dbo].[fn_ToDateTime]    Script Date: 6/4/2020 10:34:24 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- Convert a datetime string in 'yyyymmddhhmmssED' format into a valid date/time string 'yyyy-mm-dd hh:mm:ss'
-- Input string: 'yyyymmddhhmmss'
-- Output string: 'yyyy-mm-dd hh:mm:ss'
CREATE FUNCTION [dbo].[fn_ToDateTime](@datstr varchar(100))
RETURNS varchar(100) 
AS 
-- Returns the stock level for the product.
BEGIN
	declare @datval as varchar(100) = left(@datstr, 14)

	set @datstr = convert(varchar(50),stuff(stuff(stuff(stuff(stuff(@datval, 5, 0, '-'), 8, 0, '-'),11, 0, ' '), 14, 0, ':'), 17, 0, ':'))
	-- Print @datstr;

    RETURN @datstr;
END;
GO

GRANT EXECUTE ON [dbo].[fn_ToDateTime] TO <USER> ;
GRANT EXECUTE ON [dbo].[fn_ToDateTime] TO [<DOMAIN>\<USER> ] ;
GO
