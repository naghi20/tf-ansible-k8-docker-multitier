markdown
<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/f16591b9-91ec-46d5-ac92-f8c5c0819fd9" />

# 🚀 Automated Kubernetes Bootstrapper: Kubeadm + Terraform + Ansible

This repository delivers an end-to-end sandbox platform designed to help Cloud Engineers and DevOps Architects master the internals of Kubernetes lifecycle management. By decomposing the process into Infrastructure as Code (IaC) and declarative Configuration Management, you will explore exactly what managed provider layers (such as AWS EKS) engineer behind the scenes.

The orchestration workflow provisions enterprise-grade, low-cost raw **AWS EC2 Compute Nodes via Terraform**, dynamic layout inventory maps, and launches structured **Ansible Playbooks** to wire up system dependencies, configure container engines, and configure a resilient, lightweight **Flannel CNI** control plane.


## 🏗️ Architecture Blueprint & Execution Pipeline

The automated infrastructure environment lifecycle operates seamlessly across three operational phases:

+-----------------------------------------------------------------------------------+

|                            LOCAL WORKSPACE (CONTROL NODE)                         |
|                                                                                   |
|   +-----------------------+                    +------------------------------+   |
|   |   Terraform Engine    |                    |       Ansible Engine         |   |
|   |                       |                    |                              |   |
|   |  - Provisions EC2     |                    |  - Reads local inventory     |   |
|   |  - Sets up Groups     |                    |  - Runs common system prep   |   |
|   |  - Compiles inventory |──[Writes File]────►|  - Overrides Swap bounds     |   |
|   +-----------┬-----------+   (inventory.ini)  +--------------┬---------------+   |
+---------------│-----------------------------------------------│-------------------+
                │                                               │
    [Spins up Infrastructure]                       [Configures via SSH]
                │                                               │
                ▼                                               ▼
+───────────────────────────────────────────────────────────────────────────────────+

|                                  AWS TARGET VPC                                   |
|                                                                                   |
|      +----------------─────────────────────────────────────────────────────+      |
|      |                  Isolated Security Group (lab5-k8s-sg)               |      |
|      |                                                                     |      |
|      |   +----------------------------+     +---------------------------+   |      |
|      |   |  Master Control Plane      |     |    Worker Compute Nodes   |   |      |
|      |   |                            |     |                           |   |      |
|      |   |  - containerd runtime      |     |  - containerd runtime     |   |      |
|      |   |  - kubelet (Swap allowed)  |◄───►|  - kubelet (Swap allowed) |   |      |
|      |   |  - Flannel CNI Overlay     |     |  - 3x Nginx Pod Replicas  |   |      |
|      |   |  - CoreDNS (10.244.0.0/16) |     |    (Exposed NodePort)     |   |      |
|      |   +----------------------------+     +---------------------------+   |      |
|      +--------------------------------─────────────────────────────────────+      |
+───────────────────────────────────────────────────────────────────────────────────+
                                                                     ▲
                                                                     │
                                                       [External Client Requests]
                                                       (Access via http://IP:30080)
```

```

1. **Declarative Cloud Provisioning (Terraform)**: Assembles decoupled AWS instances mapped over matching operational security boundaries, exposing internal interfaces for Kubernetes cluster transport and NodePort services.
2. **Environment Discovery Pipeline**: Terraform compiles operational instances dynamically, passing target configurations straight to production-ready variable blueprints (`ansible/inventory.ini`).
3. **Cluster Engine Initialization (Ansible)**: Installs `containerd`, aligns core system systemd settings, triggers multi-node node boots, handles control components, and registers compute workers securely.

---

## 📁 Repository Blueprint Layout

``
.
├── terraform/                  # Infrastructure as Code Workspace
│   ├── main.tf                 # EC2 Resource definitions & Inventory compiler
│   ├── variables.tf            # Region, instance scaling, and key descriptors
│   └── outputs.tf              # Returns newly generated public IPs
├── ansible/                    # Configuration Management Engine
│   ├── ansible.cfg             # Disables host checking for rapid cluster setup
│   ├── requirements.yml        # Installs community.general modules
│   ├── site.yml                # Playbook orchestrating the cluster rollout
│   ├── generated/              # Local storage for dynamic join tokens & kubeconfig
│   └── roles/
│       ├── common/             # Swap file creation, persistence, and kernel settings
│       ├── container_runtime/  # Installs containerd & flips SystemdCgroup switch
│       ├── kubeadm_repo/       # Configures upstream k8s apt software repos
│       ├── k8s_master/         # Automates kubeadm init, flannel, and token extraction
│       └── k8s_worker/         # Executes clean automated cluster entry joins
└── k8s/                        # Native Kubernetes YAML Manifest Files
    ├── deployment.yaml         # 3-replica Nginx application payload
    └── service.yaml            # Exposes workload on NodePort 30080
`



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
