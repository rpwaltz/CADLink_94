In the CAD911_RMS_94_DB_SCRIPTS folder

CAD911_RMS_94.sql  - generates the CAD911_KPD_94 database tables ,  assumes CAD911_KPD_94 database has been created

sp_CADLink_XML2Table.sql   - imports the CADLink xml files into CAD911_KPD_94 database tables

sp_CADLink_Table2XML.sql – exports RMS xml files 

sp_WriteToFile.sql – writes files out to disk

fn_ToDateTime.sql – transforms data string to a formatted date/timestring

CADLink_Part1.sql  -  Job that runs sp_CADLink_XML2Table_NEW_94 

CADLink_Part2.sql – Job that runs sp_CADLink_Table2XML_NEW_94


In the Documents folder


There is database setup just as Users and permissions documented in :

StepsforSQLServer2017ToRunCADLinkAndFireLinkProcedures.docx

The description of metadata fields and mappings are found in the DataDictionary file :

Intergraph2RMS_R3_v94.xlsx


The above document was created in November of 2019 and does not reflect the new names for tables, database and jobs. But it should be easy enough to follow.

The revised workflow diagrams are :

Documet9.4\sp_CADLink_Table2XML.pdf

sp_CADLink_XML2Table.pdf

Both the documents also have drawio versions that can be edited with https://app.diagrams.net/ , a free open source, online, desktop and container deployable diagramming software tool.


