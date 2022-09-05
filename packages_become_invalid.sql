-- Even if packages become invalid, they will get automatically recompiled at first execution: 
-- this recompilation will not always trigger a error message.

--
-- No error message in this case:
--

dev001> 
dev001> drop table t;

Table dropped.

dev001> drop procedure pi;

Procedure dropped.

dev001> drop package pq;

Package dropped.

dev001> 
dev001> create table t(x int);

Table created.

dev001> 
dev001> create procedure pi
  2  is
  3  t number;
  4  begin
  5  for c in(select * from t)
  6  loop
  7   t:= t + c.x;
  8  end loop;
  9  end;
 10  /

Procedure created.

dev001> show errors
No errors.
dev001> 
dev001> create package pq
  2  is
  3  procedure pq;
  4  end;
  5  /

Package created.

dev001> show errors
No errors.
dev001> 
dev001> create package body pq
  2  is
  3  procedure pq
  4  is
  5  t number;
  6  begin
  7  for c in(select * from t)
  8  loop
  9   t:= t + c.x;
 10  end loop;
 11  end;
 12  --
 13  end;
 14  /

Package body created.

dev001> show errors
No errors.
dev001> 
dev001> exec pi;

PL/SQL procedure successfully completed.

dev001> 
dev001> exec pq.pq;

PL/SQL procedure successfully completed.

dev001> 
dev001> alter table t add (y int);

Table altered.

dev001> 
dev001> column object_name format a10;
dev001> column object_type format a20;
dev001> select object_name, object_type, status from user_objects
  2  where object_name like 'PI%' or object_name like '%PQ';

OBJECT_NAM OBJECT_TYPE          STATUS
--------------------
                                        
PI         PROCEDURE            INVALID                                         
PQ         PACKAGE              VALID                                           
PQ         PACKAGE BODY         INVALID                                         

dev001> 
dev001> exec pi;

PL/SQL procedure successfully completed.

dev001> exec pq.pq;

PL/SQL procedure successfully completed.

dev001> 
dev001> exit

--
-- Error messages in this case because the package contains global variables:
--

dev001> 
dev001> drop table t;

Table dropped.

dev001> drop procedure pi;

Procedure dropped.

dev001> drop package pq;

Package dropped.

dev001> 
dev001> create table t(x int);

Table created.

dev001> 
dev001> create procedure pi
  2  is
  3  t number;
  4  begin
  5  for c in(select * from t)
  6  loop
  7   t:= t + c.x;
  8  end loop;
  9  end;
 10  /

Procedure created.

dev001> show errors
No errors.
dev001> 
dev001> create package pq
  2  is
  3  glo number;
  4  procedure pq;
  5  end;
  6  /

Package created.

dev001> show errors
No errors.
dev001> 
dev001> create package body pq
  2  is
  3  procedure pq
  4  is
  5  t number;
  6  begin
  7  glo:=2;
  8  for c in(select * from t)
  9  loop
 10   t:= t + c.x;
 11  end loop;
 12  end;
 13  --
 14  end;
 15  /

Package body created.

dev001> show errors
No errors.
dev001> 
dev001> exec pi;

PL/SQL procedure successfully completed.

dev001> 
dev001> exec pq.pq;

PL/SQL procedure successfully completed.

dev001> 
dev001> alter table t add (y int);

Table altered.

dev001> 
dev001> column object_name format a10;
dev001> column object_type format a20;
dev001> select object_name, object_type, status from user_objects
  2  where object_name like 'PI%' or object_name like '%PQ';

OBJECT_NAM OBJECT_TYPE          STATUS
--------------------
                                        
PI         PROCEDURE            INVALID                                         
PQ         PACKAGE              VALID                                           
PQ         PACKAGE BODY         INVALID                                         

dev001> 
dev001> exec pi;

PL/SQL procedure successfully completed.

dev001> exec pq.pq;
BEGIN pq.pq; END;

*
ERROR at line 1:
ORA-04068: existing state of packages has been discarded 
ORA-04061: existing state of package body "XXX.PQ" has been  invalidated 
ORA-06508: PL/SQL: could not find program unit being called:  "XXX.PQ" 
ORA-06512: at line 1 

dev001> dev001> exit
