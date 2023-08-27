--
-- test_pkg_sql_id.sql
--
set echo on
show con_name
show user
-- 
drop table t1 purge;
drop table t2 purge;
drop table t3 purge;
--
whenever sqlerror exit failure
--
create table t1(x1 number);
create table t2(x2 varchar2(10));
create table t3(x3 date);
--
create or replace procedure pl
as
 c int;
begin
 select count(*) into c from t1, t2, t3
 where x1 = 1 or x2 = '2' or x3 = sysdate;
end;
/
show errors
--
create or replace procedure pb
as
 c int;
 v1 int := 1;
 v2 varchar2(10) := '2';
 v3 date := sysdate;
begin
 select count(*) into c from t1, t2, t3
 where x1 = v1 or x2 = v2 or x3 = v3;
end;
/
show errors
--
exec pl;
--
exec pb;
--
exit
