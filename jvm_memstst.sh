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

print_gcstat () {
    _PID=$1
    java_home="`detected_javahome ${_PID}`"
    jstat_path="${java_home}/jstat"
    if [ -e "${jstat_path}" ]; then
        java_ver=`java_version "${java_home}"`
        if [ ${java_ver} -gt 7 ]; then
            "${jstat_path}" -gc ${_PID} | tail -1 | awk                                                    \
            '{                                                                                             \
                printf "---------------------------------------------\n";                                  \
                printf "S0  領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $1/1024, $3/1024, ($3/$1 * 100);    \
                printf "S1  領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $2/1024, $4/1024, ($4/$2 * 100);    \
                printf "Eden領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $5/1024, $6/1024, ($6/$5 * 100);    \
                printf "Old 領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $8/1024, $7/1024, ($8/$7 * 100);    \
                printf "Meta領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $10/1024, $9/1024, ($10/$9 * 100);  \
                printf "CCPS領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $12/1024, $1/1024, ($12/$11 * 100); \
                printf "---------------------------------------------\n";                                  \
                printf "YGC 回数 | %7d 回\n" , $13;                                                        \
                printf "YGC 時間 | %7.2f 秒\n" , $14;                                                      \
                printf "FGC 回数 | %7d 回\n" , $15;                                                        \
                printf "FGC 時間 | %7.2f 秒\n" , $16;                                                      \
                printf "---------------------------------------------\n";                                  \
            }'
        else
            "${jstat_path}" -gc $1 | tail -1 | awk                                                         \
            '{                                                                                             \
                printf "---------------------------------------------\n";                                  \
                printf "S0  領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $1/1024, $3/1024, ($3/$1 * 100);    \
                printf "S1  領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $2/1024, $4/1024, ($4/$2 * 100);    \
                printf "Eden領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $5/1024, $6/1024, ($6/$5 * 100);    \
                printf "Old 領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $8/1024, $7/1024, ($8/$7 * 100);    \
                printf "Perm領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $10/1024, $9/1024, ($10/$9 * 100);  \
                printf "---------------------------------------------\n";                                  \
                printf "YGC 回数 | %7d 回\n" , $11;                                                        \
                printf "YGC 時間 | %7.2f 秒\n" , $12;                                                      \
                printf "FGC 回数 | %7d 回\n" , $13;                                                        \
                printf "FGC 時間 | %7.2f 秒\n" , $14;                                                      \
                printf "---------------------------------------------\n";                                  \
            }'
        fi
    fi
}

PID=$1

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
    print_gcstat ${PID}
}

