#!/bin/bash

# Flask Jenkins Deployment Script
# This script handles the deployment of the Flask application

set -e

# Configuration
APP_NAME="flask-jenkins"
GITHUB_REPO="https://github.com/theunknownodysseus/flask-jenkins.git"
DEPLOY_DIR="/tmp/flask-jenkins"
VENV_DIR="/tmp/flask-jenkins-venv"
PORT="5000"
HOST="0.0.0.0"
LOG_FILE="/tmp/flask-app.log"
PID_FILE="/tmp/flask-app.pid"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v git &> /dev/null; then
        log_error "git is not installed"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        log_error "python3 is not installed"
        exit 1
    fi
    
    log_info "All dependencies are available"
}

setup_environment() {
    log_info "Setting up Python virtual environment..."
    
    if [ ! -d "$VENV_DIR" ]; then
        python3 -m venv "$VENV_DIR"
        log_info "Virtual environment created"
    else
        log_info "Virtual environment already exists"
    fi
    
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip > /dev/null 2>&1
    pip install flask > /dev/null 2>&1
    
    log_info "Python environment is ready"
}

pull_latest_code() {
    log_info "Pulling latest code from repository..."
    
    if [ -d "$DEPLOY_DIR/.git" ]; then
        cd "$DEPLOY_DIR"
        git fetch origin
        git reset --hard origin/main
        git submodule update --init --recursive
    else
        git clone "$GITHUB_REPO" "$DEPLOY_DIR"
        cd "$DEPLOY_DIR"
        git submodule update --init --recursive
    fi
    
    log_info "Code pulled successfully"
}

stop_application() {
    log_info "Stopping existing application..."
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID" || true
            sleep 2
            log_info "Application stopped (PID: $PID)"
        fi
    else
        pkill -f "python3.*app.py" || log_warning "No running instance found"
    fi
    
    sleep 1
}

install_dependencies() {
    log_info "Installing Python dependencies..."
    
    source "$VENV_DIR/bin/activate"
    
    if [ -f "$DEPLOY_DIR/requirements.txt" ]; then
        pip install -r "$DEPLOY_DIR/requirements.txt" > /dev/null 2>&1
    fi
    
    log_info "Dependencies installed"
}

run_tests() {
    log_info "Running tests..."
    
    source "$VENV_DIR/bin/activate"
    cd "$DEPLOY_DIR"
    
    if [ -d "tests" ]; then
        python -m pytest tests/ -v || log_warning "Tests failed, but continuing deployment"
    else
        log_info "No tests directory found, skipping tests"
    fi
}

validate_syntax() {
    log_info "Validating Python syntax..."
    
    source "$VENV_DIR/bin/activate"
    
    if python -m py_compile "$DEPLOY_DIR/backend/app.py"; then
        log_info "Syntax validation passed"
    else
        log_error "Syntax validation failed"
        exit 1
    fi
}

start_application() {
    log_info "Starting Flask application..."
    
    source "$VENV_DIR/bin/activate"
    cd "$DEPLOY_DIR"
    
    # Start the application in background
    nohup python3 backend/app.py > "$LOG_FILE" 2>&1 &
    APP_PID=$!
    echo $APP_PID > "$PID_FILE"
    
    sleep 3
    
    log_info "Application started (PID: $APP_PID)"
}

health_check() {
    log_info "Performing health check..."
    
    # Try to connect multiple times
    for i in {1..10}; do
        if curl -s -f "http://127.0.0.1:$PORT/" > /dev/null 2>&1; then
            log_info "✓ Application is healthy"
            return 0
        fi
        
        if [ $i -lt 10 ]; then
            log_warning "Health check attempt $i failed, retrying..."
            sleep 2
        fi
    done
    
    log_error "Health check failed after 10 attempts"
    log_error "Application logs:"
    tail -20 "$LOG_FILE"
    exit 1
}

show_status() {
    log_info "Deployment Summary"
    echo "===================="
    echo "Application Name: $APP_NAME"
    echo "Deploy Directory: $DEPLOY_DIR"
    echo "Virtual Environment: $VENV_DIR"
    echo "Port: $PORT"
    echo "Host: $HOST"
    echo "Log File: $LOG_FILE"
    echo "PID File: $PID_FILE"
    echo ""
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        echo "Application PID: $PID"
        echo "Access URL: http://localhost:$PORT"
        echo ""
        echo "Last 10 log lines:"
        echo "=================="
        tail -10 "$LOG_FILE"
    fi
}

# Main execution
main() {
    log_info "Starting Flask Jenkins deployment..."
    echo ""
    
    check_dependencies
    setup_environment
    pull_latest_code
    install_dependencies
    validate_syntax
    run_tests
    stop_application
    start_application
    health_check
    
    echo ""
    show_status
    
    log_info "Deployment completed successfully!"
}

# Run main function
main "$@"
