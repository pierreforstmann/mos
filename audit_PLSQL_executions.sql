-- You can use audit features to track stand alone stored procedures execution and package usage:

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
 
audit_trail                    string      DB                                   
bas001> 
bas001> create or replace procedure sp is
  2  begin
  3  null;
  4  end;
  5  /

Procedure created.

bas001> 
bas001> create or replace package p is
  2  procedure sp;
  3  end;
  4  /

Package created.

bas001> 
bas001> create or replace package body p is
  2  procedure sp
  3  is
  4  begin
  5  null;
  6  end;
  7  end;
  8  /

Package body created.

bas001> 
bas001> audit execute on sp by access;

Audit succeeded.

bas001> audit execute on p by access;

Audit succeeded.

bas001> exec sp;

PL/SQL procedure successfully completed.

bas001> exec p.sp;

PL/SQL procedure successfully completed.

bas001> host pause

bas001> exec sp;

PL/SQL procedure successfully completed.

bas001> exec p.sp;

PL/SQL procedure successfully completed.

bas001> alter session set nls_date_format='DD-MON-YYYY HH24:MI:SS';

Session altered.

bas001> column timestamp format a20
bas001> column owner format a10
bas001> column obj_name format a10
bas001> column action_name format a20
bas001> select timestamp, owner, obj_name, action_name from dba_audit_trail;

TIMESTAMP            OWNER      OBJ_NAME   ACTION_NAME
----------           ---------- ---------  -----------                 
13-JUN-2008 08:57:55 O          SP         EXECUTE PROCEDURE                    
13-JUN-2008 08:57:55 O          P          EXECUTE PROCEDURE                    
13-JUN-2008 08:57:56 O          SP         EXECUTE PROCEDURE                    
13-JUN-2008 08:57:56 O          P          EXECUTE PROCEDURE 
