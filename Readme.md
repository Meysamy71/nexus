<img src="https://github.com/Meysamy71/linuxinstall/blob/main/nexus/src/nexuslogo.JPG" alt="Nexus Logo" width="1000" height="250">

# Install Nexus Repository on Rocky linux

<img src="https://img.shields.io/badge/Nexus-V3.66.0.02-green"></img>

- [Install With Script](https://github.com/Meysamy71/nexus/tree/main/script)
- [Install Docker Compose](https://github.com/Meysamy71/nexus/tree/main/docker)
- [Install Manually](#Install-Manually)

## Install Manually 

### Update the dnf packages and Install OpenJDK 1.8

`dnf update -y`

`dnf install java-1.8.0-openjdk.x86_64 -y`

### Create the required directory to store Nexus files

`mkdir /opt/nexus && cd "$_"`

### Check the latest version

[Latest Version](https://help.sonatype.com/en/download.html)

### Download the latest nexus (now v-3.66.0-02)

`wget -O nexus.tar.gz https://download.sonatype.com/nexus/3/nexus-3.66.0-02-unix.tar.gz`

### Untar the downloaded file

`tar -xvf nexus.tar.gz`

### Rename the untared file to nexus

`mv nexus-3* nexus`

### Create the user nexus

`useradd --system --no-create-home nexus`

### Change the ownership of nexus files and nexus data directory to nexus user

`chown -R nexus:nexus /opt/nexus`

### Change run_as_user parameter

`sed -i 's/^#run_as_user=""/run_as_user="nexus"/' /opt/nexus/nexus/bin/nexus.rc`

### Create the Systemd service file

```
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
```

### Manage Nexus Service, Execute the following command to add nexus service to boot

`systemctl daemon-reload`

`systemctl enable --now nexus.service`

### Show default login password
`cat /opt/nexus/sonatype-work/nexus3/admin.password`

### Firewall Add Port

`firewall-cmd --permanent --add-port=8081/tcp`
`firewall-cmd --reload`
