# HCL-arious-Deployment

A collection of Terraform projects for deploying various infrastructure patterns on Google Cloud Platform. This repository is intended to showcase Infrastructure as Code (IaC) skills for a professional resume.

## Projects

Each folder in this repository contains a standalone Terraform project demonstrating a specific cloud architecture.

### Prerequisites

Before you begin, ensure you have the following installed and configured:
-   **Terraform**: Version `1.3.0` or newer.
-   **Google Cloud SDK**: (`gcloud` CLI) Authenticated to your GCP account (`gcloud auth application-default login`).
-   A Google Cloud Project with the required APIs enabled (e.g., Compute Engine, Kubernetes Engine, Cloud Storage).

### General Usage

To deploy any of the projects, follow these steps from your terminal:

1.  **Navigate to a project directory:**
    ```sh
    cd <project-folder-name>
    ```

2.  **Create a configuration file:**
    Create a file named `terraform.tfvars` and provide the required variables. At a minimum, you will need your GCP `project_id`.

3.  **Initialize Terraform:**
    This will download the necessary providers.
    ```sh
    terraform init
    ```

4.  **Apply the configuration:**
    This will create the resources in your GCP project.
    ```sh
    terraform apply
    ```

---

### 1. `static-Website`

**Description:** Deploys a secure, highly available static website using Google Cloud Storage. This project includes a separate bucket for access logging and provisions placeholder content for immediate demonstration.

**Key Features:**
-   **GCS Website Hosting:** A main bucket configured to serve static web content.
-   **Access Logging:** A separate, cost-effective GCS bucket (`ARCHIVE` class) with a 30-day lifecycle policy to store access logs.
-   **Security:** Enforced public access prevention on the logging bucket and a public-read IAM binding on the website bucket.
-   **Demo Content:** Automatically uploads a sample `index.html` and `404.html` on creation.

**Usage:**
Create a `terraform.tfvars` file in the `static-Website` directory:
```hcl
# terraform.tfvars
project_id = "your-gcp-project-id"
```
After running `terraform apply`, the public URL for the website will be available in the `website_url` output.

---

### 2. `scalable-Web-Application`

**Description:** Provisions a complete, auto-scaling, and load-balanced web application infrastructure on Google Compute Engine. It is designed for high availability and security by placing instances in a private subnet with a Cloud NAT for egress traffic.

**Key Features:**
-   **Custom VPC & Private Subnet:** Isolates compute resources from the public internet.
-   **Cloud NAT:** Allows private instances to access the internet for updates and package installation.
-   **Managed Instance Group (MIG):** Manages a fleet of identical VMs based on an instance template.
-   **Autoscaling:** Automatically scales the number of VMs based on CPU utilization.
-   **External HTTP Load Balancer:** Distributes traffic across healthy instances.
-   **Secure Access:** Includes firewall rules for IAP (Identity-Aware Proxy) SSH, allowing secure shell access without public IPs.
-   **Zero-Downtime Deployments:** The MIG is configured with a proactive rolling update policy.

**Usage:**
Create a `terraform.tfvars` file in the `scalable-Web-Application` directory:
```hcl
# terraform.tfvars
project_id = "your-gcp-project-id"
env_prefix = "dev" // Optional: for naming resources
```
After running `terraform apply`, the public IP for the load balancer will be available in the `load_balancer_ip` output.

---

### 3. `container-App-GKE`

**Description:** Deploys a production-ready, VPC-native Google Kubernetes Engine (GKE) cluster. This configuration focuses on security and modern best practices by creating a private cluster with autoscaling node pools.

**Key Features:**
-   **VPC-Native Cluster:** Pods get native IP addresses from the VPC for better performance and security.
-   **Private Cluster:** Nodes are created without public IP addresses, reducing the attack surface. A Cloud NAT is configured to allow nodes to pull images from public registries.
-   **Release Channels:** Subscribes the cluster to the `REGULAR` release channel for automated, managed GKE version upgrades.
-   **Workload Identity:** The recommended and most secure way to grant Kubernetes service accounts access to GCP APIs.
-   **Autoscaling Node Pool:** The node pool automatically scales based on cluster load.
-   **Principle of Least Privilege:** A dedicated, non-default service account is created for the nodes with specific IAM roles.

**Usage:**
Create a `terraform.tfvars` file in the `container-App-GKE` directory:
```hcl
# terraform.tfvars
project_id   = "your-gcp-project-id"
cluster_name = "my-gke-cluster" // Optional: for naming resources
```
After running `terraform apply`, you can configure `kubectl` by running the command provided in the `kubeconfig` output.
