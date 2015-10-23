-- =============================================
-- Author:      <Vadim Belov>
-- create date: <17.08.2015>
-- Description: <Получение сведений об изменении кодов CFI в указанный период>
-- Task:        <3984>
-- =============================================
create procedure get_cfi_code_changes
(
	@isin varchar(12),
	@fromDate datetime,
	@toDate datetime,
	@inList char(1) = 'N'
)
as
begin
	set nocount on

	declare @pifTypeId int = (select
									doc_type_id
									from
									  doc_types
									where
									  doc_type_class_mn = 'PIF_RULES'),
			@duTypeId int = (select
									doc_type_id
									from
									  doc_types
									where
									  doc_type_class_mn = 'IPP_RULES')
	if @fromDate is null
	begin
		set @fromDate = '17530101'
	end

	if @toDate is null
	begin
		set @toDate = '99991231'
	end

	set @toDate = dateadd(second, 1, @toDate)

	if object_id('tempdb..#cfi_table') is not null
	begin
		drop table #cfi_table
	end

	create table #cfi_table
	(
		security_id int,
		name_full varchar(500),
		object_type char(1),
		state_reg_number varchar(50),
		isin varchar(64),
		[object_id] int,
		issuer_id int,
		full_name varchar(254),
		cfi_object_type char(1),
		cfi_object_id int
	)

	insert into #cfi_table
				(security_id, name_full, object_type, state_reg_number, isin,
				[object_id], issuer_id, full_name, cfi_object_type, cfi_object_id)
		select
			x.security_id,
			x.name_full,
			x.object_type,
			x.state_reg_number,
			x.isin,
			x.[object_id],
			x.issuer_id,
			cmp.full_name,
			case
				when i.main_issue_id is null and x.instr_type_id = 1
					then 'S'
				else x.object_type
			end as cfi_object_type,
			case
				when x.object_type = 'I' and x.instr_type_id = 1
					then
						case
							when i.main_issue_id is not null
								then
									case
										when i.int_issue_id is not null
											then i.int_issue_id
										else i.issue_id
									end
							else x.security_id
						end
				else x.[object_id]
			end as cfi_object_id
			from x_sbr as x
				left join issues as i on
					x.[object_id] = i.issue_id and
					x.object_type = 'I' and
					x.instr_type_id = 1
				join companies as cmp on
					cmp.company_id = x.issuer_id

	create nonclustered index IX_cfi_main on #cfi_table (object_id, object_type)

	create nonclustered index IX_cfi_cfi on #cfi_table (object_id, object_type)

	select
		x.[object_id],
		x.object_type,
		x.security_id,
		x.full_name,
		case x.object_type
			when 'M'
				then iss.security_name
			when 'S'
				then h.hde_short_name
			else x.name_full
		end as name,
		case
			when x.object_type = 'S'
				then dpr.reg_num
			when x.object_type = 'M'
				then dir.reg_num
			when x.object_type = 'C'
				then dk.ksu_number
			else x.state_reg_number
		end as doc_reg_no,
		c.code as prev_code,
		x.isin,
		next_code.code as new_code
		from codes as c
			join code_types as ct on
				c.code_type_id = ct.code_type_id
			join #cfi_table as x on
				c.[object_id] = x.cfi_object_id and
				c.object_type = x.cfi_object_type
			left join hde_issues as h on
				x.[object_id] = h.[object_id] and
				x.object_type = h.object_type and
				x.object_type in ('M','S')
			left join isu_securities as iss on
				x.[object_id] = iss.isu_security_id and
				x.object_type = 'M'
			outer apply
				(select
					dpr.reg_num
					from doc_pif_rules as dpr
					join documents as d on
						dpr.doc_id = d.doc_id
					where x.issuer_id = dpr.company_id and
						x.object_type = 'S' and
						d.doc_type_id = @pifTypeId
				) as dpr
			outer apply
				(select
					dir.reg_num
					from dbo.doc_ipp_rules as dir
					join documents as d
						on dir.doc_id = d.doc_id
					where x.issuer_id = dir.company_id and
						x.object_type = 'M' and
						d.doc_type_id = @duTypeId
				) as dir
			left join doc2instr as d2i on
				x.[object_id] = d2i.[object_id] and
				x.object_type = d2i.object_type and
				x.object_type = 'C'
			left join doc_ksu as dk on
				d2i.doc_id = dk.doc_id
			outer apply
				(select top 1
					cn.code,
					cn.code_date
					from codes as cn
						join code_types as ctn on
							cn.code_type_id = ctn.code_type_id
					where cn.object_type = c.object_type and
					cn.[object_id] = c.[object_id] and
					ctn.code_type_mn = 'CFI' and
					c.code_date < cn.code_date
					order by cn.code_date) as next_code
			outer apply
				(select top 1
					oper_date
					from operations as o
						left join companies as c on
							o.serv_place_id = c.company_id
					where x.[object_id] = o.[object_id] and
						x.object_type = o.object_type and
						o.oper_date < @toDate and
						c.common_name = 'НРД' and
						o.oper_type_mn = 'ACP'
					order by oper_date desc) as added
			outer apply
				(select top 1
					oper_date
					from operations as o
						left join companies as c on
							o.serv_place_id = c.company_id
					where x.[object_id] = o.[object_id] and
						x.object_type = o.object_type and
						o.oper_date < @toDate and
						c.common_name = 'НРД' and
						o.oper_type_mn = 'DEL'
					order by oper_date desc) as deleted
			outer apply
				(select top 1
					oper_date
					from operations as o
						left join companies as c on
							o.serv_place_id = c.company_id
					where x.[object_id] = o.[object_id] and
						x.object_type = o.object_type and
						o.oper_date < @toDate and
						(c.common_name = 'Московская Биржа ММВБ-РТС' or c.common_name = 'ММВБ') and
						o.oper_type_mn in ('TL1', 'TL2', 'TL3')
					order by oper_date desc) as to_list
			outer apply
				(select top 1
					oper_date
					from operations as o
						left join companies as c on
							o.serv_place_id = c.company_id
					where x.[object_id] = o.[object_id] and
						x.object_type = o.object_type and
						o.oper_date < @toDate and
						(c.common_name = 'Московская Биржа ММВБ-РТС' or c.common_name = 'ММВБ') and
						o.oper_type_mn in ('FL1', 'FL2', 'FL3')
					order by oper_date desc) as from_list
		where c.object_type in ('I', 'D', 'M', 'S', 'C')  and
			ct.code_type_mn = 'CFI'	and
			(@isin is null or x.isin like '%' + @isin + '%') and
			next_code.code is not null and
			next_code.code_date >= @fromDate and
			next_code.code_date < @toDate and
			(added.oper_date >= @fromDate or
					deleted.oper_date >= @fromDate or
					(deleted.oper_date < @fromDate and added.oper_date >= deleted.oper_date) or
					(deleted.oper_date is null and added.oper_date is not null)) and
			(@inList = 'N' or (to_list.oper_date >= @fromDate or
									from_list.oper_date >= @fromDate or
									(from_list.oper_date < @fromDate and to_list.oper_date >= from_list.oper_date) or
									(from_list.oper_date is null and to_list.oper_date is not null)))
		order by x.full_name, x.isin



	drop table #cfi_table

	select 
		*
	from sys.objects
end
GO
/* Grants */
grant execute on get_cfi_code_changes to [SQL_corpdb_sp&read] as dbo
GO
grant execute on get_cfi_code_changes to [SQL_corpdb_sp&write] as dbo
GO