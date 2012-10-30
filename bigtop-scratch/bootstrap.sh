#!/bin/bash -e

# Script to bootstrap a dev environment for Apache BigTop

if [ "$(id -u)" != "0" ]; then
    echo "Run this script as root or sudo";
    exit;
fi

function install_apache_forrest {
    
    # Download it
    pushd /opt
    wget -O - http://archive.apache.org/dist/forrest/0.8/apache-forrest-0.8.tar.gz | tar -xz
    pushd apache-forrest-*

    # Set up environment
    if [ "$(grep -c FORREST_HOME /etc/bashrc)" = 0]; then
	echo -e "\nexport FORREST_HOME=$PWD" >> /etc/bashrc
	echo -e "\nexport PATH=$PATH:$FORREST_HOME/bin" >> /etc/bashrc
    fi

    # Build it
    pushd main
    ./build.sh
    dirs -c
}

yum install git java-1.6.0-openjdk-devel java-1.6.0-openjdk-devel maven subversion gcc gcc-c++ make fuse
install_apache_forrest
exit;    

# Poorly attempt to determine the distribution
DISTRO=$(cat /proc/version | sed -e 's/ //g' | tr '[:upper:]' '[:lower:]' | egrep -o "redhat|centos|ubuntu|debian|suse" | head -n1)
exit
case $DISTRO in
    centos)
	;&
    redhat)
	yum install git java-1.6.0-openjdk-devel java-1.6.0-openjdk-devel maven subversion gcc gcc-c++ make fuse


    ubuntu)
	echo "ubuntu";;
    debian)
	echo "debian";;
    suse)
	echo "suse";;
    *)
	echo "Couldn't determine your distribution."
	exit;;
esac

exit
