#!/bin/bash

yum localinstall -y /mnt/assets/Disk1/oracle-xe-11.2.0-1.0.x86_64.rpm
sed -i -e "s|memory_target=|#memory_target=|g" /u01/app/oracle/product/11.2.0/xe/config/scripts/init.ora
sed -i -e "s|memory_target=|#memory_target=|g" /u01/app/oracle/product/11.2.0/xe/config/scripts/initXETemp.ora
/etc/init.d/oracle-xe configure responseFile=/mnt/conf/xe.rsp 2>&1 | tee -a /u01/XEsilentinstall.log

ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
ORACLE_USER_HOME=/home/oracle
echo "export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe"  >> ${ORACLE_USER_HOME}/.bashrc
echo "export ORACLE_SID=XE"                                  >> ${ORACLE_USER_HOME}/.bashrc
echo "export NLS_LANG=`$ORACLE_HOME/bin/nls_lang.sh`"        >> ${ORACLE_USER_HOME}/.bashrc
echo "export PATH=$ORACLE_HOME/bin:$PATH"                    >> ${ORACLE_USER_HOME}/.bashrc
echo "alias sqlplus='rlwrap sqlplus'"                        >> ${ORACLE_USER_HOME}/.bashrc

su - oracle -c "sqlplus -s /nolog" << _EOF
conn / as sysdba
COL HOST_NAME FOR A20
COL INSTANCE_NAME FOR A10
COL VERSION FOR A15
COL STATUS FOR A10
SELECT HOST_NAME, INSTANCE_NAME, VERSION, STATUS FROM V\$INSTANCE;
quit
_EOF

exit

