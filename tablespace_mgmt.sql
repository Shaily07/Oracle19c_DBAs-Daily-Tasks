
--Chcek tablespace size and datafiles of individual Tablespace 
set linesize 100 pages 100 trimspool on numwidth 14 
col tablespace_name format a25
SELECT  tablespace_name,
file_name,  
round(bytes / 1024 / 1024 /1024,2)  AS "Current_size_GB"
FROM dba_data_files
WHERE tablespace_name = 'SYSTEM';

--Current size 16GB; 

ALTER DATABASE DATAFILE '+DG_DATA/PEDS/DATAFILE/stage_sel_data.452.1123010927' RESIZE 28G;
ALTER DATABASE DATAFILE '+DG_DATA/PEDS/DATAFILE/stage_sel_data.452.1123010927' AUTOEXTEND ON MAXSIZE 32G;
ALTER DATABASE DATAFILE '+DG_DATA/PEDS/DATAFILE/stage_sel_data.452.1123010927' AUTOEXTEND ON MAXSIZE 30G;
--ALTER DATABASE DATAFILE '+DG_SSPRDDB_DATA/SSPRDCDB/3C6FA28F04411F80E05355311F0A6A38/DATAFILE/caps_data.367.1144517541' RESIZE 20G;
=================================
QUERY TO CHECK FRA AREAS : 
==================================
set linesize 500
col NAME for a50
select name, ROUND(SPACE_LIMIT/1024/1024/1024,2) "Allocated Space(GB)", 
round(SPACE_USED/1024/1024/1024,2) "Used Space(GB)",
round(SPACE_RECLAIMABLE/1024/1024/1024,2) "SPACE_RECLAIMABLE (GB)" ,
(select round(ESTIMATED_FLASHBACK_SIZE/1024/1024/1024,2) 
from V$FLASHBACK_DATABASE_LOG) "Estimated Space (GB)"
from V$RECOVERY_FILE_DEST;

==================================
CALCULATE MAX SIZE 
==================================

SELECT TABLESPACE_NAME, MAX_USED_PERCENT
FROM (
select tbl2.TABLESPACE_NAME, ROUND((tbl2."TOTAL_SIZE_MB" - tbl3."FREE_SIZE_MB"),2) "USED MB", ROUND(((tbl2."TOTAL_SIZE_MB" - tbl3."FREE_SIZE_MB")/TBSPC_MAXSIZE_MB)*100,2) MAX_USED_PERCENT from
        (select TABLESPACE_NAME,SUM(BYTES)/1024/1024  TOTAL_SIZE_MB,SUM(DECODE(MAXBYTES,0,BYTES,MAXBYTES))/1024/1024 TBSPC_MAXSIZE_MB from dba_data_files group by TABLESPACE_NAME)tbl2,
        (select TABLESPACE_NAME,SUM(BYTES)/1024/1024  FREE_SIZE_MB from dba_free_space group by TABLESPACE_NAME) tbl3
         where tbl2.TABLESPACE_NAME=tbl3.TABLESPACE_NAME
) WHERE MAX_USED_PERCENT > 80;


set pages 999
set lines 400
Tablespace queries by percetage wise orderded. 
SELECT df.tablespace_name tablespace_name,
 max(df.autoextensible) auto_ext,
 round(df.maxbytes / (1024 * 1024*1024), 2) max_ts_size_gb,
 round((df.bytes - sum(fs.bytes)) / (df.maxbytes) * 100, 2) max_ts_pct_used,
 round(df.bytes / (1024 * 1024*1024), 1) curr_ts_size,
 round((df.bytes - sum(fs.bytes)) / (1024 * 1024 *1024), 2) used_ts_size,
 round((df.bytes-sum(fs.bytes)) * 100 / df.bytes, 2) ts_pct_used,
 round(sum(fs.bytes) / (1024 * 1024*1024), 2) free_ts_size,
 nvl(round(sum(fs.bytes) * 100 / df.bytes), 2) ts_pct_free
FROM dba_free_space fs,
 (select tablespace_name,
 sum(bytes) bytes,
 sum(decode(maxbytes, 0, bytes, maxbytes)) maxbytes,
 max(autoextensible) autoextensible
 from dba_data_files
 group by tablespace_name) df
WHERE fs.tablespace_name (+) = df.tablespace_name
GROUP BY df.tablespace_name, df.bytes, df.maxbytes
UNION ALL
SELECT df.tablespace_name tablespace_name,
 max(df.autoextensible) auto_ext,
 round(df.maxbytes / (1024 * 1024 *1024 *1024), 2) max_ts_size,
 round((df.bytes - sum(fs.bytes)) / (df.maxbytes) * 100, 2) max_ts_pct_used,
 round(df.bytes / (1024 * 1024), 2) curr_ts_size,
 round((df.bytes - sum(fs.bytes)) / (1024 * 1024), 2) used_ts_size,
 round((df.bytes-sum(fs.bytes)) * 100 / df.bytes, 2) ts_pct_used,
 round(sum(fs.bytes) / (1024 * 1024), 2) free_ts_size,
 nvl(round(sum(fs.bytes) * 100 / df.bytes), 2) ts_pct_free
FROM (select tablespace_name, bytes_used bytes
 from V$temp_space_header
 group by tablespace_name, bytes_free, bytes_used) fs,
 (select tablespace_name,
 sum(bytes) bytes,
 sum(decode(maxbytes, 0, bytes, maxbytes)) maxbytes,
 max(autoextensible) autoextensible
 from dba_temp_files
 group by tablespace_name) df
WHERE fs.tablespace_name (+) = df.tablespace_name
GROUP BY df.tablespace_name, df.bytes, df.maxbytes
ORDER BY 4 DESC;

---TABLESPACE QUERY IN FREE SPACE ORDERED : 

set pages 100
set lines 100
SELECT d.status "Status",
  d.tablespace_name "Name",
  TO_CHAR(NVL(a.bytes / 1024 / 1024, 0),'99999990D900') "Size (M)",
  TO_CHAR(NVL(NVL(f.bytes, 0), 0)/1024/1024 ,'99999990D900') "Free (MB)",
  TO_CHAR(NVL((NVL(f.bytes, 0)) / a.bytes * 100, 0), '990D00') "Free %"
 FROM sys.dba_tablespaces d,
  (select tablespace_name, sum(bytes) bytes from dba_data_files group by tablespace_name) a,
  (select tablespace_name, sum(bytes) bytes from dba_free_space group by tablespace_name) f
  WHERE d.tablespace_name = a.tablespace_name(+)
  AND d.tablespace_name = f.tablespace_name(+)
  AND NOT (d.extent_management like 'LOCAL'  AND d.contents like 'TEMPORARY')
 order by "Free %";



 Troubleshooting Guide - 'Unable to Extend / Create' Errors (Doc ID 1025288.6)
ALTER TABLESPACE ISIS_DATA ADD DATAFILE '+DG_SISDEV_SIS_DATA' SIZE 1G AUTOEXTEND ON NEXT 100M MAXSIZE 30G;



RESIZE DATAFILE : 
-------------------------------------
--ALTER DATABASE DATAFILE '+DG_DATA/PEDS/DATAFILE/stage_sel_data.452.1123010927' RESIZE 24G;
--ALTER DATABASE DATAFILE '+DG_DATA/PEDS/DATAFILE/edsl_stage_data.431.1015247417' RESIZE 16G;
--ALTER TABLESPACE ISIS_DATA ADD DATAFILE '+DG_SISTST_SIS_DATA' SIZE 1G AUTOEXTEND ON NEXT 100M MAXSIZE 30G;
 --ALTER DATABASE DATAFILE '+DG_SISTST_SIS_DATA/SISTST/DATAFILE/isis_data.347.1133976163' AUTOEXTEND ON MAXSIZE 32G;
--ALTER DATABASE DATAFILE '+DG_SISTST_SIS_DATA/SISTST/DATAFILE/isis_data.349.1147721675' RESIZE 32G;
 --AUTOEXTEND ON MAXSIZE 32G;
-- -ALTER DATABASE DATAFILE  '+DG_ACEPRDDB_DATA/OCPRD/DATAFILE/sdr_tables_small.272.1093876483' RESIZE 5G;
-- Added below tablespaces in SISDEV as per refresh process -- (8-JAN-2024)
      ---+DG_SISDEV_SIS_DATA/SISDEV/DATAFILE/isis_data.404.1157747735
      ---+DG_SISDEV_SIS_DATA/SISDEV/DATAFILE/isis_data.405.1157747967
      ---+DG_SISDEV_SIS_DATA/SISDEV/DATAFILE/isis_data.406.1157748339
      --+DG_SISDEV_SIS_DATA/SISDEV/DATAFILE/isis_data.407.1157750033

-- Resize the Datafile in SISDEV for EDSL_SIS Owner as it's filled and user reported tablepsace related error. Rahul Sir advised me to add 500 MB space into tablespace. 
    ALTER DATABASE DATAFILE '+DG_SISDEV_SIS_DATA/SISDEV/DATAFILE/edsl_sis_data.409.1160404515' RESIZE 1G;
    -- Added one 1GB additional in the tablespace. 
    ALTER DATABASE DATAFILE '+DG_SISDEV_SIS_DATA/SISDEV/DATAFILE/edsl_sis_data.409.1160404515' RESIZE 2G;

ASM MANAGED TABLESPACE SIZE MANAGEMENT
-------------------------------------


set pages 999
set lines 400
col FILE_NAME format a75
select d.TABLESPACE_NAME, d.FILE_NAME, d.BYTES/1024/1024 SIZE_MB, d.AUTOEXTENSIBLE, d.MAXBYTES/1024/1024 MAXSIZE_MB, d.INCREMENT_BY*(v.BLOCK_SIZE/1024)/1024 INCREMENT_BY_MB
from dba_data_files d,
 v$datafile v
where d.FILE_ID = v.FILE# and tablespace_name='ISIS_DATA' 
order by d.TABLESPACE_NAME, d.FILE_NAME;


ADD Datafile in ASM Managed instance_name
-----------------------------------------------

ALTER TABLESPACE ISIS_DATA ADD DATAFILE '+DG_SISTST_SIS_DATA' SIZE 1G AUTOEXTEND ON NEXT 100M MAXSIZE 30G;

-- added tablesspace in SSPRD on 15-FEB-2024 approved by Rahul Sir (AAPS_DATA)

ALTER TABLESPACE AAPS_DATA ADD DATAFILE '+DG_SSPRDDB_DATA' SIZE 1G AUTOEXTEND ON NEXT 100M MAXSIZE 30G;


SQL> select name,open_mode from v$database;

NAME      OPEN_MODE
--------- --------------------
SSPRDCDB  READ WRITE

SQL> ALTER TABLESPACE AAPS_DATA ADD DATAFILE '+DG_SSPRDDB_DATA' SIZE 1G AUTOEXTEND ON NEXT 100M MAXSIZE 30G;

Tablespace altered.



SEGMENT LEVEL TROUBLESHOOTING STEPS: 
------------------------------------------------
set pages 100
set lines 100
SELECT d.status "Status",
  d.tablespace_name "Name",
  TO_CHAR(NVL(a.bytes / 1024 / 1024 / 1024, 0),'99999990D900') "Size (G)",
  TO_CHAR(NVL(NVL(f.bytes, 0), 0)/1024/1024/1024 ,'99999990D900') "Free (G)",
  TO_CHAR(NVL((NVL(f.bytes, 0)) / a.bytes * 100, 0), '990D00') "Free %"
 FROM sys.dba_tablespaces d,
  (select tablespace_name, sum(bytes) bytes from dba_data_files group by tablespace_name) a,
  (select tablespace_name, sum(bytes) bytes from dba_free_space group by tablespace_name) f
  WHERE d.tablespace_name = a.tablespace_name(+)
  AND d.tablespace_name = f.tablespace_name(+)
  AND NOT (d.extent_management like 'LOCAL'  AND d.contents like 'TEMPORARY')
 order by "Free %";
 
 SELECT * FROM
(select 
 SEGMENT_NAME, 
 SEGMENT_TYPE, 
 BYTES/1024/1024/1024 GB, 
 TABLESPACE_NAME 
from 
 dba_segments where tablespace_name='ISIS_DATA'
order by 3 desc ) WHERE
ROWNUM <= 10;
select * from dba_objects where object_name='SYS_LOB0003901604C00008$$';

set pages 100
set lines 100
 col segment_name format a25;
select segment_name, segment_type, tablespace_name,BYTES/1024/1024/1024 GB 
from dba_segments where segment_name in ('SYS_LOB0003899776C00016$$','SYS_LOB0003901604C00008$$','SYS_LOB0003898534C00003$$') and owner ='FCPS_ISIS_TST';

set pages 100
set lines 100
 col TABLE_NAME format a25;
 col COLUMN_NAME format a25;
sELECT TABLE_NAME, COLUMN_NAME  FROM DBA_LOBS WHERE OWNER = 'FCPS_ISIS_TST' AND  SEGMENT_NAME in ('SYS_LOB0003899776C00016$$','SYS_LOB0003901604C00008$$','SYS_LOB0003898534C00003$$');

select * from dba_objects where object_name like '%REV_SM_MESSAGE%' and owner='FCPS_ISIS_TST';
SELECT max(bytes/1024/1024/1024) FROM dba_free_space WHERE tablespace_name = 'ISIS_DATA';




SELECT NEXT_EXTENT, PCT_INCREASE
FROM DBA_SEGMENTS
WHERE SEGMENT_NAME = 'SYS_LOB0003899776C00016$$'
AND SEGMENT_TYPE = 'LOBSEGMENT'
AND OWNER = 'FCPS_ISIS_TST'
AND TABLESPACE_NAME = 'ISIS_DATA';




SELECT EXTENT_MANAGEMENT FROM DBA_TABLESPACES WHERE TABLESPACE_NAME = 'ISIS_DATA';


 SELECT name, free_mb/1024 Free_G, total_mb/1024 Total_G, round(free_mb/total_mb*100,2) as avail_percent FROM v$asm_diskgroup;



--Query to check the ASM disk group free space ; 

select a.name DiskGroup, b.disk_number Disk#, b.name DiskName, b.os_mb,b.total_mb/1024, b.free_mb/1024, b.path, b.header_status
from v$asm_disk b, v$asm_diskgroup a
where a.group_number (+) =b.group_number
order by b.group_number, b.disk_number, b.name
/

--##Calculate the current total size of Tablspace : 
-------------------------------------------
SELECT tablespace_name, round(SUM(bytes) / 1024 / 1024 / 1024) AS "Size (GB)"
FROM dba_data_files
GROUP BY tablespace_name;
