SQL> select * from v$version;
 
BANNER
----------------------------------------------------------------
Oracle Database 10g Enterprise Edition Release 10.2.0.4.0 - Prod
PL/SQL Release 10.2.0.4.0 - Production
CORE    10.2.0.4.0      Production
TNS for 32-bit Windows: Version 10.2.0.4.0 - Production
NLSRTL Version 10.2.0.4.0 - Production
 
SQL> set serveroutput on
SQL> drop table t purge;
 
Table dropped.
 
SQL> create table t(id number not null, x number constraint x_chk check (x >0));
 
Table created.
 
SQL> select constraint_name from user_constraints where constraint_type='C';
 
CONSTRAINT_NAME
------------------------------
SYS_C003570
X_CHK
 
SQL> set long 500
SQL> declare
  2  c clob;
  3  begin
  4  for ct in (select constraint_name from user_constraints where constraint_type='C')
  5  loop
  6  select dbms_metadata.get_ddl('CONSTRAINT',ct.constraint_name,USER) into c from dual;
  7  if (dbms_lob.instr(c,'NOT NULL') = 0)
  8  then
  9  dbms_output.put_line(c);
 10  end if;
 11  end loop;
 12  end;
 13  / 
 
  ALTER TABLE "TEST"."T" ADD CONSTRAINT "X_CHK" CHECK (x >0) ENABLE
 
 
PL/SQL procedure successfully completed.
