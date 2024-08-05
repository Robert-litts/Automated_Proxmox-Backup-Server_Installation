#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print error messages
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

# Function to print success messages
success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

# Function to print info messages
info() {
    echo -e "${YELLOW}INFO: $1${NC}"
}

# Function to print start message
print_start_message() {
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}Starting Deployment and Configuration${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo
}

create_lxc() {
    # Ensure terraform directory exists
    if [ ! -d "$TF_DIR" ]; then
        error "Terraform directory ($TF_DIR) does not exist."
        exit 1
    fi

    # Ensure tfplan file path is valid
    PLAN_FILE="$(pwd)/$TF_DIR/tfplan"
    
    info "Initializing Terraform..."
    if terraform -chdir="$TF_DIR" init; then
        success "Terraform initialized successfully"
    else
        error "Terraform initialization failed"
        exit 1
    fi

    info "Validating Terraform configuration..."
    if terraform -chdir="$TF_DIR" validate; then
        success "Terraform configuration is valid"
    else
        error "Terraform configuration is invalid"
        exit 1
    fi

    info "Planning Terraform changes..."
    if terraform -chdir="$TF_DIR" plan -out="$PLAN_FILE"; then
        success "Terraform plan created successfully"
    else
        error "Terraform plan failed"
        exit 1
    fi

    info "Applying Terraform changes..."
    if terraform -chdir="$TF_DIR" apply -auto-approve "$PLAN_FILE"; then
        success "Terraform apply completed successfully"
    else
        error "Terraform apply failed"
        exit 1
    fi

        # Retrieve container_id from Terraform output
    CONTAINER_ID=$(terraform -chdir="$TF_DIR" output -raw container_id)
    if [ -z "$CONTAINER_ID" ]; then
        error "Failed to retrieve container_id from Terraform output."
        exit 1
    fi
    echo "Container ID: $CONTAINER_ID"


        # Retrieve container_ip from Terraform output
    LXC_IP=$(terraform -chdir="$TF_DIR" output -raw lxc_ip)
    if [ -z "$CONTAINER_ID" ]; then
        error "Failed to retrieve container_id from Terraform output."
        exit 1
    fi
    echo "LXC IP: $LXC_IP"
}

# Function to run the Ansible playbook
run_ansible_playbook() {
    info "Running Ansible playbook..."
    if ansible-playbook -i "$ANSIBLE_DIR/$INVENTORY_FILE" "$ANSIBLE_DIR/$ANSIBLE_PLAYBOOK" -e "container_id=${CONTAINER_ID}" -e "lxc_ip=${LXC_IP}"; then
        success "Ansible playbook executed successfully."
    else
        error "Error running Ansible playbook."
        exit 1
    fi
}

# Main script execution
print_start_message

# Define variables
TF_DIR="terraform"  # Directory where your Terraform configuration is located
ANSIBLE_DIR="ansible"  # Directory where your Ansible files are located
ANSIBLE_PLAYBOOK="main.yaml"  # Your Ansible playbook file
INVENTORY_FILE="inventory.yml"  # The inventory file to be generated

# Create LXC container and fetch IP address
create_lxc

# Generate inventory and run Ansible playbook
run_ansible_playbook

success "Deployment and configuration completed successfully."
