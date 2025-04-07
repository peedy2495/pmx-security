#!/bin/bash
if [[ "${UID}" -ne 0 ]]; then
    echo " You need to run this script as root"
    exit 1
fi

# Get the script path
SCRIPT_PATH=$(dirname "$(realpath "$0")")

# the env file is placed one step up from the scriptpath
source $SCRIPT_PATH/../.env

if [[ -z "$SSH_KEY_ANSIBLE" ]]; then
    echo "SSH_KEY_ANSIBLE is not set in .env"
    exit 1
fi
if [[ -z "$SYSADMIN_AUTH" ]]; then
    echo "SYSADMIN_AUTH is not set in .env - create a password hash with mkpasswd"
    exit 1
fi

if ! grep -q '^Defaults rootpw$' /etc/sudoers.d/defaults 2>/dev/null; then
    echo 'Defaults rootpw' >/etc/sudoers.d/defaults
else
    echo "'Defaults rootpw' already exists in /etc/sudoers.d/defaults. Skipping addition."
fi

if ! id -u sysadmin &>/dev/null; then
    # create the password hash via mkpasswd
    useradd -m \
        -d /home/sysadmin \
        -s /bin/bash sysadmin \
        -G sudo \
        -p $SYSADMIN_AUTH
else
    echo "User 'sysadmin' already exists. Skipping creation."
fi

if ! id -u ansible &>/dev/null; then
    useradd -m \
        -d /home/ansible \
        -s /bin/bash ansible
    mkdir /home/ansible/.ssh
    echo "$SSH_KEY_ANSIBLE" >>/home/ansible/.ssh/authorized_keys
    chown -R ansible:ansible /home/ansible
    echo 'ansible ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/ansible
else
    echo "User 'ansible' already exists. Skipping creation."
fi

sed -i 's/#\?\(Port\s*\).*$/\1 2222/' /etc/ssh/sshd_config
sed -i 's/#\?\(PermitRootLogin\s*\).*$/\1 prohibit-password/' /etc/ssh/sshd_config
sed -i 's/#\?\(PubkeyAuthentication\s*\).*$/\1 yes/' /etc/ssh/sshd_config
sed -i 's/#\?\(PermitEmptyPasswords\s*\).*$/\1 no/' /etc/ssh/sshd_config
sed -i 's/#\?\(PasswordAuthentication\s*\).*$/\1 no/' /etc/ssh/sshd_config

systemctl restart sshd

if ! pveum group list | grep -q ' admin '; then
    pveum group add admin -comment "System Administrators"
    pveum acl modify / -group admin -role Administrator
else
    echo "Group 'admin' already exists. Skipping creation."
fi


if ! pveum user list | grep -q ' sysadmin@pam '; then
    pveum user add sysadmin@pam -email "petermark@spamfreemail.de" -group admin -comment "System Administrator"
    pveum user modify root@pam -enable 0
else
    echo "User 'sysadmin@pam' already exists. Skipping creation."
fi

