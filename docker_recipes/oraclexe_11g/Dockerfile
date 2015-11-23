FROM oraclelinux:6
MAINTAINER Akira Wakana<jalen.cn@gmail.com>

#---------------
# 基本パッケージのインストール
#---------------
RUN yum install -y glibc-common sudo wget which unzip tree nano acl

#---------------
# 日本語対応
#---------------
RUN yum -y groupinstall "Japanese Support"
RUN localedef -f UTF-8 -i ja_JP ja_JP.utf8
RUN \cp -rf /usr/share/zoneinfo/Japan /etc/localtime
RUN echo "LANG=\"ja_JP.UTF-8\"" >  /etc/sysconfig/i18n
RUN echo "ZONE=\"Asia/Tokyo\""  >  /etc/sysconfig/clock
RUN echo "UTC=True"             >> /etc/sysconfig/clock
ENV LANG ja_JP.UTF-8

#---------------
# Oracle Express Edition 11gR2
#---------------
RUN yum install -y oracle-rdbms-server-11gR2-preinstall

#---------------
# rlwrap for sqlplus
#---------------
WORKDIR /tmp
wget http://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
yum install -y rlwrap

ADD bin/init.sh /
RUN chmod +x /init.sh

CMD /mnt/bin/setupdb.sh
