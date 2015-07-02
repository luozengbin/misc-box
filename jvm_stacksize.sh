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


PID=$1

ps ${PID} | grep [j]ava > /dev/null || {
    echo "-----------------------------------------------------------------------"
    ps -ef  | grep [j]ava
    echo "-----------------------------------------------------------------------"
    echo -n "please input the java process id: "
    read PID
}

printf "[ PID ]\t[StackSize(kB)]\t[GuardPage(kB)]\t[UsedSize(kB)]\t[Thread Name]\n"

# jstackの出力結果からスレッドIDと名前を抽出する
jstack ${PID} | grep nid | sed -e "s/^\"\(.*\)\".*nid=\(0x[0-9|a-z]*\).*$/\2,\1/" | sort | while read line
do
    # スレッドIDを切り出す
    pid_hex=`echo "${line}" | awk -F"," '{print $1}'`

    # スレッド名を切り出す
    thread_name=`echo "${line}" | awk -F"," '{print $2}'`

    # スレッドIDを10進数に変換
    pid=`printf '%d\n' ${pid_hex}`

    # /proc/<pid>/smaps ファイルからスタックサイズ、ガードページサイズを取得する
    guard_page=`cat /proc/${PID}/smaps | grep -B16 "stack:${pid}" | grep -e "^Size:" | awk '{print $2}'`
    stack_page=`cat /proc/${PID}/smaps | grep -A15 "stack:${pid}" | grep -e "^Size:" | awk '{print $2}'`
    used_size=`cat /proc/${PID}/smaps  | grep -A15 "stack:${pid}" | grep -e "^Rss:" | awk '{print $2}'`
    stack_size=`expr ${guard_page} + ${stack_page}`
    printf "%7d\t%15s\t%15s\t%14s\t%s\n" "${pid}" "${stack_size}" "${guard_page}" "${used_size}" "${thread_name}"
done
