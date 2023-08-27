--
-- pkg_sql_id.sql
--
--
-- Copyright Pierre Forstmann 2023
--
set echo on
whenever sqlerror exit failure;
set serveroutput on
set linesize 120
select name from v$database;
show user;
show con_name;
--
--
create or replace package sql_id
--
-- needs "grant select on sys.v_$sql to <user>"
-- needs "grant select on sys.v_$sql_bind_capture to <user>"
-- needs statistics_level=all at database level
-- needs "set serveroutput on"
--
is
 procedure display(p_sql_id varchar2);
 procedure execute(p_ownname varchar2, p_sql_id varchar2);
end;
/
show errors
--
--
create or replace package body sql_id
is 
--
--
 procedure log(message varchar2) is
 begin
  dbms_output.put_line(message);
 end;
--
--
 procedure display(p_sql_id varchar2) is
 v_st sys.v_$sql.sql_text%type;
 v_schema sys.v_$sql.parsing_schema_name%type;
 v_child_number sys.v_$sql.child_number%type;
 v_found boolean := false;
 v_nb_params int;
 begin
  for c in (
   select parsing_schema_name, child_number, sql_text 
   from sys.v_$sql 
   where sql_id = p_sql_id)
   loop
    v_found := true;
    log('parsing_schema: ' || c.parsing_schema_name || ' child_number: ' 
	|| c.child_number || ' text: ' || c.sql_text);
   end loop;
   --
   if (not v_found)
   then
        log('ERROR: sql_id: ' || p_sql_id || ' not found.');
	return; 
  end if;
  --
  for c in (
   select hash_value, sql_id, child_number, count(*) as cnt
   from sys.v_$sql_bind_capture sbc
   where sbc.sql_id = p_sql_id
   group by hash_value, sql_id, child_number)
 loop
    log('hash_value: ' || c.hash_value || ' sql_id: ' || c.sql_id || 
	' child_number: ' || c.child_number || 
	' nb. parameters: ' || c.cnt);
 end loop;
 --
 for b in (
   select hash_value, sql_id, child_number, position, name, datatype
   from  sys.v_$sql_bind_capture sbc
   where sbc.sql_id = p_sql_id
   order by hash_value, sql_id, child_number, position
 )
 loop
   log('hash_value: ' || b.hash_value || ' sql_id: ' || b.sql_id || 
       ' child_number: ' || b.child_number || 
       ' position: ' || b.position || ' name: ' || b.name || ' datatype: ' || 
       b.datatype); 
 end loop;

 end;
--
--
 procedure execute(p_ownname varchar2, p_sql_id varchar2) is
--
ORA1008_detected EXCEPTION;
PRAGMA EXCEPTION_INIT(ORA1008_detected, -1008);
v_cn integer;
v_rp integer;
v_st clob;
v_nb integer;
v_pos integer;
v_name varchar2(30);
v_type integer;
v_number number;
v_date date;
v_varchar varchar2(128);
begin
 execute immediate('alter session set current_schema=' || p_ownname);
 dbms_output.put_line('INFO: alter session set current_schema=' || p_ownname || ' OK.');
--
 v_cn := dbms_sql.open_cursor;
--
 select sql_text into v_st 
 from sys.v_$sql 
 where sql_id = p_sql_id and parsing_schema_name = upper(p_ownname) and rownum = 1;
-- 
 dbms_sql.parse(v_cn, v_st, dbms_sql.native);
--
 select count(*) into v_nb 
 from sys.v_$sql_bind_capture sbc
 where sbc.sql_id = p_sql_id 
 and child_number = 0;
 dbms_output.put_line('INFO: found ' || v_nb || ' bind variables for SQL_ID: ' || p_sql_id);
 for idx in 1 .. v_nb
 loop
  select position, name, datatype
  into v_pos, v_name, v_type
  from  sys.v_$sql_bind_capture sbc
  where sbc.sql_id = p_sql_id
  and position = idx
  and child_number = 0;
  dbms_output.put_line('INFO: variable at position: ' || v_pos || ' is named: ' || v_name || ' and has datatype: ' || v_type);
  if (v_type = 1)
  then
   dbms_output.put_line('INFO: binding ' || v_name || ' ...');
   dbms_sql.bind_variable(v_cn, v_name, 'OK');
   dbms_output.put_line('INFO:  ... done.' );
  end if;
  if (v_type = 2)
  then
   dbms_output.put_line('INFO: binding ' || v_name || ' ...');
   dbms_sql.bind_variable(v_cn, v_name, 0);
   dbms_output.put_line('INFO:  ... done.' );
  end if;
  if (v_type = 12)
  then
   dbms_output.put_line('INFO: binding ' || v_name || ' ...');
   dbms_sql.bind_variable(v_cn, v_name, sysdate);
   dbms_output.put_line('INFO:  ... done.' );
  end if;
 end loop;
--
 dbms_output.put_line('INFO: executing: ' || v_st || ' ...');
 v_rp := dbms_sql.execute(v_cn);
 dbms_output.put_line('INFO: ... done.');
--
 dbms_sql.close_cursor(v_cn);
--
exception
     --
 when ORA1008_detected then
     begin
      dbms_output.put_line('WARNING: ORA-1008 detected.');
     end;
 when others then
     dbms_output.put_line('ERROR: unexpected exception ' || SQLCODE || ':' || SQLERRM);
     dbms_sql.close_cursor(v_cn);
     raise;
--
end;
--
--
end;
/
show errors
--
exit
