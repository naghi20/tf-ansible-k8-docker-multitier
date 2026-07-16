markdown
<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/f16591b9-91ec-46d5-ac92-f8c5c0819fd9" />

# DIY Kubernetes kubeadm Cluster Bootstrapper (AWS + Terraform + Ansible)

This repository contains a full hands-on lab infrastructure layout designed to help platform engineers understand exactly what managed services like EKS, GKE, or AKS handle under the hood. 

Using **Terraform**, the project provisions raw AWS EC2 computing nodes and generates a dynamic inventory tracking map. It then orchestrates **Ansible** playbooks to completely configure the low-level operating system components, configure container runtimes, initialize a highly stable **kubeadm** control plane with swap memory accommodations, and roll out a lightweight **Flannel CNI** plugin layer.

---

## 🏗️ End-to-End System Architecture

The automated lifecycle operates across three distinct execution phases:

```text
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
|      +--------------------------------─────────────────────────────────────+      |
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

1. **Infrastructure as Code (Terraform)**: Builds 1x Master EC2 instance and Nx Worker instances using an Ubuntu server baseline. It locks them behind a shared Security Group allowing cluster communication, SSH management, and external application ingress. 
2. **Configuration Handoff**: Terraform writes the target cloud properties dynamically into a local `ansible/inventory.ini` template layout file upon successful resource creation.
3. **Cluster Bootstrapping (Ansible)**: Installs `containerd` using matched systemd cgroups, hardcodes local `kubelet` environment variables to tolerate tiny low-memory instances via swap file allocation, executes `kubeadm init`, configures a lightweight `Flannel` CNI overlay, and hooks your workers cleanly into the cluster.

---

## 📁 Repository Directory Layout

```text
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
```

---

## 🛠️ Step-by-Step Lab Execution Flow

### Phase 1: Provision Infrastructure with Terraform
Navigate to the terraform workspace, pull down the required hashing providers, and execute your build plan:
```bash
cd terraform
terraform init
terraform apply \
  -var="key_name=your-aws-ssh-key-name" \
  -var="private_key_path=\$HOME/.ssh/your-aws-ssh-key-name.pem" \
  -var="worker_count=2"
```
*This step automatically outputs your cluster server endpoints and creates your custom `../ansible/inventory.ini` mapping parameters block.*

### Phase 2: Orchestrate the Systems with Ansible
Return to your cluster automation folder, install your repository dependencies, and launch your automated playbook run:
```bash
cd ../ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```
*Ansible handles swap files, matches your cgroup drivers, configures your upstream repos, spins up your cluster master core, configures Flannel, extracts tokens, and cleanly loops your worker targets into place.*

### Phase 3: Connect and Deploy Your Manifests
Point your local management session straight at the freshly fetched automated cluster verification certificate file:
```bash
export KUBECONFIG=\$(pwd)/generated/kubeconfig
kubectl get nodes -o wide
```

Apply your native Nginx application manifests layer into production:
```bash
kubectl apply -f ../k8s/deployment.yaml
kubectl apply -f ../k8s/service.yaml
```

---

## 🔍 Post-Deployment Cluster Validation

Run these commands to confirm that your automated infrastructure is completely operational:

* **Validate Node States**: Run `kubectl get nodes` to confirm your infrastructure pool reports a healthy `Ready` status.
* **Validate Network Stability**: Run `kubectl get pods -n kube-system` to guarantee your CoreDNS and Flannel pods have cleanly entered a `Running 1/1` loop status.
* **Validate Web Access**: Access your application by hitting any master or worker node public IP on your NodePort target: `curl http://<ANY-EC2-PUBLIC-IP>:30080`.

---

## 🧹 Automated Cloud Resource Cleanup

To prevent any unexpected charges pile up on your AWS billing statement after finishing the lab exercises, completely wipe your provisions using Terraform:
```bash
cd ../terraform
terraform destroy \
  -var="key_name=your-aws-ssh-key-name" \
  -var="private_key_path=\$HOME/.ssh/your-aws-ssh-key-name.pem" \
  -var="worker_count=2"
  -auto-approve
```
