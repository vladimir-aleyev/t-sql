
declare @plan_handle varbinary(64)
declare @plan_xml xml
DECLARE @session INT

SET @session = 237

       SELECT @plan_handle = plan_handle FROM sys.dm_exec_requests WHERE session_id = @session

       begin try
             -- convert may fail due to exceeding 128 depth limit
             select @plan_xml = convert(xml, query_plan) from sys.dm_exec_text_query_plan(@plan_handle, default, default)
       end try
       begin catch
             select @plan_xml = NULL
       end catch

       ;WITH XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS sp)
       SELECT
			@session AS session_id,
			(SELECT [text] FROM sys.dm_exec_sql_text(@plan_handle)) AS sql_text,
             parameter_list.param_node.value('(./@Column)[1]', 'nvarchar(128)') as param_name,
             parameter_list.param_node.value('(./@ParameterCompiledValue)[1]', 'nvarchar(max)') as param_compiled_value
       from (select @plan_xml as xml_showplan) as t
             outer apply t.xml_showplan.nodes('//sp:ParameterList/sp:ColumnReference') as parameter_list (param_node)


-- SELECT * FROM sys.dm_exec_requests 