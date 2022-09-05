-- This query should work for a single LOB column in a single table and takes into account the 2 segments needed for each LOB column:

SQL> create table t(x int, y clob);

Table created.

SQL> set NULL null
SQL> select segment_name, index_name from user_lobs;

SEGMENT_NAME                   INDEX_NAME
------------------------------ ------------------------------
SYS_LOB0000015911C00002$$      SYS_IL0000015911C00002$$

SQL> select v1.col_size, v2.seg_size from
  2  (select sum(dbms_lob.getlength(y)) as col_size from t) v1,
  3  (select sum(bytes) as seg_size from user_segments where segment_name in
  4   (
  5    (select segment_name from user_lobs where table_name='T' and column_name='Y')
  6    union
  7    (select index_name from user_lobs where table_name='T' and column_name='Y')
  8   )
  9   ) v2
 10  ;

  COL_SIZE   SEG_SIZE
---------- ----------
null           131072
