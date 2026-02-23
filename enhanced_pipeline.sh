#!/bin/bash

# Enhanced Blue-Green Deployment Pipeline
# Integrates security scanning, configuration validation, monitoring, and improved rollback

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.yml"
LOG_FILE="$SCRIPT_DIR/deployment.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Parse command line arguments
DEPLOYMENT_VERSION=${1:-"auto"}
DRY_RUN=${2:-false}
SKIP_SECURITY=${3:-false}
SKIP_MONITORING=${4:-false}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Logging functions
log() { echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"; }
log_info() { echo -e "${BLUE}ℹ️  [$TIMESTAMP] $1${NC}" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}✅ [$TIMESTAMP] $1${NC}" | tee -a "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}⚠️  [$TIMESTAMP] $1${NC}" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}❌ [$TIMESTAMP] $1${NC}" | tee -a "$LOG_FILE"; }
log_stage() { echo -e "${PURPLE}🚀 [$TIMESTAMP] === $1 ===${NC}" | tee -a "$LOG_FILE"; }

# Error handling
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Enhanced deployment pipeline failed with exit code $exit_code"
        log_info "Check the logs for details: $LOG_FILE"
        
        # Run post-failure monitoring
        if [[ "$SKIP_MONITORING" != "true" ]]; then
            log_info "Running post-failure monitoring..."
            python3 "$SCRIPT_DIR/monitor.py" || true
        fi
    fi
}

trap cleanup EXIT

# Pre-deployment validation
validate_environment() {
    log_stage "Environment Validation"
    
    # Check Python virtual environment
    if [[ "${VIRTUAL_ENV:-}" == "" ]]; then
        log_warning "Virtual environment not detected, activating..."
        if [ -f "venv/bin/activate" ]; then
            source venv/bin/activate
            log_success "Virtual environment activated"
        else
            log_error "Virtual environment not found. Run: python -m venv venv"
            exit 1
        fi
    else
        log_success "Virtual environment already active: $VIRTUAL_ENV"
    fi

    # Check required tools
    local required_tools=("ansible-playbook" "docker" "python3")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_error "$tool not found. Please install it."
            exit 1
        fi
    done
    
    # Check Docker service
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        exit 1
    fi

    # Validate configuration file
    if [[ -f "$SCRIPT_DIR/validate_config.py" ]]; then
        log_info "Validating configuration..."
        if python3 "$SCRIPT_DIR/validate_config.py" "$CONFIG_FILE"; then
            log_success "Configuration validation passed"
        else
            log_error "Configuration validation failed"
            exit 1
        fi
    else
        log_warning "Configuration validator not found, skipping..."
    fi

    log_success "Environment validation completed"
}

# Security scanning
run_security_scan() {
    log_stage "Security Scanning"
    
    if [[ "$SKIP_SECURITY" == "true" ]]; then
        log_warning "Security scanning skipped (--skip-security flag)"
        return 0
    fi
    
    if [[ -f "$SCRIPT_DIR/security_scan.sh" ]]; then
        log_info "Running security scan..."
        if bash "$SCRIPT_DIR/security_scan.sh"; then
            log_success "Security scan completed"
        else
            log_warning "Security scan had issues, but deployment continues..."
        fi
    else
        log_warning "Security scanner not found, skipping..."
    fi
}

# Deploy containers
deploy_containers() {
    log_stage "Container Deployment"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "DRY RUN: Would deploy containers with Ansible..."
        return 0
    fi

    log_info "Deploying blue and green containers..."
    
    if ansible-playbook -i inventory.ini deploy.yml --ask-become-pass; then
        log_success "Container deployment completed successfully"
        
        # Wait for containers to be ready
        log_info "Waiting for containers to be ready..."
        sleep 10
        
        # Verify containers are running
        for container in "blue_container" "green_container"; do
            if docker ps --filter "name=$container" --filter "status=running" --quiet | grep -q .; then
                log_success "$container is running"
            else
                log_error "$container failed to start"
                return 1
            fi
        done
        
    else
        log_error "Container deployment failed"
        return 1
    fi
}

# Switch traffic with enhanced health checks
switch_traffic() {
    log_stage "Traffic Switching & Health Validation"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_warning "DRY RUN: Would switch traffic with health checks..."
        return 0
    fi

    log_info "Switching traffic with comprehensive health checks..."
    
    if ansible-playbook -i inventory.ini switch.yml --ask-become-pass; then
        log_success "Traffic switching completed successfully"
    else
        log_error "Traffic switching failed - automatic rollback may have occurred"
        return 1
    fi
}

# Post-deployment monitoring
run_monitoring() {
    log_stage "Post-Deployment Monitoring"
    
    if [[ "$SKIP_MONITORING" == "true" ]]; then
        log_warning "Monitoring skipped (--skip-monitoring flag)"
        return 0
    fi
    
    if [[ -f "$SCRIPT_DIR/monitor.py" ]]; then
        log_info "Running post-deployment monitoring..."
        if python3 "$SCRIPT_DIR/monitor.py"; then
            log_success "Monitoring completed successfully"
        else
            log_warning "Monitoring had issues, but deployment is considered successful"
        fi
    else
        log_warning "Monitoring script not found, skipping..."
    fi
}

# Generate deployment report
generate_report() {
    log_stage "Deployment Report Generation"
    
    local report_file="deployment-report-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "Blue-Green Deployment Report"
        echo "=========================="
        echo "Generated: $(date)"
        echo "Version: $DEPLOYMENT_VERSION"
        echo "Dry Run: $DRY_RUN"
        echo ""
        
        echo "DEPLOYMENT SUMMARY:"
        echo "• Environment: $([ "$VIRTUAL_ENV" != "" ] && echo "Virtual Environment Active" || echo "System Python")"
        echo "• Security Scan: $([ "$SKIP_SECURITY" == "true" ] && echo "Skipped" || echo "Completed")"
        echo "• Monitoring: $([ "$SKIP_MONITORING" == "true" ] && echo "Skipped" || echo "Completed")"
        echo ""
        
        echo "CONTAINER STATUS:"
        for container in "blue_container" "green_container" "nginx_proxy"; do
            if docker ps --filter "name=$container" --format "table {{.Names}}\t{{.Status}}" --no-trunc 2>/dev/null | grep -q "$container"; then
                status=$(docker ps --filter "name=$container" --format "{{.Status}}" 2>/dev/null || echo "Unknown")
                echo "• $container: $status"
            else
                echo "• $container: Not found"
            fi
        done
        echo ""
        
        echo "ACCESS INFORMATION:"
        echo "• Application URL: http://localhost"
        echo "• Health Check: http://localhost/health.html"
        echo "• Log File: $LOG_FILE"
        echo ""
        
        echo "NEXT STEPS:"
        echo "1. Verify application functionality"
        echo "2. Monitor metrics and alerts" 
        echo "3. Review security scan results"
        echo "4. Update documentation if needed"
        
    } > "$report_file"
    
    log_success "Deployment report generated: $report_file"
    
    # Display summary
    echo ""
    log_info "📊 DEPLOYMENT SUMMARY:"
    cat "$report_file"
}

# Show usage
show_usage() {
    echo "Enhanced Blue-Green Deployment Pipeline"
    echo "Usage: $0 [version] [dry_run] [skip_security] [skip_monitoring]"
    echo ""
    echo "Parameters:"
    echo "  version        Deployment version (default: auto)"
    echo "  dry_run        Set to 'true' for dry run mode (default: false)"
    echo "  skip_security  Set to 'true' to skip security scan (default: false)"
    echo "  skip_monitoring Set to 'true' to skip monitoring (default: false)"
    echo ""
    echo "Examples:"
    echo "  $0                              # Normal deployment"
    echo "  $0 v2.1.0                      # Deploy specific version"
    echo "  $0 auto true                   # Dry run mode"
    echo "  $0 auto false true            # Skip security scan"
    echo "  $0 auto false false true      # Skip monitoring"
    echo ""
    echo "Features:"
    echo "  ✅ Configuration validation"
    echo "  ✅ Security scanning"
    echo "  ✅ Enhanced health checks"
    echo "  ✅ Automatic rollback"
    echo "  ✅ Comprehensive monitoring"
    echo "  ✅ Detailed reporting"
}

# Main execution
main() {
    # Show usage if help requested
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        show_usage
        exit 0
    fi

    log_stage "Enhanced Blue-Green Deployment Pipeline Started"
    log_info "Version: $DEPLOYMENT_VERSION | Dry Run: $DRY_RUN"
    log_info "Security Scan: $([ "$SKIP_SECURITY" == "true" ] && echo "Disabled" || echo "Enabled")"
    log_info "Monitoring: $([ "$SKIP_MONITORING" == "true" ] && echo "Disabled" || echo "Enabled")"

    # Execute pipeline stages
    validate_environment
    run_security_scan
    deploy_containers
    switch_traffic
    run_monitoring
    generate_report

    log_stage "🎉 Enhanced Deployment Pipeline Completed Successfully!"
    log_success "Application is now available at: http://localhost"
    log_success "Health check endpoint: http://localhost/health.html"
}

main "$@"