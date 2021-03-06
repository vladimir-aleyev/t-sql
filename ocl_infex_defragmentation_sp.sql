USE [autodoc]
GO
/****** Object:  StoredProcedure [dbo].[ocl_index_defragmentation_sp]    Script Date: 07.11.2017 16:33:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[ocl_index_defragmentation_sp]
as
begin
  --dbcc indexdefrag('autodoc','orders_clients','idx_art') WITH NO_INFOMSGS;
  --dbcc indexdefrag('autodoc','orders_clients','idx_repl') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','import_ocl_buf','idx_ss') WITH NO_INFOMSGS;
  
  dbcc indexdefrag('autodoc','orders_clients','idx_orders') WITH NO_INFOMSGS;  
  dbcc indexdefrag('autodoc','orders_clients','idx_state') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','orders_clients','idx_clients') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','orders_clients','idx_s_date') WITH NO_INFOMSGS;
  
  dbcc indexdefrag('autodoc','ocl_filter_by_clients_tb','idx_ocl_filter_by_clients_id_clients') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','ocl_filter_by_clients_tb','idx_ocl_filter_by_clients_id_clients_parent') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','ocl_filter_by_clients_tb','idx_ocl_filter_by_clients_id_retail_client') WITH NO_INFOMSGS;

  dbcc indexdefrag('autodoc','ocl_filter_by_fixparam_tb','idx_ocl_filter_by_fixparam_id_d2m') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','ocl_filter_by_fixparam_tb','idx_ocl_filter_by_fixparam_id_ocl_parent') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','ocl_filter_by_fixparam_tb','idx_ocl_filter_by_fixparam_zc_number') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','ocl_filter_by_fixparam_tb','idx_ocl_filter_by_fixparam_art_number') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','ocl_filter_by_fixparam_tb','idx_ocl_filter_by_fixparam_art_replace') WITH NO_INFOMSGS;

  -- other idx
  
  --dbcc indexdefrag('autodoc','import_price_link','idx_part_num') WITH NO_INFOMSGS;
  --dbcc indexdefrag('autodoc','import_price_link','idx_id_import_provider') WITH NO_INFOMSGS;

  dbcc indexdefrag('autodoc_price','import_price_art_is_not_mask','idx_import_provider') WITH NO_INFOMSGS;

  dbcc indexdefrag('autodoc','buxreestr_income','IDX_buxreestr_income_id_import_session') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','bux_box_doc','idx_bux_box_doc_id_doc') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','dbo.catalog_bus','idx_unique_select') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','dbo.catalog_bus','idx_id_catalog_bus_type') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','dbo.catalog_bus','idx_count_is_for_site') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','dbo.catalog_bus','idx_is_for_site_for_id_catalog_bus_type') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','dbo.proposal_stack','idx_load') WITH NO_INFOMSGS;

  dbcc indexdefrag('autodoc','dbo.export_orders_session','IX_import_provider') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','dbo.import_session_price','idx_import_provider') WITH NO_INFOMSGS;

  dbcc indexdefrag('autodoc','dbo.bux_edo_session_item','idx_bux_edo_item_session') WITH NO_INFOMSGS;

  dbcc indexdefrag('autodoc','dbo.mail_sort_session','idx_mail_sort_ss_2_profile') WITH NO_INFOMSGS;
  dbcc indexdefrag('autodoc','dbo.mail_sort_rule','idx_mail_sort_rule_2_profile') WITH NO_INFOMSGS;

  return
end
