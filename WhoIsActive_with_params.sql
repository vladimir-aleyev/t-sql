EXEC [dbo].[sp_WhoIsActive] 
	@get_full_inner_text = 1,
	@get_plans = 1,
	@get_outer_command = 1,
	@get_additional_info = 1,
	@find_block_leaders = 1,
	@get_locks = 1,
	@get_task_info = 2