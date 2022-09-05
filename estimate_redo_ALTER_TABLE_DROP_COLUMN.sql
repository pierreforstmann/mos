-- ALTER TABLE DROP COLUMNS CHECKPOINT 10000 does not start from the beginning and starts where previous run has stopped 
-- example with Oracle 10.2.0.4 database

SQL> create table t(x int, y int);
 
Table created.
 
SQL> insert into t  select rownum, rownum from dual connect by level < 1000001;
 
1000000 rows created.
 
SQL> commit;
 
Commit complete.
 
SQL> select value
  2  from v$mystat ms, v$statname sn
  3  where ms.statistic# = sn.statistic# and name ='redo size';
 
     VALUE
----------
  21029804
 
SQL> alter table t drop column y checkpoint 10000;
 
Table altered.
 
SQL> select value
  2  from v$mystat ms, v$statname sn
  3  where ms.statistic# = sn.statistic# and name ='redo size';
 
     VALUE
----------
 242016232


--
-- The redo generated in one go is 220986428 bytes.
--
-- If I restart same script and stop it about 30 seconds and start following script:
--

SQL> select value
  2  from v$mystat ms, v$statname sn
  3  where ms.statistic# = sn.statistic# and name ='redo size';
 
     VALUE
----------
         0
 
SQL> alter table t drop columns continue checkpoint 10000;
 
Table altered.
 
SQL> select value
  2  from v$mystat ms, v$statname sn
  3  where ms.statistic# = sn.statistic# and name ='redo size';
 
     VALUE
----------
 205523340



-- The redo generated is lower than the redo for the one go run which proves that Oracle does not restart from beginning.
