USE [msdb]
GO
/****** Object:  StoredProcedure [dbo].[sp_DBA_Blocking_Chain]    Script Date: 07.04.2021 10:09:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--------------
USE [msdb]
GO

/****** Object:  Table [dbo].[DBA_Blocking_Chain]   ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--CREATE TABLE [dbo].[DBA_Blocking_Chain](
--	[tid] [int] IDENTITY(1,1) NOT NULL,
--	[PostTime] [datetime] NOT NULL,
--	[spid] [int] NULL,
--	[blocked] [int] NULL,
--	[waittime] [int] NULL,
--	[lastwaittype] [varchar](100) NULL,
--	[waitresource] [varchar](100) NULL,
--	[cpu] [int] NULL,
--	[physical_io] [int] NULL,
--	[status] [varchar](100) NULL,
--	[cmd] [varchar](100) NULL,
--	[hostname] [varchar](500) NULL,
--	[program_name] [varchar](500) NULL,
--	[loginame] [varchar](100) NULL,
--	[txt] [nvarchar](max) NULL,
--	[txt_init] [nvarchar](max) NULL,
--	[lvl] [int] NULL,
-- CONSTRAINT [PK__DBA_Bloc__DC105B0FF321E5C3] PRIMARY KEY CLUSTERED 
--(
--	[tid] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
--) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
--GO

--------------

ALTER PROCEDURE [dbo].[sp_DBA_Blocking_Chain]
AS
BEGIN
  
  DECLARE @PostTime datetime = GETDATE()
   
  DECLARE @lock_a TABLE
  (
  spid int,
  blocked int,
  waittime bigint,
  lastwaittype varchar(100),
  waitresource varchar(100),
  cpu bigint,
  physical_io bigint,
  [status] varchar(100),
  cmd varchar(100),
  hostname varchar(500),
  [program_name] varchar(500),
  loginame varchar(100),
  txt nvarchar(max),
  id_parent int,
  lvl int,
  txt_init nvarchar(max) 
  )    

INSERT INTO 
@lock_a
	(
	spid,
	blocked,
	waittime,
	lastwaittype,
	waitresource,
	cpu,
	physical_io,
	[status],
	cmd,
	hostname,
	[program_name],
	loginame,
	txt,
	txt_init 
	)
SELECT
	c.spid,
	c.blocked,
	c.waittime,
	c.lastwaittype,
	c.waitresource,
	c.cpu,
	c.physical_io,
	c.[status],
	c.cmd,
	c.hostname,
	c.[program_name],
	c.loginame,
	SUBSTRING(st.text,
           COALESCE(NULLIF(c.stmt_start/2, 0), 1),
		   case 
             when c.stmt_end > 0 then c.stmt_end/2 
             else DATALENGTH(st.text) 
           end) AS txt,
	case 
		when ISNULL(st.text,'')='' then ''
		else LEFT(st.text,100)
	end AS txt_init 
FROM
	master.sys.sysprocesses c
CROSS APPLY
	master.sys.dm_exec_sql_text(c.sql_handle) AS st;
 
  
;WITH RES (
    spid,
	blocked,
	waittime,
	lastwaittype,
	waitresource,
	cpu,
	physical_io,
	[status],
	cmd,
	hostname,
	[program_name],
	loginame,
	txt,
	lvl,
	txt_init) AS
  (
 	SELECT	
		spid,
		blocked,
		waittime,
		lastwaittype,
		waitresource,
        cpu,
		physical_io,
		[status],
		cmd,
		hostname,
		[program_name],
        loginame,
		txt,
		0 as lvl,
		txt_init 
    FROM 
		@lock_a AS B 
    WHERE
		spid in(select distinct blocked from @lock_a where blocked<>0)
		and
		blocked=0
	UNION ALL
	SELECT
		b.spid,
		b.blocked,
		b.waittime,
		b.lastwaittype,
		b.waitresource,
        b.cpu,
		b.physical_io,
		b.[status],
		b.cmd,
		b.hostname,
		b.[program_name],
        b.loginame,
		b.txt,
		isnull(res.lvl,0)+1,
		b.txt_init
	FROM
		@lock_a AS B
	INNER JOIN RES ON RES.spid = B.blocked
  )

  INSERT INTO dbo.DBA_Blocking_Chain
	(
	PostTime,
	spid,
	blocked,
	waittime,
	lastwaittype,
	waitresource,
	cpu,
	physical_io,
	[status],
	cmd,
	hostname,
	[program_name],
	loginame,
	txt,
	txt_init,
	lvl
	)
  SELECT @PostTime,
         spid,
		 blocked,
		 waittime,
		 lastwaittype,
		 waitresource,
		 cpu,
		 physical_io,
		 [status],
		 cmd,
		 hostname,
		 [program_name],
		 loginame,
		 txt,
		 txt_init,
		 lvl
  FROM 
	RES
  RETURN
END













      
