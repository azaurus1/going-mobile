#!/bin/bash

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
        echo "Configure Tailscale"
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
install_k3s_first_server() {
    echo "Installing k3s as a server..."
    curl -sfL https://get.k3s.io | sh -s - server --cluster-init
}

# Function to install k3s as a server
install_k3s_server() {
    read -p "Enter first k3s server url: " K3S_URL
    read -p "Enter first k3s server token: " K3S_TOKEN
    curl -sfL https://get.k3s.io | sh -s server --server $K3S_URL --token $K3S_TOKEN
}

# Function to install k3s as an agent
install_k3s_agent() {
    echo "Installing k3s as an agent..."
    read -p "Enter first k3s server url: " K3S_URL
    read -p "Enter first k3s server token: " K3S_TOKEN
    curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -
}

# Function to install k3s as a server
setup_as_server_node() {
    read -p "Is this the first server node in the cluster?: " first_node

    case $first_node in
        "Y" | "y" | "Yes" | "yes")
            install_tailscale
            configure_tailscale $1 $2
            install_k3s_first_server
            ;;
        "N" | "n" | "No" | "no")
            install_tailscale
            configure_tailscale $1 $2
            install_k3s_server
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
}

# Function to install k3s as an agent
setup_as_agent_node() {
    install_tailscale
    configure_tailscale $1 $2
    install_k3s_agent
}

join_cluster() {
    read -p "Enter the tailscale DNS address of the K3S server to join: " server_to_join
    read -p "Enter the K3S join token: " join_token
    echo $server_to_join
    sudo k3s server --server $server_to_join --token join_token
}

display_k3s_information() {
    echo "---------------------"
    echo "k3s information"
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

cluster_menu() {
    echo "---------------------"
    echo "Cluster Menu"
    echo "---------------------"
    echo "1. Join cluster"
    echo "2. Display k3s information"
    echo "3. Back" 
    read -p "Enter your choice: " choice
    echo

    case $choice in
        1)
            join_cluster
            ;;
        2)
            display_k3s_information
            ;;
        3)
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
    echo "Going Mobile Menu"
    echo "---------------------"
    echo "1. Install as server node"
    echo "2. Install as agent node"
    echo "3. Cluster menu"
    echo "4. Quit"

    read -p "Enter your choice: " choice
    echo

    case $choice in
        1)
            setup_as_server_node
            ;;
        2)
            setup_as_agent_node
            ;;
        3)
            cluster_menu
            ;;
        4)
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