-- If modified/udpated means that an INSERT/UPDATE/DELETE statement has been run on the table,
-- you could try to use auditing feature as described in the following example:

bas001> 
bas001> create table t(x int);

Table created.

bas001> create synonym nt for t;

Synonym created.

bas001> 
bas001> select * from v$version;

BANNER
                                                                   
Oracle Database 10g Enterprise Edition Release 10.2.0.2.0 - Prod                                                                    
PL/SQL Release 10.2.0.2.0 - Production                                                                                              
CORE	10.2.0.2.0	Production                                                                                                          
TNS for 32-bit Windows: Version 10.2.0.2.0 - Production                                                                             
NLSRTL Version 10.2.0.2.0 - Production                                                                                              

bas001> show parameter audit_trail;

Parameter                      TYPE        Value
-----------
                                                     
audit_trail                    string      DB_EXTENDED                                                                              
bas001> 
bas001> audit insert,update,delete on t by access;

Audit succeeded.

bas001> insert into t values(1);

1 row created.

bas001> exec dbms_lock.sleep(1);

PL/SQL procedure successfully completed.

bas001> update t set x=2 where x=1;

1 row updated.

bas001> exec dbms_lock.sleep(1);

PL/SQL procedure successfully completed.

bas001> delete t where x=2;

1 row deleted.

bas001> exec dbms_lock.sleep(1);

PL/SQL procedure successfully completed.

bas001> commit;

Commit complete.

bas001> insert into nt values(10);

1 row created.

bas001> exec dbms_lock.sleep(1);

PL/SQL procedure successfully completed.

bas001> update nt set x=20 where x=10;

1 row updated.

bas001> exec dbms_lock.sleep(1);

PL/SQL procedure successfully completed.

bas001> delete nt where x=20;

1 row deleted.

bas001> exec dbms_lock.sleep(1);

PL/SQL procedure successfully completed.

bas001> commit;

Commit complete.

bas001> 
bas001> create or replace procedure p
  2  is
  3  begin
  4   insert into t values(30);
  5   commit;
  6  end;
  7  /

Procedure created.

bas001> exec dbms_lock.sleep(1);

PL/SQL procedure successfully completed.

bas001> exec p;

PL/SQL procedure successfully completed.

bas001> 
bas001> create view v as select x from t;

View created.

bas001> exec dbms_lock.sleep(1);

PL/SQL procedure successfully completed.

bas001> update v set x=40 where x=30;

1 row updated.

bas001> commit;

Commit complete.

bas001> 
bas001> alter session set nls_date_format='DD-MON-YYYY HH24:MI:SS';

Session altered.

bas001> column timestamp format a20
bas001> column username format a10
bas001> column owner format a10
bas001> column obj_name format a10
bas001> column action_name format a10
bas001> column sql_text format a30
bas001> select timestamp, username, obj_name, action_name, sql_text from dba_audit_trail;

TIMESTAMP            USERNAME   OBJ_NAME   ACTION_NAM SQL_TEXT
----------           ----------
                                               
18-JUN-2008 09:52:13 O          T          INSERT     insert into t values(1)                                                       
18-JUN-2008 09:52:14 O          T          UPDATE     update t set x=2 where x=1                                                    
18-JUN-2008 09:52:15 O          T          DELETE     delete t where x=2                                                            
18-JUN-2008 09:52:16 O          T          INSERT     insert into nt values(10)                                                     
18-JUN-2008 09:52:17 O          T          UPDATE     update nt set x=20 where x=10                                                 
18-JUN-2008 09:52:18 O          T          DELETE     delete nt where x=20                                                          
18-JUN-2008 09:52:20 O          T          INSERT     INSERT INTO T VALUES(30)                                                      
18-JUN-2008 09:52:21 O          T          UPDATE     update v set x=40 where x=30                                                  

8 rows selected.

