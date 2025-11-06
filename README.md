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

**For details on usage, inputs, and outputs, see the static-Website/README.md.**

---

### 2. `scalable-Web-Application`

**Description:** Provisions a complete, auto-scaling, and load-balanced web application infrastructure on Google Compute Engine. It is designed for high availability and security by placing instances in a private subnet with a Cloud NAT for egress traffic.

**For details on usage, inputs, and outputs, see the scalable-Web-Application/README.md.**

---

### 3. `container-App-GKE`

**Description:** Deploys a production-ready, VPC-native Google Kubernetes Engine (GKE) cluster. This configuration focuses on security and modern best practices by creating a private cluster with autoscaling node pools.

**For details on usage, inputs, and outputs, see the container-App-GKE/README.md.**
