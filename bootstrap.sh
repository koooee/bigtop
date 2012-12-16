#!/bin/bash -e
# Script to bootstrap a dev environment for Apache BigTop

APACHE_FORREST=http://archive.apache.org/dist/forrest/0.8/apache-forrest-0.8.tar.gz
MAVEN=http://mirror.reverse.net/pub/apache/maven/maven-3/3.0.4/binaries/apache-maven-3.0.4-bin.tar.gz
PROTOBUF=http://protobuf.googlecode.com/files/protobuf-2.4.1.tar.gz
ANT=http://apache.mirrors.lucidnetworks.net//ant/binaries/apache-ant-1.8.4-bin.tar.gz
REAL_USER=$(who am i | cut -d" " -f1)
PROFILE=~/bigtop-env.sh
NEW_PATH=$PATH


# Check if we have super powers
if [ "$(id -u)" != "0" ]; then
    echo "Run this script as root or sudo";
    exit;
fi

function install_apache_forrest () {
    
    # Download it
    pushd /opt
    wget -O - $1 | tar -xz
    chown -R $REAL_USER apache-forrest-*
    pushd apache-forrest-*
    

    # Set up environment
    echo -e "\nexport FORREST_HOME=$PWD" >> $PROFILE
    ln -s $PWD/bin/forrest /usr/bin/forrest
    
    # Build it
    pushd main
    ./build.sh
    dirs -c
}

function install_maven () {
    
    # Download it
    pushd /opt
    wget -O - $1 | tar -xz
    chown -R $REAL_USER apache-maven*
    pushd apache-maven*

    # Setup Environment
    ln -s $PWD/bin/mvn /usr/bin/mvn

    # No need to build since we are downloading the binary
    dirs -c

}

function install_protobuf () {

    # Download it
    pushd /opt
    wget -O - $1 | tar -xz
    chown -R $REAL_USER protobuf*
    pushd protobuf*

    # Configure and install it
    ./configure && make -j $(cat /proc/cpuinfo | grep -c processor) && make install
    
    dirs -c
}

# Solr Requres Ant1.8 and yum only has 1.7
function install_ant () {
    # Download it
    pushd /opt
    wget -O - $1 | tar -xz
    chown -R $REAL_USER apache-ant*
    pushd apache-ant*

    # Setup Environment
    ln -s $PWD/bin/ant /usr/bin/ant

    dirs -c
}

# Poorly attempt to determine the distribution
DISTRO=$(cat /proc/version | sed -e 's/ //g' | tr '[:upper:]' '[:lower:]' | egrep -o "redhat|centos|ubuntu|debian|suse" | head -n1)
case $DISTRO in
    centos)
	;&
    redhat)
    yum -y install git java-1.6.0-openjdk-devel java-1.6.0-openjdk-devel subversion gcc gcc-c++ make cmake javacc fuse fuse-devel lzo-devel sharutils rpm-build automake libtool redhat-rpm-config openssl-devel zlib-devel python-devel libxml2-devel libxslt-devel cyrus-sasl-devel sqlite-devel mysql-devel openldap-devel createrepo asciidoc xmlto python-setuptools
    install_apache_forrest $APACHE_FORREST
    install_maven $MAVEN
    install_protobuf $PROTOBUF
    install_ant $ANT;;
    ubuntu)
	echo "ubuntu is not yet supported.";;
    debian)
	echo "debian is not yest supported";;
    suse)
	echo "suse is not yet supported";;
    *)
	echo "Couldn't determine your distribution."
esac

echo "Run This Command: source $PROFILE"
echo "Then Run This Command: ./check-env.sh"
