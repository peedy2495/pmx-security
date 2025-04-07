# Harden virgin Proxmox installations

## Prerequisites
- installed git
- existent path /etc/pve/ext/scripts

## Account management
- create user sysadmin
- permit sysadmin's password for sudo - use the root password
- permit ssh root password authenication - be aware to never add an external pubkey!
- create an ansible pubkey account
- disabled ssh password authentication
- disable root from Dashboard, sysadmin will have full administrative permissions.
- use port 2222 for ssh logins

## Usage

Clone this repo into /etc/pve/ext/scripts.  
Now, it's available on all nodes for execution because of pmxcfs.  
Be aware, that scripts inside /etc/pve can't be modified for execution.  
Therefore you have to start 'em with `bash <path_to_script>` 