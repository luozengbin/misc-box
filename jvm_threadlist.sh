#!/bin/sh

detected_javahome()
{
    _PID=$1
    JAVA_PATH=$(readlink -f `ps -o cmd= ${_PID} | awk '{print $1}'`) || {
        echo "JAVA_HOME 特定出来ませんでした。"
        exit 1
    }
    echo "`dirname "${JAVA_PATH}"`" | sed -e "s|/jre/bin|/bin|g"
}

java_version()
{
    "${1}/java" -version 2>&1 | grep version | awk -F'"' '{print $2}' |  awk -F'.' '{print $2}'
}

finally_func() {
    RET=$?
    if [ -d ${tmpdir} ]; then
        rm -rf ${tmpdir}        
    fi
    exit ${RET}
}

trap finally_func EXIT
PID=$1
tmpdir=`mktemp -d`

ps ${PID} | grep [j]ava > /dev/null || {

    _PID=`ps -o uid=,pid=,cmd= -C java | head -1 | awk '{print $2}'`
    echo "---------------------------------------------"
    ps -o uid,pid,cmd -C java
    echo "---------------------------------------------"
    echo -n "Please input the java process id (${_PID}): "
    read PID
    if [ -z "${PID}" ]; then
        PID=${_PID}
    fi
}

ps ${PID} | grep [j]ava > /dev/null && {
    threadtdump=${tmpdir}/${PID}.tdump
    java_home="`detected_javahome ${_PID}`"
    jstack_path="${java_home}/jstack"
    if [ -e "${jstack_path}" ]; then
        "${jstack_path}" ${PID} > ${threadtdump}

            printf "[PID  ]\t[Thread Name]\n"
        ps h -L --format=lwp ${PID} | grep -v "${PID}" | while read tid
        do
            # スレッドID
            tid_hex=`printf '%#x\n' $tid`

            # スレッド名を切り出す
            threadinfo=`cat ${threadtdump} | fgrep " nid=${tid_hex} " | sed -e "s/^\"\(.*\)\".*nid=\(0x[0-9|a-z]*\).*$/\2,\1/"`
            thread_name=`echo "${threadinfo}" | awk -F"," '{print $2}'`
            printf "%6d\t%s\n" "${tid}" "${thread_name}"
        done | sort -k2,2
    fi
}

