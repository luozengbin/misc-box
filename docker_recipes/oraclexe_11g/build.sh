#!/bin/bash

readonly BASE_DIR="`dirname $(readlink -f "$0")`"
readonly CONF_FILE="${BASE_DIR}/conf/`basename $0 .sh`.conf"

export PATH=${BASE_DIR}/bin:$PATH

source ${CONF_FILE}

# download assets files
export DL_URL
echo -n "Oracle Account: " && read DL_USER && export DL_USER
echo -n "Password: " && read -s DL_PASS && export DL_PASS
export DL_FILE="${BASE_DIR}/assets/${DL_URL##*/}"

echo ""

wget_oraclexe.sh
(cd ${BASE_DIR}/assets; unzip oracle-xe-11.2.0-1.0.x86_64.rpm.zip)
docker rmi local/oraclexe11g >/dev/null 2>&1 
docker build -t local/oraclexe11g ${BASE_DIR}

docker rm oraclexe11g >/dev/null 2>&1 
docker run -it --privileged --name oraclexe11g --hostname oraclexe11g -v ${BASE_DIR}:/mnt local/oraclexe11g
docker commit oraclexe11g local/oraclexe11g
docker rm oraclexe11g
rm -rf ${BASE_DIR}/assets/Disk1
