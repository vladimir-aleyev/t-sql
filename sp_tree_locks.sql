if object_id('sp_tree_locks','P') is null exec ('create proc sp_tree_locks as')
go
alter proc sp_tree_locks
	@union_result char(1) = 'N' --Y/N
--with exec as self
as
set nocount on;

if object_id('tempdb..#locks','U') is not null drop table #locks;
create table #locks
(
	spid smallint not null,
	kpid smallint not null,
	blocked smallint not null,
	lastwaittype nchar(32) not null,
	waitresource nchar(256) not null,
	dbname nvarchar(128) null,
	cpu int not null,
	physical_io bigint not null,
	memusage int not null,
	status nchar(30),
	loginame nchar(128) not null,
	login_time datetime not null,
	last_batch datetime not null,
	waittime bigint not null,
	hostname sysname,
	program_name nvarchar(256),
	sql_handle binary(20),

	tree varchar(8000) not null,
	dl_num int not null,
	sort int not null,
	primary key clustered (dl_num, sort)
);

if object_id('tempdb..#process','U') is not null drop table #process;
create table #process
(
	spid smallint not null,
	kpid smallint not null,
	blocked smallint not null,
	lastwaittype nchar(32) not null,
	waitresource nchar(256) not null,
	dbname nvarchar(128) null,
	cpu int not null,
	physical_io bigint not null,
	memusage int not null,
	status nchar(30),
	loginame nchar(128) not null,
	login_time datetime not null,
	last_batch datetime not null,
	waittime bigint not null,
	hostname sysname,
	program_name nvarchar(256),
	sql_handle binary(20),
	primary key clustered (spid, kpid)
);
insert #process
select
	spid,
	kpid,
	blocked,
	lastwaittype,
	waitresource,
	db_name(dbid) dbname,
	cpu,
	physical_io,
	memusage,
	status,
	loginame,
	login_time,
	last_batch,
	waittime,
	hostname,
	program_name,
	sql_handle
from sys.sysprocesses

declare @q varchar(max) = 'create index ['+cast(newid() as varchar(200))+'] on #process (blocked)'
exec ( @q )

delete from #process
where blocked = 0 and
spid not in (select blocked from #process);

with mcte as
(
	select *,
		min(blocked) over (partition by spid) min_blocked,
		row_number() over (partition by spid order by blocked) rn
	from #process
)
, cte as
(
	select
		spid,
		kpid,
		blocked,
		lastwaittype,
		waitresource,
		dbname,
		cpu,
		physical_io,
		memusage,
		status,
		loginame,
		login_time,
		last_batch,
		waittime,
		hostname,
		program_name,
		sql_handle,

		convert(varchar(8000),spid) list,
		0 lev,
		min_blocked,
		rn
	from mcte
	where min_blocked = 0
	union all
	select
		m.spid,
		m.kpid,
		m.blocked,
		m.lastwaittype,
		m.waitresource,
		m.dbname,
		m.cpu,
		m.physical_io,
		m.memusage,
		m.status,
		m.loginame,
		m.login_time,
		m.last_batch,
		m.waittime,
		m.hostname,
		m.program_name,
		m.sql_handle,

		c.list+case when m.blocked = m.spid then '' else ';'+convert(varchar(8000),m.spid) end,
		case when m.blocked = m.spid then c.lev else c.lev+1 end,
		m.min_blocked,
		m.rn--, m.ds, m.qte
	from cte c join mcte m
		on c.spid = m.blocked
		and c.rn = 1
)
insert #locks
select
	spid,
	kpid,
	blocked,
	lastwaittype,
	waitresource,
	dbname,
	cpu,
	physical_io,
	memusage,
	status,
	loginame,
	login_time,
	last_batch,
	waittime,
	hostname,
	program_name,
	sql_handle,

	replicate('.',5*lev)+case when blocked=spid then '.' else '' end+convert(varchar(8000),spid),
	0, row_number() over (order by list, -abs(blocked-spid))
from cte option (maxrecursion 10000);

delete from #process
where spid in (select spid from #locks);

declare
	@rc int,
	@dl_num int = 1;

while 1=1
begin;
	with src as
	(
		select *,
			convert(varchar(8000),spid)+':'+
			convert(varchar(8000),kpid)+':'+
			convert(varchar(8000),blocked) as list,
			convert(varchar(8000),spid) as noself,
			row_number() over (partition by spid order by abs(spid-blocked) desc) rn
		from #process
	)
	, noself as
	(
		select *
		from src
		where blocked <> spid
	)
	, vector as
	(
		select top(1)
			spid,
			kpid,
			blocked,
			lastwaittype,
			waitresource,
			dbname,
			cpu,
			physical_io,
			memusage,
			status,
			loginame,
			login_time,
			last_batch,
			waittime,
			hostname,
			program_name,
			sql_handle,

			','+noself+',' as list
		from noself

		union all

		select
			p.spid,
			p.kpid,
			p.blocked,
			p.lastwaittype,
			p.waitresource,
			p.dbname,
			p.cpu,
			p.physical_io,
			p.memusage,
			p.status,
			p.loginame,
			p.login_time,
			p.last_batch,
			p.waittime,
			p.hostname,
			p.program_name,
			p.sql_handle,

			v.list+p.noself+','
		from noself p
		join vector v
			on p.spid = v.blocked
		where v.list not like '%'+p.noself+'%'
	)
	, head as
	(
		select
			reverse(stuff(reverse(
			stuff(tree,1,charindex(convert(varchar,v.spid)+',',o.tree)-1,'')+
			left(tree,charindex(convert(varchar,v.spid)+',',o.tree)-1)),1,1,'')) tree,

			v.spid,
			v.kpid,
			v.blocked,
			v.lastwaittype,
			v.waitresource,
			v.dbname,
			v.cpu,
			v.physical_io,
			v.memusage,
			v.status,
			v.loginame,
			v.login_time,
			v.last_batch,
			v.waittime,
			v.hostname,
			v.program_name,
			v.sql_handle
		from vector v cross join
		(select top (1) blocked, stuff(list,1,patindex('%,'+convert(varchar,blocked)+',%',list),'') tree from vector order by list desc) o
		where v.list like '%,'+convert(varchar,o.blocked)+',%'
	)
	, chain as
	(
		select
			spid,
			kpid,
			blocked,
			lastwaittype,
			waitresource,
			dbname,
			cpu,
			physical_io,
			memusage,
			status,
			loginame,
			login_time,
			last_batch,
			waittime,
			hostname,
			program_name,
			sql_handle,

			0 as lev, tree, convert(int,1) rn, convert(varchar(8000),spid) list
		from head

		union all

		select
			s.spid,
			s.kpid,
			s.blocked,
			s.lastwaittype,
			s.waitresource,
			s.dbname,
			s.cpu,
			s.physical_io,
			s.memusage,
			s.status,
			s.loginame,
			s.login_time,
			s.last_batch,
			s.waittime,
			s.hostname,
			s.program_name,
			s.sql_handle,

			c.lev+1, c.tree, convert(int,s.rn),
			c.list+case when s.blocked = s.spid then '' else ';'+convert(varchar(8000),s.spid) end
		from chain c
		join src s
			on c.spid = s.blocked
			and c.rn = 1
			and (';'+c.list+';' not like '%;'+convert(varchar,s.spid)+';%'
			and  ','+c.tree+',' not like '%,'+convert(varchar,s.spid)+',%'
					or s.spid = s.blocked)
	)
	insert #locks
	select
		spid,
		kpid,
		blocked,
		lastwaittype,
		waitresource,
		dbname,
		cpu,
		physical_io,
		memusage,
		status,
		loginame,
		login_time,
		last_batch,
		waittime,
		hostname,
		program_name,
		sql_handle,

		case
		when lev=0 and list not like '%;%'
			then tree
		when blocked != spid
			then replicate('.',5*lev)+convert(varchar(8000),spid)
			else replicate('.',5*(lev-1)+1)+convert(varchar(8000),spid)
		end,
		@dl_num,
		row_number() over (order by list, rn)
	from chain option (maxrecursion 10000);

	set @rc = @@rowcount
	if @rc = 0
		break

	delete from #process
	where spid in (select spid from #locks d)

	set @dl_num += 1
end

if @union_result = 'Y'
begin
	select
		case when l.dl_num = 0
			then 'locks'
			else 'dlock '+right('000000'+convert(varchar,l.dl_num),2)
		end lock_num,
		l.tree,
		l.spid,
		l.kpid,
		l.blocked,
		l.lastwaittype,
		l.waitresource,
		l.dbname,
		l.cpu,
		l.physical_io,
		l.memusage,
		l.status,
		l.loginame,
		l.login_time,
		l.last_batch,
		l.waittime,
		l.hostname,
		l.program_name,
		q.text
	from #locks l
	outer apply sys.dm_exec_sql_text(l.sql_handle) q
	order by dl_num, sort
end
else begin
	set @dl_num = 0
	while 1=1
	begin
		select
			l.tree,
			l.spid,
			l.kpid,
			l.blocked,
			l.lastwaittype,
			l.waitresource,
			l.dbname,
			l.cpu,
			l.physical_io,
			l.memusage,
			l.status,
			l.loginame,
			l.login_time,
			l.last_batch,
			l.waittime,
			l.hostname,
			l.program_name,
			q.text
		from #locks l
		outer apply sys.dm_exec_sql_text(sql_handle) q
		where dl_num = @dl_num
		order by dl_num, sort;

		delete from #locks where dl_num = @dl_num;

		if not exists (select * from #locks) break;
		set @dl_num += 1
	end
end