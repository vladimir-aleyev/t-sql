select
	ps.Name PartitionScheme,
	pf.name PartitionFunction,
	i.*
 
 from sys.indexes i
 
 join sys.partition_schemes ps on ps.data_space_id = i.data_space_id
 
 join sys.partition_functions pf on pf.function_id = ps.function_id 

where i.object_id = object_id('TableName')