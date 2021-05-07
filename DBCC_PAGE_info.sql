-- Get the page for thie table
DBCC IND(CIPageTest, 'PageTest', -1);
 
-- Look at the slot array:
DBCC TRACEON(3604);
DBCC PAGE (CIPageTest, 1, 352, 3);
