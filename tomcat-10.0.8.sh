#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Step 0: Update and install JDK
echo "Updating packages and installing Java..."
sudo apt update -y
sudo apt install default-jdk -y

# Detect JAVA_HOME
JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
echo "Detected JAVA_HOME: $JAVA_HOME"

# Step 1: Download and extract Tomcat
echo "Downloading Tomcat 10.0.8..."
wget https://archive.apache.org/dist/tomcat/tomcat-10/v10.0.8/bin/apache-tomcat-10.0.8.tar.gz -P /tmp

echo "Extracting Tomcat..."
sudo mkdir -p /opt/tomcat
sudo tar -xzf /tmp/apache-tomcat-10.0.8.tar.gz -C /opt/tomcat --strip-components=1

# Set permissions
echo "Setting permissions..."
sudo chown -R www-data:www-data /opt/tomcat
sudo chmod -R 755 /opt/tomcat
sudo chmod +x /opt/tomcat/bin/*.sh

# Step 2: Create systemd unit file
echo "Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/tomcat.service > /dev/null
[Unit]
Description=Apache Tomcat 10
After=network.target

[Service]
Type=forking
User=www-data
Group=www-data
Environment="JAVA_HOME=$JAVA_HOME"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF

# Step 3: Create Tomcat users
echo "Configuring Tomcat users..."
sudo tee /opt/tomcat/conf/tomcat-users.xml > /dev/null <<EOF
<tomcat-users>
  <role rolename="manager-gui"/>
  <user username="manager" password="StrongPassword" roles="manager-gui,manager-script"/>

  <role rolename="admin-gui"/>
  <user username="admin" password="StrongPassword" roles="manager-gui,admin-gui"/>
</tomcat-users>
EOF

# Step 4: Allow remote access to manager apps
echo "Enabling remote access..."
sudo sed -i 's/<Valve.*RemoteAddrValve.*>//g' /opt/tomcat/webapps/manager/META-INF/context.xml || true
sudo sed -i 's/<Valve.*RemoteAddrValve.*>//g' /opt/tomcat/webapps/host-manager/META-INF/context.xml || true

# Step 5: Start and enable Tomcat
echo "Starting Tomcat..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat

echo "Tomcat installation complete!"
sudo systemctl status tomcat
