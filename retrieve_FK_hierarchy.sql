--
-- retrieve_FK_hierarchy.sql
--
-- assuming all tables belong to same schema
--

drop table a
;

drop table e
;

drop table d
;

drop table c
;

drop table b
;

drop table b1
;

drop table d1
;

drop table bb1
;

drop table bb2
;

drop table dd1
;

drop table dd2
;

drop table ddd1
;

drop table dddd1
;

drop table ddddd1
;

create table ddddd1(x int primary key)
;

create table dddd1(x int primary key references ddddd1)
;

create table ddd1(x int primary key references dddd1)
;

create table bb1(x int primary key)
;

create table bb2(x int primary key)
;

create table dd1(x int primary key references ddd1)
;

create table dd2(x int primary key)
;

create table b1(x int primary key references bb1, y references bb2)
;

create table d1(x int primary key references dd1, y references dd2)
;

create table b(x int primary key references b1)
;

create table c(x int primary key)
;

create table d(x int primary key references d1)
;

create table e(x int primary key)
;

 create table a(x int primary key references b, y references c, z references d, x1 references e)
;

purge recyclebin


drop type MyTableType
;

create or replace type myScalarType as object 
  ( lvl	 number, 
   tname  varchar2(30) 
  ) 

/

create or replace type myTableType as table of myScalarType  

/

create or replace 
 function depends( p_table_name  in varchar2, 
    		       p_lvl in number default 1 ) return myTableType 
  AUTHID CURRENT_USER 
  as 
    	    l_data myTableType := myTableType(); 
    	    p_rname varchar2(30); 
     
   	    procedure recurse( p_cname in varchar2, 
   			               p_lvl   in number ) 
   	    is 
   	    p_rname varchar2(30); 
   	    begin 
   		if ( l_data.count > 1000 ) 
   		then 
   		    raise_application_error( -20001, 'probable loop' ); 
   		end if; 
   		for x in ( 
   		 select table_name, 
   			owner 
   			from user_constraints 
   			where constraint_name = p_cname 
   			and constraint_type = 'P' 
   		) 
   		loop 
   		   l_data.extend; 
   		   l_data(l_data.count) := myScalarType( p_lvl, x.table_name); 
  		   for y in ( 
   		   select r_constraint_name from user_constraints 
   		    where table_name = x.table_name and constraint_type = 'R') 
   		   loop 
   		    recurse( y.r_constraint_name, p_lvl+1); 
   		   end loop; 
   		end loop; 
  		exception when no_data_found 
   		 then return; 
   	    end; 
   	begin 
   	    l_data.extend; 
   	    for z in ( 
   	    select r_constraint_name from user_constraints 
   	      where table_name = p_table_name  
   	      and constraint_type = 'R' 
   	    ) 
   	    loop 
   	     l_data.extend; 
   	     l_data(l_data.count) := myScalarType( 1,  p_table_name); 
   	     recurse(z.r_constraint_name, 2 ); 
   	    end loop; 
   	    return l_data; 
   	end; 

/

select * from table(cast (depends('A', 1) as myTableType))
;

select tname from ( 
 select tname, lvl from table(cast (depends('A', 1) as myTableType)) 
   where lvl > 1 
  order by lvl, tname)
;

