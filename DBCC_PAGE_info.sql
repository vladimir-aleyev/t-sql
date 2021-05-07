-- Get the page for thie table
DBCC IND(CIPageTest, 'PageTest', -1);
/*
The columns mean:
	PageFID – the file ID of the page
	PagePID – the page number in the file
	IAMFID – the file ID of the IAM page that maps this page (this will be NULL for IAM pages themselves as they’re not self-referential)
	IAMPID – the page number in the file of the IAM page that maps this page
	ObjectID – the ID of the object this page is part of
	IndexID – the ID of the index this page is part of
	PartitionNumber – the partition number (as defined by the partitioning scheme for the index) of the partition this page is part of
	PartitionID – the internal ID of the partition this page is part of
	iam_chain_type – see IAM chains and allocation units in SQL Server 2005
	PageType – the page type. Some common ones are:
		1 – data page
		2 – index page
		3 and 4 – text pages
		8 – GAM page
		9 – SGAM page
		10 – IAM page
		11 – PFS page
	IndexLevel – what level the page is at in the index (if at all). Remember that index levels go from 0 at the leaf to N at the root page (except in clustered indexes in SQL Server 2000 and 7.0 – where there’s a 0 at the leaf level (data pages) and a 0 at the next level up (first level of index pages))
	NextPageFID and NextPagePID – the page ID of the next page in the doubly-linked list of pages at this level of the index
	PrevPageFID and PrevPagePID – the page ID of the previous page in the doubly-linked list of pages at this level of the index
*/ 
-- Look at the slot array:
DBCC TRACEON(3604);
DBCC PAGE (CIPageTest, 1, 352, 3);

/*
The traceflag is to make the output of DBCC PAGE go to the console, rather than to the error log. The syntax for DBCC PAGE is:

	dbcc page ( {‘dbname’ | dbid}, filenum, pagenum [, printopt={0|1|2|3} ])

The filenum and pagenum parameters are taken from the page IDs that come from various system tables and appear in DBCC or other system error messages. A page ID of, say, (1:143) has filenum = 1 and pagenum = 143.
The printopt parameter has the following meanings:
0 – print just the page header
1 – page header plus per-row hex dumps and a dump of the page slot array (unless its a page that doesn’t have one, like allocation bitmaps)
2 – page header plus whole page hex dump
3 – page header plus detailed per-row interpretation

*/







