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
v_cn integer;
v_rp integer;
v_st clob;
v_nb integer;
begin
 execute immediate('alter session set current_schema=' || p_ownname);
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
 where sbc.sql_id = p_sql_id; 
 dbms_output.put_line('found : ' || v_nb || ' bind variables');
--
-- hard code bind variables for SQL statements in PL/SQL
--
 if (v_nb = 0)
 then
  null; 
 end if;
--
 v_rp := dbms_sql.execute(v_cn);
--
 dbms_sql.close_cursor(v_cn);
--
exception
 when others then
     dbms_sql.close_cursor(v_cn);
     raise;
--
end;
/
show errors
--
exit
