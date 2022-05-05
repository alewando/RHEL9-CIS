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
 #  - Not sure why, but ansible detects the package manager on AL2022 to be `yum` and not `dnf`
 #  - This causes the `package` module to fail because it defers to the `yum` module and fails, since that requires `python2` which isn't present
echo "Change package tasks to explicit dnf tasks"
find . -iname '*.yml'| xargs sed -i 's/package:/dnf:/g'

# Update the OS family/version check
# tasks/main.yml, "Check OS version and family"
# assert:
#     that: ansible_distribution == 'Amazon' and ansible_os_family == 'RedHat' and ansible_distribution_major_version is version_compare('2022', '==')
if grep -q "Rocky" tasks/main.yml; then
  echo "Updating OS family/version check"
  sed -i "s/that: (ansible_distribution != 'CentOS' and ansible_os_family == 'RedHat'.*/that: ansible_distribution == 'Amazon' and ansible_os_family == 'RedHat' and ansible_distribution_major_version is version_compare('2022', '==')/" tasks/main.yml
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
