# Containerized App on Google Kubernetes Engine

Deploys a production-ready, VPC-native Google Kubernetes Engine (GKE) cluster. This configuration focuses on security and modern best practices by creating a private cluster with autoscaling node pools.

## Usage

1.  **Configure:** Create a `terraform.tfvars` file in this directory with the required inputs (at a minimum, `project_id`).
    ```hcl
    # terraform.tfvars
    project_id = "your-gcp-project-id"
    ```

2.  **Deploy:** Run the standard Terraform commands.
    ```sh
    terraform init
    terraform apply
    ```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
