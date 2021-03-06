#!/bin/sh
###########################################################################
# jvm_stacksize.sh - take jvm stack size snapshot
#
#    Authors: Akira Wakana <jalen.cn@gmail.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, version 3 of the License.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Usage:
#    $jvm_stacksize.sh <JVM ProcessID>
###########################################################################

print_stacksize()
{
    rm -rf ${tmpdir}/stacksize.txt
    printf "[ PID ]\t[StackSize(kB)]\t[GuardPage(kB)]\t[UsedSize(kB)]\t[Thread Name]\n"
    ps h -L --format=lwp ${PID} | grep -v "${PID}" | while read pid
    do
        # スレッドID
        pid_hex=`printf '%#x\n' $pid`

        # スレッド名を切り出す
        threadinfo=`cat ${threadtdump} | fgrep " nid=${pid_hex} " | sed -e "s/^\"\(.*\)\".*nid=\(0x[0-9|a-z]*\).*$/\2,\1/"`
        if [ "${threadinfo}" == "" ]; then
            jstack ${PID} > ${threadtdump}
            threadinfo=`cat ${threadtdump} | fgrep " nid=${pid_hex} " | sed -e "s/^\"\(.*\)\".*nid=\(0x[0-9|a-z]*\).*$/\2,\1/"`
        fi
        thread_name=`echo "${threadinfo}" | awk -F"," '{print $2}'`

        # /proc/<pid>/smaps ファイルからスタックサイズ、ガードページサイズを取得する
        # 次のsmaps出力サンプルに★コメントの部分は取得詳細ロジックとなります。
        # 
        #    7ff751076000-7ff751079000 ---p 00000000 00:00 0
        #    Size:                 12 kB    ★説明: StackRedPages(4Kb) + StackYellowPages(8Kb) = 12Kb
        #    Rss:                   0 kB
        #    Pss:                   0 kB
        #    Shared_Clean:          0 kB
        #    Shared_Dirty:          0 kB
        #    Private_Clean:         0 kB
        #    Private_Dirty:         0 kB
        #    Referenced:            0 kB
        #    Anonymous:             0 kB
        #    AnonHugePages:         0 kB
        #    Swap:                  0 kB
        #    KernelPageSize:        4 kB
        #    MMUPageSize:           4 kB
        #    Locked:                0 kB
        #    VmFlags: mr mw me ac          ★説明:書き込み不可
        #    7ff751079000-7ff751177000 rw-p 00000000 00:00 0                          [stack:21275]
        #    Size:               1016 kB   ★説明: ここからNormal Stackページ
        #    Rss:                 108 kB
        #    Pss:                 108 kB
        #    Shared_Clean:          0 kB
        #    Shared_Dirty:          0 kB
        #    Private_Clean:         0 kB
        #    Private_Dirty:       108 kB
        #    Referenced:          108 kB
        #    Anonymous:           108 kB
        #    AnonHugePages:         0 kB
        #    Swap:                  0 kB
        #    KernelPageSize:        4 kB
        #    MMUPageSize:           4 kB
        #    Locked:                0 kB
        #    VmFlags: rd wr mr mw me ac
        
        guard_page=`cat /proc/${PID}/smaps | grep -B16 "stack:${pid}" | grep -e "^Size:" | awk '{print $2}'`
        stack_page=`cat /proc/${PID}/smaps | grep -A15 "stack:${pid}" | grep -e "^Size:" | awk '{print $2}'`
        used_size=`cat /proc/${PID}/smaps  | grep -A15 "stack:${pid}" | grep -e "^Rss:" | awk '{print $2}'`
        stack_size=`expr ${guard_page} + ${stack_page}`
        printf "%7d\t%15s\t%15s\t%14s\t%s\n" "${pid}" "${stack_size}" "${guard_page}" "${used_size}" "${thread_name}"
    done > ${tmpdir}/stacksize.txt
    sort -r -k4,4 ${tmpdir}/stacksize.txt
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

ps ${PID} | grep [j]ava > /dev/null || {
    echo "-----------------------------------------------------------------------"
    ps -ef  | grep [j]ava
    echo "-----------------------------------------------------------------------"
    echo -n "please input the java process id: "
    read PID
}

export PID

export tmpdir=`mktemp -d`

export threadtdump=${tmpdir}/${PID}.tdump

jstack ${PID} > ${threadtdump}

export -f print_stacksize

watch "bash -c print_stacksize"

rm -rf ${tmpdir}
