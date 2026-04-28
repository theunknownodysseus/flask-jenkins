#!/bin/bash

# Jenkins Setup Script
# This script helps set up Jenkins for automated deployment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Jenkins Setup for Flask Deployment${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Function to print colored output
print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_warning "This script should be run as root for system-level installation"
    print_info "Run with: sudo $0"
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
fi

print_step "Detected OS: $OS"

# Install Jenkins
install_jenkins() {
    print_step "Installing Jenkins..."
    
    if [ "$OS" == "Ubuntu" ] || [ "$OS" == "Debian GNU/Linux" ]; then
        # Add Jenkins repository
        curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
        sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
        apt-get update
        apt-get install -y openjdk-11-jre-headless jenkins
    else
        print_warning "Automatic installation not supported for this OS"
        print_info "Please install Jenkins manually from: https://jenkins.io/download/"
        return
    fi
    
    print_info "Jenkins installed successfully"
}

# Install dependencies
install_dependencies() {
    print_step "Installing dependencies..."
    
    if [ "$OS" == "Ubuntu" ] || [ "$OS" == "Debian GNU/Linux" ]; then
        apt-get update
        apt-get install -y \
            git \
            python3 \
            python3-pip \
            python3-venv \
            curl \
            wget
    fi
    
    print_info "Dependencies installed"
}

# Start Jenkins
start_jenkins() {
    print_step "Starting Jenkins service..."
    
    if command -v systemctl &> /dev/null; then
        systemctl start jenkins
        systemctl enable jenkins
        print_info "Jenkins started and enabled"
    else
        service jenkins start
        print_info "Jenkins started"
    fi
}

# Get Jenkins initial password
get_jenkins_password() {
    print_step "Retrieving Jenkins initial password..."
    
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
        echo ""
        echo -e "${GREEN}Initial Admin Password:${NC}"
        echo -e "${YELLOW}$PASSWORD${NC}"
        echo ""
    fi
}

# Print next steps
print_next_steps() {
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}Setup Complete!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo ""
    echo "1. Access Jenkins at: ${YELLOW}http://localhost:8080${NC}"
    echo ""
    echo "2. Complete setup:"
    echo "   - Enter the initial password shown above"
    echo "   - Install suggested plugins"
    echo "   - Create your first admin user"
    echo ""
    echo "3. Install required plugins:"
    echo "   - Pipeline"
    echo "   - Git"
    echo "   - GitHub"
    echo "   - GitHub Integration"
    echo ""
    echo "4. Configure GitHub credentials:"
    echo "   - Manage Jenkins → Manage Credentials"
    echo "   - Add GitHub personal access token"
    echo ""
    echo "5. Create Pipeline Job:"
    echo "   - New Item → Pipeline"
    echo "   - Define → Pipeline script from SCM"
    echo "   - SCM: Git"
    echo "   - Repository: https://github.com/theunknownodysseus/flask-jenkins.git"
    echo "   - Script Path: Jenkinsfile"
    echo ""
    echo "6. Set up GitHub Webhook:"
    echo "   - GitHub repo → Settings → Webhooks"
    echo "   - Payload URL: http://your-server:8080/github-webhook/"
    echo "   - Content type: application/json"
    echo ""
    echo "7. Verify deployment:"
    echo "   - Push to main branch"
    echo "   - Check Jenkins builds automatically"
    echo ""
    echo -e "${BLUE}For detailed instructions, see: JENKINS_SETUP.md${NC}"
    echo ""
}

# Main menu
show_menu() {
    echo ""
    echo "What would you like to do?"
    echo "1. Install Jenkins (requires root)"
    echo "2. Install dependencies only"
    echo "3. Start Jenkins"
    echo "4. Show initial admin password"
    echo "5. Run full setup (1+2+3)"
    echo "6. Exit"
    echo ""
}

# Menu loop
while true; do
    show_menu
    read -p "Select option (1-6): " choice
    
    case $choice in
        1)
            install_jenkins
            ;;
        2)
            install_dependencies
            ;;
        3)
            start_jenkins
            ;;
        4)
            get_jenkins_password
            ;;
        5)
            install_dependencies
            install_jenkins
            start_jenkins
            get_jenkins_password
            print_next_steps
            break
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            print_warning "Invalid option. Please select 1-6."
            ;;
    esac
done
