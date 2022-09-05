SQL> desc test.t;
 Name                                      Null?    Type
 ----------------------------------------- -------- ----------------------------
 X                                                  VARCHAR2(10)
 
SQL> select * from test.t;
 
X
----------
0.
 
SQL> delete test.t;
 
1 row deleted.
 
SQL> commit;
 
Commit complete.
 
SQL> select undo_sql from flashback_transaction_query where table_name = 'T' and logon_user='SYS';
 
UNDO_SQL
--------------------------------------------------------------------------------
insert into "TEST"."T"("X") values ('0.');
 
SQL>
