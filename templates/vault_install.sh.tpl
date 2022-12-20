#! /bin/bash

VAULT_HOME_DIRECTORY="${vault_home_directory}"
VAULT_DATA_DIRECTORY="${vault_data_directory}/data"
VAULT_TLS_DIRECTORY="${vault_data_directory}/tls"
VAULT_LICENSE_DIRECTORY="${vault_data_directory}/license"
VAULT_BIN_DIRECTORY="${vault_bin_directory}"
VAULT_SYSTEMD_DIRECTORY="${vault_systemd_directory}"
VAULT_USER="vault"
VAULT_GROUP="vault"
VAULT_INSTALL_URL="${vault_install_url}"
REQUIRED_PACKAGES="wget jq unzip"

# have_program is a helper function to determine if a package is installed
function have_program {
  [ -x "$(which $1)" ]
}

# install_tools installs any necessary tools used in this script
function install_necessary_tools {
  echo "[INFO] Installing necessary tools..."
  
  # Determine package manager to use
  if have_program apt-get; then
    package_manager="apt-get"
    sudo $package_manager update -y
  elif have_program yum; then
    package_manager="yum"
  fi

  # Install required packages
  sudo $package_manager install -y $REQUIRED_PACKAGES

  echo "[INFO] Done installing necessary tools."
}

# install_configure_cloud_tool installs the necessary cloud tool
function install_configure_cloud_tool {
  echo "[INFO] Installing necessary cloud tool..."
%{ if cloud == "azure" ~}
  if ! have_program az; then
    if have_program apt-get; then
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    elif have_program yum; then
      sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

      sudo bash -c "cat > /etc/yum.repos.d/azure-cli.repo" <<EOF
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

      sudo $package_manager install -y azure-cli
    fi

    echo "[INFO] Authenticating to Azure via Managed Identity"
    az login --identity
    echo "[INFO] Authenticated to Azure via Managed Identity"
  fi
%{ endif ~}
%{ if cloud == "aws" ~}
  if ! have_program aws; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -f ./awscliv2.zip && rm -rf ./aws

    echo "[INFO] Done installing AWS CLI"
  fi
%{ endif ~}

  echo "[INFO] Done installing necessary cloud tool."
}

# scrape_vm_info gets the required information needed from the cloud's API
function scrape_vm_info {
  echo "[INFO] Scraping virtual machine information..."

%{ if cloud == "gcp" ~}
  # https://cloud.google.com/compute/docs/metadata/default-metadata-values
%{ endif ~}
%{ if cloud == "azure" ~}
  # https://docs.microsoft.com/en-us/azure/virtual-machines/linux/instance-metadata-service?tabs=linux
  SUBSCRIPTION_ID=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute/subscriptionId?api-version=2021-02-01&format=text")
  SCALE_SET_NAME=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute/vmScaleSetName?api-version=2021-02-01&format=text")
  RESOURCE_GROUP_NAME=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute/resourceGroupName?api-version=2021-02-01&format=text")
%{ endif ~}
%{ if cloud == "aws" ~}
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
  REGION="$(curl -s http://169.254.169.254/latest/meta-data/placement/region)"
%{ endif ~}

  echo "[INFO] Done scraping virtual machine information."
}

# user_create creates a dedicated linux user for Vault
function user_group_create {
  echo "[INFO] Creating Vault user and group..."

  # Create the dedicated as a system group
  sudo groupadd --system $VAULT_GROUP

  # Create a dedicated user as a system user
  sudo useradd --system -m -d $VAULT_HOME_DIRECTORY -g $VAULT_GROUP $VAULT_USER

  echo "[INFO] Done creating Vault user and group"
}

# directory_creates creates the necessary directories for Vault
function directory_create {
  echo "[INFO] Creating necessary directories..."

  # Define all directories needed as an array
  directories=( $VAULT_HOME_DIRECTORY $VAULT_DATA_DIRECTORY $VAULT_TLS_DIRECTORY $VAULT_LICENSE_DIRECTORY )

  # Loop through each item in the array; create the directory and configure permissions
  for directory in "$${directories[@]}"; do
    mkdir -p $directory
    sudo chown $VAULT_USER:$VAULT_GROUP $directory
    sudo chmod 750 $directory
  done

  echo "[INFO] Done creating necessary directories."
}

# install_vault_binary downloads the Vault binary and puts it in dedicated bin directory
function install_vault_binary {
  echo "[INFO] Installing Vault binary to: $VAULT_BIN_DIRECTORY..."

  # Download the Vault binary to the dedicated bin directory
  sudo wget $VAULT_INSTALL_URL -O $VAULT_BIN_DIRECTORY/vault.zip
  
  # Unzip the zip file containing the Vault binary
  sudo unzip $VAULT_BIN_DIRECTORY/vault.zip -d $VAULT_BIN_DIRECTORY

  # Ensure the user `vault` owns the binary
  sudo chown $VAULT_USER:$VAULT_GROUP $VAULT_BIN_DIRECTORY/vault

  # Ensure the user and group `vault` can only execute the binary
  sudo chmod 755 $VAULT_BIN_DIRECTORY/vault

  # Remove zip file
  sudo rm $VAULT_BIN_DIRECTORY/vault.zip

  echo "[INFO] Done installing Vault binary."
}

# fetch_tls_certificates fetches the TLS certificates from cloud's secret manager
function fetch_tls_certificates {
  echo "[INFO] Fetching TLS certificates..."
%{ if cloud == "gcp" ~}
  # Retrieve CA certificate
  gcloud secrets versions access latest --secret=${vault_api_ca_cert} > $VAULT_TLS_DIRECTORY/ca.pem

  # Retrieve signed certificate and retrieve CA certificate again to append to the signed certificate's file
  gcloud secrets versions access latest --secret=${vault_api_cert} > $VAULT_TLS_DIRECTORY/cert.pem && echo $'\n' >> $VAULT_TLS_DIRECTORY/cert.pem
  gcloud secrets versions access latest --secret=${vault_api_ca_cert} >> $VAULT_TLS_DIRECTORY/cert.pem

  # Retrieve private key of signed certificate
  gcloud secrets versions access latest --secret=${vault_api_key} > $VAULT_TLS_DIRECTORY/key.pem
%{ endif ~}
%{ if cloud == "azure" ~}
  # Retrieve CA certificate
  az keyvault secret show --vault-name ${kms_data.vault_name} --name ${vault_api_ca_cert} --query value --output tsv | base64 -di > $VAULT_TLS_DIRECTORY/ca.pem

  # Retrieve signed certificate and retrieve CA certificate again to append to the signed certificate's file
  az keyvault secret show --vault-name ${kms_data.vault_name} --name ${vault_api_cert} --query value --output tsv | base64 -di > $VAULT_TLS_DIRECTORY/cert.pem && echo $'\n' >> $VAULT_TLS_DIRECTORY/cert.pem
  az keyvault secret show --vault-name ${kms_data.vault_name} --name ${vault_api_ca_cert} --query value --output tsv | base64 -di >> $VAULT_TLS_DIRECTORY/cert.pem

  # Retrieve private key of signed certificate
  az keyvault secret show --vault-name ${kms_data.vault_name} --name ${vault_api_key} --query value --output tsv | base64 -di > $VAULT_TLS_DIRECTORY/key.pem
%{ endif ~}
%{ if cloud == "aws" ~}
  # Retrieve CA certificate
  aws secretsmanager get-secret-value --secret-id ${vault_api_ca_cert} --region $REGION --output text --query SecretString > $VAULT_TLS_DIRECTORY/ca.pem

  # Retrieve signed certificate and retrieve CA certificate again to append to the signed certificate's file
  aws secretsmanager get-secret-value --secret-id ${vault_api_cert} --region $REGION --output text --query SecretString > $VAULT_TLS_DIRECTORY/cert.pem && echo $'\n' >> $VAULT_TLS_DIRECTORY/cert.pem 
  aws secretsmanager get-secret-value --secret-id ${vault_api_ca_cert} --region $REGION --output text --query SecretString >> $VAULT_TLS_DIRECTORY/cert.pem

  # Retrieve private key of signed certificate
  aws secretsmanager get-secret-value --secret-id ${vault_api_key} --region $REGION --output text --query SecretString > $VAULT_TLS_DIRECTORY/key.pem
%{ endif ~}

  # Ensure proper permissions on TLS certificates
  sudo chmod 400 $VAULT_TLS_DIRECTORY/*

  # Ensure proper ownership on TLS certificates
  sudo chown $VAULT_USER:$VAULT_GROUP $VAULT_TLS_DIRECTORY/*

  echo "[INFO] Done fetching TLS certificates."
}

# fetch_vault_license fetches the Vault license from the cloud's secret manager
function fetch_vault_license {
  echo "[INFO] Retriving Vault license..."
%{ if cloud == "gcp" ~}
  gcloud secrets versions access latest --secret=${vault_license} > $VAULT_LICENSE_DIRECTORY/license.hclic
%{ endif ~}
%{ if cloud == "azure" ~}
  az keyvault secret download --vault-name ${kms_data.vault_name} --name ${vault_license} --file $VAULT_LICENSE_DIRECTORY/license.hclic
%{ endif ~}
%{ if cloud == "aws" ~}
  aws secretsmanager get-secret-value --secret-id ${vault_license} --region $REGION --output text --query SecretString > $VAULT_LICENSE_DIRECTORY/license.hclic
%{ endif ~}

  # Ensure proper permissions on license
  sudo chmod 400 $VAULT_LICENSE_DIRECTORY/license.hclic

  # Ensure proper ownership on license
  sudo chown $VAULT_USER:$VAULT_GROUP $VAULT_LICENSE_DIRECTORY/license.hclic

  echo "[INFO] Done fetching Vault license."
}

# template_vault_config templates out the Vault configuration
function template_vault_config {
  FULL_HOSTNAME="$(hostname -f)"
  
  echo "[INFO] Templating out Vault configuration file..."

  echo "[INFO] Templating out listener stanza..."
  sudo bash -c "cat > $VAULT_HOME_DIRECTORY/vault.hcl" <<EOF
listener "tcp" {
  address       = "[::]:${vault_api_port}"
  tls_cert_file = "$VAULT_TLS_DIRECTORY/cert.pem"
  tls_key_file  = "$VAULT_TLS_DIRECTORY/key.pem"

  tls_require_and_verify_client_cert = ${vault_tls_require_and_verify_client_cert}
  tls_disable_client_certs           = ${vault_tls_disable_client_certs}
}
EOF
  echo "[INFO] Done templating out listener stanza."

  echo "[INFO] Templating out storage stanza..."

  sudo bash -c "cat >> $VAULT_HOME_DIRECTORY/vault.hcl" <<EOF

storage "raft" {
  path    = "$VAULT_DATA_DIRECTORY"
  node_id = "$FULL_HOSTNAME"
  retry_join {
%{ if cloud == "gcp" ~}
    auto_join             = "provider=gce tag_value=${auto_join_tag_value}"
%{ endif ~}
%{ if cloud == "azure" ~}
    auto_join             = "provider=azure subscription_id=$SUBSCRIPTION_ID resource_group=$RESOURCE_GROUP_NAME vm_scale_set=$SCALE_SET_NAME"
%{ endif ~}
%{ if cloud == "aws" ~}
    auto_join             = "provider=aws region=$REGION tag_key=${auto_join_tag_key} tag_value=${auto_join_tag_value} addr_type=private_v4"
%{ endif ~}
    auto_join_scheme      = "https"
    leader_ca_cert_file   = "$VAULT_TLS_DIRECTORY/ca.pem"
%{ if vault_leader_tls_servername != "" ~}
    leader_tls_servername = "${vault_leader_tls_servername}"
%{ else ~}
    leader_tls_servername = "$FULL_HOSTNAME"
%{ endif ~}
  }
}
EOF
  
  echo "[INFO] Done templating out storage stanza."

%{ if vault_license != "" ~}
  echo "[INFO] Templating out license info..."
  sudo bash -c "cat >> $VAULT_HOME_DIRECTORY/vault.hcl" <<EOF

license_path = "$VAULT_LICENSE_DIRECTORY/license.hclic"
EOF
    echo "[INFO] Done templating out license info..."
%{ endif ~}

  echo "[INFO] Templating out seal stanza..."
  sudo bash -c "cat >> $VAULT_HOME_DIRECTORY/vault.hcl" <<EOF

%{ if vault_seal_type == "shamir" ~}
seal "${vault_seal_type}" {}
%{ else }
seal "${vault_seal_type}" {
%{ for key, value in kms_data }
  ${key} = "${value}"
%{ endfor ~}
}
%{ endif ~}
EOF
  
  echo "[INFO] Done templating out seal stanza."

  echo "[INFO] Templating out remaining info..."
  sudo bash -c "cat >> $VAULT_HOME_DIRECTORY/vault.hcl" <<EOF

api_addr      = "https://$FULL_HOSTNAME:${vault_api_port}"
cluster_addr  = "https://$FULL_HOSTNAME:${vault_cluster_port}"
disable_mlock = ${vault_disable_mlock}
ui            = ${vault_enable_ui}
EOF
  echo "[INFO] Done templating out remaining info."

  # Ensure proper permissions of configuration file
  sudo chmod 660 $VAULT_HOME_DIRECTORY/vault.hcl

  # Ensure proper ownership of configuration file
  sudo chown $VAULT_USER:$VAULT_GROUP $VAULT_HOME_DIRECTORY/vault.hcl

  echo "[INFO] Done templating out Vault configuration file."
}

# template_vault_config templates out the Vault system file
function template_vault_systemd {
  echo "[INFO] Templating out the Vault service..."

  sudo bash -c "cat > $VAULT_SYSTEMD_DIRECTORY/vault.service" <<EOF
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=$VAULT_HOME_DIRECTORY/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=$VAULT_USER
Group=$VAULT_GROUP
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=$VAULT_BIN_DIRECTORY/vault server -config=$VAULT_HOME_DIRECTORY/vault.hcl
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

  # Ensure proper permissions on service file
  sudo chmod 644 $VAULT_SYSTEMD_DIRECTORY/vault.service

  echo "[INFO] Done templating out the Vault service."
}

# start_enable_vault starts and enables the vault service
function start_enable_vault {
  echo "[INFO] Starting and enabling the Vault service..."

  sudo systemctl enable vault

  sudo systemctl start vault

  echo "[INFO] Done starting and enabling the Vault service."
}

function main {
%{ if skip_install_tools == false ~}
  install_necessary_tools
%{ endif ~}
  install_configure_cloud_tool
  scrape_vm_info

%{ if using_packer_image == false ~}
  user_group_create
  directory_create
  install_vault_binary
%{ endif ~}

  fetch_tls_certificates
  fetch_vault_license
  template_vault_config
  template_vault_systemd
  start_enable_vault
}

# Check if the script has already run
if [ ! -f "/etc/vault.d/.completed" ]; then
  echo "[INFO] Running script for first time."
  main
  touch /etc/vault.d/.completed
else
  echo "[INFO] Not running script. Already run."
fi
