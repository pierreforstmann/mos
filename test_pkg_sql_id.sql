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
 where x1 = 10  or x2 = '11' or x3 = to_date('12/12/2023','DD/MM/YYYY');
end;
/
show errors
--
create or replace procedure pb1
as
 c int;
 v1 int := 1;
 v2 varchar2(10) := 'ONE';
 v3 date := to_date('01/01/2023','DD/MM/YYYY'); 
begin
 select count(*) into c from t1, t2, t3
 where x1 = v1 or x2 = v2 or x3 = v3;
end;
/
show errors
--
create or replace procedure pb2
as
 c int;
 v1 int := 2;
 v2 varchar2(10) := 'TWO';
 v3 date := to_date('02/02/2023','DD/MM/YYYY') ;
begin
 select count(*) into c from t1, t2, t3
 where x1 = v1 or x2 = v2 or x3 = v3;
end;
/
--
create or replace procedure pb3
as
 c int;
 v1 int := 3;
 v2 varchar2(10) := 'THREE';
 v3 date := to_date('03/03/2023','DD/MM/YYYY'); 
begin
 select count(*) into c from t1, t2, t3
 where x1 = v1 or x2 = v2 or x3 = v3;
end;
/
--
exec pl;
--
exec pb1;
exec pb2;
exec pb3;
--
exit
