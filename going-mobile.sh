#!/bin/bash

# K3S Node Flow is as follows:
# Connect to Headscale server
# Instantiate a k3s server with the etcd server tailscale address
# Get Key from the first server
# Instantiate a k3s server with the etcd server tailscale address AND using key from first server
# NOTE: Be certain to use the tailscale addresses for everything to be sure that nothing is leaked


# TODO: Update to reflect using external etcd.
# TODO: Check for tailscale on run
# TODO: Setup argo using argo folder

# Function to install tailscale
install_tailscale() {
    echo "Installing tailscale..."
    # install using tailscale install script
    curl -fsSL https://tailscale.com/install.sh | sh
}

# Function to configure tailscale
configure_tailscale() {
    if [[ $# -lt 2 ]]; then
        echo "---------------------"
        echo "  Configure Tailscale"
        echo "---------------------"
        read -p "Enter your headscale login server url: " headscale_login_url 
        read -p "Enter your authkeys: " headscale_authkey
        echo "---------------------"
        echo "Configuring tailscale..."
        sudo tailscale up --login-server $headscale_login_url --authkey $headscale_authkey
    else
        echo "Configuring tailscale..."
        sudo tailscale up --login-server $1 --authkey $2
    fi
}

# Function to install k3s as a server
install_k3s_server() {
    #Open port 6443 in ufw
    sudo ufw allow 6443/tcp
    read -p "Enter first k3s server token: " K3S_TOKEN
    read -p "Enter etcd url (including port 2379): " ETCD_URL
    curl -sfL https://get.k3s.io | sh -s server --token=$K3S_TOKEN --datastore-endpoint=$ETCD_URL
}

# Function to install k3s as an agent
install_k3s_agent() {
    # TODO: Update to use new external DB method
    #Open port 6443 in ufw
    sudo ufw allow 6443/tcp
    echo "Installing k3s as an agent..."
    read -p "Enter k3s server url (including port 6443): " K3S_URL
    read -p "Enter k3s server token: " K3S_TOKEN
    curl -sfL https://get.k3s.io | sh agent --token=$K3S_TOKEN --server=$K3S_URL 
}

# Function to install k3s as a server
setup_as_server_node() {
    install_tailscale
    configure_tailscale $1 $2
    install_k3s_server
}

# Function to install k3s as an agent
setup_as_agent_node() {
    install_tailscale
    configure_tailscale $1 $2
    install_k3s_agent
}

display_k3s_information() {
    echo "---------------------"
    echo "   k3s information"
    echo "---------------------"
    hostname=$(hostname)
    tailscale_address=$(tailscale status --json | jq -r '.Self.DNSName')
    k3s_join_token=$(sudo cat /var/lib/rancher/k3s/server/node-token)
    echo "Hostname: $hostname"
    echo "Tailscale address: $tailscale_address"
    echo "K3S Join Token: $k3s_join_token"
    echo
    cluster_menu
}

install_headscale(){
    echo "Installing Headscale..."
    read -p "Enter your headscale url: " $headscale_server_url

    # open ports
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8080/tcp
    sudo ufw allow 41641/udp
    sudo ufw allow 3478/udp

    # download headscale
    sudo wget https://github.com/juanfont/headscale/releases/download/v0.22.3/headscale_0.22.3_linux_amd64 -O /usr/local/bin/headscale 
    chmod +x /usr/local/bin/headscale
    sudo mkdir /var/lib/headscale/
    sudo touch /var/lib/headscale/db.sqlite
    sudo mkdir -p /etc/Headscale
    sudo touch /etc/headscale/config.yaml

    # TODO: use sed to modify the config template


}
install_etcd(){
    echo "Installing etcd..."
    ETCD_VER=v3.4.27
    # choose either URL
    DOWNLOAD_URL=${https://github.com/etcd-io/etcd/releases/download}
    sudo curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /usr/local/bin/etcd-${ETCD_VER}-linux-amd64.tar.gz
    chmod +x /usr/local/bin/etcd-${ETCD_VER}-linux-amd64.tar.gz

    # TODO: Create a systemd config file
    # TODO: Enable systemd service


}

install_argo(){
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml

}

cluster_menu() {
    echo "---------------------"
    echo "    Cluster Menu"
    echo "---------------------"
    echo "1. Display k3s information"
    echo "2. Back" 
    read -p "Enter your choice: " choice
    echo

    case $choice in
        1)
            display_k3s_information
            ;;
        2)
            echo
            display_menu
            ;;
        *)
            echo "Invalid choice. Please try again."
            echo
            cluster_menu
            ;;
    esac # Correct ending for case statement
}
headscale_server_menu() {
    echo "-----------------------------"
    echo "    Headscale + etcd Menu"
    echo "-----------------------------"
    echo "1. Install headscale"
    echo "2. Install etcd" 
    echo "3. Install and configure tailscale"
    echo "4. Back" 
    read -p "Enter your choice: " choice
    echo

    case $choice in
        1)
            install_headscale
            ;;
        2)
            install_etcd
            ;;
        2)
            install_tailscale
            configure_tailscale
            ;;
        4)
            echo
            display_menu
            ;;
        *)
            echo "Invalid choice. Please try again."
            echo
            cluster_menu
            ;;
    esac # Correct ending for case statement
}




# Function to display the menu
display_menu() {
    echo ""
    echo "IC5kODg4OGIuICAgICAgICAgICBkOGIgICAgICAgICAgICAgICAgICAgICAgICA4ODhiICAgICBkODg4ICAgICAgICAgIDg4OCAgICAgIGQ4YiA4ODggICAgICAgICAgCmQ4OFAgIFk4OGIgICAgICAgICAgWThQICAgICAgICAgICAgICAgICAgICAgICAgODg4OGIgICBkODg4OCAgICAgICAgICA4ODggICAgICBZOFAgODg4ICAgICAgICAgIAo4ODggICAgODg4ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDg4ODg4Yi5kODg4ODggICAgICAgICAgODg4ICAgICAgICAgIDg4OCAgICAgICAgICAKODg4ICAgICAgICAgLmQ4OGIuICA4ODggODg4ODhiLiAgIC5kODhiLiAgICAgICA4ODhZODg4ODhQODg4ICAuZDg4Yi4gIDg4ODg4Yi4gIDg4OCA4ODggIC5kODhiLiAgCjg4OCAgODg4ODggZDg4IiI4OGIgODg4IDg4OCAiODhiIGQ4OFAiODhiICAgICAgODg4IFk4ODhQIDg4OCBkODgiIjg4YiA4ODggIjg4YiA4ODggODg4IGQ4UCAgWThiIAo4ODggICAgODg4IDg4OCAgODg4IDg4OCA4ODggIDg4OCA4ODggIDg4OCAgICAgIDg4OCAgWThQICA4ODggODg4ICA4ODggODg4ICA4ODggODg4IDg4OCA4ODg4ODg4OCAKWTg4YiAgZDg4UCBZODguLjg4UCA4ODggODg4ICA4ODggWTg4YiA4ODggICAgICA4ODggICAiICAgODg4IFk4OC4uODhQIDg4OCBkODhQIDg4OCA4ODggWThiLiAgICAgCiAiWTg4ODhQODggICJZODhQIiAgODg4IDg4OCAgODg4ICAiWTg4ODg4ICAgICAgODg4ICAgICAgIDg4OCAgIlk4OFAiICA4ODg4OFAiICA4ODggODg4ICAiWTg4ODggIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDg4OCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgWThiIGQ4OFAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAiWTg4UCIg" | base64 -d
    echo ""
    echo "---------------------"
    echo "  Going Mobile Menu"
    echo "---------------------"
    echo "1. Install Headscale + etcd server"
    echo "2. Install as server node"
    echo "3. Install as agent node"
    echo "4. Cluster menu"
    echo "5. Quit"

    read -p "Enter your choice: " choice
    echo

    case $choice in
        1)
            headscale_server_menu
            ;;
        2)
            setup_as_server_node
            ;;
        3)
            setup_as_agent_node
            ;;
        4)
            cluster_menu
            ;;
        5)
            echo "Quitting..."
            exit
            ;;
        *)
            echo "Invalid choice. Please try again."
            echo
            display_menu
            ;;
    esac # Correct ending for case statement
}

# Check if parameters were provided to skip the menu
if [[ $# -gt 0 ]]; then
    if [[ $1 == "server" ]]; then
        setup_as_server_node $2 $3
    elif [[ $1 == "agent" ]]; then
        setup_as_agent_node $2 $3
    else
        echo "Invalid parameter. Usage: $0 [server|agent]"
        exit 1
    fi
else
    display_menu
fi