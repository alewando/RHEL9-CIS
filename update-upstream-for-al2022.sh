#!/usr/bin/env bash

# Updates the upstream RHEL9-CIS playbook to work with Amazon Linux 2022

# Add distro vars file
DISTRO_VARS_FILE="vars/Amazon.yml"
if [[ ! -e ${DISTRO_VARS_FILE} ]]; then
  echo "Adding distro vars file"
  cat << EOF > "${DISTRO_VARS_FILE}"
---
# OS Specific Settings

rpm_gpg_key: /etc/pki/rpm-gpg/RPM-GPG-KEY-amazon-linux-2022
EOF
fi 

# Include 'ssm-user' in list of users that can sudo without password
if grep -q "ec-user" tasks/section_5/cis_5.3.x.yml; then
  echo "Adding ssm-user as sudoer without password"
  sed -i 's/ec2-user/ec2-user|ssm-user/g' tasks/section_5/cis_5.3.x.yml
fi

# Update package names
echo "Update package names"
find . -iname '*.yml'| xargs sed -i 's/rsyslog-logrotate/logrotate/g'