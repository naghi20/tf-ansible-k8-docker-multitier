<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/f16591b9-91ec-46d5-ac92-f8c5c0819fd9" />

# 🚀 Automated Kubernetes Bootstrapper: Kubeadm + Terraform + Ansible

This repository delivers an end-to-end sandbox platform designed to help Cloud Engineers and DevOps Architects master the internals of Kubernetes lifecycle management. By decomposing the process into Infrastructure as Code (IaC) and declarative Configuration Management, you will explore exactly what managed provider layers (such as AWS EKS) engineer behind the scenes.

The orchestration workflow provisions enterprise-grade, low-cost raw **AWS EC2 Compute Nodes via Terraform**, dynamic layout inventory maps, and launches structured **Ansible Playbooks** to wire up system dependencies, configure container engines, and configure a resilient, lightweight **Flannel CNI** control plane.

---

## 🏗️ Architecture Blueprint & Execution Pipeline

The automated infrastructure environment lifecycle operates seamlessly across three operational phases:

```text
==========================================================================================
1. DEPLOYMENT LAYER (LOCAL WORKSPACE)
==========================================================================================
 [ Terraform Engine ]                         [ Ansible Automation Engine ]
         │                                                 ▲
         │ (Configures Core Hardware Pools)                 │ (Discovers Target Layout)
         ▼                                                 │
 ┌──────────────────────┐                        ┌─────────┴───────────────┐
 │ AWS EC2 Computes     ├───────────────────────►│ Dynamic Inventory Map   │
 │ Security Ingresses   │  [Writes Topologies]   │ (ansible/inventory.ini) │
 └──────────────────────┘                        └─────────────────────────┘
         │
         ▼
==========================================================================================
2. INFRASTRUCTURE INSTANCE POOLS (AWS SECURITY REGION)
==========================================================================================
 ┌──────────────────────────────────────────────────────────────────────────────────────┐
 │                     Isolated Lab Security Border (lab5-k8s-sg)                      │
 │                                                                                      │
 │  ┌───────────────────────────────────┐        ┌───────────────────────────────────┐  │
 │  │        MASTER CONTROL PLANE       │        │        WORKER COMPUTE NODES       │  │
 │  ├───────────────────────────────────┤        ├───────────────────────────────────┤  │
 │  │ • Containerd Engine Core          │        │ • Containerd Engine Core          │  │
 │  │ • Kubeadm Control Runtime         │◄──────►│ • Automated Join Execution        │  │
 │  │ • Flannel CNI Software Layer      │        │ • Scaled Application Deployments  │  │
 │  │ • CoreDNS Cluster Pods            │        │ • Production Ingress (Port 30080) │  │
 │  └───────────────────────────────────┘        └───────────────────────────────────┘  │
 └──────────────────────────────────────────────────────────────────────────────────────┘
                                                                     ▲
==========================================================================================           │
3. TRAFFIC INGRESS MANAGEMENT                                        │
==========================================================================================           │
 [ Engineering Workstation Client ] ─────────────────────────────────┴── [ HTTP Ingress Access ]
```

1. **Declarative Cloud Provisioning (Terraform)**: Assembles decoupled AWS instances mapped over matching operational security boundaries, exposing internal interfaces for Kubernetes cluster transport and NodePort services.
2. **Environment Discovery Pipeline**: Terraform compiles operational instances dynamically, passing target configurations straight to production-ready variable blueprints (`ansible/inventory.ini`).
3. **Cluster Engine Initialization (Ansible)**: Installs `containerd`, aligns core system systemd settings, triggers multi-node node boots, handles control components, and registers compute workers securely.

---

## 📁 Repository Blueprint Layout

```text
.
├── terraform/                  # Cloud Infrastructure Provisioning System
│   ├── main.tf                 # Active AWS resources & inventory compilation hooks
│   ├── variables.tf            # Scaling maps, compute tags, and regions
│   └── outputs.tf              # Returns newly generated public endpoints
├── ansible/                    # Configuration & Cluster Lifecycle Management
│   ├── ansible.cfg             # Speed optimized setup profiles
│   ├── requirements.yml        # Upstream community collection dependencies
│   ├── site.yml                # Main execution blueprint entrypoint
│   ├── generated/              # Cluster security credentials and configuration files
│   └── roles/
│       ├── common/             # OS performance parameters & memory swapping limits
│       ├── container_runtime/  # Installs containerd engine & cgroup systems
│       ├── kubeadm_repo/       # Pins stable upstream Kubernetes mirrors
│       ├── k8s_master/         # Initializes control engines & outputs credentials
│       └── k8s_worker/         # Automates node cluster join operations
└── k8s/                        # Native Kubernetes Production Objects
    ├── deployment.yaml         # Scaled application configuration targets (Nginx)
    └── service.yaml            # Exposes operational workloads on NodePort 30080
```

---

## 🛠️ Step-by-Step Production Run Guide

### Phase 1: Provision Hardware Layout with Terraform
Initialize provider settings, compile resource targets, and deploy compute components:
```bash
cd terraform
terraform init
terraform apply \
  -var="key_name=your-aws-ssh-key-name" \
  -var="private_key_path=\$HOME/.ssh/your-aws-ssh-key-name.pem" \
  -var="worker_count=2"
```

### Phase 2: Cluster Setup Orchestration via Ansible
Return to your cluster management workspace, satisfy dependencies, and trigger setup playbooks:
```bash
cd ../ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```

### Phase 3: Cluster Connection & Application Deploy
Map your local administrative session context properties directly to your production cluster's fresh orchestration keys:
```bash
export KUBECONFIG=\$(pwd)/generated/kubeconfig
kubectl get nodes -o wide
```

Spin up your test application services and expose your cluster ingress configs:
```bash
kubectl apply -f ../k8s/deployment.yaml
kubectl apply -f ../k8s/service.yaml
```

---

## 🔍 Validation Checkpoints

Confirm that your deployment environment layer has achieved operational readiness:

* **Node Status**: Check health states with `kubectl get nodes` to ensure master and workers report `Ready`.
* **Network Fabrics**: Run `kubectl get pods -n kube-system` to guarantee your CoreDNS and Flannel elements are fully `Running`.
* **Application Ingress**: Check cluster load behaviors by querying node addresses directly on the target public port line: `curl http://<EC2-PUBLIC-IP>:30080`.

---

## 🧼 Tear Down & Cleanup

Avoid unexpected infrastructure costs by deleting resources through Terraform when your lab session concludes:
```bash
cd ../terraform
terraform destroy -auto-approve
```
