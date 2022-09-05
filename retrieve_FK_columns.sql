-- You can try to use and adapt follwowig SQL*Plus script (v_tn must be assigned to the table name which has the primary key. 
-- The script assumes all related tables are in the current schema):

SQL> column column_name format a20
SQL> column table_name format a20
SQL> 
SQL> alter session set nls_language=american;
 
Session altered.
 
SQL> select * from v$version;
 
BANNER                                                                                                                              
----------------------------------------------------------------                                                                    
Oracle Database 10g Express Edition Release 10.2.0.1.0 - Product                                                                    
PL/SQL Release 10.2.0.1.0 - Production                                                                                              
CORE	10.2.0.1.0	Production                                                                                                          
TNS for 32-bit Windows: Version 10.2.0.1.0 - Production                                                                             
NLSRTL Version 10.2.0.1.0 - Production                                                                                              
 
SQL> 
SQL> 
SQL> drop table c purge;
 
Table dropped.
 
SQL> drop table p purge;
 
Table dropped.
 
SQL> 
SQL> create table p(px int, py int);
 
Table created.
 
SQL> alter table p add primary key(px,py);
 
Table altered.
 
SQL> 
SQL> create table c(c0 int primary key, c1 int check(c1>0), cx int, cy int, constraint ri foreign key(cx,cy) references p);
 
Table created.
 
SQL> 
SQL> 
SQL> var v_tn varchar2(30);
SQL> exec :v_tn := 'p';
 
PL/SQL procedure successfully completed.
 
SQL> 
SQL> select c.table_name, c.constraint_name, cc.column_name
  2  from user_constraints c, user_cons_columns cc
  3  where r_constraint_name in
  4   (select constraint_name
  5   from user_constraints uc
  6   where uc.constraint_type = 'P' and uc.table_name = upper(:v_tn))
  7  and c.table_name = cc.table_name
  8  and c.constraint_name = cc.constraint_name;
 
TABLE_NAME           CONSTRAINT_NAME                COLUMN_NAME                                                                     
-------------------- ------------------------------ --------------------                                                            
C                    RI                             CX                                                                              
C                    RI                             CY                                                                              
 
SQL> 
