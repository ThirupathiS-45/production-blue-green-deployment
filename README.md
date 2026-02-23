# 🚀 Production-Grade Blue-Green Deployment with Ansible & Docker

## 📌 Project Overview

This project implements an **enterprise-grade** Blue-Green deployment architecture with comprehensive DevOps practices:

- **Docker** (Multi-stage builds, Security hardening)
- **Ansible** (Infrastructure as Code with enhanced playbooks)  
- **Nginx** (Containerized Reverse Proxy with health routing)
- **Zero-Downtime Switching** with advanced health checks
- **Automatic Rollback** with comprehensive validation
- **Security Scanning** & vulnerability assessment
- **Real-time Monitoring** & metrics collection
- **Configuration Management** with validation
- **Enhanced CI/CD Pipeline** with multiple execution modes

The system ensures safe, automated, secure, and observable zero-downtime application deployments.

---

## 🏗 Enhanced Architecture

```
Browser → Nginx Proxy → Blue/Green Containers → Docker Network
                ↓
    Health Checks → Monitoring → Alerting → Rollback
                ↓
    Security Scan → Config Validation → Metrics Collection
```

**Deployment Flow:**
1. **Pre-flight** → Config Validation → Security Scan
2. **Deploy** → Build & Start Containers → Health Validation  
3. **Switch** → Traffic Routing → Deep Health Checks → Rollback (if needed)
4. **Monitor** → Metrics Collection → Alert Generation → Report

---

## ✨ Enhanced Features

### 🔄 **Advanced Blue-Green Deployment**
- **Parallel Environments**: Blue (stable) & Green (candidate) versions
- **Intelligent Switching**: Health-check driven traffic routing
- **Rollback Automation**: Instant revert on failure detection
- **Configuration Driven**: YAML-based deployment parameters

### 🏥 **Comprehensive Health Checks** 
- **Multi-endpoint Validation**: Basic connectivity + detailed health APIs
- **Retry Logic**: Configurable retry attempts with exponential backoff
- **Deep Health Validation**: Application metrics, dependencies, performance
- **Failure Detection**: Automatic issue identification and remediation

### 🔒 **Enterprise Security**
- **Container Scanning**: Vulnerability assessment for Docker images  
- **Security Hardening**: Non-root users, minimal attack surface
- **Dockerfile Best Practices**: Multi-stage builds, security validations
- **Compliance Reporting**: Security posture analysis and recommendations

### 📊 **Real-time Monitoring & Observability**
- **System Metrics**: CPU, memory, disk usage tracking
- **Application Performance**: Response times, availability, throughput
- **Container Health**: Status monitoring, restart tracking, uptime analysis
- **Alert Management**: Configurable thresholds, notification system

### 🛠 **Configuration Management**
- **YAML Configuration**: Centralized, version-controlled settings
- **Schema Validation**: Automated config correctness verification  
- **Environment Specific**: Dev/staging/production parameter management
- **Dynamic Updates**: Runtime configuration changes support

### 📈 **Enhanced CI/CD Pipeline**
- **Multi-mode Execution**: Normal, dry-run, selective component execution
- **Comprehensive Logging**: Structured logs with severity levels
- **Error Handling**: Graceful failure management and recovery
- **Reporting**: Detailed deployment reports and metrics

---

## 📂 Project Structure

```
production-blue-green-deployment/
│
├── app/
│   ├── v1/                     # Blue (Stable) Version
│   │   ├── Dockerfile
│   │   └── index.html
│   │
│   └── v2/                     # Green (Release Candidate) Version
│       ├── Dockerfile
│       └── index.html
│
├── templates/
│   └── nginx.conf.j2           # Nginx reverse proxy template
│
├── deploy.yml                  # Initial deployment playbook
├── switch.yml                  # Traffic switching & rollback playbook
├── inventory.ini               # Ansible inventory file
├── pipeline.sh                 # CI/CD simulation script
├── README.md
└── venv/                       # Python virtual environment
```

## ⚙️ Technologies Used

- Docker
- Ansible (Core 2.17+)
- Nginx
- Linux (Ubuntu)
- Bash
- Python Virtual Environment

---

## 🚀 Setup Instructions

### 1️⃣ Create Virtual Environment

python3 -m venv venv
source venv/bin/activate
pip install ansible requests

---

### 2️⃣ Install Docker Collection

ansible-galaxy collection install community.docker

---

### 3️⃣ Deploy Infrastructure

ansible-playbook -i inventory.ini deploy.yml

Access:
http://localhost

---

## 🔄 Switching Deployment

Edit in switch.yml:

active_version: green

Then run:

ansible-playbook -i inventory.ini switch.yml

---

## 🚀 CI/CD Simulation

Run:

./pipeline.sh

Pipeline Flow:
- Deploy containers
- Switch traffic
- Validate health
- Rollback if needed

---

## 🧠 DevOps Concepts Implemented

- Blue-Green Deployment
- Zero Downtime Release
- Reverse Proxy Routing
- Health Check Validation
- Conditional Rollback
- Infrastructure as Code
- CI/CD Automation

---
