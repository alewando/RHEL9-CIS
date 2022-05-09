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

 # Change all `dnf:` tasks to `dnf:`
#  - Ansible detects the package manager on AL2022 to be `yum` and not `dnf`
#    - See https://github.com/ansible/ansible/pull/77050
#    - This is fixed in Ansible 6 (ansible-core 2.13) but it is not available yet
 #  - This causes the `package` module to fail because it defers to the `yum` module and fails, since that requires `python2` which isn't present
# TODO: Remove this once ansible 6 is released (expected 2022-06-21)
echo "Change package tasks to explicit dnf tasks"
find . -iname '*.yml'| xargs sed -i 's/package:/dnf:/g'

# Include 'ssm-user' in list of users that can sudo without password
if grep -q "ec-user" tasks/section_5/cis_5.3.x.yml; then
  echo "Adding ssm-user as sudoer without password"
  sed -i 's/ec2-user/ec2-user|ssm-user/g' tasks/section_5/cis_5.3.x.yml
fi

# Update package names
echo "Update package names"
find . -iname '*.yml'| xargs sed -i 's/rsyslog-logrotate/logrotate/g'

# Add missing variable defaults (may be fixed upstream)
# defaults/main.yml:
# rhel9cis_pam_faillock:
#     remember: 5
#     attempts: 5
#     fail_for_root: false
#     unlock_time: 900
if ! grep -q "fail_for_root" defaults/main.yml; then
  echo "Adding missing variable defaults"
  sed -i '/\s*remember: 5/a\    attempts: 5\n    fail_for_root: no\n    unlock_time: 900' defaults/main.yml
fi
