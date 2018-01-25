#!/usr/bin/env bash


#title           :logstash.sh
#description     :Vagrant shell script install Zookeeper & Kafka
#author		     :Justin Jessup
#date            :11/22/2016
#version         :0.1
#usage		     :bash logstash.sh
#notes           :Executed via Vagrant => vagrant-kafka
#bash_version    :GNU bash, version 4.1.2(1)-release (x86_64-redhat-linux-gnu)
#License         :MIT
#==============================================================================


echo "Setting up nameservers..."
cat /dev/null > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

###########################
# ORACLE JAVA JDK 8 INSTALL
###########################

echo "Installing Oracle Java Development Kit"
JDK_VERSION="jdk-8u162-linux-x64"
JDK_RPM="$JDK_VERSION.rpm"

if [ ! -f /tmp/$JDK_RPM ]; then
    echo Downloading $JDK_RPM
    wget –quiet -O /tmp/$JDK_RPM --no-check-certificate --no-cookies --header \
    "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u162-b12/$JDK_RPM"
fi

echo "Disabling firewalld & selinux..."
/usr/bin/systemctl stop firewalld.service
/usr/bin/systemctl disable firewalld.service
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g ' /etc/sysconfig/selinux
setenforce permissive


echo "Installing JDK Version: $JDK_VERSION"
rpm -ivh /tmp/$JDK_RPM
echo "Completed installation JDK Version: $JDK_VERSION"

########################
# INSTALL EPEL
########################

rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

########################
# ZOOKEEPER INSTALL
########################

echo "Installing Zookeeper"
yum -y install git lsof wget make rpmdevtools bind-utils tcpdump vim-enhanced iftop
cd /opt
git clone https://github.com/AlienOneSecurityLLC/zookeeper-el7-rpm.git
cd /opt/zookeeper-el7-rpm
make rpm
cd x86_64
rpm -ivh zookeeper-*.rpm
echo "Setting unique zookeeper id..."
touch myid
str=$(hostname);last_char=${str: -1};cd /var/lib/zookeeper;echo $last_char > myid
sed -i 's/JVMFLAGS=/JVMFLAGS=\"-Xmx512m -Djute.maxbuffer=1000000000\"/g' /etc/sysconfig/zookeeper
echo "server.1=10.30.3.2:2888:3888" >> /etc/zookeeper/zoo.cfg
echo "server.2=10.30.3.3:2888:3888" >> /etc/zookeeper/zoo.cfg
echo "server.3=10.30.3.4:2888:3888" >> /etc/zookeeper/zoo.cfg
chown -R zookeeper:zookeeper /opt/zookeeper
sed -i '$ d' /etc/hosts
systemctl start zookeeper
sed -i 's/eforward        2181\/tcp                \# eforward/zookeeper        2181\/tcp                \# zookeeper/g' /etc/services
lsof -i TCP:2181 | grep LISTEN
echo "Completed installation of Zookeeper"

#######################
# INSTALL OpenSource Confluent Platform 2.11(Scala Version)
#######################

cp /vagrant/config/confluent.repo /etc/yum.repos.d
yum clean all
yum -y update
yum install confluent-platform-oss-2.11
cp /vagrant/config/confluent-*.service /etc/systemd/system
chmod 0644 /etc/systemd/system/confluent-*.service
systemctl daemon-reload
cd /etc/systemd/system;for i in $(ls confluent-*.service);do systemctl enable $i;done
echo "Setting unique kafka broker id..."
str=$(hostname)
last_char=${str: -1}
sed -i "s/broker.id\=0/broker.id=$last_char/g" /etc/kafka/server.properties
ip_address=$(ifconfig -a | grep 'inet ' | grep '30.3' | cut -d't' -f2 | awk '{print $1}')
sed -i "s/\#advertised.listeners=PLAINTEXT\:\/\/your.host.name:9092/advertised.listeners=PLAINTEXT\:\/\/$ip_address:9092/g" /etc/kafka/server.properties
mkdir -p /opt/kafka-logs-1
sed -i 's/log.dirs\=\/var\/lib\/kafka/log.dirs\=\/opt\/kafka-logs-1/g' /etc/kafka/server.properties
sed -i 's/\#delete.topic.enable\=true/delete.topic.enable\=true/g' /etc/kafka/server.properties
sed -i "s/num.partitions\=1/num.partitions\=3/g" /etc/kafka/server.properties
sed -i "s/zookeeper.connect\=localhost\:2181/zookeeper.connect\=localhost\:2181,10.30.3.2\:2181,10.30.3.3\:2181,10.30.3.4\:2181/g" /etc/kafka/server.properties
systemctl start zookeeper
systemctl start kafka
systemctl start schema-registry
systemctl start kafka-rest
sed -i "s/XmlIpcRegSvc    9092\/tcp                \# Xml-Ipc Server Reg/kafka    9092\/tcp                \# Kafka/g" /etc/services
lsof -i TCP:9092 | grep LISTEN
echo "Completed installation of OpenSource Confluent Platform 2.11(Scala Version)..."
