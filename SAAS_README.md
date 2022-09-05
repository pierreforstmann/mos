# Schema as a service with definer rights PL/SQL package

## The problem

You are database administrator and you are asked to create schemas on the same database but really too frequently or you are asked to do this on too many databases quite frequently. What do you do ? If this is a non production database, you could give DBA privileges to the application teams requesting this but this may be against your organization security policy. 

Ideally you would like to have something like schema as a service as in Oracle Entreprise Manager 12c. But let’s assume this is not possible for some reason.

The purpose of the blog post is to give a solution based on PL/SQL that allows at the same time to create and drop schema without giving any DBA like privilege (no DBA role and not even CREATE USER, ALTER USER or CREATE TABLESPACE system privilege).

## The solution

You can use Oracle PL/SQL features to give execution privilege to a package without giving privileges needed to run the code inside the package.

Thanks to definer rights a PL/SQL package will run with privileges granted to the owner or definer of the package but the user running the package needs only the execution privilege on the PL/SQL package. 

This is a fundamental PL/SQL feature available since Oracle 7 (see for example page 221 of Oracle7 Server Application Developer’s Guide which says: *Attention: A stored subprogram or package executes in the privilege domain of the owner of the procedure. The owner must have been explicitly granted the necessary object privileges to all objects referenced within the body of the code*). 

The definer rights feature name has been introduced in Oracle 8i PL/SQL User’s Guide and Reference page 295 which says: *By default, stored procedures and SQL methods execute with the privileges of their owner, not their current user. Such definer-rights routines are bound to the schema in which they reside.*

## Specifications

Here are the specifications of schemas as a service (SAAS):
1. SAAS must allow to create a schema and a single tablespace for this schema (the tablespace can only be used by the schema owner)
2. SAAS must allow to the created user to create table and stored PL/SQL.
3. SAAS must allow to drop the schema and its tablespace
4. SAAS must only work for a database using Oracle Managed Files (OMF)
5. the schema name must start with U letter (in order to avoid any problem with Oracle provided schemas)
6. the Oracle user using SAAS must not be granted DBA role or any system privilege but only execution of the SAAS PL/SQL package.

## Design

Two user accounts need to be created:

1. SYSSA: this account will be granted the privileges to create an user account and a tablespace.

It must also be granted the privileges to be granted to the user account that it will create. It will also own the SAAS package.

This account owns elevated privileges and must be managed like a DBA account (i.e. its password must be restricted to DBA team).

2. SADM: this is the account that must be used by SAAS user: this account will only be granted execution privilege on the SAAS package owned by SYSSA.

## Setup

I will use a 12.1.0.2 database but I could have used a 9.2 database with OMF (or even a 7.3 database without using OMF).

First to have SQL*Plus display the current database and the current user, add in your shell login script:

    export SQLPATH=/home/oracle/scripts

And create /home/oracle/scripts/login.sql:

    $ cat /home/oracle/scripts/login.sql
    set sqlprompt "&&_USER@&&_CONNECT_IDENTIFIER>"

In order to avoid to use SYS and even SYSTEM accounts, create a OS authenticated account (assuming UNIX current account is oracle):

    $ sqlplus / as sysdba
  
    SQL*Plus: Release 12.1.0.2.0 Production on Tue Mar 24 20:13:58 2015

    Copyright (c) 1982, 2014, Oracle.  All rights reserved.


    Connected to:
    Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
    With the Partitioning, Automatic Storage Management, OLAP, Advanced Analytics
    and Real Application Testing options

    SYS@DB12>create user ops$oracle identified externally;

    User created.

    SYS@DB12>grant dba to ops$oracle;

    Grant succeeded.

Now you can connect without giving user account and password:

    $ sqlplus /

    SQL*Plus: Release 12.1.0.2.0 Production on Tue Mar 24 20:14:16 2015

    Copyright (c) 1982, 2014, Oracle.  All rights reserved.


    Connected to:
    Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
    With the Partitioning, Automatic Storage Management, OLAP, Advanced Analytics
    and Real Application Testing options

    OPS$ORACLE@DB12>show user;
    USER is "OPS$ORACLE" 
    OPS$ORACLE@DB12>
    OPS$ORACLE@DB12>select name from v$database;

    NAME
    ---------
    DB12

    OPS$ORACLE@DB12>

  ### Creating SYSSA account:

    OPS$ORACLE@DB12>create user syssa identified by syssa;

    User created.

    OPS$ORACLE@DB12>grant create session to syssa with admin option;

    Grant succeeded.

    OPS$ORACLE@DB12>grant create table to syssa with admin option;

    Grant succeeded.

    OPS$ORACLE@DB12>grant create user to syssa with admin option;

    Grant succeeded.

    OPS$ORACLE@DB12>grant alter user to syssa with admin option;

    Grant succeeded.

    OPS$ORACLE@DB12>grant create procedure to syssa;

    Grant succeeded.

    OPS$ORACLE@DB12>grant create tablespace to syssa;

    Grant succeeded.

    OPS$ORACLE@DB12>grant drop user to syssa;

    Grant succeeded.

    OPS$ORACLE@DB12>grant drop tablespace to syssa;

    Grant succeeded.

Note that the privileges that SYSSA will grant to the created schema must be granted with admin option.

### Creating SCHEMA_ADMIN package

The SCHEMA_ADMIN package implements the SAAS code with 2 self explanatory procedures: one to create schema and one to drop schema.

    OPS$ORACLE@DB12>connect syssa/syssa
    Connected.
    SYSSA@DB12>create or replace package schema_admin
    2  is
    3  procedure create_schema(p_name varchar2);
    4  procedure drop_schema(p_name varchar2);
    5  end;
    6  /

    Package created.

    SYSSA@DB12>
    SYSSA@DB12>show errors
    No errors.
    SYSSA@DB12>create or replace package body schema_admin is
    2  --
    3  procedure log(p_msg varchar2)
    4  is
    5  begin
    6    dbms_output.put_line(p_msg);
    7  end;
    8  --
    9  procedure create_schema(p_name varchar2) is
    10  l_stmt varchar2(250);
    11  l_tsn  varchar2(30);
    12  l_mh varchar2(40) := 'schema_admin.create_schema: ';
    13  begin
    14    log(l_mh || 'p_name=' || p_name || ': started.');
    15    if (upper(p_name) not like 'U%')
    16    then
    17     raise_application_error(-20000, 'Schema name must start with U .');
    18    end if;
    19    l_stmt := 'create user ' || p_name || ' identified by ' || p_name;
    20    log(l_mh || l_stmt);
    21    execute immediate l_stmt;
    22    l_stmt := 'grant create session to ' || p_name;
    23    log(l_mh || l_stmt);
    24    execute immediate l_stmt;
    25    l_stmt := 'grant create table to ' || p_name;
    26    log(l_mh || l_stmt);
    27    execute immediate l_stmt;
    28    l_tsn := 'ts_' || p_name;
    29    l_stmt := 'create tablespace ' || l_tsn;
    30    log(l_mh || l_stmt);
    31    execute immediate l_stmt;
    32    l_stmt := 'alter user ' || p_name || ' default tablespace ' || l_tsn || ' quota unlimited on ' || l_tsn;
    33    log(l_mh || l_stmt);
    34    execute immediate l_stmt;
    35    log(l_mh || 'p_name=' || p_name || ': ended.');
    36  end ;
    37  --
    38  procedure drop_schema(p_name varchar2) is
    39  l_stmt varchar2(250);
    40  l_tsn varchar2(30);
    41  l_mh varchar2(40) := ' schema_admin.drop_schema: ';
    42  begin
    43    log(l_mh || 'p_name=' || p_name || ': started.');
    44    if (upper(p_name) not like 'U%')
    45    then
    46     raise_application_error(-20000, 'Schema name must start with U .');
    47    end if;
    48    l_stmt := 'drop user ' || p_name || ' cascade';
    49    log(l_mh || l_stmt);
    50    execute immediate l_stmt;
    51    l_tsn := 'ts_' || p_name;
    52    l_stmt := 'drop tablespace ' || l_tsn;
    53    log(l_mh || l_stmt);
    54    execute immediate l_stmt;
    55    log(l_mh || 'p_name=' || p_name || ': ended.');
    56  end;
    57  --
    58  end;
    59  /

    Package body created.

    SYSSA@DB12>show errors
    No errors.

The log procedure implements some code instrumentation with DBMS_OUTPUT package to check what SQL statements are run.

### Creating the SADM account

    OPS$ORACLE@DB12>create user sadm identified by sadm;

    User created.

    OPS$ORACLE@DB12>grant create session to sadm;

    Grant succeeded.

Grant to SADM account the privilege to execute the SAAS package

    OPS$ORACLE@DB12>connect syssa/syssa
    Connected.
    SYSSA@DB12>grant execute on syssa.schema_admin to sadm;

    Grant succeeded.

    SYSSA@DB12>

### Testing

    SADM@DB12>set serveroutput on
    SADM@DB12>set linesize 130
    SADM@DB12>exec syssa.schema_admin.create_schema('uappli01');
    schema_admin.create_schema: p_name=uappli01: started.
    schema_admin.create_schema: create user uappli01 identified by uappli01
    schema_admin.create_schema: grant create session to uappli01
    schema_admin.create_schema: grant create table to uappli01
    schema_admin.create_schema: create tablespace ts_uappli01
    schema_admin.create_schema: alter user uappli01 default tablespace ts_uappli01 quota unlimited on ts_uappli01
    schema_admin.create_schema: p_name=uappli01: ended.

    PL/SQL procedure successfully completed.

    SADM@DB12>--
    SADM@DB12>connect uappli01/uappli01;
    Connected.
    UAPPLI01@DB12>create table t(x varchar2(30));

    Table created.

    UAPPLI01@DB12>insert into t values('OK');

    1 row created.

    UAPPLI01@DB12>commit;

    Commit complete.

    UAPPLI01@DB12>column segment_name format a15
    UAPPLI01@DB12>column tablespace_name format a20
    UAPPLI01@DB12>select segment_name, tablespace_name from user_segments;

    SEGMENT_NAME    TABLESPACE_NAME
    --------------- --------------------
    T               TS_UAPPLI01

    UAPPLI01@DB12>--
    UAPPLI01@DB12>connect sadm/sadm
    Connected.
    SADM@DB12>set serveroutput on
    SADM@DB12>set linesize 130
    SADM@DB12>exec syssa.schema_admin.drop_schema('uappli01');
    schema_admin.drop_schema: p_name=uappli01: started.
    schema_admin.drop_schema: drop user uappli01 cascade
    schema_admin.drop_schema: drop tablespace ts_uappli01
    schema_admin.drop_schema: p_name=uappli01: ended.

    PL/SQL procedure successfully completed.

    SADM@DB12>

## Conclusion

This simple example has showed how to use PL/SQL definer rights feature to implement a very simple schema as a service without compromising database security.

This sample example is only a starting point that should be adapted to specific needs.

