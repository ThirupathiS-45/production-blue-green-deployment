#!/usr/bin/env python3
"""
Configuration validator for Blue-Green Deployment System
Validates YAML configuration against schema requirements
"""

import yaml
import sys
from pathlib import Path

def load_config(config_path="config.yml"):
    """Load and parse YAML configuration file."""
    try:
        with open(config_path, 'r') as file:
            return yaml.safe_load(file)
    except FileNotFoundError:
        print(f"❌ Configuration file not found: {config_path}")
        return None
    except yaml.YAMLError as e:
        print(f"❌ Invalid YAML syntax: {e}")
        return None

def validate_config(config):
    """Validate configuration against required schema."""
    errors = []
    
    # Check required top-level sections
    required_sections = ['deployment']
    for section in required_sections:
        if section not in config:
            errors.append(f"Missing required section: {section}")
    
    if 'deployment' not in config:
        return errors
    
    deployment = config['deployment']
    
    # Validate app configuration
    if 'app' not in deployment:
        errors.append("Missing app configuration")
    else:
        app = deployment['app']
        if 'name' not in app or not app['name']:
            errors.append("App name is required")
            
    # Validate version configuration
    if 'versions' not in deployment:
        errors.append("Missing versions configuration")
    else:
        versions = deployment['versions']
        required_versions = ['blue', 'green']
        for version in required_versions:
            if version not in versions:
                errors.append(f"Missing {version} version configuration")
            else:
                version_config = versions[version]
                required_fields = ['tag', 'port', 'replicas']
                for field in required_fields:
                    if field not in version_config:
                        errors.append(f"Missing {field} in {version} version")
                
                # Validate port ranges
                if 'port' in version_config:
                    port = version_config['port']
                    if not isinstance(port, int) or port < 1024 or port > 65535:
                        errors.append(f"Invalid port {port} for {version} version (must be 1024-65535)")
    
    # Validate network configuration
    if 'network' not in deployment:
        errors.append("Missing network configuration")
    else:
        network = deployment['network']
        if 'name' not in network:
            errors.append("Network name is required")
            
    # Validate health check configuration
    if 'health_checks' in deployment:
        health = deployment['health_checks']
        if 'timeout' in health and (not isinstance(health['timeout'], int) or health['timeout'] < 1):
            errors.append("Health check timeout must be a positive integer")
        if 'retries' in health and (not isinstance(health['retries'], int) or health['retries'] < 1):
            errors.append("Health check retries must be a positive integer")
    
    return errors

def main():
    """Main validation function."""
    config_path = sys.argv[1] if len(sys.argv) > 1 else "config.yml"
    
    print(f"🔍 Validating configuration: {config_path}")
    
    config = load_config(config_path)
    if config is None:
        sys.exit(1)
    
    errors = validate_config(config)
    
    if errors:
        print("❌ Configuration validation failed:")
        for error in errors:
            print(f"   • {error}")
        sys.exit(1)
    else:
        print("✅ Configuration validation passed")
        print(f"   • App: {config['deployment']['app']['name']}")
        print(f"   • Blue version: {config['deployment']['versions']['blue']['tag']}")
        print(f"   • Green version: {config['deployment']['versions']['green']['tag']}")
        print(f"   • Network: {config['deployment']['network']['name']}")
        sys.exit(0)

if __name__ == "__main__":
    main()