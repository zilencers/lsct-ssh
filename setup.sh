#!/bin/bash

ABS_PATH=$(pwd)/packages/lsct-ssh
SSH_PATH=/etc/ssh
SSH_CFG=/etc/ssh/ssh_config
SSHD_CFG=/etc/ssh/sshd_config
MODULI=/etc/ssh/moduli

install_pkgs() {
    printf "WARNING: $3 package will be installed. Continue (y/N): "
    read answer
    
    if [ "$answer" == "y" ] ; then 
        echo "Installing Packages...."
        # $1 = Package Manager
        # $2 = Install Cmd
        # $3 = Package
        $@
    else
	./lsct
    fi
}

copy_keys() {
    systemctl start sshd.service
    local ip=$(ip addr | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}/24\b")

    echo "WARNING: This configuration will disable password authentication."
    echo "It is recommended you copy your client public key to this server now."
    echo "Generate client keys using the following commands:"
    echo "ssh-keygen -t ed25519 -o -a 100"
    echo "ssh-keygen -t rsa -b 4096 -o -a 100"
    echo ""
    echo "From the client use the following command to copy your public key" 
    echo "to this server:"
    echo "ssh-copy-id -i [key-name.pub] root@$ip"
    echo ""
    echo "Press any key to continue setup"
    read
}

backup_config() {
    echo "Backing up config files..."
    mv $SSHD_CFG $SSHD_CFG.bak
    mv $SSH_CFG $SSH_CFG.bak
    mv $MODULI $MODULI.bak
}

copy_config() {
    echo "Copying config files to /etc/ssh/..."
    if [ "$ABS_PATH/sshd_config" ] ; then
        mv $ABS_PATH/sshd_config $SSH_PATH
        chown root:root $SSHD_CFG
    fi
    
    if [ "$ABS_PATH/ssh_config" ] ; then
        mv $ABS_PATH/ssh_config $SSH_PATH
        chown root:root $SSH_CFG
    fi
    
    if [ "$ABS_PATH/moduli" ] ; then
        mv $ABS_PATH/moduli /etc/ssh/
        chown root:root $MODULI
    fi
}

gen_new_keys() {
    echo "Removing default server keys..."
    rm $SSH_PATH/ssh_host_*key*

    echo "Generating new server keys..."
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" < /dev/null
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" < /dev/null
}

create_group() {
    printf "Would you like to create an ssh-user group? (y/N) "
    read answer

    if [ "$answer" == "y" ] ; then
        groupadd ssh-user
    fi

    printf "Would you like to add users to the ssh-user group? (y/N) "
    read choice

    while [ "$choice" == "y" ]
    do
        echo "Enter the username you wish to add to the ssh-user group"
	read user

	usermod -a -G ssh-user $user

	printf "Add another user? (y/N) "
	read choice
    done
}

start_service() {
    echo "Enabling service at startup..."
    systemctl enable sshd.service
    sleep 1

    echo "Restarting service..."
    systemctl restart sshd.service
    sleep 2
    systemctl status sshd.service
    
    echo "SSH Setup Completed Successfully"
    echo "Press any key to continue"
    read
}

main() {
    install_pkgs $@
    copy_keys
    backup_config
    copy_config
    gen_new_keys
    create_group
    start_service
}

main $@

