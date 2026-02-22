#!/bin/bash

echo "🚀 Starting CI/CD Simulation..."

source venv/bin/activate

echo "📦 Deploying Containers..."
ansible-playbook -i inventory.ini deploy.yml --ask-become-pass

echo "🔄 Switching Traffic..."
ansible-playbook -i inventory.ini switch.yml --ask-become-pass

echo "✅ Deployment Pipeline Completed!"
