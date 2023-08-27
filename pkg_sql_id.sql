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
-- needs "grant select on dba_hist_sql_text to <user>"
-- needs "grant select on dba_hist_sqlbind to <user>"
--
is
 procedure display(p_sql_id varchar2);
 procedure adisplay(p_sql_id varchar2);
 procedure execute(p_ownname varchar2, 
	           p_sql_id varchar2, 
		   p_child_number int default 0,
	           p_use_default_values boolean default false);
 procedure aexecute(p_ownname varchar2, 
	           p_sql_id varchar2, 
	           p_use_default_values boolean default false);
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
 function get_bind_value(p_sql_id varchar2, 
			 p_child_number int, 
			 p_bind_var_index int)
 return anydata 
 is
 v_max_last date; 
 v_value sys.v_$sql_bind_capture.value_anydata%type;
 begin
 --
 -- bind variable values are captured every 15 minutes
 --
   select max(last_captured) into v_max_last 
   from  sys.v_$sql_bind_capture sbc
   where sbc.sql_id = p_sql_id 
   and sbc.child_number = p_child_number
   and sbc.position = p_bind_var_index;
 -- 
   select value_anydata into v_value
   from  sys.v_$sql_bind_capture sbc
   where sbc.sql_id = p_sql_id 
   and sbc.child_number = p_child_number
   and sbc.position = p_bind_var_index
   and last_captured = v_max_last;
 return v_value;
 end;
--
--
 procedure display(p_sql_id varchar2) is
 v_sql_id_found boolean := false;
 v_nb_params int;
 begin
  for c in (
   select parsing_schema_name, child_number, sql_text 
   from sys.v_$sql 
   where sql_id = p_sql_id)
   loop
    v_sql_id_found := true;
    log('parsing_schema: ' || c.parsing_schema_name || ' child_number: ' 
	|| c.child_number || ' text: ' || c.sql_text);
   end loop;
   --
   if (not v_sql_id_found)
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
   select hash_value, sql_id, child_number, position, name, datatype, value_string
   from  sys.v_$sql_bind_capture sbc
   where sbc.sql_id = p_sql_id
   order by hash_value, sql_id, child_number, position
 )
 loop
   log('hash_value: ' || b.hash_value || ' sql_id: ' || b.sql_id || 
       ' child_number: ' || b.child_number || 
       ' position: ' || b.position || ' name: ' || b.name || ' datatype: ' || 
       b.datatype || ' value: ' || b.value_string); 
 end loop;
 --
 end;
--
--
procedure adisplay(p_sql_id varchar2) is
 v_sql_id_found boolean := false;
 v_nb_params int;
 begin
  for c in (
   select sql_text
   from dba_hist_sqltext 
   where sql_id = p_sql_id)
   loop
    v_sql_id_found := true;
    log('text: ' || c.sql_text);
   end loop;
   --
   if (not v_sql_id_found)
   then
        log('ERROR: sql_id: ' || p_sql_id || ' not found.');
        return;
  end if;
  --
  for c in (
   select sql_id, last_captured, count(*) as cnt
   from dba_hist_sqlbind
   where sql_id = p_sql_id
   group by sql_id, last_captured
   )
 loop
    log(' sql_id: ' || c.sql_id ||
        ' last_captured: ' || c.last_captured ||
        ' nb. parameters: ' || c.cnt);
 end loop;
 --
 for b in (
   select sql_id, last_captured, position, name, datatype, value_string
   from dba_hist_sqlbind 
   where sql_id = p_sql_id
   order by last_captured, position
 )
 loop
   log(' sql_id: ' || b.sql_id ||
       ' last_captured: ' || b.last_captured ||
       ' position: ' || b.position || ' name: ' || b.name || ' datatype: ' ||
       b.datatype || ' value: ' || b.value_string);
 end loop;
 --
 end;
--
--
 procedure execute(p_ownname varchar2, 
	           p_sql_id varchar2, 
		   p_child_number int default 0,
	           p_use_default_values boolean default false) 
	           is
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
v_varchar2 varchar2(4000);
v_value sys.v_$sql_bind_capture.value_anydata%type;
begin
 execute immediate('alter session set current_schema=' || p_ownname);
 dbms_output.put_line('INFO: alter session set current_schema=' || p_ownname || ' OK.');
--
 v_cn := dbms_sql.open_cursor;
--
 select sql_text into v_st 
 from sys.v_$sql 
 where sql_id = p_sql_id and child_number = p_child_number;
-- 
 dbms_sql.parse(v_cn, v_st, dbms_sql.native);
--
 select count(*) into v_nb 
 from sys.v_$sql_bind_capture sbc
 where sbc.sql_id = p_sql_id 
 and child_number = p_child_number;
 log('INFO: SQL_ID: ' || p_sql_id || ' child_number: ' || p_child_number 
     || ' has ' || v_nb || ' parameters.');
 for idx in 1 .. v_nb
 loop
  select position, name, datatype
  into v_pos, v_name, v_type
  from  sys.v_$sql_bind_capture sbc
  where sbc.sql_id = p_sql_id
  and position = idx
  and child_number = p_child_number;
  -- type 1 = varchar2
  -- type 2 = number
  -- type 12 = date
   log('INFO: binding ' || v_name || ' ...');
   if (not p_use_default_values)
   then
    v_value := get_bind_value( p_sql_id, p_child_number, v_pos);
    case v_type 
     when 1 then
      v_varchar2 := SYS.ANYDATA.accessVarchar2(v_value);
      dbms_sql.bind_variable(v_cn, v_name, v_varchar2);
     when 2 then
      v_number := SYS.ANYDATA.accessNumber(v_value);
      dbms_sql.bind_variable(v_cn, v_name, v_number);
     when 12 then
      v_date := SYS.ANYDATA.accessDate(v_value);
      dbms_sql.bind_variable(v_cn, v_name, v_date);
     else log('ERROR: unexpected datatype: ' || v_type);
    end case;
   else
    case v_type 
     when 1 then
      v_varchar2 := 'ZERO';
      dbms_sql.bind_variable(v_cn, v_name, v_varchar2);
     when 2 then
      v_number := '0';
      dbms_sql.bind_variable(v_cn, v_name, v_number);
     when 12 then
      v_date := to_date('01/01/1970','DD/MM/YYYY');
      dbms_sql.bind_variable(v_cn, v_name, v_date);
     else log('ERROR: unexpected datatype: ' || v_type);
    end case;
   end if;
   log('INFO:  ... done.' );
 end loop;
--
 log('INFO: executing: ' || v_st || ' ...');
 v_rp := dbms_sql.execute(v_cn);
 log('INFO: ... done.');
--
 dbms_sql.close_cursor(v_cn);
--
 exception
     --
 when ORA1008_detected then
     begin
      log('WARNING: ORA-1008 detected.');
     end;
 when others then
     log('ERROR: unexpected exception: sqlcode: ' || SQLCODE || ' message: ' || SQLERRM);
     dbms_sql.close_cursor(v_cn);
     raise;
--
 end;
--
--
function aget_bind_value(p_sql_id varchar2,
                         p_bind_var_index int)
 return anydata
 is
 v_max_last date;
 v_value dba_hist_sqlbind.value_anydata%type;
 begin
 --
 -- bind variable values are captured every 15 minutes
 --
   select max(last_captured) into v_max_last
   from dba_hist_sqlbind 
   where sql_id = p_sql_id
   and position = p_bind_var_index;
 --
   select value_anydata into v_value
   from dba_hist_sqlbind 
   where sql_id = p_sql_id
   and position = p_bind_var_index
   and last_captured = v_max_last;
 return v_value;
 end;
--
--
 procedure aexecute(p_ownname varchar2,
                   p_sql_id varchar2,
                   p_use_default_values boolean default false)
                   is
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
v_varchar2 varchar2(4000);
v_value sys.v_$sql_bind_capture.value_anydata%type;
v_max_last date;
begin
 execute immediate('alter session set current_schema=' || p_ownname);
 dbms_output.put_line('INFO: alter session set current_schema=' || p_ownname || ' OK.');
--
 v_cn := dbms_sql.open_cursor;
--
 select sql_text into v_st
 from dba_hist_sqltext 
 where sql_id = p_sql_id;
--
 dbms_sql.parse(v_cn, v_st, dbms_sql.native);
--
--
 select distinct max(last_captured) into v_max_last
 from dba_hist_sqlbind
 where sql_id = p_sql_id;
--
 select count(*) into v_nb
 from dba_hist_sqlbind 
 where sql_id = p_sql_id
 and last_captured = v_max_last;
 log('INFO: sql_id: ' || p_sql_id || ' has ' || v_nb || ' parameters.');
 for idx in 1 .. v_nb
 loop
  select position, name, datatype
  into v_pos, v_name, v_type
  from dba_hist_sqlbind 
  where sql_id = p_sql_id
  and position = idx
  and last_captured = v_max_last;
  -- type 1 = varchar2
  -- type 2 = number
  -- type 12 = date
   log('INFO: binding ' || v_name || ' ...');
   if (not p_use_default_values)
   then
    v_value := aget_bind_value( p_sql_id, v_pos);
    case v_type
     when 1 then
      v_varchar2 := SYS.ANYDATA.accessVarchar2(v_value);
      dbms_sql.bind_variable(v_cn, v_name, v_varchar2);
     when 2 then
      v_number := SYS.ANYDATA.accessNumber(v_value);
      dbms_sql.bind_variable(v_cn, v_name, v_number);
     when 12 then
      v_date := SYS.ANYDATA.accessDate(v_value);
      dbms_sql.bind_variable(v_cn, v_name, v_date);
     else log('ERROR: unexpected datatype: ' || v_type);
    end case;
   else
    case v_type
     when 1 then
      v_varchar2 := 'ZERO';
      dbms_sql.bind_variable(v_cn, v_name, v_varchar2);
     when 2 then
      v_number := '0';
      dbms_sql.bind_variable(v_cn, v_name, v_number);
     when 12 then
      v_date := to_date('01/01/1970','DD/MM/YYYY');
      dbms_sql.bind_variable(v_cn, v_name, v_date);
     else log('ERROR: unexpected datatype: ' || v_type);
    end case;
   end if;
   log('INFO:  ... done.' );
 end loop;
--
 log('INFO: executing: ' || v_st || ' ...');
 v_rp := dbms_sql.execute(v_cn);
 log('INFO: ... done.');
--
 dbms_sql.close_cursor(v_cn);
--
 exception
     --
 when ORA1008_detected then
     begin
      log('WARNING: ORA-1008 detected.');
     end;
 when others then
     log('ERROR: unexpected exception: sqlcode: ' || SQLCODE || ' message: ' || SQLERRM);
     dbms_sql.close_cursor(v_cn);
     raise;
 end;
--
--
end;
/
show errors
--
exit
