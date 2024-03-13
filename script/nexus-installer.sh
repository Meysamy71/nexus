#!/bin/bash

clear

# URL of the Nexus download page
URL="https://help.sonatype.com/en/download.html"
# Fetch the page content
CONTENT=`curl -s $URL`
# Extract the latest version number
LATEST_VERSION=`echo $CONTENT |  grep -oP 'https://download.sonatype.com/nexus/3/nexus-\S*-unix.tar.gz' | head -1 | grep -o 'nexus-\S*-unix.tar.gz' |grep -Po "\d+\.\d+\.\d+-?\d+"`
# Construct the download URL
DOWNLOAD_URL="https://download.sonatype.com/nexus/3/nexus-${LATEST_VERSION}-unix.tar.gz"


echo """
##############################################################################
##         Welcome To Nexus Repository Installer                            ##
##         Date            `date "+%F %T "`                             ##
##         Version         Nexus-installer-1.0.0                            ##
##         Nexus Version   $LATEST_VERSION                                        ##
##         Author          Meysam Yavarikhoo                                ##
##         Copyright       Copyright (c) 2024 https://github.com/Meysamy71  ##
##         License         GNU General Public License                       ##
##############################################################################"""

# Print Info Function
INFO(){
    echo "`date '+%F %T'` : INFO : ${*}"
}

# Print Warning Function

WARNING(){
    echo "`date '+%F %T'` : WARNING : ${*}"
}

# Print Error Function

ERROR(){
    echo "`date '+%F %T'` : ERROR :Failed ${*}"
}

# Print successful Function

SUCCESSFUL(){
    echo "`date '+%F %T'` : SUCCESSFUL : ${*}"
}

# Check Status code

CheckStatus(){
    if [ $? -eq 0 ]
    then
    SUCCESSFUL ${*}
    else
    ERROR ${*}
    fi
}

# Progress Bar 
Progress()
{
	echo -n "`date '+%F %T'` : INFO : Please Wait..."
	while true
	do
		echo -n "."
		sleep 1
	done
}

# Check User Login

INFO "Check User Login"
if [[ `id -u` -ne 0 ]];
then
        WARNING "You Must Run This Script From Root User Only"
        exit 0
else
        SUCCESSFUL "Your User Is Root"
fi

# Check Internet Connection
INFO "Check Internet Connection"
ping -c 1 8.8.8.8 >> /dev/null 2> /dev/null
if [ $? -eq 0 ]
then
        SUCCESSFUL "Internet is Connected"
else
        ERROR "Internet is Disconnected"
	exit 0
fi

# Update the dnf packages Install OpenJDK 1.8
INFO "Update the dnf packages"
Progress &
MySelfID=$!
dnf update -y > /dev/null
kill $MySelfID >/dev/null 2>&1
echo -e "\n"
CheckStatus "Updated the dnf packages"
INFO "Installed OpenJDK 1.8"
Progress &
MySelfID=$!
dnf install -y java-1.8.0-openjdk.x86_64 > /dev/null
kill $MySelfID >/dev/null 2>&1
echo -e "\n"
CheckStatus "Installed OpenJDK 1.8"

# Create the required directory to store Nexus files
INFO "Create the nexus directory"
mkdir /opt/nexus > /dev/null 2>&1 && cd "$_" > /dev/null 2>&1
CheckStatus "Created the nexus directory"

# Download the latest nexus
INFO "Download the latest nexus"
wget -O nexus.tar.gz $DOWNLOAD_URL -q --show-progress
echo -e "\n"
CheckStatus "Downloaded the latest nexus"

# Untar the downloaded file
INFO "Untar downloaded file"
tar -xvf nexus.tar.gz > /dev/null 2>&1
CheckStatus "Untar the downloaded file"

# Rename the untared file to nexus
INFO "Rename the untared file to nexus"
mv nexus-3* nexus > /dev/null 2>&1
CheckStatus "Rename the untared file to nexus"

# Create the user nexus
INFO "Create the user nexus"
useradd --system --no-create-home nexus > /dev/null 2>&1
CheckStatus "Create the user nexus"

# Change the ownership of nexus files and nexus data directory to nexus user
INFO "Change the ownership of nexus Directory"
chown -R nexus:nexus /opt/nexus > /dev/null 2>&1
CheckStatus "Change the ownership of nexus files and nexus data directory to nexus user"

# Change run_as_user parameter
INFO "Change run_as_user parameter"
sed -i 's/^#run_as_user=""/run_as_user="nexus"/' /opt/nexus/nexus/bin/nexus.rc > /dev/null 2>&1
CheckStatus "Change run_as_user parameter"

# Create the Systemd service file
INFO "Create the Systemd service file"
cat << EOF > /etc/systemd/system/nexus.service
[Unit]
Description=Nexus Service
After=syslog.target network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/nexus/bin/nexus start
ExecStop=/opt/nexus/nexus/bin/nexus stop
User=nexus
Group=nexus
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
CheckStatus "Create the Systemd service file"

# Manage Nexus Service, Execute the following command to add nexus service to boot
INFO "Daemon Reload"
systemctl daemon-reload > /dev/null 2>&1
CheckStatus "Daemon Reloaded"
INFO "Enable And Start nexus.service"
systemctl enable --now nexus.service > /dev/null 2>&1
CheckStatus "Nexus Service Enabled and Start"

# Firewall Add Port
INFO "Check Firewall Status"
STATUS="$(systemctl is-active firewalld.service)"
if [ "${STATUS}" = "active" ]
then
    INFO "Firewall Is Active"
    INFO "Firewall Add Port 8081"
    firewall-cmd --permanent --add-port=8081/tcp > /dev/null 2>&1
    CheckStatus "Add the Nexus Port"
    INFO "Firewall Reload"
    firewall-cmd --reload > /dev/null 2>&1
    CheckStatus "Firewall Reloaded"
else
    WARNING "Your Firewall is Deactive"
fi

# Check Nexus Service
INFO "Check Nexus Status"
STATUS="$(systemctl is-active nexus.service)"
if [ "${STATUS}" = "active" ]
then
    SUCCESSFUL "Nexus Is Active"
else
    ERROR "Your Nexus Service Is Deactive"
fi

# Starting Nexus
INFO "Starting Nexus"
Progress &
MySelfID=$!
while [ ! -f /opt/nexus/sonatype-work/nexus3/admin.password ]
do
  sleep 3
done
kill $MySelfID >/dev/null 2>&1
echo -e "\n"
CheckStatus "Nexus is started"


# Show default login password
INFO "Default Login Password"
PASS=`cat /opt/nexus/sonatype-work/nexus3/admin.password`
CheckStatus $PASS
