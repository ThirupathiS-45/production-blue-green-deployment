# 🚀 Production-Grade Blue-Green Deployment with Ansible & Docker

## 📌 Project Overview

This project implements a production-style Blue-Green deployment architecture using:

- Docker
- Ansible (Infrastructure as Code)
- Nginx (Containerized Reverse Proxy)
- Zero-Downtime Switching
- Automatic Rollback Mechanism
- CI/CD Pipeline Simulation

The system ensures safe, automated, and zero-downtime application deployments.

---

## 🏗 Architecture

Browser → Nginx (Docker Reverse Proxy) → Blue / Green Containers → Docker Network

Deployment Flow:
Deploy → Switch Traffic → Health Check → Rollback (if needed)

---

## ✨ Features

### ✅ Blue-Green Deployment
Two versions of the application run simultaneously:
- Blue (stable version)
- Green (new version)

### ✅ Zero Downtime Switching
Traffic is switched via reverse proxy without stopping containers.

### ✅ Automatic Rollback
If health check fails:
- Traffic automatically reverts to previous stable version.

### ✅ CI/CD Simulation
Pipeline script automates:
1. Container deployment
2. Traffic switching
3. Health validation

### ✅ Infrastructure as Code
All provisioning handled via Ansible playbooks.

---

## 📂 Project Structure

blue-green-deployment/
│
├── app/
│   ├── v1/
│   │   ├── Dockerfile
│   │   └── index.html
│   └── v2/
│       ├── Dockerfile
│       └── index.html
│
├── templates/
│   └── nginx.conf.j2
│
├── deploy.yml
├── switch.yml
├── inventory.ini
├── pipeline.sh
├── README.md
└── venv/

---

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
