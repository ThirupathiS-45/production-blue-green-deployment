#!/bin/bash

# Enhanced CI/CD Pipeline with Logging and Error Handling
set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Configuration
LOG_FILE="${PWD}/deployment.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DEPLOYMENT_VERSION=${1:-"auto"}
DRY_RUN=${2:-false}

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}ℹ️  [$TIMESTAMP] $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ [$TIMESTAMP] $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠️  [$TIMESTAMP] $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ [$TIMESTAMP] $1${NC}" | tee -a "$LOG_FILE"
}

# Error handling
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Deployment failed with exit code $exit_code"
        log_info "Check the logs for details: $LOG_FILE"
    fi
}

trap cleanup EXIT

# Pre-deployment validation
validate_environment() {
    log_info "Validating environment..."
    
    # Check if Python virtual environment exists and is activated
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        log_warning "Virtual environment not detected, activating..."
        if [ -f "venv/bin/activate" ]; then
            source venv/bin/activate
            log_success "Virtual environment activated"
        else
            log_error "Virtual environment not found. Run: python -m venv venv"
            exit 1
        fi
    fi

    # Check required tools
    command -v ansible-playbook >/dev/null 2>&1 || { log_error "ansible-playbook not found"; exit 1; }
    command -v docker >/dev/null 2>&1 || { log_error "docker not found"; exit 1; }
    
    # Check Docker service
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        exit 1
    fi

    log_success "Environment validation completed"
}

# Main deployment function
main() {
    log_info "🚀 Starting Enhanced CI/CD Pipeline..."
    log_info "Deployment Version: $DEPLOYMENT_VERSION"
    log_info "Dry Run Mode: $DRY_RUN"
    log_info "Log File: $LOG_FILE"

    validate_environment

    if [ "$DRY_RUN" = "true" ]; then
        log_warning "DRY RUN MODE - No actual changes will be made"
        log_info "Would deploy containers..."
        log_info "Would switch traffic..."
        log_success "Dry run completed successfully!"
        exit 0
    fi

    log_info "📦 Deploying Containers..."
    if ansible-playbook -i inventory.ini deploy.yml --ask-become-pass; then
        log_success "Container deployment completed successfully"
    else
        log_error "Container deployment failed"
        exit 1
    fi

    log_info "🔄 Switching Traffic with Health Checks..."
    if ansible-playbook -i inventory.ini switch.yml --ask-become-pass; then
        log_success "Traffic switching completed successfully"
    else
        log_error "Traffic switching failed - check for automatic rollback"
        exit 1
    fi

    log_success "✅ Deployment Pipeline Completed Successfully!"
    log_info "Access your application: http://localhost"
    log_info "Health check endpoint: http://localhost/health.html"
}

# Show usage if --help is passed
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [version] [dry_run]"
    echo "  version: Deployment version (default: auto)"
    echo "  dry_run: Set to 'true' for dry run mode (default: false)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Normal deployment"
    echo "  $0 v2.1.0            # Deploy specific version"
    echo "  $0 auto true         # Dry run mode"
    exit 0
fi

main "$@"
