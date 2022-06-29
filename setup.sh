#!/bin/bash

PACKAGES="openssh"

install_pkgs() {
    echo "Installing Packages ...."
    pacman -S $PACKAGES
}

backup_config() {
    echo "Backing up config files..."
    mv /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    mv /etc/ssh/ssh_config /etc/ssh/ssh_config.bak
    mv /etc/ssh/modlui /etc/ssh/moduli.bak
}

copy_config() {
    echo "Copying config files to /etc/ssh/..."
    if [ "./sshd_config" ] ; then
        mv ./sshd_config /etc/ssh/
        chown root:root /etc/ssh/sshd_config
    fi
    
    if [ "./ssh_config" ] ; then
        mv ./ssh_config /etc/ssh/
        chown root:root /etc/ssh/ssh_config
    fi
    
    if [ "./moduli" ] ; then
        mv ./moduli /etc/ssh/
        chown root:root /etc/ssh/moduli
    fi
}

gen_new_keys() {
    echo "Removing default server keys..."
    cd /etc/ssh
    rm ssh_host_*key*

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

    echo "Starting service..."
    systemctl start sshd.service
    systemctl status sshd.service
    
    echo "SSH Init Completed Successfully"
}

main() {
    install_pkgs
    backup_config
    copy_config
    gen_new_keys
    create_group
    start_service
}

main

