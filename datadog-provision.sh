#!/bin/bash
API_KEY=$(cat /tmp/api_key)
sudo DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=${API_KEY} DD_SITE="datadoghq.eu" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"

sudo echo -e "\nlogs_enabled: true" >> /etc/datadog-agent/datadog.yaml

sudo cat<<EOF>/etc/datadog-agent/conf.d/http_check.d/conf.yaml
instances:
  - name: onliner.by
    url: https://onliner.by
EOF
sudo mkdir /etc/datadog-agent/conf.d/httpd.d
sudo cat<<EOF>/etc/datadog-agent/conf.d/httpd.d/conf.yaml
logs:
  - type: file
    path: /etc/httpd/logs/*
    source: httpd
    service: httpd
EOF
sudo cat<<EOF>/etc/datadog-agent/conf.d/tomcat.d/log.yaml
logs:
  - type: file
    path: /var/log/tomcat/*
    service: tomcat
    source: tomcat
EOF
sudo yum install httpd -y
sudo systemctl enable httpd
sudo systemctl start httpd
sudo chmod 755 /etc/httpd/*
sudo yum install -y tomcat tomcat-webapps tomcat-admin-webapps
sudo sed -i 's@<!-- <user name="admin" password="adminadmin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" /> -->@<user name="admin" password="admin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" />@g' /etc/tomcat/tomcat-users.xml
sudo systemctl enable tomcat
sudo systemctl restart tomcat
sudo systemctl restart datadog-agent
