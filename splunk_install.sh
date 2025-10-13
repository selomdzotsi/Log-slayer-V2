#!/bin/bash
#Improvements
#Chek for dependancies eg curl is installed on system.
echo "Splunk Installer Script" >> install.log
date >> install.log
echo -e "Downloading Splunk Enterprise Debian Package" >> install.log
#Downloading Splunk Enterprise Debian Package
if wget -O splunk-9.4.2-e9664af3d956-linux-amd64.deb "https://download.splunk.com/products/splunk/releases/9.4.2/linux/splunk-9.4.2-e9664af3d956-linux-amd64.deb"; then
   echo -e "Download Succesfull" >> install.log
else
   echo -e "Splunk Debian Package Download Failed. Read install.log file for more details" >> install.log
   exit 1
fi
#Installing Splunk Enterprise
if dpkg -i splunk-9.4.2-e9664af3d956-linux-amd64.deb; then
   dpkg --status splunk >> install.log  
   echo -e "Splunk Enterprise Succesfully Installed" >> install.log
else
   echo -e "Splunk Enterprise Installation Failed. Read install.log file for more details"
exit 1
fi
#Start Splunk 
cd /opt/splunk/bin
if sudo ./splunk start --accept-license; then      #Need to add user input for usernam and port
   echo -e "Splunk Succesfully Installed" >> install.log
   #echo -e "Navigate to $HOSTNAME:8000 to login"
   sudo /opt/splunk/bin/splunk enable boot-start -user splunk -systemd-managed 1 >> install.log
else
   echo -e "Splunk Failed to Start" >> install.log
exit 1
fi