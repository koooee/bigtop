# Script to bootstrap a dev environment for Apache BigTop
# Script should be run via: source bootstrap.sh
APACHE_FORREST=http://archive.apache.org/dist/forrest/0.8/apache-forrest-0.8.tar.gz

if [ "$(id -u)" != "0" ]; then
    echo "Run this script as root or sudo";
    exit;
fi

function install_apache_forrest () {
    
    # Download it
    pushd /opt
    wget -O - $1 | tar -xz
    pushd apache-forrest-*

    # Set up environment
    if [ "$(grep -c FORREST_HOME /etc/bashrc)" -eq "0" ]; then
	echo "Adding forrest to profile"
	echo -e "\nexport FORREST_HOME=$PWD" >> /etc/bashrc
	echo -e "\nexport PATH=$PATH:$FORREST_HOME/bin" >> /etc/bashrc
	source /etc/bashrc
    fi
    
    # Build it
    pushd main
    ./build.sh
    dirs -c
}

# Poorly attempt to determine the distribution
DISTRO=$(cat /proc/version | sed -e 's/ //g' | tr '[:upper:]' '[:lower:]' | egrep -o "redhat|centos|ubuntu|debian|suse" | head -n1)
case $DISTRO in
    centos)
	;&
    redhat)
        yum -y install git java-1.6.0-openjdk-devel java-1.6.0-openjdk-devel maven subversion gcc gcc-c++ make fuse fuse-devel lzo-devel sharutils rpm-build automake libtool redhat-rpm-config openssl-devel
	install_apache_forrest $APACHE_FORREST;;
    ubuntu)
	echo "ubuntu";;
    debian)
	echo "debian";;
    suse)
	echo "suse";;
    *)
	echo "Couldn't determine your distribution."
esac

