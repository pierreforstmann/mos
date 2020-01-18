/*
**
** saas.sql 
**
** Schemas as a service in Oracle database 
**
*/
set echo on
create user syssa identified by syssa;
grant create session to syssa with admin option;
grant create table to syssa with admin option;
grant create user to syssa with admin option;
grant alter user to syssa with admin option;
grant create procedure to syssa;
grant create tablespace to syssa;
grant drop user to syssa;
grant drop tablespace to syssa;
--
--
connect syssa/syssa
create or replace package schema_admin
is
procedure create_schema(p_name varchar2);
procedure drop_schema(p_name varchar2);
end;
/

show errors
create or replace package body schema_admin is
--
procedure log(p_msg varchar2)
is
begin
  dbms_output.put_line(p_msg);
end;
--
procedure create_schema(p_name varchar2) is
l_stmt varchar2(250);
l_tsn  varchar2(30);
l_mh varchar2(40) := 'schema_admin.create_schema: ';
begin
  log(l_mh || 'p_name=' || p_name || ': started.');
  if (upper(p_name) not like 'U%')
  then
   raise_application_error(-20000, 'Schema name must start with U .');
  end if;
  l_stmt := 'create user ' || p_name || ' identified by ' || p_name;
  log(l_mh || l_stmt);
  execute immediate l_stmt;
  l_stmt := 'grant create session to ' || p_name;
  log(l_mh || l_stmt);
  execute immediate l_stmt;
  l_stmt := 'grant create table to ' || p_name;
  log(l_mh || l_stmt);
  execute immediate l_stmt;
  l_tsn := 'ts_' || p_name;
  l_stmt := 'create tablespace ' || l_tsn;
  log(l_mh || l_stmt);
  execute immediate l_stmt;
  l_stmt := 'alter user ' || p_name || ' default tablespace ' || l_tsn || ' quota unlimited on ' || l_tsn;
  log(l_mh || l_stmt);
  execute immediate l_stmt;
  log(l_mh || 'p_name=' || p_name || ': ended.');
end ;
--
procedure drop_schema(p_name varchar2) is
l_stmt varchar2(250);
l_tsn varchar2(30);
l_mh varchar2(40) := ' schema_admin.drop_schema: ';
begin
  log(l_mh || 'p_name=' || p_name || ': started.');
  if (upper(p_name) not like 'U%')
  then
   raise_application_error(-20000, 'Schema name must start with U .');
  end if;
  l_stmt := 'drop user ' || p_name || ' cascade';
  log(l_mh || l_stmt);
  execute immediate l_stmt;
  l_tsn := 'ts_' || p_name;
  l_stmt := 'drop tablespace ' || l_tsn;
  log(l_mh || l_stmt);
  execute immediate l_stmt;
  log(l_mh || 'p_name=' || p_name || ': ended.');
end;
--
end;
/
show errors
connect /
create user sadm identified by sadm;
grant create session to sadm;

