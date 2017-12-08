#! /bin/ksh
#-- 
#-- 


if [ $# -eq 0 ] 
then
  echo
 echo  Usage: $0 "BPFRH2"
  echo
  exit 1
fi

arg1=$1
len=`echo "${arg1}\c" |wc -c`

if [ $len -gt 8 ]
then
  echo
  echo Invalid DB name "$arg1" : Must be 8 characters or less.
  echo DB creation would fail.  Exiting...
  echo
  exit 1
fi

P8DBNAME=$1
P8DBDIR=/db2data/${P8DBNAME}
DB2USER=db2user

mkdir -p ${P8DBDIR}

#-- Close any outstanding connection
db2 CONNECT RESET

db2 +p -t <<End_of_file
CREATE DATABASE $P8DBNAME
ON $P8DBDIR
USING CODESET UTF-8 TERRITORY US
COLLATE USING SYSTEM
CATALOG TABLESPACE MANAGED BY SYSTEM
 USING ('$P8DBDIR/sys')
TEMPORARY TABLESPACE
    MANAGED BY SYSTEM
 USING ('$P8DBDIR/systmp')
USER TABLESPACE
    MANAGED BY SYSTEM
 USING ('$P8DBDIR/usr')
;

-- Increase the application heap size
UPDATE DATABASE CONFIGURATION FOR ${P8DBNAME} USING APPLHEAPSZ 2560;
UPDATE DATABASE CONFIGURATION FOR ${P8DBNAME} USING STMTHEAP 8192;

End_of_file

sleep 5

db2 +p -t <<End_of_file
-- Connect
CONNECT TO $P8DBNAME;
-- Drop unnecessary default tablespaces
-- Try not dropping
DROP TABLESPACE USERSPACE1;
-- REVOKE USE OF TABLESPACE USERSPACE1 FROM PUBLIC;
-- Create default buffer pool size
CREATE Bufferpool FNCEDEFAULTBP IMMEDIATE  SIZE -1 PAGESIZE 32 K;

End_of_file

db2 CONNECT RESET
db2 deactivate database $P8DBNAME
sleep 5

db2 CONNECT TO $P8DBNAME



db2 +p -t <<End_of_file
-- Create tablespaces
CREATE REGULAR
   TABLESPACE ${P8DBNAME}
   PAGESIZE 32 K
   MANAGED BY DATABASE
   USING (FILE '$P8DBDIR/usr2/${P8DBNAME}_tbs.dbf' 128M)
   BUFFERPOOL "FNCEDEFAULTBP";

CREATE USER TEMPORARY
   TABLESPACE USERTEMP1
   PAGESIZE 32 K
   MANAGED BY DATABASE
   USING (FILE '$P8DBDIR/usrtmp/${P8DBNAME}_tmp.dbf' 50M)
   BUFFERPOOL "FNCEDEFAULTBP";

CREATE SYSTEM TEMPORARY
   TABLESPACE TEMPSYS1
   PAGESIZE 32 K
   MANAGED BY SYSTEM
   USING ('$P8DBDIR/systmp2' )
   BUFFERPOOL "FNCEDEFAULTBP";

End_of_file

#db2 REVOKE USE OF TABLESPACE USERSPACE1 FROM $DB2USER;

#-- Grant USER access to tablespaces
echo Grant user $DB2USER access to tablespace

db2 GRANT CREATETAB,CONNECT ON DATABASE  TO user $DB2USER;
db2 GRANT USE OF TABLESPACE ${P8DBNAME}_TBS TO user $DB2USER;
db2 GRANT USE OF TABLESPACE USERTEMP1 TO user $DB2USER;

#-- Optionally, grant GROUP access to tablespaces
#-- GRANT CREATETAB,CONNECT ON DATABASE  TO GROUP DB2USERS;
#-- GRANT USE OF TABLESPACE USERTEMP1 TO GROUP DB2USERS;
#-- GRANT USE OF TABLESPACE USERSPACE1 TO GROUP DB2USERS;

#-- Close connection
db2 CONNECT RESET
db2 activate database $P8DBNAME
