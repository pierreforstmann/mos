-- You can try auditing with the right AUDIT_TRAIL parameter:

bas002> select * from v$version;

BANNER

Oracle Database 10g Enterprise Edition Release 10.2.0.2.0 - Prod
PL/SQL Release 10.2.0.2.0 - Production
CORE    10.2.0.2.0      Production
TNS for 32-bit Windows: Version 10.2.0.2.0 - Production
NLSRTL Version 10.2.0.2.0 - Production

bas002> show parameter audit_trail;

Parameter                      TYPE        Value

-----------
audit_trail                    string      DB, EXTENDED
bas002> audit create user;

Audit succeeded.

bas002> create user top identified by top007 default tablespace t;
create user top identified by top007 default tablespace t
*
ERROR at line 1:
ORA-00959: tablespace 'T' does not exist

bas002> select sql_text from dba_audit_trail where sql_text like '%create%user%'; SQL_TEXT

create user top identified by *******default tablespace t



