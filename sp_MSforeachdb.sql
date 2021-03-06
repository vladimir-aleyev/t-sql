USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MSforeachdb]    Script Date: 04/11/2014 09:23:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
 * The following table definition will be created by SQLDMO at start of each connection.
 * We don't create it here temporarily because we need it in Exec() or upgrade won't work.
 */

ALTER proc [dbo].[sp_MSforeachdb]
	@command1 nvarchar(2000), @replacechar nchar(1) = N'?', @command2 nvarchar(2000) = null, @command3 nvarchar(2000) = null,
	@precommand nvarchar(2000) = null, @postcommand nvarchar(2000) = null
as
    set deadlock_priority low
    
	/* This proc returns one or more rows for each accessible db, with each db defaulting to its own result set */
	/* @precommand and @postcommand may be used to force a single result set via a temp table. */

	/* Preprocessor won't replace within quotes so have to use str(). */
	declare @inaccessible nvarchar(12), @invalidlogin nvarchar(12), @dbinaccessible nvarchar(12)
	select @inaccessible = ltrim(str(convert(int, 0x03e0), 11))
	select @invalidlogin = ltrim(str(convert(int, 0x40000000), 11))
	select @dbinaccessible = N'0x80000000'		/* SQLDMODbUserProf_InaccessibleDb; the negative number doesn't work in convert() */

	if (@precommand is not null)
		exec(@precommand)

	declare @origdb nvarchar(128)
	select @origdb = db_name()

	/* If it's a single user db and there's an entry for it in sysprocesses who isn't us, we can't use it. */
   /* Create the select */
	exec(N'declare hCForEach cursor global for select name from master.dbo.sysdatabases d ' +
			N' where (d.status & ' + @inaccessible + N' = 0)' +
			N' and ((DATABASEPROPERTY(d.name, ''issingleuser'') = 0 and (has_dbaccess(d.name) = 1)) or ' +
			N' ( DATABASEPROPERTY(d.name, ''issingleuser'') = 1 and not exists ' +
			N' (select * from master.dbo.sysprocesses p where dbid = d.dbid and p.spid <> @@spid)))' )

	declare @retval int
	select @retval = @@error
	if (@retval = 0)
		exec @retval = sp_MSforeach_worker @command1, @replacechar, @command2, @command3

	if (@retval = 0 and @postcommand is not null)
		exec(@postcommand)

   declare @tempdb nvarchar(258)
   SELECT @tempdb = REPLACE(@origdb, N']', N']]')
   exec (N'use ' + N'[' + @tempdb + N']')

	return @retval
