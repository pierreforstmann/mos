--
-- exec_sql.sql
--
--
-- Copyright Pierre Forstmann 2023
--
set echo on
whenever sqlerror exit failure;
set serveroutput on
select name from v$database;
show user;
show con_name;
--
create or replace procedure exec_sql(p_ownname varchar2, p_sql_id varchar2)
--
-- needs "grant select on sys.v_$sql to <user>"
-- needs "grant select on sys.v_$sql_bind_capture to <user>"
-- needs statistics_level=all
--
is
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
/
show errors
--
exit
