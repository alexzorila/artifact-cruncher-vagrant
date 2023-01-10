# Bootstrap script used to download, install and configure Splunk on a fresh
# copy of Ubuntu 22.04 LTS VirtualBox VM


install_splunk(){
# Source: https://github.com/clong/DetectionLab/blob/master/Vagrant/logger_bootstrap.sh  
# Check if Splunk is already installed
if [ -f "/opt/splunk/bin/splunk" ]; then
  echo "[$(date +%H:%M:%S)]: Splunk is already installed"
else
  echo "[$(date +%H:%M:%S)]: Installing Splunk..."
  # Get download.splunk.com into the DNS cache. Sometimes resolution randomly fails during wget below
  dig @8.8.8.8 download.splunk.com >/dev/null
  dig @8.8.8.8 splunk.com >/dev/null
  dig @8.8.8.8 www.splunk.com >/dev/null

  # Try to resolve the latest version of Splunk by parsing the HTML on the downloads page
  echo "[$(date +%H:%M:%S)]: Attempting to autoresolve the latest version of Splunk..."
  LATEST_SPLUNK=$(curl https://www.splunk.com/en_us/download/splunk-enterprise.html | grep -i deb | grep -Eo "data-link=\"................................................................................................................................" | cut -d '"' -f 2)
  # Sanity check what was returned from the auto-parse attempt
  if [[ "$(echo "$LATEST_SPLUNK" | grep -c "^https:")" -eq 1 ]] && [[ "$(echo "$LATEST_SPLUNK" | grep -c "\.deb$")" -eq 1 ]]; then
    echo "[$(date +%H:%M:%S)]: The URL to the latest Splunk version was automatically resolved as: $LATEST_SPLUNK"
    echo "[$(date +%H:%M:%S)]: Attempting to download..."
    wget --progress=bar:force -P /opt "$LATEST_SPLUNK"
  else
    echo "[$(date +%H:%M:%S)]: Unable to auto-resolve the latest Splunk version. Falling back to hardcoded URL..."
    # Download Hardcoded Splunk
    wget --progress=bar:force -O /opt/splunk-8.0.2-a7f645ddaf91-linux-2.6-amd64.deb 'https://download.splunk.com/products/splunk/releases/8.0.2/linux/splunk-8.0.2-a7f645ddaf91-linux-2.6-amd64.deb&wget=true'
  fi
  if ! ls /opt/splunk*.deb 1>/dev/null 2>&1; then
    echo "Something went wrong while trying to download Splunk. This script cannot continue. Exiting."
    exit 1
  fi
  if ! dpkg -i /opt/splunk*.deb >/dev/null; then
    echo "Something went wrong while trying to install Splunk. This script cannot continue. Exiting."
    exit 1
  fi

  # Start Splunk for the first time
  /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd changeme

  # Skip Splunk Tour and Change Password Dialog
  echo "[$(date +%H:%M:%S)]: Disabling the Splunk tour prompt..."
  touch /opt/splunk/etc/.ui_login
  mkdir -p /opt/splunk/etc/users/admin/search/local
  echo -e "[search-tour]\nviewed = 1" >/opt/splunk/etc/system/local/ui-tour.conf
  # Source: https://answers.splunk.com/answers/660728/how-to-disable-the-modal-pop-up-help-us-to-improve.html
  if [ ! -d "/opt/splunk/etc/users/admin/user-prefs/local" ]; then
    mkdir -p "/opt/splunk/etc/users/admin/user-prefs/local"
  fi
  echo '[general]
render_version_messages = 1
dismissedInstrumentationOptInVersion = 4
notification_python_3_impact = false
display.page.home.dashboardId = /servicesNS/nobody/search/data/ui/views/logger_dashboard' >/opt/splunk/etc/users/admin/user-prefs/local/user-prefs.conf

  # Enable SSL Login for Splunk
  echo -e "[settings]\nenableSplunkWebSSL = true" >/opt/splunk/etc/system/local/web.conf 
fi
# Include Splunk in the PATH
echo export PATH="$PATH:/opt/splunk/bin" >>~/.bashrc
echo "export SPLUNK_HOME=/opt/splunk" >>~/.bashrc
}


configure_splunk(){
# Set default App Web GUI opens
mkdir /opt/splunk/etc/apps/user-prefs/local
echo -e "[general_default]\ndefault_namespace = search" > /opt/splunk/etc/apps/user-prefs/local/user-prefs.conf
	
# Set default index search to any
echo -e "[role_admin]\nsrchIndexesDefault = *" > /opt/splunk/etc/system/local/authorize.conf

# Increase MAX_DAYS_AGO to allow for old timestamps to be parsed
echo -e "[default]\nMAX_DAYS_AGO = 10951" > /opt/splunk/etc/system/local/props.conf
# Source: https://docs.splunk.com/Documentation/Splunk/9.0.3/Admin/Propsconf#Timestamp_extraction_configuration

# Create index for forensic data
/opt/splunk/bin/splunk add index forensics -auth admin:changeme

# Configure data ingestion sources
echo '[monitor:///vagrant/parsed]
disabled = false
host = splunklocal
index = forensics
crcSalt = <SOURCE>' > /opt/splunk/etc/apps/search/local/inputs.conf
}


reboot_splunk(){
echo -e "\n\n[$(date '+%d/%m/%Y %H:%M:%S')]: Rebooting Splunk for changes to take effect ..."
/opt/splunk/bin/splunk enable boot-start
/opt/splunk/bin/splunk restart
}

install_mftecmd(){
echo -e "\n\n[$(date '+%d/%m/%Y %H:%M:%S')]: Setting up MFTECmd ..."
apt update -y
apt install dotnet6 sleuthkit unzip -y
git clone https://github.com/EricZimmerman/MFTECmd.git /opt/MFTECmd
dotnet publish /opt/MFTECmd/ -r ubuntu.22.04-x64 --self-contained --framework net6.0
cp -s /opt/MFTECmd/MFTECmd/bin/Debug/net6.0/ubuntu.22.04-x64/MFTECmd /usr/local/bin/
}

install_cdqr(){
echo -e "\n\n[$(date '+%d/%m/%Y %H:%M:%S')]: Setting up CDQR ..."
apt update -y
apt install plaso -y
git clone https://github.com/orlikoski/CDQR.git /opt/CDQR
chmod +x /opt/CDQR/src/cdqr.py
cp -s /opt/CDQR/src/cdqr.py /usr/local/bin/
# Disable individual report creation
sed -i '2788s/^/#/' /opt/CDQR/src/cdqr.py
}

setup_parsing(){
mkdir /opt/parse
cp /vagrant/parse.sh /opt/parse/parse
cp -s /opt/parse/parse /usr/local/bin/
}

install_splunk
configure_splunk
install_mftecmd
install_cdqr
setup_parsing
reboot_splunk