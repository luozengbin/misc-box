#!/bin/sh

printf "Please Input Java PID First: "
read PID

print_gcstat () {
  jstat -gc $1 | tail -1 | awk                                                                      \
     '{                                                                                             \
         printf "---------------------------------------------\n";                                  \
         printf "S0  領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $1/1024, $3/1024, ($3/$1 * 100);    \
         printf "S1  領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $2/1024, $4/1024, ($4/$2 * 100);    \
         printf "Eden領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $5/1024, $6/1024, ($6/$5 * 100);    \
         printf "Old 領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $8/1024, $7/1024, ($8/$7 * 100);    \
         printf "Perm領域 | %7.2f / %7.2f (MB)  | %5.2f%% \n" , $10/1024, $9/1024, ($10/$9 * 100);  \
         printf "---------------------------------------------\n";                                  \
         printf "YGC 回数 | %7d\n" , $11;                                                           \
         printf "YGC 時間 | %7.2f (S)\n" , $12;                                                     \
         printf "FGC 回数 | %7d\n" , $13;                                                           \
         printf "FGC 時間 | %7.2f (S)\n" , $14;                                                     \
         printf "---------------------------------------------\n";                                  \
     }'    
}

if [ ! -z "${PID}" ]; then
    echo ">>> Full GC実施前のメモリ容量 <<<"
    print_gcstat ${PID}
    echo "`which jcmd` ${PID} GC.run ..."
    jcmd ${PID} GC.run
    echo ">>> Full GC実施のメモリ容量 <<<"
    print_gcstat ${PID}
fi
