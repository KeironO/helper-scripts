#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

print_banner() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "       Ansible User Setup Script        "
    echo "========================================"
    echo -e "${NC}"
}


check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run with sudo or as root.${NC}"
        exit 1
    fi
}

create_ansible_user() {
    echo -e "${YELLOW}Creating ansible user...${NC}"
    
    # Check if user already exists
    if id "ansible" &>/dev/null; then
        echo -e "${YELLOW}User 'ansible' already exists. Skipping user creation.${NC}"
    else
        useradd -m ansible -s /bin/bash
        
        # Set password for ansible user
        echo -e "${YELLOW}Setting password for ansible user...${NC}"
        echo -e "${YELLOW}(This password will be needed when using ssh-copy-id later)${NC}"
        passwd ansible
    fi
}

configure_sudo() {
    echo -e "${YELLOW}Configuring sudo access for ansible user...${NC}"
    
    # Create sudoers file for ansible user
    echo "ansible ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible
    chmod 440 /etc/sudoers.d/ansible
    
    echo -e "${GREEN}Sudo access configured successfully.${NC}"
}

setup_ssh() {
    echo -e "${YELLOW}Setting up SSH directory for ansible user...${NC}"
    
    mkdir -p /home/ansible/.ssh
    chmod 700 /home/ansible/.ssh
    
    touch /home/ansible/.ssh/authorized_keys
    chmod 600 /home/ansible/.ssh/authorized_keys
    
    # Set proper ownership
    chown -R ansible:ansible /home/ansible/.ssh
    
    echo -e "${GREEN}SSH directory set up successfully.${NC}"
}

display_next_steps() {
    echo -e "${GREEN}"
    echo "========================================"
    echo "       Setup Completed Successfully     "
    echo "========================================"
    echo -e "${NC}"
    
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "1. On your Ansible control node, create an SSH key if you haven't already:"
    echo -e "   ${BLUE}ssh-keygen -t ed25519 -f ~/.ssh/ansible_id${NC}"
    echo -e ""
    echo -e "2. Copy the SSH key to this host:"
    echo -e "   ${BLUE}ssh-copy-id -i ~/.ssh/ansible_id ansible@$IP_ADDRESS${NC}"
    echo -e ""
    echo -e "3. Test the connection:"
    echo -e "   ${BLUE}ssh -i ~/.ssh/ansible_id ansible@$IP_ADDRESS${NC}"
    echo -e ""
    echo -e "4. Test Ansible connectivity:"
    echo -e "   ${BLUE}ansible -m ping $IP_ADDRESS${NC}"
    echo -e ""
}

main() {
    print_banner
    check_sudo
    create_ansible_user
    configure_sudo
    setup_ssh
    display_next_steps
}

main