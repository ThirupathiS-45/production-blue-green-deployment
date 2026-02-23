#!/usr/bin/env python3
"""
Monitoring and Metrics Collection for Blue-Green Deployment
Collects deployment metrics, performance data, and system health
"""

import json
import time
import requests
from datetime import datetime, timedelta
from pathlib import Path
import subprocess

class DeploymentMonitor:
    def __init__(self):
        self.metrics_file = "deployment-metrics.json"
        self.alerts_file = "deployment-alerts.json"
        self.start_time = datetime.now()
        
    def collect_system_metrics(self):
        """Collect basic system metrics."""
        try:
            # CPU and memory usage (simulated)
            cpu_usage = self._get_cpu_usage()
            memory_usage = self._get_memory_usage()
            disk_usage = self._get_disk_usage()
            
            return {
                "timestamp": datetime.now().isoformat(),
                "system": {
                    "cpu_usage_percent": cpu_usage,
                    "memory_usage_percent": memory_usage,
                    "disk_usage_percent": disk_usage,
                    "load_average": self._get_load_average()
                }
            }
        except Exception as e:
            return {"error": f"Failed to collect system metrics: {str(e)}"}
    
    def collect_container_metrics(self):
        """Collect Docker container metrics."""
        containers = ["blue_container", "green_container", "nginx_proxy"]
        container_stats = {}
        
        for container in containers:
            try:
                # Get container status
                result = subprocess.run(
                    ["docker", "inspect", "--format", "{{.State.Status}}", container],
                    capture_output=True, text=True, timeout=10
                )
                
                if result.returncode == 0:
                    status = result.stdout.strip()
                    container_stats[container] = {
                        "status": status,
                        "uptime": self._calculate_uptime(container),
                        "restart_count": self._get_restart_count(container)
                    }
                else:
                    container_stats[container] = {"status": "not_found"}
                    
            except Exception as e:
                container_stats[container] = {"error": str(e)}
        
        return {
            "timestamp": datetime.now().isoformat(),
            "containers": container_stats
        }
    
    def collect_application_metrics(self):
        """Collect application performance metrics."""
        endpoints = [
            "http://localhost",
            "http://localhost/health.html"
        ]
        
        metrics = {
            "timestamp": datetime.now().isoformat(),
            "application": {}
        }
        
        for endpoint in endpoints:
            try:
                start_time = time.time()
                response = requests.get(endpoint, timeout=10)
                response_time = (time.time() - start_time) * 1000  # Convert to ms
                
                metrics["application"][endpoint] = {
                    "status_code": response.status_code,
                    "response_time_ms": round(response_time, 2),
                    "content_length": len(response.content),
                    "available": response.status_code == 200
                }
                
            except requests.exceptions.RequestException as e:
                metrics["application"][endpoint] = {
                    "error": str(e),
                    "available": False
                }
        
        return metrics
    
    def collect_deployment_metrics(self):
        """Collect deployment-specific metrics."""
        deployment_log = Path("deployment.log")
        
        metrics = {
            "timestamp": datetime.now().isoformat(),
            "deployment": {
                "last_deployment": None,
                "total_deployments": 0,
                "success_rate": 0,
                "average_deployment_time": 0
            }
        }
        
        if deployment_log.exists():
            try:
                with open(deployment_log, 'r') as f:
                    lines = f.readlines()
                
                # Analyze deployment log
                successful_deployments = len([l for l in lines if "✅" in l and "Deployment Pipeline Completed" in l])
                failed_deployments = len([l for l in lines if "❌" in l and "failed" in l])
                total_deployments = successful_deployments + failed_deployments
                
                if total_deployments > 0:
                    success_rate = (successful_deployments / total_deployments) * 100
                else:
                    success_rate = 0
                
                metrics["deployment"].update({
                    "total_deployments": total_deployments,
                    "successful_deployments": successful_deployments,
                    "failed_deployments": failed_deployments,
                    "success_rate": round(success_rate, 2)
                })
                
            except Exception as e:
                metrics["deployment"]["error"] = str(e)
        
        return metrics
    
    def check_alerts(self, metrics):
        """Check for alert conditions based on metrics."""
        alerts = []
        timestamp = datetime.now().isoformat()
        
        # System alerts
        if "system" in metrics:
            system = metrics["system"]
            if system.get("cpu_usage_percent", 0) > 80:
                alerts.append({
                    "timestamp": timestamp,
                    "severity": "high",
                    "type": "system",
                    "message": f"High CPU usage: {system['cpu_usage_percent']}%"
                })
            
            if system.get("memory_usage_percent", 0) > 85:
                alerts.append({
                    "timestamp": timestamp,
                    "severity": "high", 
                    "type": "system",
                    "message": f"High memory usage: {system['memory_usage_percent']}%"
                })
        
        # Application alerts
        if "application" in metrics:
            for endpoint, data in metrics["application"].items():
                if not data.get("available", True):
                    alerts.append({
                        "timestamp": timestamp,
                        "severity": "critical",
                        "type": "application",
                        "message": f"Endpoint unavailable: {endpoint}"
                    })
                
                response_time = data.get("response_time_ms", 0)
                if response_time > 5000:  # 5 seconds
                    alerts.append({
                        "timestamp": timestamp,
                        "severity": "medium",
                        "type": "performance", 
                        "message": f"Slow response time: {response_time}ms for {endpoint}"
                    })
        
        # Container alerts
        if "containers" in metrics:
            for container, data in metrics["containers"].items():
                if data.get("status") != "running":
                    alerts.append({
                        "timestamp": timestamp,
                        "severity": "critical",
                        "type": "container",
                        "message": f"Container not running: {container} (status: {data.get('status', 'unknown')})"
                    })
        
        return alerts
    
    def save_metrics(self, metrics):
        """Save metrics to file."""
        try:
            # Load existing metrics
            existing_metrics = []
            if Path(self.metrics_file).exists():
                with open(self.metrics_file, 'r') as f:
                    existing_metrics = json.load(f)
            
            # Append new metrics
            existing_metrics.append(metrics)
            
            # Keep only last 100 entries
            if len(existing_metrics) > 100:
                existing_metrics = existing_metrics[-100:]
            
            # Save updated metrics
            with open(self.metrics_file, 'w') as f:
                json.dump(existing_metrics, f, indent=2)
                
        except Exception as e:
            print(f"❌ Failed to save metrics: {e}")
    
    def save_alerts(self, alerts):
        """Save alerts to file."""
        if not alerts:
            return
            
        try:
            existing_alerts = []
            if Path(self.alerts_file).exists():
                with open(self.alerts_file, 'r') as f:
                    existing_alerts = json.load(f)
            
            existing_alerts.extend(alerts)
            
            # Keep only last 50 alerts
            if len(existing_alerts) > 50:
                existing_alerts = existing_alerts[-50:]
            
            with open(self.alerts_file, 'w') as f:
                json.dump(existing_alerts, f, indent=2)
                
        except Exception as e:
            print(f"❌ Failed to save alerts: {e}")
    
    def generate_report(self):
        """Generate monitoring report."""
        report = {
            "generated_at": datetime.now().isoformat(),
            "monitoring_duration": str(datetime.now() - self.start_time),
            "summary": {}
        }
        
        # Load recent metrics
        if Path(self.metrics_file).exists():
            with open(self.metrics_file, 'r') as f:
                metrics = json.load(f)
                report["total_metric_points"] = len(metrics)
                if metrics:
                    latest = metrics[-1]
                    report["latest_status"] = latest
        
        # Load alerts
        if Path(self.alerts_file).exists():
            with open(self.alerts_file, 'r') as f:
                alerts = json.load(f)
                report["total_alerts"] = len(alerts)
                report["recent_alerts"] = alerts[-5:] if alerts else []
        
        return report
    
    # Helper methods (simulated for demo)
    def _get_cpu_usage(self):
        import random
        return round(random.uniform(10, 70), 2)
    
    def _get_memory_usage(self):
        import random
        return round(random.uniform(30, 80), 2)
    
    def _get_disk_usage(self):
        import random
        return round(random.uniform(20, 60), 2)
    
    def _get_load_average(self):
        import random
        return round(random.uniform(0.5, 2.0), 2)
    
    def _calculate_uptime(self, container):
        import random
        return f"{random.randint(1, 24)}h {random.randint(1, 60)}m"
    
    def _get_restart_count(self, container):
        import random
        return random.randint(0, 3)

def main():
    """Main monitoring loop."""
    print("🔍 Starting Blue-Green Deployment Monitoring...")
    
    monitor = DeploymentMonitor()
    
    try:
        # Collect all metrics
        system_metrics = monitor.collect_system_metrics()
        container_metrics = monitor.collect_container_metrics()
        app_metrics = monitor.collect_application_metrics()
        deployment_metrics = monitor.collect_deployment_metrics()
        
        # Combine metrics
        all_metrics = {
            **system_metrics,
            **container_metrics, 
            **app_metrics,
            **deployment_metrics
        }
        
        # Check for alerts
        alerts = monitor.check_alerts(all_metrics)
        
        # Save data
        monitor.save_metrics(all_metrics)
        monitor.save_alerts(alerts)
        
        # Generate and display report
        report = monitor.generate_report()
        
        print("📊 Monitoring Report:")
        print(f"   • System Status: {'✅ Healthy' if system_metrics.get('system') else '❌ Issues'}")
        print(f"   • Application Status: {'✅ Available' if not any(not data.get('available', True) for data in app_metrics.get('application', {}).values()) else '❌ Unavailable'}")
        print(f"   • Active Alerts: {len(alerts)}")
        print(f"   • Metrics File: {monitor.metrics_file}")
        
        if alerts:
            print("\n🚨 Active Alerts:")
            for alert in alerts[-3:]:  # Show last 3 alerts
                print(f"   • {alert['severity'].upper()}: {alert['message']}")
        
        print(f"\n✅ Monitoring completed successfully!")
        
    except Exception as e:
        print(f"❌ Monitoring failed: {e}")

if __name__ == "__main__":
    main()