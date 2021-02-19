-- To view information about the full-text catalogs with in-progress population activity
SELECT * FROM sys.dm_fts_active_catalogs

--To view current activity of a filter daemon host process
SELECT * FROM sys.dm_fts_fdhosts

--To view information about in-progress index populations
SELECT * FROM  sys.dm_fts_index_population

--To view memory buffers in a memory pool that are used as part of a crawl or crawl range.
SELECT * FROM sys.dm_fts_memory_buffers

--To view the shared memory pools available to the full-text gatherer component for a full-text crawl or a full-text crawl range
SELECT * FROM  sys.dm_fts_memory_pools

--To view information about each full-text indexing batch
SELECT * FROM sys.dm_fts_outstanding_batches

--To view information about the specific ranges related to an in-progress population
SELECT * FROM sys.dm_fts_population_ranges
